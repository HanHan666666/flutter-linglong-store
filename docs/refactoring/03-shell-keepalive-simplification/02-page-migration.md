# KeepAlive Page Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 按任务逐项执行。步骤使用 `- [ ]` 复选框语法。

**Goal:** 把 4 个主页面从旧 `VisibilityAwareMixin + AutomaticKeepAliveClientMixin` 迁移到新的主页面激活作用域，同时把非主页面移出保活体系。

**Architecture:** 主页面只感知一个布尔状态：当前是否为激活主页面。隐藏时暂停副作用，恢复时做轻量恢复。非主页面（尤其 `CustomCategoryPage`）不再参与任何伪 KeepAlive 生命周期。

**Tech Stack:** Flutter, Riverpod, Widget Test, Integration Test

---

## 本文档覆盖的页面

### 主页面（要迁移到新 mixin）

- `lib/presentation/pages/recommend/recommend_page.dart`
- `lib/presentation/pages/all_apps/all_apps_page.dart`
- `lib/presentation/pages/ranking/ranking_page.dart`
- `lib/presentation/pages/my_apps/my_apps_page.dart`

### 非主页面（要脱离旧 KeepAlive 体系）

- `lib/presentation/pages/custom_category/custom_category_page.dart`

---

## Task 6：迁移 `RecommendPage`

**Files:**
- Modify: `lib/presentation/pages/recommend/recommend_page.dart`
- Test: `test/widget/presentation/widgets/app_shell_primary_stack_test.dart`

### 目标

让 `RecommendPage`：

- 不再依赖 `AutomaticKeepAliveClientMixin`
- 不再依赖 `PageVisibilityEvent`
- 仍然保留这些行为：
  - 页面隐藏时暂停滚动自动补页
  - 页面隐藏时暂停轮播自动播放
  - 页面恢复时继续自动补页检查
  - 页面恢复时只做轻量刷新，不重新走首屏加载

### 需要删掉的内容

- [ ] `import '../../../core/config/page_visibility.dart';`
- [ ] `import '../../../core/config/visibility_aware_mixin.dart';`
- [ ] `with AutomaticKeepAliveClientMixin, VisibilityAwareMixin`
- [ ] `wantKeepAlive`
- [ ] `routePath`
- [ ] `onVisibilityChanged(PageVisibilityEvent event)`
- [ ] `super.build(context)`（如果这个调用只为 keepAlive mixin 服务）

### 需要加上的内容

- [ ] `import '../../../core/config/shell_primary_route.dart';`
- [ ] `import '../../../core/config/shell_branch_visibility.dart';`
- [ ] `with ShellBranchVisibilityMixin`
- [ ] 实现 `watchedPrimaryRoute => ShellPrimaryRoute.recommend`
- [ ] 实现 `onPrimaryRouteVisibilityChanged({required bool isActive, required bool isInitial})`

### 建议替换后的核心代码

```dart
class _RecommendPageState extends ConsumerState<RecommendPage>
    with ShellBranchVisibilityMixin<RecommendPage> {
  final ScrollController _scrollController = ScrollController();
  bool _autoLoadCheckScheduled = false;
  bool _isPageVisible = true;
  bool _hasLoadedData = false;

  @override
  ShellPrimaryRoute get watchedPrimaryRoute => ShellPrimaryRoute.recommend;

  @override
  void onPrimaryRouteVisibilityChanged({
    required bool isActive,
    required bool isInitial,
  }) {
    if (isActive) {
      _resumeSideEffects();
      if (_hasLoadedData && !isInitial) {
        performLightweightRefresh();
      }
      return;
    }

    _pauseSideEffects();
  }
}
```

### 必须保持不变的行为

- `_scrollController` 逻辑继续存在
- `_BannerSection` 继续从父组件接收 `isPageVisible`
- `_hasLoadedData` 仍用于避免首次可见时误触发轻量刷新
- `performLightweightRefresh()` 可以继续保留为空实现，但不要删除这个“恢复入口”

### 迁移后检查点

- [ ] 首次打开推荐页时，轮播正常
- [ ] 切到其他主页面时，轮播停止
- [ ] 再切回推荐页时，轮播恢复
- [ ] 自动补页仅在推荐页激活时触发

---

## Task 7：迁移 `AllAppsPage`

**Files:**
- Modify: `lib/presentation/pages/all_apps/all_apps_page.dart`

### 目标

保留“页面隐藏时暂停滚动触底加载”的行为，但去掉旧生命周期系统。

### 需要删掉的内容

