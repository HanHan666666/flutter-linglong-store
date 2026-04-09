# 架构改进分析：迁移约束下的 Flutter 发挥空间

> 生成日期：2026-04-09
> 分析对象：flutter-linglong-store（当前 master）
> 对比基准：rust-linglong-store（Tauri/React 旧版）

## 概述

本项目作为从 Tauri/React 到 Flutter 的迁移，目标是 **"UI 像素级一致" + "业务逻辑等价"**。这个目标本身就是一个强约束——很多设计决策不是"Flutter 应该怎么做"，而是"React/Rust 版是怎么做的，我怎么在 Flutter 里实现同样的效果"。

本文档识别出当前项目中因迁移约束而无法采用 Flutter 惯用方案的区域，以及如果不受约束时可以采取的改进方向。

---

## 1. KeepAlive / 页面可见性系统 — 最严重的过度设计

### 现状

`routes.dart` 中实现了约 430 行的自定义 KeepAlive/可见性系统，包含：

- `KeepAlivePageWrapper` — 页面包装器
- `KeepAliveVisibilitySync` — 不可见的同步 Widget
- `PageVisibilityManager` — 单例可见性管理器
- `KeepAlivePageRegistry` — 全局静态注册表
- `VisibilityInherited` — InheritedWidget 子组件访问
- `PageBecameVisibleNotification` / `PageBecameHiddenNotification` — 通知系统

这套系统的存在目的是复制 React 版 `KeepAliveOutlet` 的行为（用 `display: none` 隐藏非活动页面，保留 DOM 和滚动位置）。

### Flutter 本可以怎么做

Flutter 内置方案即可实现同等效果：

- `IndexedStack` — 天然保留所有子树状态
- `AutomaticKeepAliveClientMixin` — 控制页面是否保持存活
- `PageStorageKey` — 自动保存/恢复滚动位置等状态
- `go_router` 的 `ShellRoute` — 本身就会保持 Shell 页面存活

**预计节省：** 500+ 行复杂的生命周期管理代码。

### 被束缚的原因

迁移要求"逻辑 100% 功能还原"，旧版 React 用 visibility toggle 实现 KeepAlive，所以 Flutter 也必须造一套等价的机制。

---

## 2. 安装队列 — 命令式循环而非流式处理

### 现状

`install_queue_provider.dart` 967 行，核心逻辑是：

```
processQueue() → processInstallTask() → Future.delayed(100ms) → 重试
```

这是直接从 React 版的 `setTimeout(() => get().processQueue(), 100)` 翻译过来的。文件中包含：

- 30+ 个方法
- 手动持久化到 SharedPreferences
- `Timer.periodic` 超时检测
- `_isUserCancelled` 标志区分取消和失败
- 崩溃恢复逻辑

### Flutter 本可以怎么做

```dart
// 用 async* 流生成器替代命令式循环
Stream<InstallProgress> installStream() async* {
  while (queue.isNotEmpty) {
    final task = queue.removeFirst();
    yield* executeInstall(task);
  }
}

// 消费者直接 listen
ref.listen(installProgressProvider, (prev, next) { ... });
```

Dart 的 Stream 是一等公民，React 没有原生 Stream 才用 setTimeout 轮询，Flutter 不该继承这个模式。

### 被束缚的原因

注释里多次写着"参考 Rust 版本"，状态机、超时检测、持久化恢复逻辑全部 1:1 照搬 `state_machine.rs` 和 Rust 的 `InstallSlot`。

---

## 3. GlobalApp 提供者 — 上帝对象

### 现状

`global_provider.dart` 438 行，一个 StateNotifier 管理了：

- 国际化（中文/英文切换）
- 主题（light/dark/system）
- 用户偏好设置（9 个字段）
- 环境检测状态（arch、osVersion、llVersion）
- 应用版本信息

共计 17+ 个 setter 方法。

### Flutter 本可以怎么做

拆分为多个独立的 Riverpod Provider：

```
localeProvider          — 只管理语言
themeProvider           — 只管理主题
userPreferencesProvider — 只管理用户偏好
environmentStateProvider— 只管理环境检测
```

Riverpod 天然支持通过 `ref.watch()` 组合多个 provider，不需要一个上帝对象。

### 被束缚的原因

React 版的 Zustand store 就是一个大的 global state object，Flutter 版继承了这种"一个 store 装一切"的思路。

---

## 4. 侧边栏 hover 效果 — 重复造轮子

### 现状

`sidebar.dart` 中每个菜单项都重复写了：

```dart
MouseRegion(
  onEnter: (_) => setState(() => _isHovered = true),
  onExit: (_) => setState(() => _isHovered = false),
  child: ...
)
```

这个模式在 `_MenuItemTileState`、`_DynamicMenuItemTileState`、`_BottomIconButtonState` 中重复了 3+ 次。

### Flutter 本可以怎么做

- 用 `InkWell` 内置的 `onHover` 参数
- 或封装一个可复用的 `HoverableContainer` widget

### 被束缚的原因

React 版用 CSS `:hover` 伪类，Flutter 没有完全等价的 CSS 伪类语法，所以用手动 setState 来模拟同样的视觉过渡效果。

---

## 5. 主题系统 — 明暗主题重复 170 行

### 现状

`theme.dart` 1115 行，其中：

