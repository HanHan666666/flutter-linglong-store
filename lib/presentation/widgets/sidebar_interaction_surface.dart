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

class _SidebarInteractionSurfaceState extends State<SidebarInteractionSurface> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 选中 pill 背景按原设计是「品牌蓝的半透明变体」，因此对 scheme.primary
    // 做同样的透明度运算（docs/48 §7.6）：回退路径数值逐位不变，系统强调色
    // 下随 scheme.primary 一起流动。调用方传入的 selectedColor 优先级不变。
    final selectedBg =
        widget.selectedColor ??
        Theme.of(context).colorScheme.primary.withValues(
          alpha: isDark ? 0.22 : 0.08,
        );
    final hoverBg =
        widget.hoverColor ??
        palette.surfaceContainerHighest.withValues(alpha: isDark ? 0.46 : 0.72);
    // 默认态使用目标色的透明版本，避免 Colors.transparent（透明黑）
    // 在动画插值时产生深色闪烁
    final defaultBg = hoverBg.withValues(alpha: 0);

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
            borderRadius: widget.borderRadius ?? AppRadius.smRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
