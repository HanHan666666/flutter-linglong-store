# KeepAlive Visibility Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复 ShellRoute 下 KeepAlive 页面没有被显式标记为 hidden 的问题，确保切离页面后副作用立即暂停，`玲珑进程` 不再在后台每 3 秒继续轮询。

**Architecture:** 保持现有 `VisibilityAwareMixin` 与 `runningProcessProvider` 职责不变，只在路由层补一条“当前路由 -> KeepAlive 包装器可见性”的显式同步链路。`AppShell` 作为当前路由事实来源，驱动注册表同步；`KeepAlivePageWrapper` 负责把同步结果落到 InheritedWidget 和 PageVisibilityManager。

**Tech Stack:** Flutter, Dart, flutter_test, flutter_riverpod, go_router

---

### Task 1: 补齐可见性框架失败测试

**Files:**
- Create: `test/widget/core/config/keepalive_visibility_sync_test.dart`

- [ ] **Step 1: 写失败测试，覆盖路由显式同步**

```dart
expect(eventsByRoute['/my-apps'], contains(PageVisibilityStatus.mountedHidden));
expect(eventsByRoute['/ranking'], contains(PageVisibilityStatus.mountedVisible));
```

- [ ] **Step 2: 运行该测试并确认失败**

Run: `flutter test test/widget/core/config/keepalive_visibility_sync_test.dart`
Expected: FAIL，提示显式同步能力不存在或旧页面没有切到 hidden。

### Task 2: 实现 KeepAlive 显式可见性同步

**Files:**
- Modify: `lib/core/config/routes.dart`
- Modify: `lib/presentation/widgets/app_shell.dart`
- Test: `test/widget/core/config/keepalive_visibility_sync_test.dart`

- [ ] **Step 1: 在路由层增加 KeepAlive 页面注册表**

```dart
class KeepAlivePageRegistry {
  static void register(String routePath, KeepAlivePageWrapperState state) {}
  static void unregister(String routePath, KeepAlivePageWrapperState state) {}
  static void syncVisibleRoute(String currentPath) {}
}
```

- [ ] **Step 2: KeepAlivePageWrapperState 注册/注销自身**

```dart
@override
void initState() {
  super.initState();
  KeepAlivePageRegistry.register(widget.routePath, this);
}
```

- [ ] **Step 3: AppShell 在当前路由变化时显式同步**

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  KeepAlivePageRegistry.syncVisibleRoute(currentPath);
});
```

- [ ] **Step 4: 保持现有可见性事件分发逻辑兼容**

Run: `flutter test test/widget/core/config/keepalive_visibility_sync_test.dart`
Expected: PASS

### Task 3: 补充文档与回归验证

**Files:**
- Modify: `docs/10-linglong-process-management.md`
- Modify: `docs/02-flutter-architecture.md`

- [ ] **Step 1: 在进程管理文档中补充“路由切换显式驱动隐藏”约束**

```md
- KeepAlive 页面是否可见以 Shell 当前路由为准，路由切换时必须显式驱动 hidden/visible，同步进程轮询启停。
```

- [ ] **Step 2: 在架构文档中补充统一可见性机制说明**

```md
- KeepAlivePageWrapper 不允许只依赖 activate/deactivate 猜生命周期；AppShell 必须按当前路由显式同步页面可见性。
```

- [ ] **Step 3: 运行相关测试与最小静态检查**

Run: `flutter test test/widget/core/config/keepalive_visibility_sync_test.dart test/unit/core/config/visibility_aware_mixin_test.dart test/unit/application/providers/running_process_provider_test.dart`
Expected: PASS

Run: `flutter analyze lib/core/config/routes.dart lib/presentation/widgets/app_shell.dart test/widget/core/config/keepalive_visibility_sync_test.dart`
Expected: 0 issues found

- [ ] **Step 4: 检查改动范围并提交**

Run: `git diff -- lib/core/config/routes.dart lib/presentation/widgets/app_shell.dart docs/10-linglong-process-management.md docs/02-flutter-architecture.md test/widget/core/config/keepalive_visibility_sync_test.dart`
Expected: 仅包含本次可见性同步修复链路改动