- `lightTheme` 和 `darkTheme` 各有 ~170 行几乎相同的结构，仅替换颜色值
- 所有动画被设为 `Duration.zero`（`AppAnimation.fast = Duration.zero`）
- `AppColors` 中 30+ 个硬编码 hex 值，1:1 对应 Ant Design tokens
- `AppTextStyles` 定义了 7 个字号级别，又在 `TextTheme` 中重复映射了一遍

### Flutter 本可以怎么做

- 用基础主题 + `ThemeData.copyWith()` 派生另一个主题
- 用 `ThemeExtension` 定义自定义设计令牌，避免逐个覆盖子组件
- 保留适度的过渡动画（Flutter 的优势）

### 被束缚的原因

Ant Design 5 的明暗主题 token 值必须像素级匹配，导致无法用 Flutter 的主题派生机制。

---

## 6. 安装状态机 — 直接移植 Rust 代码

### 现状

`install_state_machine.dart` 和 `install_queue_provider.dart` 中的状态机：

- 状态名完全一致：`idle`、`waiting`、`installing`、`succeeded`、`failed`
- 超时值一致：`PROGRESS_TIMEOUT_SECS = 360`
- 注释明确写着"对应 Rust 版本的状态流转"
- 变量命名也保持一致

### Flutter 本可以怎么做

用 Freezed `union` 类型 + `when()` 模式匹配写出更优雅的有限状态机：

```dart
@freezed
sealed class InstallState with _$InstallState {
  const factory InstallState.idle() = _Idle;
  const factory InstallState.waiting(String taskId) = _Waiting;
  const factory InstallState.installing({required String taskId, required double progress}) = _Installing;
  const factory InstallState.succeeded(String taskId) = _Succeeded;
  const factory InstallState.failed({required String taskId, required String error}) = _Failed;
}
```

### 被束缚的原因

Rust 版本的状态机是枚举 + match，Dart 版选择了用类 + 字段来 1:1 映射，而非利用 Freezed 的联合类型。

---

## 7. ProcessManager — 死代码/重复实现

### 现状

`process_manager.dart` 307 行，提供：

- `getRunningApps()` — 解析 `ll-cli ps` 输出
- `killApp()` / `prune()` — 进程管理

但实际的 CLI 操作使用 `LinglongCliRepositoryImpl` → `CliExecutor`，不调用 `ProcessManager`。

`ProcessManager` 有自己独立的 `_parsePsOutput()` 正则解析逻辑，而 `CliOutputParser` 已经做了同样的事。

### 应该做的

**直接删除。** 这是迁移过程中先写了但后来被其他方案取代后没有清理的遗迹。

---

## 8. 仓库层产生本地化字符串 — 架构泄漏

### 现状

`install_messages.dart` 让仓库层（在 widget 树之外）手动调用：

```dart
final localizations = lookupAppLocalizations(locale);
return localizations.installing;
```

这绕过了 Flutter 通过 `BuildContext` 获取本地化的标准机制。

### Flutter 本可以怎么做

仓库返回错误码/枚举：

```dart
enum InstallError { timeout, dependencyMissing, userCancelled }

// 仓库返回类型结果
Future<Either<InstallError, Success>> install(...)
```

由页面/UI 层负责将错误码映射为本地化字符串。

### 被束缚的原因

Rust 版本直接在后端拼接英文错误消息返回。Flutter 版为了给用户看到中文提示，在仓库层硬编码了本地化逻辑。

---

## 9. 没有采用 Rust FFI

### 现状

迁移计划 `docs/01-migration-plan.md` 第 3.3 节推荐了"方案 D"—— 混合 Dart + Rust（通过 `flutter_rust_bridge`），用于安装进度流式传输和网络速度监控。

**实际上没有实现。** `lib/` 目录下没有 Rust 代码，没有 FFI 绑定，pubspec 中没有 `flutter_rust_bridge` 依赖。所有 CLI 交互通过 `dart:io Process.start()` 完成。

### 评估

纯 Dart 方案在当前规模下是可行的，但如果未来需要更高性能的进程通信（如实时网络速度监控、大文件操作），Rust FFI 仍是一个可选项。

---

## 改进优先级汇总

| 改进方向 | 预计收益 | 实施复杂度 | 是否破坏迁移等价 |
|---------|---------|-----------|----------------|
| 替换自定义 KeepAlive 为 Flutter 内置方案 | 减少 ~500 行复杂代码 | 中 | 是（需验证 UI 等价性） |
| 安装队列改为 Stream + AsyncNotifier | 更简洁，更符合 Flutter 习惯 | 中 | 是（需验证业务等价性） |
| 拆分 GlobalApp 为多个专注的 Provider | 更好的关注点分离 | 低 | 否（内部重构） |
| 删除 ProcessManager 死代码 | 减少维护负担 | 低 | 否 |
| 仓库层返回错误码而非本地化字符串 | 更干净的架构 | 低 | 否（内部重构） |
| 主题去重 + 保留适度动画 | 减少 170 行重复代码 | 低 | 是（动画改变需确认） |
| 封装可复用 hover 组件 | 消除重复代码 | 低 | 否 |
| 安装状态机改为 Freezed union | 更类型安全 | 中 | 否（内部重构） |

---

## 结论

**当前项目的代码质量在平均水平之上**，架构分层清晰，文档完善，有测试意识和工程纪律。核心问题不是代码写得差，而是"迁移等价"这个目标本身就是强约束，导致大量非 Flutter 惯用的实现。

如果未来有机会打破迁移约束，优先改进 KeepAlive 系统和安装队列这两个领域，可以获得最大的代码简化收益。
