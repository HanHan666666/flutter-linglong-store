# KeepAlive Core Router/Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 按任务逐项执行。步骤使用 `- [ ]` 复选框语法。

**Goal:** 用 `AppShell` 内部的懒加载 `IndexedStack` 替换当前自定义 KeepAlive 路由包装层，同时保持侧边栏壳层、普通二级页面路由和现有用户操作路径不变。

**Architecture:** `ShellRoute` 继续负责壳层；4 个主页面由 `AppShell` 直接托管并按需放入 `IndexedStack`；当前匹配到二级路由时，仅把二级页面作为覆盖层显示在内容区。当前激活主页面通过极小作用域下发给页面，用于暂停/恢复副作用。

**Tech Stack:** Flutter, go_router 14.6.x, Riverpod, Widget Test

---

## 目标文件结构

### 新增

- `lib/core/config/shell_primary_route.dart`
- `lib/core/config/shell_branch_visibility.dart`

### 修改

- `lib/core/config/routes.dart`
- `lib/presentation/widgets/app_shell.dart`

### 待删除（必须在页面迁移完成后再删）

- `lib/core/config/keepalive_visibility_sync.dart`
- `lib/core/config/page_visibility.dart`
- `lib/core/config/visibility_aware_mixin.dart`
- `lib/core/config/keepalive_paint_gate.dart`

---

## Task 1：建立主页面枚举与路径映射

**Files:**
- Create: `lib/core/config/shell_primary_route.dart`
- Modify: `lib/core/config/routes.dart`
- Test: `test/widget/core/config/shell_branch_visibility_test.dart`

### 目标

把“哪些页面属于主侧边栏固定页”收敛到一个单独文件，后续所有主页面判断都不再散落在：

- `keepAliveRoutes`
- 各页面的 `routePath`
- `Sidebar` 选中态判断
- `AppShell` 中的特殊字符串分支

### 建议代码骨架

```dart
import 'routes.dart';

enum ShellPrimaryRoute {
  recommend,
  allApps,
  ranking,
  myApps;

  String get path => switch (this) {
    ShellPrimaryRoute.recommend => AppRoutes.recommend,
    ShellPrimaryRoute.allApps => AppRoutes.allApps,
    ShellPrimaryRoute.ranking => AppRoutes.ranking,
    ShellPrimaryRoute.myApps => AppRoutes.myApps,
  };

  static ShellPrimaryRoute? tryParse(String path) {
    for (final value in ShellPrimaryRoute.values) {
      if (value.path == path) {
        return value;
      }
    }
    return null;
  }

  static bool isPrimaryPath(String path) => tryParse(path) != null;
}
```

### 执行步骤

- [ ] 新建 `shell_primary_route.dart`，只保留 4 个固定主页面枚举与路径映射
- [ ] 不要在这个文件里放任何 UI 逻辑、Provider 或路由 builder
- [ ] 在 `routes.dart` 中移除 `keepAliveRoutes` 常量，后续统一改为 `ShellPrimaryRoute.isPrimaryPath()`
- [ ] 先不删除旧 KeepAlive 文件，避免一次改太多导致回归难排查

### 注意事项

- 这个枚举文件必须足够“傻”，只做映射，不做状态管理
- 不要把 `/setting`、`/search_list`、`/update_apps`、`/custom_category/:code`、`/app/:id` 塞进来

---

## Task 2：建立新的“主页面激活作用域”并替换旧可见性状态机入口

**Files:**
- Create: `lib/core/config/shell_branch_visibility.dart`
- Test: `test/widget/core/config/shell_branch_visibility_test.dart`

### 目标

用一个很小的作用域替换：

- `PageVisibilityManager`
- `PageVisibilityStatus`
- `PageVisibilityEvent`
- `VisibilityInherited`
- `VisibilityAwareMixin`

新方案只解决一个问题：

> 当前某个主页面是不是“激活中的那个主页面”？

### 新文件职责

这个文件建议只包含 3 个东西：

1. `ShellBranchVisibilityScope`
2. `ShellBranchVisibilityMixin`
3. `BuildContext` 扩展（可选）

