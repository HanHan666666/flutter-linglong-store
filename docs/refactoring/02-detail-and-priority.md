# 整改方案（二）：大文件拆分、规范违规修正与排行榜设计问题

---

## 第六章：大文件拆分

### 6.1 `theme.dart`（~1115 行）→ 拆为 4 个文件

**现状**：8 个独立概念（AppColors、AppTextStyles、AppSpacing、AppRadius、AppShadows、AppAnimation、AppColorPalette、AppTheme）全部堆在一个文件。

**整改**：

```
lib/core/config/
├── theme.dart              → 保留为 barrel export（~10行）
├── theme/
│   ├── app_colors.dart     → AppColors + AppColorPalette（~200行）
│   ├── app_text_styles.dart → AppTextStyles（~100行）
│   ├── app_spacing.dart    → AppSpacing + AppRadius + AppShadows（~80行）
│   ├── app_animation.dart  → AppAnimation（~30行）
│   └── app_theme.dart      → AppTheme (light/dark builder)（~300行）
```

原文件改为 barrel export，外部 import 路径不变。**零破坏性改动**。

### 6.2 `app_detail_page.dart`（~1100 行）→ 拆为 3 个文件

**现状**：Provider 状态类 + Notifier + 页面 Widget 全在一个文件。

**整改**：

```
lib/presentation/pages/app_detail/
├── app_detail_page.dart         → 页面 Widget（~600行）
lib/application/providers/
├── app_detail_provider.dart     → AppDetailState + AppDetail notifier（~250行）
├── app_detail_provider.g.dart   → Riverpod codegen
```

Provider 移到 Application 层，符合分层架构。页面文件瘦身至 ~600 行（仍可接受，内含 10+ 个 `_build*` helper 方法属于 UI 细节）。

### 6.3 `install_queue_provider.dart`（~900 行）→ 拆为 3 个文件

**现状**：状态定义 + 队列处理 + 持久化 + 进度监听 + 取消/重试全在一个文件。

**整改**：

```
lib/application/providers/
├── install_queue_provider.dart  → 主 Provider + 队列调度（~400行）
├── install_queue_state.dart     → InstallQueueState / InstallTask 状态类（~150行）
├── install_queue_persistence.dart → 持久化读写逻辑（~150行）
```

### 6.4 `routes.dart`（~672 行）→ 提取 KeepAlive 组件

**现状**：路由定义 + `KeepAlivePageWrapper` + `PageCacheManager` + `AppErrorPage` + 导航扩展混在一起。

**整改**：

- 提取 `KeepAlivePageWrapper` 到 `lib/core/config/keep_alive_page_wrapper.dart`（~160 行）
- 提取 `AppErrorPage` 到 `lib/presentation/pages/error/app_error_page.dart`（~40 行）
- `routes.dart` 瘦身至 ~400 行（纯路由定义 + shell 构建）

### 6.5 `api_dto.dart`（~810 行）→ 按领域拆分

**现状**：30+ 个 Freezed DTO 类全在一个文件。

**整改**：

```
lib/data/models/
├── api_dto.dart            → barrel export
├── dto/
│   ├── app_dto.dart        → 应用列表/搜索相关 DTO
│   ├── detail_dto.dart     → 详情/版本/评论 DTO
│   ├── category_dto.dart   → 分类/侧边栏 DTO
│   ├── carousel_dto.dart   → 轮播/推荐 DTO
│   └── analytics_dto.dart  → 埋点 DTO
```

原 `api_dto.dart` 改为 barrel export，外部不感知拆分。

---

## 第七章：规范违规修正

### 7.1 ScaffoldMessenger.showSnackBar（24 处违规）

**现状**：AGENTS.md 2026-03-23 明确禁止在 `lib/` 中新增 `ScaffoldMessenger/showSnackBar`，应统一走 `app_notification_helpers.dart`。但目前仍有 24 处违规。

**分布**：

| 文件 | 处数 |
|------|------|
| `app_detail_page.dart` | 7 |
| `setting_page.dart` | 3 |
| `linglong_env_dialog.dart` | 3 |
| `feedback_dialog.dart` | 3 |
| `linglong_process_panel.dart` | 2 |
| `app_card_actions.dart` | 2 |
| `app_uninstall_service.dart` | 2 |
| `recommend_page.dart` | 1 |
| `app_detail_info_section.dart` | 1 |

**整改**：逐文件替换为 `showAppNotification()` / `showAppError()` 等 notification helper。Application 层（`app_uninstall_service.dart`）改为返回 typed result，由页面决定展示。

**改动量**：单纯的 API 替换，每处 1~3 行改动。但需**逐个审查**每处的 context 可用性和语义，不能批量搜索替换。

### 7.2 硬编码中文字符串

**现状**：多个文件存在绕过 `l10n` 的硬编码中文。

**关键位置**：

