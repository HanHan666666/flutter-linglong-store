# 评论"有帮助"/"没帮助"投票功能

## 目标
- 将评论区底部的 `有帮助 / 没帮助` 从**纯文本展示**升级为**可交互投票按钮**。
- 后端新增投票接口，支持匿名用户（基于 IP）对评论进行赞同/反对操作。
- 前端投票后乐观更新本地状态，已投票的评论高亮显示且不可重复点击。
- 与现有匿名评论体系保持一致，不引入登录/鉴权机制。

## 现状分析

### 数据库层
`ll_app_comment` 表已有 `agree_num`（赞同数）和 `disagree_num`（反对数）字段，新建评论时初始化为 0。

### 后端 API
当前仅有两个评论相关接口：
| 接口 | 方法 | 用途 |
|------|------|------|
| `/app/getAppCommentList` | POST | 查询评论列表 |
| `/app/saveAppComment` | POST | 新增评论 |

**缺失**：没有提交赞同/反对的接口，`agree_num / disagree_num` 只能通过数据库直接修改或新建评论时初始化。

### 前端 UI
`app_detail_comment_section.dart:230-247` 使用纯 `Text` 组件展示数值：
```dart
Text('$helpfulLabel ${comment.agreeNum}'),      // 不可点击
Text('$notHelpfulLabel ${comment.disagreeNum}'), // 不可点击
```
无点击事件、无回调、无状态管理。

---

## 方案设计

### 核心决策

**防重复策略：基于 IP + CommentId 去重**

- 当前系统无用户登录体系，评论完全匿名。
- 唯一可用的客户端标识是 `client_ip`（与现有 `saveAppComment` 获取 IP 的方式一致）。
- 新建 `ll_app_comment_vote` 表记录每次投票，防止同一 IP 对同一评论重复操作。
- 查询评论列表时额外返回当前 IP 的投票状态（`votedType`），前端据此渲染按钮态。

**是否允许切换投票：不允许。**
- 投票后按钮变为高亮不可点击态，保持简单可控。
- 如需切换需改 vote 表逻辑并增加切换接口，作为后续迭代。

### 交互流程

```
┌─────────────────────────────────────────────────────┐
│                     用户操作                         │
└─────────────────────────────────────────────────────┘
                           │
                           ▼
              用户点击"有帮助"按钮
                           │
              ┌────────────┴────────────┐
              │  前端校验：该评论是否    │
              │  已投票 (votedType != 0)│
              └────────────┬────────────┘
                    已投票 │     未投票
                       │         │
                       ▼         ▼
                    忽略操作   显示 loading 态
                                 │
                                 ▼
                  POST /app/commentVote
                  { commentId, voteType: 1 }
                                 │
                    ┌────────────┴────────────┐
                    │  后端：查询 vote 表       │
                    │  该 IP 是否已对该评论投票 │
                    └────────────┬────────────┘
                         已投票 │        未投票
                            │           │
                            ▼           ▼
                      返回 false    1. 插入 vote 记录
                                   2. agree_num += 1
                                   3. 返回 true
                                        │
                                        ▼
                              前端收到成功响应
                                        │
                                        ▼
                        乐观更新本地状态：
                        - agreeNum + 1
                        - votedType = 1
                        - 按钮高亮 + 不可点击
                                        │
                                        ▼
                              页面重新渲染完成
```

### 错误处理

| 场景 | 后端行为 | 前端行为 |
|------|---------|---------|
| 同一 IP 重复投票 | 返回失败 / 抛异常 | 提示"已投过票"，保持原状态 |
| commentId 不存在 | 返回 false | 提示"操作失败"，保持原状态 |
| 网络异常 | — | catch → 通过通知中心提示错误 |
| 并发竞争（几乎不可能） | DB 层唯一索引兜底 | 同重复投票处理 |

---

## 后端改动

### 1. 数据库 DDL

