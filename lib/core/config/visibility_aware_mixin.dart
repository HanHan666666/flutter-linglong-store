import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'page_visibility.dart';
import 'routes.dart';

/// 可见性感知 Mixin
///
/// 让 StatefulWidget 可以响应页面可见性变化。
/// 适用于需要 KeepAlive 的页面，用于暂停/恢复副作用。
///
/// ## 使用示例
///
/// ```dart
/// class _MyPageState extends ConsumerState<MyPage>
///     with AutomaticKeepAliveClientMixin, VisibilityAwareMixin {
///
///   @override
///   bool get wantKeepAlive => true;
///
///   @override
///   String get routePath => '/my-page';
///
///   @override
///   void onVisibilityChanged(PageVisibilityEvent event) {
///     if (event.becameHidden) {
///       // 暂停副作用
///       _pauseAutoPlay();
///       _pauseScrollListener();
///     } else if (event.becameVisible) {
///       // 恢复副作用（可选：轻量刷新）
///       _resumeAutoPlay();
///       if (event.isFirstVisible) {
///         // 首次可见时的处理
///       }
///     }
///   }
/// }
/// ```
///
mixin VisibilityAwareMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// 当前页面的路由路径
  ///
  /// 子类必须实现此 getter 返回对应的路由路径
  String get routePath;

  /// 上一次的可见性状态（内部追踪，用于检测变化）
  bool? _lastIsVisible;

  /// 上一次的可见性状态枚举（用于构建事件）
  PageVisibilityStatus _previousVisibilityStatus = PageVisibilityStatus.mountedHidden;

  /// 是否已初始化
  bool _initialized = false;

  /// 当前是否可见
  bool get isCurrentlyVisible =>
      PageVisibilityManager.instance.isVisible(routePath);

  /// 当前可见性状态
  PageVisibilityStatus get currentVisibilityStatus =>
      PageVisibilityManager.instance.getVisibilityStatus(routePath);

  /// 页面可见性变更回调
  ///
  /// 子类实现此方法来响应可见性变化
  void onVisibilityChanged(PageVisibilityEvent event);

  @override
  void initState() {
    super.initState();
    _initialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 获取当前可见性状态（建立依赖关系）
    final inherited = VisibilityInherited.of(context);
    final isVisible = inherited?.isVisible ?? true;

    if (_initialized) {
      // 首次初始化
      _initialized = false;
      _lastIsVisible = isVisible;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 首次可见事件
        _handleVisibilityChange(
          PageVisibilityStatus.mountedVisible,
          PageVisibilityChangeReason.initialLoad,
          isFirstVisible: true,
        );

        // 通知管理器
        PageVisibilityManager.instance.notifyPageMounted(routePath);
      });
    } else if (_lastIsVisible != isVisible) {
      // 可见性状态变化
      _lastIsVisible = isVisible;

      if (isVisible) {
        notifyBecameVisible();
      } else {
        notifyBecameHidden();
      }
    }
  }

  @override
  void dispose() {
    // 页面销毁时通知被淘汰
    PageVisibilityManager.instance.notifyPageEvicted(
      routePath,
      reason: PageVisibilityChangeReason.memoryPressure,
    );
    super.dispose();
  }

  /// 处理可见性变更
  void _handleVisibilityChange(
    PageVisibilityStatus newStatus,
    PageVisibilityChangeReason reason, {
    bool isFirstVisible = false,
  }) {
    final previousStatus = _previousVisibilityStatus;

    // 如果状态没有变化且不是首次可见，则不触发回调
    if (previousStatus == newStatus && !isFirstVisible) {
      return;
    }

    // 更新内部状态
    _previousVisibilityStatus = newStatus;

    // 创建事件
    final event = PageVisibilityEvent(
      routePath: routePath,
      previousStatus: previousStatus,
      currentStatus: newStatus,
      reason: reason,
      isFirstVisible: isFirstVisible,
    );

    // 调用子类的回调
    onVisibilityChanged(event);
  }

  /// 通知页面变为可见（由 InheritedWidget 更新触发）
  void notifyBecameVisible() {
    _handleVisibilityChange(
      PageVisibilityStatus.mountedVisible,
      PageVisibilityChangeReason.routeSwitchBack,
    );
  }

  /// 通知页面变为隐藏（由 InheritedWidget 更新触发）
  void notifyBecameHidden() {
    _handleVisibilityChange(
      PageVisibilityStatus.mountedHidden,
      PageVisibilityChangeReason.routeSwitchAway,
    );
  }

  /// 手动触发轻量刷新
  ///
  /// 从隐藏状态恢复时，只允许调用此方法进行轻量刷新，
  /// 不允许重新加载首屏数据或重置滚动位置
  void performLightweightRefresh() {
    // 子类可以覆盖此方法实现轻量刷新逻辑
    // 默认实现为空
  }
}

