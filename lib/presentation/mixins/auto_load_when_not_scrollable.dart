import 'package:flutter/material.dart';

/// 分页列表"内容不足一屏时自动加载更多"的 Mixin。
///
/// 解决的问题：
/// - 当列表首屏数据不足以填满视口时（`maxScrollExtent <= 1`），
///   用户无法滚动，导致 `_onScroll` 永远不会触发，分页加载被阻塞。
/// - 全屏窗口、大分辨率屏幕下尤为常见。
///
/// 使用方式：
/// ```dart
/// class _MyPageState extends ConsumerState<MyPage>
///     with AutoLoadWhenNotScrollable {
///
///   final ScrollController _scrollController = ScrollController();
///   bool _isPageVisible = true;
///
///   @override
///   ScrollController get scrollController => _scrollController;
///
///   @override
///   bool get isPageVisible => _isPageVisible;
///
///   @override
///   bool get isLoading => state.isLoading; // 首次加载中
///
///   @override
///   bool get isLoadingMore => state.isLoadingMore;
///
///   @override
///   bool get hasMore => state.data?.hasMore ?? false;
///
///   @override
///   VoidCallback get onLoadMore => () => ref.read(myProvider.notifier).loadMore();
///
///   @override
///   void initState() {
///     super.initState();
///     initAutoLoad();
///     _scrollController.addListener(_onScroll);
///   }
///
///   @override
///   void dispose() {
///     disposeAutoLoad();
///     _scrollController.removeListener(_onScroll);
///     _scrollController.dispose();
///     super.dispose();
///   }
///
///   void _onScroll() {
///     onScroll(); // mixin 方法：包含滚动加载 + 自动加载检查
///   }
///
///   @override
///   void onVisibilityChanged(bool visible) {
///     _isPageVisible = visible;
///     super.onVisibilityChanged(visible);
///   }
/// }
/// ```
///
/// 核心逻辑：
/// 1. 数据加载完成后，通过 `addPostFrameCallback` 检查内容是否可滚动
/// 2. 如果 `maxScrollExtent <= 1`（不可滚动）且 `hasMore == true`，自动调用 `loadMore()`
/// 3. 加载后递归检查，直到列表可滚动或没有更多数据
/// 4. 页面隐藏时自动暂停，避免无效网络请求
mixin AutoLoadWhenNotScrollable<T extends StatefulWidget> on State<T> {
  // ==================== 子类必须实现的抽象成员 ====================

  /// 列表的 ScrollController
  ScrollController get scrollController;

  /// 页面是否可见（用于控制副作用）
  bool get isPageVisible;

  /// 是否正在首次加载数据
  bool get isLoading;

  /// 是否正在加载更多数据
  bool get isLoadingMore;

  /// 是否还有更多数据可加载
  bool get hasMore;

  /// 加载更多的回调
  VoidCallback get onLoadMore;

  // ==================== 内部状态 ====================

  /// 避免同一帧重复安排"内容不足一屏自动补页"检查。
  bool _autoLoadCheckScheduled = false;

  // ==================== 生命周期方法 ====================

  /// 在子类的 `initState()` 中调用，初始化自动加载逻辑。
  ///
  /// 注意：子类仍需自行添加 `_scrollController.addListener(_onScroll)`。
  @protected
  void initAutoLoad() {
    // 子类负责在 initState 中监听 scrollController
  }

  /// 在子类的 `dispose()` 中调用，清理状态。
  @protected
  void disposeAutoLoad() {
    _autoLoadCheckScheduled = false;
  }

  /// 页面可见性变更时调用。
  ///
  /// 子类应在 `onPrimaryRouteVisibilityChanged` 或类似生命周期中调用此方法。
  ///
  /// 页面可见时会自动触发一次"内容不足一屏"检查；页面隐藏时会暂停副作用。
  @protected
  void onVisibilityChanged(bool visible) {
    if (visible) {
      // 恢复时检查是否需要自动补页
      _scheduleAutoLoadCheck();
    }
    // 隐藏时 _autoLoadCheckScheduled 不会被重置，
    // 但 shouldAutoLoad 会因 isPageVisible 返回 false 而短路。
  }

  /// 滚动回调方法。
  ///
  /// 子类应在 `_onScroll` 中调用此方法，或直接将其作为 scroll listener：
  /// ```dart
  /// _scrollController.addListener(onScroll);
  /// ```
  ///
  /// 此方法内部包含：
  /// 1. 滚动到底部 200px 时触发 `loadMore()`
  /// 2. 自动检查"内容不足一屏"场景
  @protected
  @visibleForTesting
  void onScroll() {
    // 页面隐藏时跳过滚动处理，避免无效网络请求
    if (!isPageVisible) return;
    if (!scrollController.hasClients) return;

    // 滚动到距离底部 200px 时加载更多
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      onLoadMore();
    }

    // 同时检查是否需要自动补页（例如窗口放大后内容变少）
    _maybeLoadMoreWhenNotScrollable();
  }

  // ==================== 自动加载核心逻辑 ====================

  /// 判断是否应该执行"内容不足一屏自动加载"检查。
  bool _shouldAutoLoadWhenNotScrollable() {
    return isPageVisible && !isLoading && !isLoadingMore && hasMore;
  }

  /// 安排一次"内容不足一屏自动加载"检查。
  ///
  /// 使用 `addPostFrameCallback` 确保布局完成后才读取 `maxScrollExtent`。
  void _scheduleAutoLoadCheck() {
    if (_autoLoadCheckScheduled || !_shouldAutoLoadWhenNotScrollable()) {
      return;
    }

    _autoLoadCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLoadCheckScheduled = false;
      if (!mounted) {
        return;
      }
      _maybeLoadMoreWhenNotScrollable();
    });
  }

  /// 检查当前列表是否不可滚动，如果是则自动加载更多。
  ///
  /// 判断依据：`maxScrollExtent <= 1` 表示内容高度 ≤ 视口高度，无法滚动。
  void _maybeLoadMoreWhenNotScrollable() {
    if (!_shouldAutoLoadWhenNotScrollable()) {
      return;
    }

    if (!scrollController.hasClients) {
      _scheduleAutoLoadCheck();
      return;
    }

    final position = scrollController.position;
    if (!position.hasContentDimensions || position.viewportDimension <= 0) {
      _scheduleAutoLoadCheck();
      return;
    }

    final notScrollable = position.maxScrollExtent <= 1;
    if (notScrollable) {
      onLoadMore();
    }
  }
}