新建投票记录表：

```sql
-- ============================================
-- 评论投票记录表
-- 记录每个 IP 对每条评论的投票，用于去重和统计
-- ============================================
CREATE TABLE ll_app_comment_vote (
    id          VARCHAR(64)  NOT NULL COMMENT '雪花ID主键',
    comment_id  VARCHAR(64)  NOT NULL COMMENT '关联评论ID',
    app_id      VARCHAR(128) NOT NULL COMMENT '应用包名（冗余，方便查询）',
    vote_type   TINYINT      NOT NULL DEFAULT 1 COMMENT '投票类型: 1=赞同 2=反对',
    client_ip   VARCHAR(64)  NOT NULL COMMENT '客户端IP（去重标识）',
    create_time VARCHAR(32)  NOT NULL DEFAULT '' COMMENT '创建时间',
    PRIMARY KEY (id),
    INDEX idx_comment_ip (comment_id, client_ip)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评论投票记录表';
```

### 2. 新增文件

#### Entity: `AppCommentVote.java`

路径：`ll-common/src/main/java/com/dongpl/entity/AppCommentVote.java`

```java
package com.dongpl.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName(value = "ll_app_comment_vote")
public class AppCommentVote {

    @TableId
    private String id;

    @TableField(value = "comment_id")
    private String commentId;

    @TableField(value = "app_id")
    private String appId;

    /** 投票类型: 1=赞同 2=反对 */
    @TableField(value = "vote_type")
    private Integer voteType;

    @TableField(value = "client_ip")
    private String clientIp;

    @TableField(value = "create_time")
    private String createTime;
}
```

#### Mapper: `AppCommentVoteMapper.java`

路径：`ll-common/src/main/java/com/dongpl/mapper/master/AppCommentVoteMapper.java`

```java
package com.dongpl.mapper.master;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.dongpl.entity.AppCommentVote;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AppCommentVoteMapper extends BaseMapper<AppCommentVote> {
}
```

#### BO: `AppCommentVoteBO.java`

路径：`ll-common/src/main/java/com/dongpl/bo/AppCommentVoteBO.java`

```java
package com.dongpl.bo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(name = "评论投票请求参数", description = "评论投票请求参数")
@Data
public class AppCommentVoteBO {

    @Schema(name = "commentId", description = "评论ID", example = "123456789")
    private String commentId;

    @Schema(name = "voteType", description = "投票类型: 1=赞同 2=反对", example = "1")
    private Integer voteType;
}
```

### 3. 修改文件

#### VO 增加 votedType 字段

文件：`ll-common/src/main/java/com/dongpl/vo/AppCommentVO.java`

新增字段：
```java
/** 当前请求IP的投票状态: 0=未投 1=已赞同 2=已反对 */
@Schema(name = "votedType", description = "当前IP投票状态", example = "0")
private Integer votedType;
```

#### Controller 新增接口

文件：`ll-server/src/main/java/com/dongpl/controller/app/AppController.java`

在 `saveAppComment` 接口之后新增：
```java
@Operation(summary = "评论投票", description = "对评论进行赞同/反对投票-2026年04月新增", method = "POST")
@PostMapping("/commentVote")
public Result<Boolean> commentVote(
    @RequestBody AppCommentVoteBO voteBO,
    HttpServletRequest request) {
    return Result.ok(appService.commentVote(voteBO, request));
}
```

#### Service 接口新增方法

文件：`ll-server/src/main/java/com/dongpl/service/AppService.java`

```java
/** 评论投票 */
Boolean commentVote(AppCommentVoteBO voteBO, HttpServletRequest request);
```

#### ServiceImpl 实现核心逻辑

文件：`ll-server/src/main/java/com/dongpl/service/impl/AppServiceImpl.java`

需要注入 `AppCommentVoteMapper`：
```java
@Resource
private AppCommentVoteMapper appCommentVoteMapper;
```