### 建议代码骨架

```dart
import 'package:flutter/widgets.dart';

import 'shell_primary_route.dart';

class ShellBranchVisibilityScope extends InheritedWidget {
  const ShellBranchVisibilityScope({
    required this.activeRoute,
    required this.currentRoute,
    required super.child,
    super.key,
  });

  final ShellPrimaryRoute? activeRoute;
  final ShellPrimaryRoute currentRoute;

  bool get isActive => activeRoute == currentRoute;

  static ShellBranchVisibilityScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellBranchVisibilityScope>();
  }

  @override
  bool updateShouldNotify(ShellBranchVisibilityScope oldWidget) {
    return activeRoute != oldWidget.activeRoute ||
        currentRoute != oldWidget.currentRoute;
  }
}

mixin ShellBranchVisibilityMixin<T extends StatefulWidget> on State<T> {
  ShellPrimaryRoute get watchedPrimaryRoute;

  bool? _lastActive;
  bool _initialized = false;

  void onPrimaryRouteVisibilityChanged({
    required bool isActive,
    required bool isInitial,
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = ShellBranchVisibilityScope.maybeOf(context);
    final isActive = scope?.isActive ?? false;

    if (!_initialized) {
      _initialized = true;
      _lastActive = isActive;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        onPrimaryRouteVisibilityChanged(
          isActive: isActive,
          isInitial: true,
        );
      });
      return;
    }

    if (_lastActive != isActive) {
      _lastActive = isActive;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        onPrimaryRouteVisibilityChanged(
          isActive: isActive,
          isInitial: false,
        );
      });
    }
  }
}
```

### 必须遵守的约束

- [ ] 不要重新定义复杂的“上一状态 / 当前状态 / change reason / event bus”
- [ ] mixin 只传 `isActive` 与 `isInitial`
- [ ] 不要重建新的单例管理器
- [ ] 不要引入全局 Map 或注册表

### 为什么允许一个小 mixin

因为当前 4 个主页面都已经有“激活时恢复、隐藏时暂停”的页面级逻辑：

- `RecommendPage`
- `AllAppsPage`
- `RankingPage`
- `MyAppsPage`

完全去掉通知层会导致这些逻辑散落在 `build()` 里做副作用判断，反而更糟。

所以允许保留一个**极小的页面级 mixin**，但不能再出现全局生命周期编排。

---

## Task 3：把 `AppShell` 改成主页面栈的唯一宿主

**Files:**
- Modify: `lib/presentation/widgets/app_shell.dart`
- Modify: `lib/core/config/routes.dart`
- Test: `test/widget/presentation/widgets/app_shell_primary_stack_test.dart`

### 目标

让 `AppShell` 自己负责：

- 当前主页面索引
- 已访问主页面集合
- 主页面懒加载
- 主页面栈与二级页面覆盖层切换

当前主页面只允许由 `AppShell` 创建并持有，**不再由路由系统为每次导航单独创建 KeepAlive wrapper**。

### `AppShell` 新职责

建议 `AppShell` 增加以下状态字段：

```dart
ShellPrimaryRoute _activePrimaryRoute = ShellPrimaryRoute.recommend;
final Set<ShellPrimaryRoute> _visitedPrimaryRoutes = {
  ShellPrimaryRoute.recommend,
};
```

建议新增以下私有方法：

```dart
void _syncPrimaryRouteFromPath(String currentPath) {
  final matched = ShellPrimaryRoute.tryParse(currentPath);
  if (matched == null) {
    return;
  }
  if (_activePrimaryRoute == matched && _visitedPrimaryRoutes.contains(matched)) {
    return;
  }
  setState(() {
    _activePrimaryRoute = matched;
    _visitedPrimaryRoutes.add(matched);
  });
}

bool _isSecondaryRoute(String currentPath) {
  return !ShellPrimaryRoute.isPrimaryPath(currentPath);
}
```

### `AppShell` 构造参数建议调整

当前 `AppShell` 只有 `child`。

整改后建议改为：

