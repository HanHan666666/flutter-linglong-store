# 整改方案（一）：问题分析与架构层面整改

> 日期：2026-04-09  
> 范围：lib/ 目录全量代码审查  
> 原则：只改需要改的，控制成本，实用主义

---

## 第一章：死代码清理

以下文件在 `lib/` 中 **零引用**，可直接删除。

| 文件 | 行数 | 说明 |
|------|------|------|
| `lib/core/constants/app_constants.dart` | ~43 | 与 `AppConfig` 重复定义 `appName`/`appVersion`，仅测试 fixture 引用 |
| `lib/core/constants/install_error_codes.dart` | ~43 | 硬编码中文错误码，已被 `InstallMessages` 完全替代 |
| `lib/core/constants/operate_type.dart` | ~32 | `OperateType` 枚举零使用 |
| `lib/core/utils/debounce_throttle.dart` | ~44 | `Debounce`/`Throttle` 零使用；还重定义了 `VoidCallback` |
| `lib/core/utils/app_display.dart` | ~38 | `AppDisplay` 零使用 |

另外：

- `lib/core/widgets/` 空目录，删除。

**改动量**：删 5 个文件 + 1 个空目录，零风险。

---

## 第二章：架构层依赖违规修正

### 2.1 Domain → Data 依赖（严重）

**现状**：`lib/domain/repositories/app_repository.dart` 第 2 行直接 `import '../../data/models/api_dto.dart'`，接口方法返回 `AppDetailDTO`、`AppCommentDTO`、`AppVersionDTO`。

**问题**：Domain 层是最内层，不应依赖 Data 层的 DTO。这使得替换数据源时必须连带修改 Domain 接口。

**整改方案**：

1. 在 `lib/domain/models/` 新建纯领域模型：
   - `app_detail.dart` — `AppDetail`（Freezed）
   - `app_comment.dart` — `AppComment`（Freezed）
   - `app_version.dart` — `AppVersion`（Freezed）
2. 修改 `app_repository.dart` 接口，返回类型改为领域模型。
3. 在 `app_repository_impl.dart` 中添加 DTO → 领域模型的映射。

**改动面**：新增 3 个小模型文件（各 30~50 行），修改 `app_repository.dart` + `app_repository_impl.dart` + `app_detail_page.dart` 中的类型引用。

### 2.2 Application → Presentation 依赖（中等）

**现状**：

| Application 文件 | 违规 import |
|---|---|
| `app_uninstall_service.dart` | `confirm_dialog.dart`, `uninstall_blocked_dialog.dart` |
| `application_card_state_provider.dart` | `install_button.dart`（为了 `InstallButtonState` 枚举） |
| `app_uninstall_provider.dart` | `download_manager_dialog.dart` |

**整改方案**：

1. 将 `InstallButtonState` 枚举从 `install_button.dart` 提取到 `lib/domain/models/install_button_state.dart`。
2. `AppUninstallService` 不应直接弹 Dialog——改为返回 typed result（如枚举），由 Presentation 层决定是否弹窗。这符合 AGENTS.md 2026-03-23 约定。

**改动面**：提取 1 个枚举文件，重构 `AppUninstallService` 的弹窗逻辑到页面层。

### 2.3 UI 状态混入 Domain（中等）

**现状**：`RecommendState` 和 `RankingState`（含 `isLoading`、`isLoadingMore`、`error`、`currentPage`）定义在 `lib/domain/models/` 中。

**问题**：加载/错误/分页是 UI/Application 关注点，不属于领域模型。

**整改方案**：将 `RecommendState` 移至 `recommend_provider.dart` 内部，`RankingState` 移至 `ranking_provider.dart` 内部。`lib/domain/models/` 只保留纯数据类 `RecommendAppInfo`、`RankingAppInfo` 等。

**改动面**：状态类位置迁移，Provider 文件略微增大，Domain 文件缩小。

---

## 第三章：重复状态管理合并

### 3.1 SettingProvider 与 GlobalAppProvider 重叠（严重）

