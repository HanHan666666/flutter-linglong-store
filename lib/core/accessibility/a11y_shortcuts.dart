import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局键盘快捷键处理器
///
/// 在 MaterialApp 外层包裹此组件，为桌面端用户提供标准键盘导航能力。
/// 使用 Shortcuts + Actions 机制注册常用快捷键。
class A11yKeyboardHandler extends StatelessWidget {
  final Widget child;

  const A11yKeyboardHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: _DoNothingAction(),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (DismissIntent intent) {
              // 尝试关闭当前顶层路由（弹窗/对话框）
              Navigator.maybeOf(context)?.maybePop();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

/// 不执行任何操作的 Action，用于拦截 ActivateIntent
///
/// InkWell / ElevatedButton 等控件会自行响应 ActivateIntent，
/// 此处仅防止未绑定的快捷键触发默认行为。
class _DoNothingAction extends Action<ActivateIntent> {
  @override
  Object? invoke(ActivateIntent intent) => null;
}

/// 方向键导航意图（私有）
///
/// 用于在列表 / TabBar 组件间进行上下左右导航。
class _DirectionalIntent extends Intent {
  const _DirectionalIntent(this.direction);

  /// 导航方向
  final NavigationDirection direction;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _DirectionalIntent && other.direction == direction;
  }

  @override
  int get hashCode => direction.hashCode;
}

/// 导航方向枚举
enum NavigationDirection { up, down, left, right }

/// 方向键导航组件
///
/// 用于列表 / TabBar 等需要方向键导航的组件。
/// 内部使用 Shortcuts 注册方向键到 [_DirectionalIntent]，
/// 并通过 Actions 触发对应的回调。
class A11yDirectionalNavigation extends StatelessWidget {
  final Widget child;

  /// 向上导航回调
  final VoidCallback? onUp;

  /// 向下导航回调
  final VoidCallback? onDown;

  /// 向左导航回调
  final VoidCallback? onLeft;

  /// 向右导航回调
  final VoidCallback? onRight;

  const A11yDirectionalNavigation({
    super.key,
    required this.child,
    this.onUp,
    this.onDown,
    this.onLeft,
    this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowUp):
            const _DirectionalIntent(NavigationDirection.up),
        LogicalKeySet(LogicalKeyboardKey.arrowDown):
            const _DirectionalIntent(NavigationDirection.down),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft):
            const _DirectionalIntent(NavigationDirection.left),
        LogicalKeySet(LogicalKeyboardKey.arrowRight):
            const _DirectionalIntent(NavigationDirection.right),
      },
      child: Actions(
        actions: <Type, Action<_DirectionalIntent>>{
          _DirectionalIntent: CallbackAction<_DirectionalIntent>(
            onInvoke: (_DirectionalIntent intent) {
              switch (intent.direction) {
                case NavigationDirection.up:
                  onUp?.call();
                case NavigationDirection.down:
                  onDown?.call();
                case NavigationDirection.left:
                  onLeft?.call();
                case NavigationDirection.right:
                  onRight?.call();
              }
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
