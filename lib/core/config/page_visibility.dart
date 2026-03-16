import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// 页面可见性状态
///
/// 对应 KeepAlive 状态机的状态转换:
/// - MountedVisible: 页面当前可见，用户可以交互
/// - MountedHidden: 页面已挂载但不可见（切换到其他 tab）
/// - Evicted: 页面被 LRU 淘汰或因内存压力移除
enum PageVisibilityStatus {
  /// 页面可见且活跃
  mountedVisible,

  /// 页面已挂载但隐藏（KeepAlive 缓存状态）
  mountedHidden,

  /// 页面已被淘汰（需要重建）
  evicted,
}

/// 页面可见性状态变更原因
enum PageVisibilityChangeReason {
  /// 用户导航到其他页面
  routeSwitchAway,

  /// 用户导航回该页面
  routeSwitchBack,

  /// LRU 淘汰
  lruEviction,

  /// 内存压力
  memoryPressure,

  /// 页面首次加载
  initialLoad,
}

/// 页面可见性变更事件
class PageVisibilityEvent {
  const PageVisibilityEvent({
    required this.routePath,
    required this.previousStatus,
    required this.currentStatus,
    required this.reason,
    this.isFirstVisible = false,
  });

  /// 路由路径
  final String routePath;

  /// 之前的可见性状态
  final PageVisibilityStatus previousStatus;

  /// 当前的可见性状态
  final PageVisibilityStatus currentStatus;

  /// 变更原因
  final PageVisibilityChangeReason reason;

  /// 是否首次可见
  final bool isFirstVisible;

  /// 是否变为可见
  bool get becameVisible =>
      currentStatus == PageVisibilityStatus.mountedVisible &&
      previousStatus != PageVisibilityStatus.mountedVisible;

  /// 是否变为隐藏
  bool get becameHidden =>
      currentStatus == PageVisibilityStatus.mountedHidden &&
      previousStatus != PageVisibilityStatus.mountedHidden;

  /// 是否被淘汰
  bool get wasEvicted =>
      currentStatus == PageVisibilityStatus.evicted;

  @override
  String toString() {
    return 'PageVisibilityEvent(routePath: $routePath, '
        '$previousStatus -> $currentStatus, reason: $reason)';
  }
}

/// 页面可见性变更回调
typedef PageVisibilityCallback = void Function(PageVisibilityEvent event);

/// 页面可见性状态管理器
///
/// 单例模式，用于全局追踪所有 KeepAlive 页面的可见性状态
class PageVisibilityManager {
  PageVisibilityManager._();

  static final PageVisibilityManager instance = PageVisibilityManager._();

  /// 当前各页面的可见性状态
  final Map<String, PageVisibilityStatus> _visibilityStates = {};

  /// 页面是否首次可见的标记
  final Map<String, bool> _firstVisibleFlags = {};

  /// 可见性变更监听器
  final List<VoidCallback> _listeners = [];

  /// 获取当前可见的页面路径
  String? get currentVisiblePath => _currentVisiblePath;
  String? _currentVisiblePath;

  /// 获取所有缓存的页面路径
  List<String> get cachedPaths => _visibilityStates.keys
      .where((path) => _visibilityStates[path] != PageVisibilityStatus.evicted)
      .toList();

  /// 注册页面可见性变更监听器
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// 移除页面可见性变更监听器
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// 通知页面挂载（首次加载）
  void notifyPageMounted(String routePath) {
    _visibilityStates[routePath] = PageVisibilityStatus.mountedVisible;
    _firstVisibleFlags[routePath] = true;
    _currentVisiblePath = routePath;

    // 通知其他已缓存的页面变为隐藏
    for (final path in _visibilityStates.keys.toList()) {
      if (path != routePath &&
          _visibilityStates[path] == PageVisibilityStatus.mountedVisible) {
        _visibilityStates[path] = PageVisibilityStatus.mountedHidden;
      }
    }

    _notifyListeners();
  }

