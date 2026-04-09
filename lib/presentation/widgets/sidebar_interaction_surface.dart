import 'package:flutter/material.dart';

import '../../core/config/theme.dart';

/// 侧边栏通用交互表面
///
/// 封装 hover / active / tap 三态交互，避免在多个菜单项中重复实现。
/// 提供统一的背景色动画过渡，调用者负责内容布局和语义标注。
class SidebarInteractionSurface extends StatefulWidget {
  const SidebarInteractionSurface({
    required this.isSelected,
    required this.onTap,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.hoverColor,
    this.selectedColor,
    super.key,
  });

  /// 是否选中状态
  final bool isSelected;

  /// 点击回调
  final VoidCallback onTap;

  /// 内容子组件
  final Widget child;

  /// 固定宽度（可选，不设置则自适应父容器宽度）
  final double? width;

  /// 固定高度（可选）
  final double? height;

  /// 圆角（可选，默认 AppRadius.xsRadius）
  final BorderRadius? borderRadius;

  /// hover 状态背景色（可选，默认 surfaceContainerLow）
  final Color? hoverColor;

  /// 选中状态背景色（可选，默认 primaryLight）
  final Color? selectedColor;

  @override
  State<SidebarInteractionSurface> createState() =>
      _SidebarInteractionSurfaceState();
}

class _SidebarInteractionSurfaceState
    extends State<SidebarInteractionSurface> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final selectedBg = widget.selectedColor ?? palette.primaryLight;
    final hoverBg = widget.hoverColor ?? palette.surfaceContainerLow;
    // 默认态使用目标色的透明版本，避免 Colors.transparent（透明黑）
    // 在动画插值时产生深色闪烁
    final defaultBg = palette.surfaceContainerLow.withAlpha(0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? selectedBg
                : (_isHovered ? hoverBg : defaultBg),
            borderRadius: widget.borderRadius ?? AppRadius.xsRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}