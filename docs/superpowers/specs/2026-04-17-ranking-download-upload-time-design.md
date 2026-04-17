# 排行榜回归双Tab并添加下载量与上架时间显示

## 背景

Flutter 版本玲珑商店当前有 4 个排行榜 Tab（下载榜、新秀榜、更新榜、热门榜），但后端只提供了 2 个接口：
- `getInstallAppList`：下载量榜数据
- `getNewAppList`：最新上架榜数据

导致 `download` 和 `hot` Tab 数据重复，`rising` 和 `update` Tab 数据重复。

Electron 老版本只有 2 个 Tab（最新上架榜、下载量榜），且卡片展示了上架时间和下载次数，用户可以清晰知道近期上架的软件和下载热度。

Flutter 版本当前缺失这些信息展示。

## 目标

1. 回归到 Electron 版本的 2 个 Tab 结构
2. 在卡片中显示上架时间（相对时间格式，最长7天）
3. 在卡片中显示最近30天下载量（格式："下载 XXX次"）

## 设计

### 1. 数据模型调整

#### RankingType 枚举缩减

**文件**: `lib/domain/models/ranking_models.dart`

**变更**:
- 移除 `hot` 和 `update` 类型
- 只保留 `download` 和 `rising`

```dart
enum RankingType {
  /// 最新上架榜（原 rising）
  rising('rising'),

  /// 下载量榜
  download('download'),
}
```

#### RankingAppInfo 添加字段

**文件**: `lib/domain/models/ranking_models.dart`

**新增字段**:
- `createTime`: String? - 上架时间（ISO 8601 格式，如 "2026-04-01T10:30:00")

```dart
@freezed
sealed class RankingAppInfo with _$RankingAppInfo {
  const factory RankingAppInfo({
    required String appId,
    required String name,
    required String version,
    String? description,
    String? icon,
    String? developer,
    String? category,
    String? size,
    double? rating,
    int? downloadCount,        // 最近30天下载量
    String? createTime,        // 上架时间（新增）
    required int rank,
    @Default(false) bool isInstalled,
    @Default(false) bool hasUpdate,
  }) = _RankingAppInfo;
}
```

### 2. Provider 逻辑调整

**文件**: `lib/application/providers/ranking_provider.dart`

**变更内容**:

1. **删除冗余 API 调用**:
   - 移除 `hot` 和 `update` 的 case 分支

2. **API 调用映射**:
   ```dart
   final response = await switch (type) {
     RankingType.download => apiService.getInstallAppList(
       const PageParams(pageNo: 1, pageSize: 100),
     ),
     RankingType.rising => apiService.getNewAppList(
       const PageParams(pageNo: 1, pageSize: 100),
     ),
   };
   ```

3. **数据转换逻辑**:
   - `download` Tab: 使用 `dto.last30DownloadCount`（最近30天下载量）
   - `rising` Tab: 使用 `dto.createTime`（上架时间）

   ```dart
   return RankingAppInfo(
     appId: dto.appId,
     name: dto.appName,
     version: dto.appVersion ?? '',
     description: dto.appDesc,
     icon: dto.appIcon,
     developer: dto.developerName,
     category: dto.categoryName,
     size: dto.packageSize,
     downloadCount: dto.last30DownloadCount?.toInt(), // 最近30天下载量
     createTime: dto.createTime,                      // 上架时间
     rank: rank,
   );
   ```

### 3. UI 页面调整

**文件**: `lib/presentation/pages/ranking/ranking_page.dart`

**变更内容**:

1. **TabController 长度改为 2**:
   ```dart
   _tabController = TabController(
     length: RankingType.values.length, // 自动计算（现为 2）
     vsync: this,
   );
   ```

2. **Tab 文案国际化**:
   - 使用新的国际化标签：
     - `ranking.rising` → `l10n.rankingTabNewUpload`（"最新上架榜")
     - `ranking.download` → `l10n.rankingTabDownloadCount`（"下载量榜")

### 4. 卡片展示逻辑

**方案**: 在 `_RankingTabContent` 的 `_AppsGrid` 中，根据 Tab 类型展示不同信息。

**实现方式**: 扩展 `AppCard` 组件，新增可选参数：
- `uploadTime`: String? - 上架时间（仅在最新上架榜显示）
- `downloadCountText`: String? - 下载量文本（仅在下载量榜显示）

**卡片底部展示规则**:

| Tab 类型 | 展示内容 | 格式 |
|---------|---------|------|
| 最新上架榜 | 上架时间 | 相对时间："3天前上架"（<7天）或 "2026-04-01上架"（≥7天） |
| 下载量榜 | 下载量 | "下载 1,234次"（千位分隔符） |

**实现位置**:
- 在 `AppCard` 的 `build` 方法中，根据参数在卡片底部添加展示区域
- 使用 `Semantics` 标注，支持屏幕阅读器

### 5. 时间格式化工具

**文件**: `lib/core/utils/format_utils.dart`（新增方法）

**功能**: `formatRelativeTime(String? createTime, AppLocalizations l10n)`

**规则**:
```dart
String formatRelativeTime(String? createTime, AppLocalizations l10n) {
  if (createTime == null) return '';

  final parsed = DateTime.tryParse(createTime);
  if (parsed == null) return '';

  final now = DateTime.now();
  final difference = now.difference(parsed);

  if (difference.inHours < 24) {
    // 小于24小时：显示小时数
    return l10n.uploadedXHoursAgo(difference.inHours);
  } else if (difference.inDays < 7) {
    // 小于7天：显示天数
    return l10n.uploadedXDaysAgo(difference.inDays);
  } else {
    // 超过7天：显示完整日期
    final dateStr = parsed.toIso8601String().split('T')[0]; // "2026-04-01"
    return l10n.uploadedOnDate(dateStr);
  }
}
```

