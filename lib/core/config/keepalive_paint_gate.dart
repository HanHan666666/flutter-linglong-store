import 'package:flutter/material.dart';

/// KeepAlive 页面绘制闸门。
///
/// 隐藏页面时仍然保留 Element/State，确保缓存状态不丢失；
/// 但会把页面从绘制树、命中测试树和 ticker 树中移除，
/// 避免切页时旧页面继续透出到新页面骨架屏后面。
class KeepAlivePaintGate extends StatelessWidget {
  const KeepAlivePaintGate({
    required this.isVisible,
    required this.child,
    super.key,
  });

  final bool isVisible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: isVisible,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Offstage(offstage: !isVisible, child: child),
      ),
    );
  }
}