新增 `commentVote` 方法：
```java
@Override
@Transactional(rollbackFor = Exception.class)
public Boolean commentVote(AppCommentVoteBO voteBO, HttpServletRequest request) {
    // 参数校验
    if (voteBO == null || StrUtil.isBlank(voteBO.getCommentId())
        || voteBO.getVoteType() == null
        || (voteBO.getVoteType() != 1 && voteBO.getVoteType() != 2)) {
        return false;
    }

    String clientIp = IpAddressUtils.getClientIp(request);

    // 1. 校验评论是否存在
    AppComment comment = appCommentMapper.selectById(voteBO.getCommentId());
    if (comment == null) {
        return false;
    }

    // 2. 检查该 IP 是否已对该评论投过票
    LambdaQueryWrapper<AppCommentVote> existQuery = new LambdaQueryWrapper<>();
    existQuery.eq(AppCommentVote::getCommentId, voteBO.getCommentId());
    existQuery.eq(AppCommentVote::getClientIp, clientIp);
    Long existCount = appCommentVoteMapper.selectCount(existQuery);
    if (existCount != null && existCount > 0) {
        // 已投过票，返回失败（不抛异常，让前端友好提示）
        return false;
    }

    // 3. 插入投票记录
    AppCommentVote vote = new AppCommentVote();
    vote.setId(IdUtil.getSnowflakeNextIdStr());
    vote.setCommentId(voteBO.getCommentId());
    vote.setAppId(comment.getAppId());
    vote.setVoteType(voteBO.getVoteType());
    vote.setClientIp(clientIp);
    vote.setCreateTime(DateUtil.now());
    appCommentVoteMapper.insert(vote);

    // 4. 更新评论表的计数（原子性由 @Transactional 保证）
    if (voteBO.getVoteType() == 1) {
        comment.setAgreeNum(comment.getAgreeNum() + 1);
    } else {
        comment.setDisagreeNum(comment.getDisagreeNum() + 1);
    }
    comment.setUpdateTime(DateUtil.now());
    appCommentMapper.updateById(comment);

    return true;
}
```

修改现有 `getAppCommentList` 方法签名（增加 `HttpServletRequest request`），并在返回前填充 `votedType`：

```java
@Override
public List<AppCommentVO> getAppCommentList(
    AppCommentSearchBO searchBO, HttpServletRequest request) {

    // ... 原有查询逻辑不变，得到 List<AppComment> 和转换为 List<AppCommentVO> ...

    // 新增：批量查询当前 IP 对这些评论的投票状态
    String clientIp = IpAddressUtils.getClientIp(request);
    List<String> commentIds = comments.stream()
        .map(AppComment::getId)
        .filter(Objects::nonNull)
        .toList();

    Map<String, Integer> voteMap = new HashMap<>();
    if (!commentIds.isEmpty()) {
        LambdaQueryWrapper<AppCommentVote> voteQuery = new LambdaQueryWrapper<>();
        voteQuery.in(AppCommentVote::getCommentId, commentIds);
        voteQuery.eq(AppCommentVote::getClientIp, clientIp);
        List<AppCommentVote> votes = appCommentVoteMapper.selectList(voteQuery);
        voteMap = votes.stream()
            .collect(Collectors.toMap(
                AppCommentVote::getCommentId,
                AppCommentVote::getVoteType,
                (a, b) -> a));
    }

    // 设置每条评论的 votedType
    for (AppCommentVO vo : result) {
        vo.setVotedType(voteMap.getOrDefault(vo.getId(), 0));
    }
    return result;
}
```

> **注意**：`getAppCommentList` 方法签名变更后，Controller 处调用处也需要同步传入 `request` 参数。

---

## 前端改动

### 1. Domain Model

文件：`lib/domain/models/app_comment.dart`