- [ ] `page_visibility.dart` import
- [ ] `visibility_aware_mixin.dart` import
- [ ] `AutomaticKeepAliveClientMixin`
- [ ] `VisibilityAwareMixin`
- [ ] `wantKeepAlive`
- [ ] `routePath`
- [ ] `onVisibilityChanged(PageVisibilityEvent event)`
- [ ] `super.build(context)`

### 需要加上的内容

```dart
@override
ShellPrimaryRoute get watchedPrimaryRoute => ShellPrimaryRoute.allApps;

@override
void onPrimaryRouteVisibilityChanged({
  required bool isActive,
  required bool isInitial,
}) {
  _isPageVisible = isActive;
}
```

### 额外要求

- `CategoryFilterSection` 的展开状态 `_isCategoryExpanded` 必须在切页后保留
- `ScrollController` 位置必须在切换主页面后保留
- `RefreshIndicator` 行为不变

---

## Task 8：迁移 `RankingPage`

**Files:**
- Modify: `lib/presentation/pages/ranking/ranking_page.dart`

### 目标

保留当前行为：

- `TabController` 状态保留
- 页面隐藏时，不处理 tab 切换副作用
- 页面恢复时，不重建 tab 状态

### 需要删掉的内容

- [ ] `page_visibility.dart` import
- [ ] `visibility_aware_mixin.dart` import
- [ ] `AutomaticKeepAliveClientMixin`
- [ ] `wantKeepAlive`
- [ ] `routePath`
- [ ] `onVisibilityChanged(PageVisibilityEvent event)`
- [ ] `super.build(context)`

### 替换后的关键代码

```dart
class _RankingPageState extends ConsumerState<RankingPage>
    with SingleTickerProviderStateMixin, ShellBranchVisibilityMixin<RankingPage> {
  late TabController _tabController;
  bool _isPageVisible = true;

  @override
  ShellPrimaryRoute get watchedPrimaryRoute => ShellPrimaryRoute.ranking;

  @override
  void onPrimaryRouteVisibilityChanged({
    required bool isActive,
    required bool isInitial,
  }) {
    _isPageVisible = isActive;
  }
}
```

### 额外注意

`RankingPage` 已经有自己的 `_HoverableTab`，这部分和 KeepAlive 无关，不要在这一波顺手改。

---

## Task 9：迁移 `MyAppsPage`

**Files:**
- Modify: `lib/presentation/pages/my_apps/my_apps_page.dart`
- Modify: `lib/application/providers/running_process_provider.dart`（只在必要时，避免改行为）

### 目标

`MyAppsPage` 的重点不是滚动，而是：

- 当前页面激活时，告诉 `runningProcessProvider` 页面可见
- 页面隐藏时，告诉 `runningProcessProvider` 页面不可见
- 玲珑进程 tab 的激活逻辑保留现状

### 需要删掉的内容

- [ ] `page_visibility.dart` import
- [ ] `visibility_aware_mixin.dart` import
- [ ] `AutomaticKeepAliveClientMixin`
- [ ] `wantKeepAlive`
- [ ] `routePath`
- [ ] `onVisibilityChanged(PageVisibilityEvent event)`
- [ ] `super.build(context)`

### 替换后的关键代码

```dart
@override
ShellPrimaryRoute get watchedPrimaryRoute => ShellPrimaryRoute.myApps;

@override
void onPrimaryRouteVisibilityChanged({
  required bool isActive,
  required bool isInitial,
}) {
  ref.read(runningProcessProvider.notifier).setPageVisible(isActive);
}
```

### 必须保留的现有行为

- `_activeTab` 状态切页后保留
- 搜索关键字 `_searchQuery` 保留
- `runningProcessProvider.notifier.setProcessTabActive(...)` 行为保持不变
- `dispose()` 中仍要调用 `setProcessTabActive(false)`

### 需要额外检查的点

- [ ] 当页面隐藏且当前 tab 是“玲珑进程”时，轮询会停
- [ ] 回到 `MyAppsPage` 后，轮询会恢复
- [ ] 切换 `我的应用 / 玲珑进程` tab 不受 KeepAlive 改造影响

---

## Task 10：把 `CustomCategoryPage` 脱离旧 KeepAlive 体系

**Files:**
- Modify: `lib/presentation/pages/custom_category/custom_category_page.dart`

### 结论先说

`CustomCategoryPage` **不应该继续接入任何保活可见性系统**。

原因：

- 它不是 4 个固定主页面之一
- 当前用户路径下，它属于一次性内容页
- 离开后重新进入时重建是合理的
- 它的滚动监听只在当前页面可见时才会存在，页面销毁即可自然停止

### 需要删掉的内容