**现状**：两个 Provider 都管理 locale 和 theme mode：

- 都从同一个 SharedPreferences key 读取
- 都写入同一个 key
- 都做同样的 `_invalidateLocaleDependentProviders()`
- `setting_page.dart` 被迫同时调用两者

**整改方案**：

合并为 **`GlobalAppProvider` 作为唯一真相源**。`SettingProvider` 只保留"设置页私有"的逻辑（如缓存清理、prune 操作），locale/theme 的读写全部委托给 `GlobalAppProvider`。

具体做法：
1. 删除 `SettingProvider` 中的 `setLocale()`、`setThemeMode()` 及其 SP 读写。
2. `setting_page.dart` 中 locale/theme 操作统一调 `globalAppProvider`。
3. `SettingProvider` 降级为纯设置操作 Provider（清缓存、prune、环境检测触发等），不再维护自己的 locale/theme 状态。

**改动面**：`setting_provider.dart` 减少 ~100 行，`setting_page.dart` 调整约 10 行调用。

---

## 第四章：代码重复消除

### 4.1 `_resolveApiLang` 重复 4 次

**现状**：完全相同的 locale → `zh_CN`/`en_US` 转换分布在：
- `all_apps_provider.dart`
- `recommend_provider.dart`
- `custom_category_provider.dart`
- `app_repository_impl.dart`

**整改**：提取为 `lib/core/utils/locale_utils.dart` 的 `resolveApiLang(Locale)` 顶层函数。

### 4.2 `_convertApps` 重复 4 次

**现状**：DTO → `RecommendAppInfo` 的相同映射分布在 4 个 Provider 中。

**整改**：在 `lib/data/mappers/` 新建 `app_list_mapper.dart`，提供 `mapAppListToRecommendApps()` 方法。

### 4.3 `_AppsGrid` + `_calculateCrossAxisCount` 重复 5 次

**现状**：5 个页面各自私有定义了相同的响应式网格组件。

**整改**：提取为 `lib/presentation/widgets/responsive_app_grid.dart`
- `ResponsiveAppGrid`：封装响应式列数计算 + SliverGrid
- `LoadingMoreIndicator` / `NoMoreDataIndicator`：替代重复的 `_LoadingMoreItem`/`_NoMoreDataItem`
- `AppGridShimmer`：替代重复的骨架屏

**改动面**：新增 1 个共享 Widget 文件（~120 行），5 个页面各自删除 ~80 行重复代码。

### 4.4 Visibility/KeepAlive 滚动触底模板重复

**现状**：`all_apps`、`custom_category`、`ranking`、`recommend` 页面都有相同的 `_isPageVisible` + `_onScroll` + scroll threshold 200 模板。

**整改**：已有 `VisibilityAwareMixin`，但各页面未统一使用。确认各页面迁移到统一的 Mixin 后，相关模板代码自然消除。这个整改与 4.3 结合，每个列表页可减少 ~50 行样板代码。

---

## 第五章：异常体系统一

### 5.1 CLI 异常类双重定义

**现状**：

- `lib/core/network/api_exceptions.dart` 定义了 sealed `AppException` 体系，含 `CliTimeoutException`、`CliExecutionException`。
- `lib/core/platform/cli_executor.dart` 底部重新定义了同名但独立的 `CliTimeoutException`、`CliExecutionException`、`CliCancelledException`，是普通 `Exception` 子类。

两套类名相同但类型不兼容，`cli_executor.dart` 实际抛出的是自己定义的版本，`api_exceptions.dart` 中的 sealed 版本从未被使用。

**整改**：

1. 删除 `cli_executor.dart` 底部的三个异常类。
2. `cli_executor.dart` 改为 import 并使用 `api_exceptions.dart` 中的 sealed 异常。
3. 如果 sealed 体系缺少 `CliCancelledException`，在 `api_exceptions.dart` 中补充。

**改动面**：`cli_executor.dart` 删 ~20 行 + 改 throw 语句，`api_exceptions.dart` 可能加 1 个类。