```dart
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    required this.child,
    required this.currentPath,
    required this.currentUri,
    super.key,
  });

  final Widget child;
  final String currentPath;
  final Uri currentUri;
}
```

原因：

- 不要在 `build()` 里到处再从 `GoRouterState.of(context)` 二次推导
- 让路径变化进入 `didUpdateWidget()`，而不是在 `build()` 里夹杂状态同步

### `AppShell` 的核心内容区目标结构

```dart
Widget _buildContentArea(Widget overlayChild) {
  final showOverlay = _isSecondaryRoute(widget.currentPath);
  final activeRoute = showOverlay ? null : _activePrimaryRoute;

  return Stack(
    children: [
      Offstage(
        offstage: showOverlay,
        child: _PrimaryIndexedStack(
          activeRoute: activeRoute,
          visitedRoutes: _visitedPrimaryRoutes,
        ),
      ),
      if (showOverlay) Positioned.fill(child: overlayChild),
    ],
  );
}
```

### 为什么要“主页面栈 + 二级页面覆盖层”

这是这次方案最关键的设计点：

- 访问 `/setting`、`/app/:id` 等页面时，**主页面栈仍留在树里**
- 这样返回主页面时，主页面状态不会丢
- 同时二级页面本身还是普通路由，离开就释放

这一步直接替代了当前那套：

- 路由匹配后生成 `KeepAlivePageWrapper`
- wrapper 注册到全局注册表
- `KeepAliveVisibilitySync` 再反向同步当前路由

### `_PrimaryIndexedStack` 的实现要求

建议不要把所有逻辑堆回 `AppShell.build()`，至少拆 2 个私有 helper：

- `_buildPrimaryIndexedStack()`
- `_buildPrimarySlot(ShellPrimaryRoute route)`

每个 slot 的建议结构：

```dart
Widget _buildPrimarySlot(ShellPrimaryRoute route) {
  final hasVisited = _visitedPrimaryRoutes.contains(route);
  final isActive = !_isSecondaryRoute(widget.currentPath) && route == _activePrimaryRoute;

  if (!hasVisited) {
    return const SizedBox.shrink();
  }

  return TickerMode(
    enabled: isActive,
    child: ExcludeFocus(
      excluding: !isActive,
      child: IgnorePointer(
        ignoring: !isActive,
        child: ShellBranchVisibilityScope(
          activeRoute: !_isSecondaryRoute(widget.currentPath) ? _activePrimaryRoute : null,
          currentRoute: route,
          child: _buildPrimaryPage(route),
        ),
      ),
    ),
  );
}
```

### `_buildPrimaryPage(route)` 的唯一合法返回值

```dart
Widget _buildPrimaryPage(ShellPrimaryRoute route) {
  return switch (route) {
    ShellPrimaryRoute.recommend => const RecommendPage(),
    ShellPrimaryRoute.allApps => const AllAppsPage(),
    ShellPrimaryRoute.ranking => const RankingPage(),
    ShellPrimaryRoute.myApps => const MyAppsPage(),
  };
}
```

### 禁止事项

- [ ] 不要在这里重新加 `GlobalKey<KeepAlivePageWrapperState>`
- [ ] 不要再创建新的 `PageCacheManager`
- [ ] 不要在 slot 里包装自定义 `Notification`
- [ ] 不要用字符串 hardcode 判断主页面顺序，统一用枚举

---

## Task 4：重写 `routes.dart`，让主路由只负责路径匹配，不再负责页面保活

**Files:**
- Modify: `lib/core/config/routes.dart`

### 目标

让 `routes.dart` 只负责：

- 路由路径定义
- Shell 壳层装配
- 二级页面构建
- 启动页 redirect

而不再负责：

- KeepAlive 包装
- 页面可见性通知
- 页面缓存
- 生命周期同步

### `ShellRoute` builder 建议改法

把当前：

```dart
builder: (context, state, child) => AppShell(child: child)
```

改为：

```dart
builder: (context, state, child) => AppShell(
  child: child,
  currentPath: state.matchedLocation,
  currentUri: state.uri,
)
```