新增 `votedType` 字段：
```dart
/// 应用评论领域模型
@freezed
sealed class AppComment with _$AppComment {
  const factory AppComment({
    required String id,
    required String appId,
    String? version,
    required String remark,
    /// 赞同数
    @Default(0) int agreeNum,
    /// 反对数
    @Default(0) int disagreeNum,
    /// 当前用户的投票状态: 0=未投, 1=已赞同, 2=已反对
    @Default(0) int votedType,
    /// 创建时间
    String? createTime,
  }) = _AppComment;
}
```

修改后执行代码生成：
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 2. Data Layer — DTO

在 DTO 层新增投票请求模型（参考现有 BO 结构）。

### 3. API Service

文件：`lib/data/datasources/remote/app_api_service.dart`

新增接口方法：
```dart
/// 评论投票（有帮助/没帮助）
/// POST /app/commentVote
@POST('/app/commentVote')
Future<HttpResponse<BooleanResponse>> commentVote(
  @Body() AppCommentVoteBO request,
);
```

### 4. Repository 接口

文件：`lib/domain/repositories/app_repository.dart`

新增抽象方法：
```dart
/// 对评论进行投票
/// [commentId] 评论ID
/// [voteType] 投票类型: 1=赞同 2=反对
Future<bool> voteComment({
  required String commentId,
  required int voteType,
});
```

### 5. Repository 实现

文件：`lib/data/repositories/app_repository_impl.dart`

实现 `voteComment` 方法：
```dart
@override
Future<bool> voteComment({
  required String commentId,
  required int voteType,
}) async {
  AppLogger.info('评论投票: commentId=$commentId, voteType=$voteType');
  final response = await _apiService.commentVote(
    AppCommentVoteBO(commentId: commentId, voteType: voteType),
  );
  return response.data.data ?? false;
}
```

同时在 `_mapToAppComment` 映射方法中补充 `votedType` 字段映射。

### 6. Provider 状态管理

文件：`lib/application/providers/app_detail_provider.dart`

**State 新增字段：**
```dart
/// 正在投票中的评论 ID 集合（用于显示 loading 态）
final Set<String> votingCommentIds;
```

**copyWith 新增参数：**
```dart
Set<String>? votingCommentIds,
```

**新增方法 `voteComment`：**
```dart
/// 对评论进行赞同/反对投票
Future<void> voteComment(String commentId, int voteType) async {
  // 更新 state：标记该评论正在投票
  final newVoting = Set<String>.from(state.votingCommentIds)..add(commentId);
  state = state.copyWith(votingCommentIds: newVoting);

  try {
    final repository = ref.read(appRepositoryProvider);
    final success = await repository.voteComment(
      commentId: commentId,
      voteType: voteType,
    );

    if (!success) {
      throw Exception('投票失败，可能已经投过票了');
    }

    // 乐观更新：直接修改本地评论列表的计数和投票状态
    final updatedComments = state.comments.map((c) {
      if (c.id == commentId) {
        return c.copyWith(
          agreeNum: voteType == 1 ? c.agreeNum + 1 : c.agreeNum,
          disagreeNum: voteType == 2 ? c.disagreeNum + 1 : c.disagreeNum,
          votedType: voteType,
        );
      }
      return c;
    }).toList();

    state = state.copyWith(
      comments: updatedComments,
      votingCommentIds: newVoting..remove(commentId),
    );
  } catch (e) {
    // 移除投票中状态，保留错误供 UI 层展示
    state = state.copyWith(
      votingCommentIds: newVoting..remove(commentId),
    );
    rethrow;
  }
}
```

### 7. UI 组件

文件：`lib/presentation/widgets/app_detail_comment_section.dart`

#### Widget 构造器新增参数