/// 自动暂停副作用辅助类
///
/// 用于管理需要根据可见性暂停/恢复的副作用
class SuspendableSideEffect<T> {
  SuspendableSideEffect({
    required this.onResume,
    required this.onPause,
    this.onDispose,
  });

  /// 恢复回调
  final VoidCallback onResume;

  /// 暂停回调
  final VoidCallback onPause;

  /// 销毁回调
  final VoidCallback? onDispose;

  /// 是否已暂停
  bool _isPaused = false;

  /// 是否已销毁
  bool _isDisposed = false;

  /// 暂停副作用
  void pause() {
    if (_isPaused || _isDisposed) return;
    _isPaused = true;
    onPause();
  }

  /// 恢复副作用
  void resume() {
    if (!_isPaused || _isDisposed) return;
    _isPaused = false;
    onResume();
  }

  /// 切换暂停/恢复
  void toggle(bool shouldPause) {
    if (shouldPause) {
      pause();
    } else {
      resume();
    }
  }

  /// 销毁
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    onDispose?.call();
  }
}

/// 可暂停定时器管理器
///
/// 用于管理需要根据可见性暂停的定时器
class PausableTimerManager {
  PausableTimerManager();

  /// 活跃的定时器
  final Map<String, Timer> _timers = {};

  /// 暂停的定时器信息（用于恢复）
  final Map<String, _PausedTimerInfo> _pausedTimers = {};

  /// 页面是否可见
  bool _isVisible = true;

  /// 设置可见性状态
  void setVisibility(bool isVisible) {
    if (_isVisible == isVisible) return;
    _isVisible = isVisible;

    if (isVisible) {
      _resumeAll();
    } else {
      _pauseAll();
    }
  }

  /// 注册定时器
  void registerTimer(
    String key,
    Duration duration,
    VoidCallback callback, {
    bool periodic = false,
  }) {
    // 如果页面不可见，记录但暂不启动
    if (!_isVisible) {
      _pausedTimers[key] = _PausedTimerInfo(
        duration: duration,
        callback: callback,
        periodic: periodic,
      );
      return;
    }

    _createTimer(key, duration, callback, periodic);
  }

  void _createTimer(
    String key,
    Duration duration,
    VoidCallback callback,
    bool periodic,
  ) {
    // 取消已存在的同名定时器
    cancelTimer(key);

    if (periodic) {
      _timers[key] = Timer.periodic(duration, (_) => callback());
    } else {
      _timers[key] = Timer(duration, () {
        _timers.remove(key);
        callback();
      });
    }
  }

  /// 取消定时器
  void cancelTimer(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
    _pausedTimers.remove(key);
  }

  void _pauseAll() {
    // 保存当前定时器状态并取消
    for (final entry in _timers.entries) {
      if (entry.value.isActive) {
        // 对于周期性定时器，保存信息以便恢复
        // 注意：这里简化处理，实际可能需要保存剩余时间
        entry.value.cancel();
      }
    }
    _timers.clear();
  }

  void _resumeAll() {
    // 恢复暂停的定时器
    for (final entry in _pausedTimers.entries) {
      final info = entry.value;
      _createTimer(entry.key, info.duration, info.callback, info.periodic);
    }
    _pausedTimers.clear();
  }

  /// 释放所有资源
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _pausedTimers.clear();
  }
}

class _PausedTimerInfo {
  _PausedTimerInfo({
    required this.duration,
    required this.callback,
    required this.periodic,
  });

  final Duration duration;
  final VoidCallback callback;
  final bool periodic;
}