# Secondary Cleanups After KeepAlive Simplification

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 按任务逐项执行。步骤使用 `- [ ]` 复选框语法。

**Goal:** 在 KeepAlive 主重构稳定后，顺手解决与可维护性直接相关、但不应该阻塞主重构交付的 4 类问题：遗留死代码、侧边栏 hover 重复、全局状态过大、安装文案分层泄漏。

**Architecture:** 这部分按两级优先级执行：先做低风险清理（`ProcessManager`、sidebar hover），再做架构边界整改（`GlobalApp` 拆分、`InstallMessages` 上移）。后两项必须单独 PR，不能和 KeepAlive 一起合并。

**Tech Stack:** Flutter, Riverpod, go_router, Widget Test, Unit Test

---

## 执行顺序

### 同一波尾声可做

1. 删除 `ProcessManager`
2. 抽离侧边栏 hover 交互壳

### 下一波独立做

3. 拆分 `GlobalApp`
4. 整改 `InstallMessages` 边界

---

## Task 13：删除遗留 `ProcessManager`

**Files:**
- Delete: `lib/core/platform/process_manager.dart`
- Verify: `lib/application/providers/running_process_provider.dart`
- Verify: `lib/data/repositories/linglong_cli_repository_impl.dart`
- Verify: `lib/data/mappers/cli_output_parser.dart`

### 结论

这项应该做，而且是低风险收益项。

当前正式进程链路已经是：

- `running_process_provider.dart`
- `linglong_cli_repository_impl.dart`
- `cli_output_parser.dart`

`ProcessManager` 保留的价值只剩误导。

### 执行步骤

- [ ] 先全局 grep `ProcessManager`，确认没有真实业务引用
- [ ] 删除 `lib/core/platform/process_manager.dart`
- [ ] 再全局 grep 一次，确认 `lib/` 下已无引用
- [ ] 运行分析与测试，确认没有因导入残留导致编译错误

### 这一步不能做的事

- [ ] 不要在删除时顺手重构 `running_process_provider.dart`
- [ ] 不要顺手改 `LinglongCliRepositoryImpl.killApp()` 的实现
- [ ] 不要把“删除死代码”扩展成“重写进程管理”

---

## Task 14：抽离 `sidebar.dart` 中重复的 hover / active 交互壳

**Files:**
- Create: `lib/presentation/widgets/sidebar_interaction_surface.dart`
- Modify: `lib/presentation/widgets/sidebar.dart`
- Test: `test/widget/presentation/widgets/sidebar_test.dart`

### 目标

把当前 `sidebar.dart` 里 3 处重复模式收敛掉：

- `_MenuItemTileState`
- `_DynamicMenuItemTileState`
- `_BottomIconButtonState`

当前重复点：

- `_isHovered`
- `MouseRegion(onEnter/onExit)`
- hover 背景色切换
- active / inactive / hover 三态背景切换

### 新文件职责

新文件建议只提供一个轻量容器组件，例如：

```dart
class SidebarInteractionSurface extends StatefulWidget {
  const SidebarInteractionSurface({
    required this.isSelected,
    required this.onTap,
    required this.builder,
    this.height,
    this.borderRadius,
    super.key,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext context, bool isHovered) builder;
}
```

### `sidebar.dart` 的预期改法

#### `_MenuItemTile`

把：

- `MouseRegion`
- `GestureDetector`
- `AnimatedContainer`
- `_isHovered`

统一收进 `SidebarInteractionSurface`。

#### `_DynamicMenuItemTile`

同样处理，但保留它自己的 label / icon / route 逻辑。

#### `_BottomIconButton`

同样处理，但注意它是纯 icon 按钮，没有前导竖条。

### 不要在这一步做的事

- [ ] 不要去改 `RankingPage._HoverableTab`
- [ ] 不要顺手把 `Sidebar` 改成 `HookWidget`
- [ ] 不要动现有 spacing / width / tooltip / a11y 行为

### 交付标准

- [ ] `sidebar.dart` 中不再出现 3 份相似 hover 状态机
- [ ] 底部按钮展开态横排、折叠态竖排逻辑不变
- [ ] `sidebar_test.dart` 通过

---

## Task 15：拆分 `GlobalApp`，但先做兼容 façade，不要一步到位硬拆

**Files:**
- Create: `lib/application/providers/app_locale_provider.dart`
- Create: `lib/application/providers/app_theme_mode_provider.dart`
- Create: `lib/application/providers/app_user_preferences_provider.dart`
- Create: `lib/application/providers/app_environment_provider.dart`
- Modify: `lib/application/providers/global_provider.dart`
- Modify: `lib/application/providers/launch_provider.dart`
- Modify: `lib/application/providers/search_provider.dart`
- Modify: `lib/presentation/pages/setting/setting_page.dart`
- Modify: `lib/presentation/widgets/app_shell.dart`
- Modify: `lib/presentation/widgets/feedback_dialog.dart`
- Verify: `lib/core/di/providers.dart`

### 这项为什么不能和 KeepAlive 同批做

因为这不是路由问题，而是全局状态边界问题。捆一起改会把定位范围放大：

- KeepAlive 出 bug，不知道是壳层还是 provider
- locale/theme 出 bug，不知道是路由切换还是状态拆分

所以正确顺序是：

1. 先把 KeepAlive 稳定
2. 再拆 `GlobalApp`

### 目标结构

#### `app_locale_provider.dart`