- [ ] `page_visibility.dart` import
- [ ] `visibility_aware_mixin.dart` import
- [ ] `AutomaticKeepAliveClientMixin`
- [ ] `VisibilityAwareMixin`
- [ ] `_isPageVisible`
- [ ] `wantKeepAlive`
- [ ] `routePath`
- [ ] `onVisibilityChanged(...)`
- [ ] `_onScroll()` 中的 `_isPageVisible` 判断
- [ ] `super.build(context)`

### `_onScroll()` 的目标实现

直接保留成普通滚动触底判断：

```dart
void _onScroll() {
  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent - 200) {
    ref.read(customCategoryProvider(widget.code).notifier).loadMore();
  }
}
```

### 迁移后收益

这一步会非常直接地证明一个原则：

> 不是所有处于 Shell 内的页面都需要“可见性同步系统”。

---

## Task 11：统一删掉页面里的旧保活遗留调用

**Files:**
- Modify: `recommend_page.dart`
- Modify: `all_apps_page.dart`
- Modify: `ranking_page.dart`
- Modify: `my_apps_page.dart`
- Modify: `custom_category_page.dart`

### 目标

做一次统一收尾，避免旧字段和新结构并存。

### 必须确认已经没有的内容

- [ ] `routePath` getter
- [ ] `wantKeepAlive` getter
- [ ] `PageVisibilityEvent`
- [ ] `VisibilityAwareMixin`
- [ ] `AutomaticKeepAliveClientMixin`
- [ ] `performLightweightRefresh()` 以外的旧页面可见性回调残留

### 如果还残留，说明哪里有问题

- 如果还有 `routePath`：说明执行方还在把页面当成“被路由系统托管的 keepalive 实例”
- 如果还有 `wantKeepAlive`：说明执行方没有真正理解 `IndexedStack` 已经承担了保活职责
- 如果还有 `PageVisibilityEvent`：说明旧系统没有彻底切断

---

## Task 12：替换旧测试，新增新测试

**Files:**
- Delete: `test/widget/core/config/keepalive_paint_gate_test.dart`
- Delete: `test/widget/core/config/keepalive_visibility_sync_test.dart`
- Create: `test/widget/core/config/shell_branch_visibility_test.dart`
- Create: `test/widget/presentation/widgets/app_shell_primary_stack_test.dart`

### 新测试 1：`shell_branch_visibility_test.dart`

必须覆盖：

- [ ] `ShellBranchVisibilityScope` 能正确下发当前激活主页面
- [ ] `ShellBranchVisibilityMixin` 首次挂载会收到一次初始通知
- [ ] 从激活切到隐藏时会收到 `isActive = false`
- [ ] 从隐藏切回激活时会收到 `isActive = true`
- [ ] 二级页面显示时，主页面会收到 `isActive = false`

### 新测试 2：`app_shell_primary_stack_test.dart`

必须覆盖：

- [ ] 第一次进入 `/` 时，只创建推荐页
- [ ] 切到 `/all-apps` 后，`AllAppsPage` 首次创建
- [ ] 再切回 `/` 后，`RecommendPage` 不被重建
- [ ] 在 `/app/:id` 或 `/setting` 覆盖层显示时，主页面栈仍保留
- [ ] 覆盖层关闭后，主页面栈状态仍在

### 推荐测试技巧

给 4 个主页面临时放测试专用 key / counter，不要用打印日志猜重建次数。

例如：

```dart
class TestCounterPage extends StatefulWidget {
  const TestCounterPage({required this.label, super.key});
  final String label;

  @override
  State<TestCounterPage> createState() => _TestCounterPageState();
}

class _TestCounterPageState extends State<TestCounterPage> {
  static final Map<String, int> buildCounts = {};

  @override
  Widget build(BuildContext context) {
    buildCounts.update(widget.label, (value) => value + 1, ifAbsent: () => 1);
    return Text(widget.label);
  }
}
```

---

## 本文档执行完成后的删除动作

只有当：

- [ ] 4 个主页面都已迁移到新 mixin
- [ ] `CustomCategoryPage` 已脱离旧系统
- [ ] 新测试已补齐

才允许回到 `01-core-router-and-shell.md` 中的 Task 5，删除旧 KeepAlive 文件。

---

## 本文档完成后的最小人工验收

- [ ] 推荐页滚动位置切换后保留
- [ ] 全部应用页分类展开状态切换后保留
- [ ] 排行榜当前 tab 保留
- [ ] 我的应用页当前 tab 与搜索关键词保留
- [ ] 自定义分类页离开后再进入，允许重新构建
- [ ] 进入设置 / 搜索 / 详情后，返回主页面状态仍在

---

## 交接到下一份文档

完成本文件后，再执行：

- `03-secondary-cleanups.md`
- `04-validation-rollout.md`