| 文件 | 示例 |
|------|------|
| `all_apps_page.dart` | `'暂无应用'`、`'该分类下暂无应用'`、`'没有更多了'` |
| `custom_category_page.dart` | `'暂无应用'`、`'该分类下暂无应用'` |
| `ranking_page.dart` | `'暂无排行'`、`'请检查网络连接后重试'` |
| `recommend_page.dart` | `'暂无推荐'`、`'加载中...'`、`'没有更多数据了'` |
| `ranking_models.dart` | `RankingType.label` 返回 `'下载榜'`/`'新秀榜'` |
| `install_queue_provider.dart` | `'安装超时：长时间未收到进度更新'` |
| `launch_provider.dart` | `'正在检测环境...'`、`'正在加载已安装应用...'` |

**整改**：在 `app_zh.arb` / `app_en.arb` 中补充对应 key，然后替换硬编码为 `l10n.xxx`。Domain 层（`ranking_models.dart`）的标签改到 Presentation 层解析。

### 7.3 Setting 页直接使用 Dio 进行版本检查

**现状**：`setting_page.dart` 中 `_checkForUpdate()` 方法直接 `new Dio()` 发请求到 Gitee API，在页面中做 semver 比较。

**问题**：
- 页面层不应包含网络调用
- 项目已有 `version_compare.dart` 工具类但未复用
- Gitee API URL 和 owner 硬编码

**整改**：新建 `lib/application/services/version_check_service.dart`（~60 行），封装版本检查逻辑，复用 `version_compare.dart`。页面只调服务并展示结果。

---

## 第八章：设计问题

### 8.1 排行榜假数据

**现状**：`ranking_provider.dart` 中 `RankingType.update` 和 `RankingType.hot` 两个排行类型：
- 调用的是与 `download`/`rising` 相同的 API（非专用排行接口）
- 下载量/热度值被伪造为 `100 - rank + 1`（即排名第 1 → 显示 100）

**问题**：这是假数据伪装成真数据展示给用户，需要确认 **这是有意为之的临时方案，还是遗留 bug**。

**建议**：
- **方案 A**（后端没有对应接口）：在 UI 上隐藏这两个 Tab，或明确标注为"示例数据"
- **方案 B**（后端有但未对接）：对接正确的 API
- **需要你确认后端现状后决定**

### 8.2 Freezed 使用不一致

**现状**：`recommend_models.dart` 和 `ranking_models.dart` 中，State 类用 `@freezed`，但伴生的 Data 类（`RecommendData`、`RankingData`、`PaginatedResponse`）用手写的 mutable class + 手写 `copyWith`。

**整改**：统一为 Freezed。手写 `copyWith` 是维护负担，也容易漏字段。

---

## 第九章：整改优先级与分批计划

按 **投入产出比** 排序：

### P0：风险最低、收益最大（可立即执行）

| 编号 | 整改项 | 估计改动 | 章节 |
|------|--------|----------|------|
| 1 | 删除 5 个死代码文件 + 空目录 | 删 5 文件 | 第一章 |
| 2 | 提取 `_resolveApiLang` 为共享工具 | 新增 1 文件 ~20 行，改 4 文件 | 4.1 |
| 3 | 提取 `_convertApps` 为共享 Mapper | 新增 1 文件 ~40 行，改 4 文件 | 4.2 |
| 4 | 合并 Setting/Global 重叠状态 | 改 2 文件 | 第三章 |

### P1：架构矫正（需要谨慎但很必要）

| 编号 | 整改项 | 估计改动 | 章节 |
|------|--------|----------|------|
| 5 | Domain → Data 依赖解偶 | 新增 3 模型文件，改接口 + 实现 | 2.1 |
| 6 | Application → Presentation 依赖解偶 | 提取枚举 + 重构卸载服务 | 2.2 |
| 7 | 异常体系统一 | 改 2 文件 | 第五章 |

### P2：代码瘦身（改善可维护性）

| 编号 | 整改项 | 估计改动 | 章节 |
|------|--------|----------|------|
| 8 | 提取 `ResponsiveAppGrid` 共享组件 | 新增 1 文件 ~120 行，改 5 页面 | 4.3 |
| 9 | 拆分 `theme.dart` | 新增 5 文件，原文件改为 barrel | 6.1 |
| 10 | 拆分 `app_detail_page.dart` | Provider 迁移到 application/ | 6.2 |
| 11 | 拆分 `install_queue_provider.dart` | 拆为 3 文件 | 6.3 |

### P3：规范对齐（逐步推进）

| 编号 | 整改项 | 估计改动 | 章节 |
|------|--------|----------|------|
| 12 | ScaffoldMessenger → notification helper | 改 9 文件 24 处 | 7.1 |
| 13 | 硬编码中文 → l10n | 改 7+ 文件 | 7.2 |
| 14 | 版本检查服务化 | 新增 1 服务文件，改 setting_page | 7.3 |

### P4：需要业务确认的

| 编号 | 整改项 | 状态 | 章节 |
|------|--------|------|------|
| 15 | 排行榜假数据处理 | 需确认后端现状 | 8.1 |

---

## 附录：本次审查未涉及的部分

以下方面本次未深入审查，后续可按需追加：

- **测试代码**：`test/` 目录未逐文件审查
- **构建脚本**：`build/scripts/` 未审查
- **CI/CD**：`.github/workflows/` 未审查
- **Rust FFI**：`lib/rust/` 如果存在，未审查
- **性能**：未做 Profile 级别的运行时分析
- **安全**：未做安全审计