```dart
class AppDetailCommentSection extends StatefulWidget {
  const AppDetailCommentSection({
    // ... 现有参数 ...
    this.onHelpful,          // 新增：点击"有帮助"
    this.onNotHelpful,       // 新增：点击"没帮助"
    this.votingCommentIds,   // 新增：正在投票的评论 ID 集合
    super.key,
  });

  // ... 现有字段 ...

  /// 点击"有帮助"回调，传入评论 ID
  final Future<void> Function(String commentId)? onHelpful;

  /// 点击"没帮助"回调，传入评论 ID
  final Future<void> Function(String commentId)? onNotHelpful;

  /// 正在投票中的评论 ID 集合
  final Set<String>? votingCommentIds;
}
```

#### 替换纯文本为可交互按钮

将原第 230-247 行的 `Wrap(Text(...), Text(...))` 替换为：

```dart
Wrap(
  spacing: 16,
  runSpacing: 8,
  children: [
    _VoteButton(
      label: helpfulLabel,
      count: comment.agreeNum,
      isActive: comment.votedType == 1,
      isVoting: widget.votingCommentIds?.contains(comment.id) ?? false,
      onTap: widget.onHelpful != null
          ? () => widget.onHelpful!.call(comment.id)
          : null,
    ),
    _VoteButton(
      label: notHelpfulLabel,
      count: comment.disagreeNum,
      isActive: comment.votedType == 2,
      isVoting: widget.votingCommentIds?.contains(comment.id) ?? false,
      onTap: widget.onNotHelpful != null
          ? () => widget.onNotHelpful!.call(comment.id)
          : null,
    ),
  ],
),
```

#### 新增 `_VoteButton` 私有组件