  /// 通知页面切换到可见状态
  void notifyPageVisible(
    String routePath, {
    PageVisibilityChangeReason reason = PageVisibilityChangeReason.routeSwitchBack,
  }) {
    _visibilityStates[routePath] = PageVisibilityStatus.mountedVisible;
    if (!_firstVisibleFlags.containsKey(routePath)) {
      _firstVisibleFlags[routePath] = true;
    }
    _currentVisiblePath = routePath;

    // 通知其他已缓存的页面变为隐藏
    for (final path in _visibilityStates.keys.toList()) {
      if (path != routePath &&
          _visibilityStates[path] == PageVisibilityStatus.mountedVisible) {
        _visibilityStates[path] = PageVisibilityStatus.mountedHidden;
      }
    }

    _notifyListeners();
  }

  /// 通知页面切换到隐藏状态
  void notifyPageHidden(
    String routePath, {
    PageVisibilityChangeReason reason = PageVisibilityChangeReason.routeSwitchAway,
  }) {
    final previousStatus = _visibilityStates[routePath];

    if (previousStatus == PageVisibilityStatus.mountedVisible) {
      _visibilityStates[routePath] = PageVisibilityStatus.mountedHidden;
      _notifyListeners();
    }
  }

  /// 通知页面被淘汰
  void notifyPageEvicted(
    String routePath, {
    PageVisibilityChangeReason reason = PageVisibilityChangeReason.lruEviction,
  }) {
    _visibilityStates[routePath] = PageVisibilityStatus.evicted;
    _firstVisibleFlags.remove(routePath);
    _notifyListeners();
  }

  /// 获取页面的当前可见性状态
  PageVisibilityStatus getVisibilityStatus(String routePath) {
    return _visibilityStates[routePath] ?? PageVisibilityStatus.mountedHidden;
  }

  /// 检查页面是否当前可见
  bool isVisible(String routePath) {
    return _visibilityStates[routePath] == PageVisibilityStatus.mountedVisible;
  }

  /// 检查页面是否首次可见
  bool isFirstVisible(String routePath) {
    return _firstVisibleFlags[routePath] ?? false;
  }

  /// 清除首次可见标记（在页面处理完首次可见后调用）
  void clearFirstVisibleFlag(String routePath) {
    _firstVisibleFlags.remove(routePath);
  }

  /// 清除所有状态
  void clearAll() {
    _visibilityStates.clear();
    _firstVisibleFlags.clear();
    _currentVisiblePath = null;
    _notifyListeners();
  }

  void _notifyListeners() {
    for (final listener in List.from(_listeners)) {
      listener();
    }
  }

  /// 获取可见性事件
  PageVisibilityEvent? getLastEvent(String routePath) {
    final status = _visibilityStates[routePath];
    if (status == null) return null;

    return PageVisibilityEvent(
      routePath: routePath,
      previousStatus: status,
      currentStatus: status,
      reason: PageVisibilityChangeReason.routeSwitchBack,
      isFirstVisible: _firstVisibleFlags[routePath] ?? false,
    );
  }
}

/// Riverpod Provider for PageVisibilityManager
final pageVisibilityManagerProvider = Provider<PageVisibilityManager>((ref) {
  return PageVisibilityManager.instance;
});

/// 页面可见性状态 Provider
///
/// 用于在 Widget 树中获取当前页面的可见性状态
final pageVisibilityStatusProvider =
    StateProvider.family<PageVisibilityStatus, String>((ref, routePath) {
  final manager = ref.watch(pageVisibilityManagerProvider);
  return manager.getVisibilityStatus(routePath);
});

/// 当前页面是否可见的 Provider
final isPageVisibleProvider =
    Provider.family<bool, String>((ref, routePath) {
  final manager = ref.watch(pageVisibilityManagerProvider);
  return manager.isVisible(routePath);
});