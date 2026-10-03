/// 桌面操作区的紧凑图标与悬浮标签。
///
/// 以局部状态承载展开动画，并在窄约束下保护图标和完整无障碍说明。
library;

import 'package:flutter/material.dart';

/// 可展开图标按钮。
///
/// 默认只显示圆形图标按钮，鼠标悬浮或键盘聚焦时沿阅读方向展开为圆角胶囊，
/// 显示图标 + 文字标签。用于桌面端空间受限但需要明确语义的操作区。
///
/// 展开动画使用 [AnimatedContainer] 控制尺寸与背景，[AnimatedOpacity] 控制
/// 文字淡入，避免文字在容器未展开时提前出现造成视觉截断。
class ExpandableIconButton extends StatefulWidget {
  /// 保持原有图标热区尺寸，与操作组的收起态宽度预算共用来源。
  static const double _iconAreaSize = 40;

  /// 收起态实际外宽包含 40px 图标区和两侧 1px 边框，供操作组预留稳定热区。
  static const double collapsedWidth = _iconAreaSize + 2;

  /// 创建一个可展开图标按钮。
  const ExpandableIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.foregroundColor,
    this.semanticsLabel,
    super.key,
  });

  /// 按钮图标。
  final IconData icon;

  /// 展开后显示的文字标签。
  final String label;

  /// 点击回调。
  final VoidCallback onTap;

  /// 图标颜色，为空时使用主题 [ColorScheme.onSurfaceVariant]。
  final Color? iconColor;

  /// 文字颜色，为空时使用主题 [ColorScheme.onSurface]。
  final Color? foregroundColor;

  /// 无障碍语义标签，为空时使用 [label]。
  final String? semanticsLabel;

  @override
  State<ExpandableIconButton> createState() => _ExpandableIconButtonState();
}

/// 将展开状态限制在单个操作内，避免重建详情页或重新订阅业务数据。
class _ExpandableIconButtonState extends State<ExpandableIconButton> {
  /// 控制当前操作标签可见性，不持久化到业务状态。
  bool _isExpanded = false;

  /// 长标签只占剩余宽度，完整说明继续通过 Tooltip 和语义标签提供。
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        widget.iconColor ?? theme.colorScheme.onSurfaceVariant;
    final effectiveForegroundColor =
        widget.foregroundColor ?? theme.colorScheme.onSurface;
    final label = widget.label;

    return Semantics(
      button: true,
      label: widget.semanticsLabel ?? label,
      child: Tooltip(
        message: label,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isExpanded = true),
          onExit: (_) => setState(() => _isExpanded = false),
          child: FocusableActionDetector(
            onShowHoverHighlight: (value) {
              setState(() => _isExpanded = value);
            },
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: 40,
                  padding: _isExpanded
                      ? const EdgeInsets.symmetric(horizontal: 12)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: _isExpanded
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: ExpandableIconButton._iconAreaSize,
                        height: 40,
                        child: ExcludeSemantics(
                          child: Icon(
                            widget.icon,
                            size: 20,
                            color: effectiveIconColor,
                          ),
                        ),
                      ),
                      // Wrap 会给单个按钮有界宽度；标签必须可收缩，
                      // 否则英文/阿拉伯语长文案会穿过操作区边界。
                      Flexible(
                        child: AnimatedOpacity(
                          opacity: _isExpanded ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: _isExpanded
                                ? Text(
                                    label,
                                    key: const ValueKey(
                                      'expandable-icon-button-label',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: effectiveForegroundColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