```dart
/// 投票按钮组件：支持三种状态 —— 默认（可点击）、已投票（高亮不可点）、投票中（loading）
class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.label,
    required this.count,
    required this.isActive,
    required this.isVoting,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final bool isVoting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return MouseRegion(
      cursor: (isActive || isVoting || onTap == null)
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: (isActive || isVoting) ? null : onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              isVoting ? '...' : '$label $count',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 8. 页面层对接

应用详情页（`app_detail_page.dart` 或对应页面文件）需要将 Provider 的 `voteComment` 方法和 `votingCommentIds` 传入 `AppDetailCommentSection`：

```dart
AppDetailCommentSection(
  // ... 现有参数 ...
  onHelpful: (commentId) =>
      ref.read(appDetailProvider.notifier).voteComment(commentId, 1),
  onNotHelpful: (commentId) =>
      ref.read(appDetailProvider.notifier).voteComment(commentId, 2),
  votingCommentIds: ref.watch(appDetailProvider).votingCommentIds,
)
```

---

## 改动清单汇总

### 后端（Java / MyBatis-Plus）

| 操作 | 文件 | 说明 |
|------|------|------|
| **新增** | `entity/AppCommentVote.java` | 投票记录实体 |
| **新增** | `mapper/master/AppCommentVoteMapper.java` | Mapper 接口 |
| **新增** | `bo/AppCommentVoteBO.java` | 投票请求参数 |
| **修改** | `vo/AppCommentVO.java` | +`votedType` 字段 |
| **修改** | `controller/app/AppController.java` | +`POST /app/commentVote` |
| **修改** | `service/AppService.java` | +`commentVote()` 接口方法 |
| **修改** | `service/impl/AppServiceImpl.java` | 实现投票逻辑 + 修改 `getAppCommentList` 签名 |
| **SQL** | DDL 执行 | 新建 `ll_app_comment_vote` 表 |

### 前端（Flutter）

| 操作 | 文件 | 说明 |
|------|------|------|
| **修改** | `domain/models/app_comment.dart` | +`votedType` 字段 |
| **新增** | `data/models/` 下相关 DTO | `AppCommentVoteBO` 等 |
| **修改** | `data/datasources/remote/app_api_service.dart` | +`commentVote()` API |
| **修改** | `domain/repositories/app_repository.dart` | +`voteComment()` 抽象方法 |
| **修改** | `data/repositories/app_repository_impl.dart` | +实现 + 映射 |
| **修改** | `application/providers/app_detail_provider.dart` | +state 字段 + `voteComment()` 方法 |
| **修改** | `presentation/widgets/app_detail_comment_section.dart` | Text → `_VoteButton` |
| **修改** | 详情页页面文件 | 传入新回调参数 |

---

## 国际化

在以下文件中确认已有 key（通常已存在，无需新增）：

| Key | 中文 | English |
|-----|------|---------|
| `commentHelpful` | 有帮助 | Helpful |
| `commentNotHelpful` | 没帮助 | Not helpful |

如需新增错误提示文案：
| Key | 中文 | English |
|-----|------|---------|
| `commentVoteFailed` | 投票失败，请稍后重试 | Vote failed, please try again |
| `commentAlreadyVoted` | 您已经投过票了 | You have already voted |

---

## 测试覆盖

### 后端
- [ ] `commentVote` 正常赞同流程：插入 vote 记录、`agree_num + 1`
- [ ] `commentVote` 正常反对流程：插入 vote 记录、`disagree_num + 1`
- [ ] `commentVote` 重复投票拦截：同一 IP 第二次返回 false
- [ ] `commentVote` 不存在的 commentId 返回 false
- [ ] `commentVote` 参数校验：缺少 commentId 或非法 voteType
- [ ] `getAppCommentList` 返回正确的 `votedType`（已投/未投）
- [ ] `getAppCommentList` 无投票记录时 `votedType = 0`

### 前端
- [ ] Widget 测试：默认态（灰色图标+文字，可点击）
- [ ] Widget 测试：已投票态（主题色高亮，不可点击）
- [ ] Widget 测试：投票中态（loading 占位）
- [ ] Provider 测试：`voteComment` 成功后乐观更新 `agreeNum` / `votedType`
- [ ] Provider 测试：`voteComment` 失败后保持原状态
- [ ] Provider 测试：已投票的评论再次调用被忽略
- [ ] Repository 单测：正确构造请求体并调用 API

---

## 参考文件

### 后端代码位置
- Controller: `/home/han/linglong-store/linglong-server/ll-server/src/main/java/com/dongpl/controller/app/AppController.java`
- Service 接口: `/home/han/linglong-store/linglong-server/ll-server/src/main/java/com/dongpl/service/AppService.java`
- Service 实现: `/home/han/linglong-store/linglong-server/ll-server/src/main/java/com/dongpl/service/impl/AppServiceImpl.java`
- 评论实体: `/home/han/linglong-store/linglong-server/ll-common/src/main/java/com/dongpl/entity/AppComment.java`
- 评论 VO: `/home/han/linglong-store/linglong-server/ll-common/src/main/java/com/dongpl/vo/AppCommentVO.java`
- 评论保存 BO: `/home/han/linglong-store/linglong-server/ll-common/src/main/java/com/dongpl/bo/AppCommentSaveBO.java`
- 评论查询 BO: `/home/han/linglong-store/linglong-server/ll-common/src/main/java/com/dongpl/bo/AppCommentSearchBO.java`
- 评论 Mapper: `/home/han/linglong-store/linglong-server/ll-common/src/main/java/com/dongpl/mapper/master/AppCommentMapper.java`
- IP 工具类: `/home/han/linglong-store/linglong-server/ll-server/src/main/java/com/dongpl/utils/IpAddressUtils.java`

### 前端代码位置
- 评论组件: `lib/presentation/widgets/app_detail_comment_section.dart`
- 评论模型: `lib/domain/models/app_comment.dart`
- API 服务: `lib/data/datasources/remote/app_api_service.dart`
- Repository 接口: `lib/domain/repositories/app_repository.dart`
- Repository 实现: `lib/data/repositories/app_repository_impl.dart`
- Detail Provider: `lib/application/providers/app_detail_provider.dart`
- 相关文档: `docs/13-app-detail-comment-section.md`