### 6. 下载量格式化

**文件**: `lib/core/utils/format_utils.dart`（新增方法）

**功能**: `formatDownloadCount(int? count, AppLocalizations l10n)`

**规则**:
```dart
String formatDownloadCount(int? count, AppLocalizations l10n) {
  if (count == null || count <= 0) return '';

  // 使用千位分隔符
  final formatted = count.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );

  return l10n.downloadedXTimes(formatted);
}
```

### 7. 国际化字符串

**文件**: `lib/core/i18n/l10n/app_localizations.dart` 及对应的 ARB 文件

**新增字符串**:
```arb
{
  "rankingTabNewUpload": "最新上架榜",
  "rankingTabDownloadCount": "下载量榜",
  "uploadedXHoursAgo": "{count}小时前上架",
  "uploadedXDaysAgo": "{count}天前上架",
  "uploadedOnDate": "{date}上架",
  "downloadedXTimes": "下载 {count}次"
}
```

**占位符说明**:
- `{count}`: 数字（小时数/天数/下载量）
- `{date}`: 日期字符串（YYYY-MM-DD 格式）

### 8. API DTO 映射确认

**文件**: `lib/data/models/api_dto.dart`

**字段已存在**:
- `dto.createTime`: String? - 上架时间（后端已返回）
- `dto.last30DownloadCount`: String? - 最近30天下载量（后端已返回）

**无需修改 DTO 结构**，直接使用现有字段。

### 9. 测试调整

**影响测试文件**:
- `test/unit/application/providers/ranking_provider_test.dart`
- `test/widget/presentation/pages/ranking_page_test.dart`
- `test/unit/core/utils/format_utils_test.dart`（新增）

**测试内容**:
- Provider 测试：验证只调用 2 个 API，数据映射正确
- Widget 测试：验证 Tab 数量、文案、卡片展示正确
- 工具测试：验证时间格式化和下载量格式化逻辑

### 10. 无障碍支持

**卡片底部信息展示**必须遵循无障碍规范：
- 使用 `Semantics` 标注：
  - 上架时间：`Semantics(label: "上架于 2026-04-01")`
  - 下载量：`Semantics(label: "下载次数 1234")`
- 确保屏幕阅读器能正确朗读

### 11. 架构边界

**改动范围**:
- Domain 层：`ranking_models.dart`（模型字段）
- Application 层：`ranking_provider.dart`（业务逻辑）
- Presentation 层：`ranking_page.dart`、`AppCard`（UI展示）
- Core 层：`format_utils.dart`（工具函数）
- I18n 层：国际化字符串

**不受影响**:
- 首页推荐、分类推荐、应用详情等其他模块
- 已安装列表、更新列表等业务逻辑

## 实施步骤

1. 修改 `ranking_models.dart`：缩减枚举、添加字段
2. 修改 `ranking_provider.dart`：删除冗余逻辑、调整数据映射
3. 创建 `format_utils.dart` 工具函数（时间、下载量格式化）
4. 扩展 `AppCard` 组件：添加上架时间和下载量展示参数
5. 修改 `ranking_page.dart`：调整 Tab 数量和文案
6. 新增国际化字符串并生成代码
7. 更新测试文件：provider、widget、utils
8. 运行 `flutter test` 和 `flutter analyze` 验证
9. 手动测试 UI 效果（相对时间、下载量显示）

## 迁移一致性检查

| 检查项 | Electron 版本 | Flutter 版本（目标） | 一致性 |
|-------|--------------|-------------------|--------|
| Tab 数量 | 2（最新上架、下载量） | 2（最新上架榜、下载量榜） | ✅ 一致 |
| Tab 文案 | "最新上架(前100)"、"下载量(前100)" | "最新上架榜"、"下载量榜" | ✅ 一致（文案略微优化） |
| 上架时间显示 | 显示日期 "2026-04-01" | 相对时间（<7天）或完整日期（≥7天） | ✅ 改进（更友好） |
| 下载量显示 | "下载 XXX次" | "下载 XXX次" | ✅ 一致 |
| 后端接口 | getNewAppList、getInstallAppList | 同上 | ✅ 一致 |

## 风险评估

| 风险 | 影响 | 缓解措施 |
|-----|------|---------|
| 后端 createTime 格式不规范 | 时间解析失败，显示空字符串 | 使用 `DateTime.tryParse` 安全解析，null 返回空字符串 |
| 用户不理解相对时间 | 误以为是错误数据 | 超过7天显示完整日期，提供清晰的国际化文案 |
| 下载量数据为 null 或 0 | 显示空字符串影响信息密度 | null/0 时不显示下载量文本，卡片保持简洁 |

## 性能考虑

- 时间格式化计算：在 `build` 方法中调用，不涉及 IO 操作，性能影响极小
- 下载量格式化：纯字符串操作，无性能问题
- Tab 切换缓存机制保持不变，性能不受影响

## 成功标准

1. ✅ Tab 数量减少为 2，无数据重复
2. ✅ 最新上架榜卡片显示相对时间（<7天）或完整日期（≥7天）
3. ✅ 下载量榜卡片显示"下载 XXX次"格式
4. ✅ 无障碍支持完整（屏幕阅读器可朗读）
5. ✅ 所有测试通过（provider、widget、utils）
6. ✅ 静态分析 0 error/0 warning
7. ✅ 迁移一致性达标（与 Electron 版本逻辑对齐）