职责：

- 当前 locale
- 持久化 `_kLanguageKey`
- 语言切换后 invalidate 语言相关 Provider

#### `app_theme_mode_provider.dart`

职责：

- 当前主题模式
- 持久化 `_kThemeModeKey`

#### `app_user_preferences_provider.dart`

职责：

- `UserPreferences`
- 持久化 `_kUserPreferencesKey`
- autoRunAfterInstall 等设置读写

#### `app_environment_provider.dart`

职责：

- `arch`
- `osVersion`
- `llVersion`
- `envReady`
- `checking / installing / checked / reason`

### 兼容策略（必须执行）

在第一版拆分时，**不要马上删 `global_provider.dart`**。

先把它降级成一个兼容 façade：

- 内部 `watch` 4 个新 provider
- 只保留组合态与少量兼容 getter
- 新代码不再新增对 `globalAppProvider` 的直接依赖

### 当前已知引用点（本次必须逐个处理）

- `launch_provider.dart`
- `search_provider.dart`
- `setting_page.dart`
- `app_shell.dart`
- `feedback_dialog.dart`
- `core/di/providers.dart`

### 推荐迁移顺序

- [ ] 先拆 locale provider
- [ ] 再拆 theme provider
- [ ] 再拆 user preferences provider
- [ ] 最后拆 environment provider
- [ ] 等所有直接引用迁移完成后，再考虑删除 façade

### 必须避免的错误做法

- [ ] 不要一次性把所有 setter 全删了再全局修引用
- [ ] 不要在多个 provider 里各自读写 `SharedPreferences` key 的副本常量
- [ ] 不要把“拆分”做成“复制一份旧逻辑到多个文件”

---

## Task 16：把安装文案本地化边界从 Repository 往上收

**Files:**
- Create: `lib/domain/models/install_message_key.dart`
- Create: `lib/application/services/install_progress_localizer.dart`
- Modify: `lib/domain/models/install_progress.dart`
- Modify: `lib/data/repositories/linglong_cli_repository_impl.dart`
- Modify: `lib/application/providers/install_queue_provider.dart`
- Verify: `lib/core/i18n/install_messages.dart`

### 这项为什么排在后面

它是明确的架构优化，但不是当前最痛点。当前实现虽然分层不漂亮，但至少做到了：

- 用户看不到原始 JSON 噪音
- `rawMessage / errorDetail` 和展示文案分离

因此这项应该在 KeepAlive 和 `GlobalApp` 稳定后做。

### 目标结构

#### 第一步：把“显示文案”换成“消息 key”

新增：

```dart
enum InstallMessageKey {
  waitingForInstall,
  waitingForUpdate,
  preparingInstall,
  preparingUpdate,
  installCompleted,
  updateCompleted,
  installCancelled,
  updateCancelled,
  installFailed,
  updateFailed,
  timeout,
  unknownStatus,
  // ... 根据现有文案收敛
}
```

#### 第二步：`InstallProgress` 扩展为“typed message + raw detail”

建议新增字段：

```dart
final InstallMessageKey? messageKey;
final Map<String, String>? messageArgs;
```

现有字段保留：

- `rawMessage`
- `error`
- `errorCode`
- `errorDetail`

#### 第三步：仓储层只负责发 key，不负责发最终本地化字符串

`LinglongCliRepositoryImpl` 以后输出：

- `messageKey`
- `rawMessage`
- `errorDetail`

不再直接输出用户最终可见中文/英文文案。

#### 第四步：Application 层统一做本地化映射

新增 `install_progress_localizer.dart`，负责：

- 读取 `InstallMessages`
- 根据 `messageKey + args` 生成最终 `InstallTask.message`

### 这样拆的好处

- Repository 不再依赖 `InstallMessages`
- CLI 原始语义与 UI 展示语义解耦
- 以后如果桌面通知、日志、页面展示要区分文案，不需要再回头拆 repository

### 这一步不要做的事

- [ ] 不要直接把所有字符串改成 enum，然后把 UI 搞崩
- [ ] 不要删除 `rawMessage` 和 `errorDetail`
- [ ] 不要让页面层自己各自翻译 `messageKey`

本次的唯一真相源应该在 **Application 层**。

---

## 执行建议：第二波怎么拆 PR

### PR 2A：低风险整理

包含：

- 删除 `ProcessManager`
- 抽侧边栏 hover 交互壳

### PR 2B：全局状态拆分

包含：

- 4 个新 provider
- `global_provider.dart` 降级 façade
- 引用方渐进迁移

### PR 2C：安装文案边界整改

包含：

- `InstallMessageKey`
- `InstallProgress` typed message
- repository -> application 本地化职责重排

---

## 这个文档的底线原则

### 原则 1：低风险项和高耦合项不能混 PR

- `ProcessManager`、sidebar hover：低风险
- `GlobalApp`、`InstallMessages`：高耦合

必须拆开。

### 原则 2：不要拿“分层更优雅”当理由一次性大手术

正确做法是：

- 先加兼容层
- 再迁移引用
- 最后删旧入口

### 原则 3：只做我已经明确建议过的内容

不要自行扩写成：

- 主题系统大重构
- 安装状态机全面重写
- 所有 Provider 一次性重命名

这次不是“全项目革命”，而是“主线路瘦身 + 几个高价值收尾”。

---

## 交接到最后一份文档

执行收尾与验证时，继续看：

- `04-validation-rollout.md`
