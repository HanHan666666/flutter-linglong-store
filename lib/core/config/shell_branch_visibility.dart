import 'package:flutter/widgets.dart';

import 'shell_primary_route.dart';

/// Shell 主路由可见性作用域
///
/// 由 AppShell 下发，用于告知主页面当前是否为激活状态。
/// 替代旧的 `VisibilityInherited`、`PageVisibilityManager` 等复杂机制。
class ShellBranchVisibilityScope extends InheritedWidget {
  const ShellBranchVisibilityScope({
    required this.activeRoute,
    required this.currentRoute,
    required super.child,
    super.key,
  });

  /// 当前激活的主路由（二级路由覆盖时为 null）
  final ShellPrimaryRoute? activeRoute;

  /// 当前主路由实例对应的路由类型
  final ShellPrimaryRoute currentRoute;

  /// 判断当前主路由是否为激活状态
  bool get isActive => activeRoute == currentRoute;

  /// 从 BuildContext 获取可见性作用域（建立依赖）
  static ShellBranchVisibilityScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellBranchVisibilityScope>();
  }

  @override
  bool updateShouldNotify(ShellBranchVisibilityScope oldWidget) {
    return activeRoute != oldWidget.activeRoute ||
        currentRoute != oldWidget.currentRoute;
  }
}

/// Shell 主路由可见性感知 Mixin
///
/// 用于主页面（RecommendPage、AllAppsPage、RankingPage、MyAppsPage）
/// 感知自身激活状态变化，从而暂停/恢复副作用。
///
/// **约束：**
/// - 只传递 `isActive` 与 `isInitial`
/// - 不引入全局状态管理
/// - 不重建新的单例管理器
mixin ShellBranchVisibilityMixin<T extends StatefulWidget> on State<T> {
  /// 当前页面对应的主路由类型
  ShellPrimaryRoute get watchedPrimaryRoute;

  bool? _lastActive;
  bool _initialized = false;

  /// 当主路由可见性变化时回调
  ///
  /// - `isActive`: 当前是否为激活状态
  /// - `isInitial`: 是否为初始化回调（首次构建）
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

/// BuildContext 可见性扩展
///
/// 用于在子组件中快速判断当前主路由是否激活。
extension ShellBranchVisibilityExtension on BuildContext {
  /// 判断当前主路由是否为激活状态
  ///
  /// 如果不在 ShellBranchVisibilityScope 作用域内，返回 false。
  bool get isShellBranchActive {
    final scope = ShellBranchVisibilityScope.maybeOf(this);
    return scope?.isActive ?? false;
  }

  /// 获取当前主路由类型
  ///
  /// 如果不在 ShellBranchVisibilityScope 作用域内，返回 null。
  ShellPrimaryRoute? get currentShellBranch {
    final scope = ShellBranchVisibilityScope.maybeOf(this);
    return scope?.currentRoute;
  }
}