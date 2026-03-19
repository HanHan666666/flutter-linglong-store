import 'package:flutter/material.dart';

/// KeepAlive 页面可见性绑定。
///
/// 由具体页面包装器注册“显示 / 隐藏”回调，统一交给当前路由驱动。
class KeepAliveVisibilityBinding {
  const KeepAliveVisibilityBinding({
    required this.show,
    required this.hide,
    required this.isMounted,
  });

  final VoidCallback show;
  final VoidCallback hide;
  final bool Function() isMounted;
}

/// KeepAlive 页面注册表。
///
/// 路由切换时由当前路由统一驱动 visible/hidden，同步到所有仍挂载的
/// KeepAlive 页面，避免再依赖 activate/deactivate 猜测生命周期。
class KeepAlivePageRegistry {
  KeepAlivePageRegistry._();

  static final Map<String, Set<KeepAliveVisibilityBinding>> _bindingsByRoute = {};

  /// 注册 KeepAlive 页面可见性绑定。
  static void register({
    required String routePath,
    required KeepAliveVisibilityBinding binding,
  }) {
    final bindings = _bindingsByRoute.putIfAbsent(
      routePath,
      () => <KeepAliveVisibilityBinding>{},
    );
    bindings.add(binding);
  }

  /// 注销 KeepAlive 页面可见性绑定。
  static void unregister({
    required String routePath,
    required KeepAliveVisibilityBinding binding,
  }) {
    final bindings = _bindingsByRoute[routePath];
    if (bindings == null) {
      return;
    }

    bindings.remove(binding);
    if (bindings.isEmpty) {
      _bindingsByRoute.remove(routePath);
    }
  }

  /// 按当前路由显式同步所有 KeepAlive 页面可见性。
  static void syncVisibleRoute(String currentPath) {
    for (final entry in _bindingsByRoute.entries.toList()) {
      final isVisibleRoute = entry.key == currentPath;
      for (final binding in entry.value.toList()) {
        if (!binding.isMounted()) {
          continue;
        }

        if (isVisibleRoute) {
          binding.show();
        } else {
          binding.hide();
        }
      }
    }
  }

  /// 测试辅助：清空注册表。
  static void clear() {
    _bindingsByRoute.clear();
  }
}

/// 当前路由的 KeepAlive 可见性同步器。
///
/// 由 Shell 当前路由显式驱动，保证切换到普通页面时也能把已缓存的
/// KeepAlive 页面标记为 hidden。
class KeepAliveVisibilitySync extends StatefulWidget {
  const KeepAliveVisibilitySync({required this.currentPath, super.key});

  final String currentPath;

  @override
  State<KeepAliveVisibilitySync> createState() => _KeepAliveVisibilitySyncState();
}

class _KeepAliveVisibilitySyncState extends State<KeepAliveVisibilitySync> {
  String? _scheduledPath;

  @override
  void initState() {
    super.initState();
    _scheduleSync(widget.currentPath);
  }

  @override
  void didUpdateWidget(covariant KeepAliveVisibilitySync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      _scheduleSync(widget.currentPath);
    }
  }

  void _scheduleSync(String currentPath) {
    if (_scheduledPath == currentPath) {
      return;
    }

    _scheduledPath = currentPath;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledPath != currentPath) {
        return;
      }
      KeepAlivePageRegistry.syncVisibleRoute(currentPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
