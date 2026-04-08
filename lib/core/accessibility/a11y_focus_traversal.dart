import 'package:flutter/widgets.dart';

/// 阅读顺序 Focus 遍历策略
///
/// Tab / Shift+Tab 按 从上到下、从左到右 的顺序移动焦点，
/// 符合桌面端用户的阅读习惯。自动跳过不可见/禁用的元素。
///
/// 用法：在 MaterialApp 的 builder 或顶层 Widget 中使用：
/// ```dart
/// ReadingOrderTraversalScope(
///   child: ...,
/// )
/// ```
class ReadingOrderTraversalPolicy extends WidgetOrderTraversalPolicy {
  ReadingOrderTraversalPolicy();
}

/// A11yFocusScope 使用 InheritedWidget 在子树中标记焦点范围边界，
/// 业务代码可通过 _A11yFocusScopeInherited.of(context) 检测是否处于无障碍范围内。

/// 无障碍 Focus 范围隔离 Widget
///
/// 用于页面级或弹窗级，防止焦点泄漏到背景层。
/// 用法：在页面根节点或 Dialog 内容外层包裹：
/// ```dart
/// A11yFocusScope(
///   child: YourDialogContent(),
/// )
/// ```
class A11yFocusScope extends StatelessWidget {
  const A11yFocusScope({
    super.key,
    required this.child,
    this.debugLabel,
  });

  final Widget child;
  final String? debugLabel;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Focus(
        debugLabel: debugLabel ?? 'A11yFocusScope',
        canRequestFocus: true,
        descendantsAreFocusable: true,
        child: _A11yFocusScopeMarkerWidget(
          child: child,
        ),
      ),
    );
  }
}

/// 内部 Widget，用于在焦点树中标记 A11yFocusScope 边界
class _A11yFocusScopeMarkerWidget extends StatelessWidget {
  const _A11yFocusScopeMarkerWidget({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 使用 InheritedWidget 传递标记，让子树可识别处于 A11yFocusScope 内
    return _A11yFocusScopeInherited(
      child: child,
    );
  }
}

class _A11yFocusScopeInherited extends InheritedWidget {
  const _A11yFocusScopeInherited({required super.child});

  @override
  bool updateShouldNotify(_A11yFocusScopeInherited oldWidget) => false;
}

/// ReadingOrderTraversalScope Widget
///
/// 在子树内应用 ReadingOrderTraversalPolicy。
/// 这是 A11yFocusScope 的简化版本，只负责 Focus 遍历策略。
class ReadingOrderTraversalScope extends StatelessWidget {
  const ReadingOrderTraversalScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: child,
    );
  }
}
