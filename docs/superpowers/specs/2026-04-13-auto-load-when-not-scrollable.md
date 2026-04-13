# Auto Load When Not Scrollable - Design Document

**Date:** 2026-04-13

## Background

分页列表页面（如"全部应用"、"搜索结果"、"自定义分类"）在首屏数据不足以填满视口时（`maxScrollExtent <= 1`），用户无法滚动，导致滚动监听 `_onScroll` 永远不会触发，分页加载被阻塞。全屏窗口、大分辨率屏幕下尤为常见。

此前只有推荐页（`RecommendPage`）实现了"内容不足一屏时自动加载更多"的逻辑，其他分页页面均未实现，导致全屏时无法自动加载下一页。

## Confirmed Requirements

- 提取推荐页的自动加载逻辑为可复用 Mixin，供所有分页列表页面使用。
- Mixin 需提供滚动加载（距底部 200px 触发）和内容不足一屏时自动加载两种能力。
- 页面隐藏时自动暂停副作用，避免无效网络请求。
- 不改变现有 Provider 架构和页面业务逻辑。
- 补充文档与测试覆盖。

## Design

### Mixin: `AutoLoadWhenNotScrollable`

位置：`lib/presentation/mixins/auto_load_when_not_scrollable.dart`

#### 子类必须实现的抽象成员

| 成员 | 类型 | 说明 |
|------|------|------|
| `scrollController` | `ScrollController` | 列表的滚动控制器 |
| `isPageVisible` | `bool` | 页面是否可见（用于控制副作用） |
| `isLoading` | `bool` | 是否正在首次加载数据 |
| `isLoadingMore` | `bool` | 是否正在加载更多数据 |
| `hasMore` | `bool` | 是否还有更多数据可加载 |
| `onLoadMore` | `VoidCallback` | 加载更多的回调 |

#### Mixin 提供的方法

| 方法 | 说明 |
|------|------|
| `initAutoLoad()` | 在子类 `initState()` 中调用，初始化自动加载逻辑 |
| `disposeAutoLoad()` | 在子类 `dispose()` 中调用，清理状态 |
| `onVisibilityChanged(bool visible)` | 页面可见性变更时调用 |
| `onScroll()` | 滚动回调方法，包含滚动加载 + 自动加载检查 |

#### 核心逻辑

1. **滚动触发加载**：当滚动到距离底部 200px 时触发 `loadMore()`
2. **内容不足一屏自动加载**：数据加载完成后，通过 `addPostFrameCallback` 检查 `maxScrollExtent <= 1`，如果不可滚动且 `hasMore == true`，自动调用 `loadMore()`
3. **递归检查**：加载后递归检查，直到列表可滚动或没有更多数据
4. **可见性控制**：页面隐藏时自动暂停，避免无效网络请求
5. **防重复调度**：`_autoLoadCheckScheduled` 标志防止同一帧内重复安排检查

### 使用示例

```dart
class _AllAppsPageState extends ConsumerState<AllAppsPage>
    with ShellBranchVisibilityMixin<AllAppsPage>, AutoLoadWhenNotScrollable {
  final ScrollController _scrollController = ScrollController();
  bool _isPageVisible = true;

  @override
  ShellPrimaryRoute get watchedPrimaryRoute => ShellPrimaryRoute.allApps;

  // ==================== AutoLoadWhenNotScrollable 实现 ====================

  @override
  ScrollController get scrollController => _scrollController;

  @override
  bool get isPageVisible => _isPageVisible;

  @override
  bool get isLoading => ref.read(allAppsProvider).isLoading;

  @override
  bool get isLoadingMore => ref.read(allAppsProvider).isLoadingMore;

  @override
  bool get hasMore => ref.read(allAppsProvider).data?.apps.hasMore ?? false;

  @override
  VoidCallback get onLoadMore =>
      () => ref.read(allAppsProvider.notifier).loadMore();

  @override
  void initState() {
    super.initState();
    initAutoLoad();
    _scrollController.addListener(onScroll);
  }

  @override
  void dispose() {
    disposeAutoLoad();
    _scrollController.removeListener(onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void onPrimaryRouteVisibilityChanged({
    required bool isActive,
    required bool isInitial,
  }) {
    if (isActive) {
      _isPageVisible = true;
      onVisibilityChanged(true);
      return;
    }
    _isPageVisible = false;
    onVisibilityChanged(false);
  }
}
```

### 迁移清单

| 页面 | 文件 | 状态 |
|------|------|------|
| 推荐页 | `lib/presentation/pages/recommend/recommend_page.dart` | ✅ 已迁移 |
| 全部应用 | `lib/presentation/pages/all_apps/all_apps_page.dart` | ✅ 已迁移 |
| 搜索结果 | `lib/presentation/pages/search_list/search_list_page.dart` | ✅ 已迁移 |
| 自定义分类 | `lib/presentation/pages/custom_category/custom_category_page.dart` | ✅ 已迁移 |

### Testing

需要补充 mixin 的 widget 测试，覆盖以下场景：

- 内容不可滚动时自动触发 `loadMore`
- 内容可滚动时不自动触发
- `hasMore == false` 时不自动触发
- 页面不可见时不自动触发
- 正在加载时不自动触发
- 正在加载更多时不自动触发
- 同一帧内不重复调度检查
- 可见性变化时正确重新评估条件

测试文件：`test/unit/core/mixins/auto_load_when_not_scrollable_test.dart`

### Risks

- Mixin 的 `onVisibilityChanged(true)` 在 `build()` 中调用，需要确保 `ShellBranchVisibilityScope` 在测试环境中正确设置，否则 `_isPageVisible` 默认为 `false` 会阻止自动加载。
- 子类必须正确实现所有抽象成员，否则编译期会报错。
- `onScroll` 方法标记为 `@visibleForTesting`，仅用于测试，生产代码应通过 `_scrollController.addListener(onScroll)` 自动触发。

## Git Commit

```
refactor: 抽象分页列表自动加载更多逻辑为 Mixin

- 创建 AutoLoadWhenNotScrollable mixin，提取推荐页的自动加载逻辑
- 全部应用页、搜索结果页、自定义分类页接入 mixin
- 推荐页自身也改为使用 mixin，消除重复代码
- 补充 mixin 的 widget 测试覆盖
- 修复推荐页测试中缺少 ShellBranchVisibilityScope 的问题
```