### 旧导航索引类型一并删除

当前 `routes.dart` 中还有以下零引用遗留：

- `NavigationBranch`
- `navigationIndexProvider`
- `NavigationIndexNotifier`

这 3 个符号已经不再承担任何真实状态职责，且会与新的
`ShellPrimaryRoute` 形成双入口。整改时必须一并删除。

### 4 个主页面路由的处理方式

当前 4 个主页面是直接把真实页面交给路由系统。

整改后改成：

- 路由只用于匹配 path
- 实际页面内容由 `AppShell` 的 `IndexedStack` 提供
- 这 4 条路由在 `routes.dart` 中返回一个占位 widget 即可

建议新增一个私有占位组件：

```dart
class _PrimaryShellPlaceholder extends StatelessWidget {
  const _PrimaryShellPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

主页面路由示例：

```dart
GoRoute(
  path: AppRoutes.recommend,
  name: 'recommend',
  builder: (context, state) => const _PrimaryShellPlaceholder(),
),
```

其余 3 个主页面同理。

### 为什么主页面路由可以只返回 placeholder

因为主页面状态已经由 `AppShell` 持有，路由只需要告诉壳层：

> 当前匹配到的是哪一个主页面路径。

这样：

- 路由系统不再承担页面缓存责任
- 主页面实例只有一份
- 逻辑集中在壳层

### 二级页面路由保持真实页面 builder

以下页面保留原有真实 builder：

- `SearchListPage`
- `SettingPage`
- `UpdateAppPage`
- `CustomCategoryPage`
- `AppDetailPage`

这些页面仍然通过 `child` 传给 `AppShell` 作为覆盖层显示。

### 本任务结束后，`routes.dart` 必须移除的内容

- [ ] `PageBecameVisibleNotification`
- [ ] `PageBecameHiddenNotification`
- [ ] `NavigationBranch`
- [ ] `navigationIndexProvider`
- [ ] `NavigationIndexNotifier`
- [ ] `keepAliveRoutes`
- [ ] `maxCachedPages`
- [ ] `_buildKeepAlivePage()`
- [ ] `KeepAlivePageWrapper`
- [ ] `KeepAlivePageWrapperState`
- [ ] `VisibilityInherited`
- [ ] `_BuildKeepAlivePage`
- [ ] `PageCacheManager`
- [ ] `PageVisibilityExtension`

如果删不干净，说明这次整改只是“换皮”，不是重构。

---

## Task 5：先保留旧文件，等页面迁移完成后统一删除

**Files:**
- Delete later: `keepalive_visibility_sync.dart`, `page_visibility.dart`, `visibility_aware_mixin.dart`, `keepalive_paint_gate.dart`

### 原因

`AppShell` 与 `routes.dart` 改完之后，4 个主页面和 1 个自定义分类页还会暂时引用旧 mixin / event 类型。

因此顺序必须是：

1. 先完成壳层与路由改造
2. 再迁移页面
3. 最后统一删旧文件

### 这一阶段的验收标准

在进入页面迁移文档前，必须满足：

- [ ] `routes.dart` 里已经没有 KeepAlive wrapper 逻辑
- [ ] `AppShell` 已经能托管主页面 `IndexedStack`
- [ ] 主页面路径切换时，`_activePrimaryRoute` 会更新
- [ ] 二级页面路径切换时，主页面 `IndexedStack` 仍留在树中
- [ ] 编译通过

---

## 本文档执行后的最小验证

### 手工验证

- [ ] 从 `/` 切到 `/all-apps`，右侧内容正常切换
- [ ] 从 `/ranking` 进入 `/setting`，二级页面显示正常
- [ ] 从 `/setting` 返回 `/ranking`，`RankingPage` 没被重建到初始状态（先不校验细节，只看结构正常）

### 命令验证

- [ ] 运行 `flutter analyze`
- [ ] 运行与本任务相关的 widget tests（后续在 `04-validation-rollout.md` 统一列命令）

---

## 交接到下一份文档

完成本文件后，不要急着删旧可见性文件。

下一步继续执行：

- `02-page-migration.md`
