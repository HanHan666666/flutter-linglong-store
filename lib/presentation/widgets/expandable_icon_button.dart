import 'package:flutter/material.dart';

/// 可展开图标按钮。
///
/// 默认只显示圆形图标按钮，鼠标悬浮或键盘聚焦时向右平滑展开为圆角胶囊，
/// 显示图标 + 文字标签。用于桌面端空间受限但需要明确语义的操作区。
///
/// 展开动画使用 [AnimatedContainer] 控制尺寸与背景，[AnimatedOpacity] 控制
/// 文字淡入，避免文字在容器未展开时提前出现造成视觉截断。
class ExpandableIconButton extends StatefulWidget {
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

class _ExpandableIconButtonState extends State<ExpandableIconButton> {
  bool _isExpanded = false;

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
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: ExcludeSemantics(
                          child: Icon(
                            widget.icon,
                            size: 20,
                            color: effectiveIconColor,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _isExpanded ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: _isExpanded
                              ? Text(
                                  label,
                                  key: const ValueKey('expandable-icon-button-label'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: effectiveForegroundColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : const SizedBox.shrink(),
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
