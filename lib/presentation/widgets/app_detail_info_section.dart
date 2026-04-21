import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/l10n/app_localizations.dart';

enum AppDetailInfoSpan { compact, full }

class AppDetailInfoEntry {
  const AppDetailInfoEntry({
    required this.label,
    required this.value,
    this.span = AppDetailInfoSpan.compact,
    this.isCopyable = false,
  });

  final String label;
  final String value;
  final AppDetailInfoSpan span;
  final bool isCopyable;
}

class AppDetailInfoSection extends StatelessWidget {
  const AppDetailInfoSection({required this.entries, super.key});

  final List<AppDetailInfoEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 24.0;
        const runSpacing = 16.0;
        final columnCount = _resolveColumnCount(constraints.maxWidth);
        final compactWidth = columnCount == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columnCount - 1)) /
                  columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: entries.map((entry) {
            final itemWidth = entry.span == AppDetailInfoSpan.full
                ? constraints.maxWidth
                : compactWidth;
            return SizedBox(
              key: ValueKey('app-detail-info-${entry.label}'),
              width: itemWidth,
              child: _AppDetailInfoItem(entry: entry),
            );
          }).toList(),
        );
      },
    );
  }

  int _resolveColumnCount(double maxWidth) {
    if (maxWidth >= 840) {
      return 3;
    }
    if (maxWidth >= 520) {
      return 2;
    }
    return 1;
  }
}

class _AppDetailInfoItem extends StatelessWidget {
  const _AppDetailInfoItem({required this.entry});

  final AppDetailInfoEntry entry;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.label, style: labelStyle),
        const SizedBox(height: 6),
        if (entry.isCopyable)
          _CopyableValue(value: entry.value)
        else
          Text(entry.value),
      ],
    );
  }
}

class _CopyableValue extends StatefulWidget {
  const _CopyableValue({required this.value});

  static const _buttonSize = 24.0;
  static const _buttonSpacing = 4.0;
  static const _copiedFeedbackDuration = Duration(milliseconds: 1200);

  final String value;

  @override
  State<_CopyableValue> createState() => _CopyableValueState();
}

class _CopyableValueState extends State<_CopyableValue> {
  Timer? _copiedTimer;
  bool _isCopied = false;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleCopyPressed() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;

    _copiedTimer?.cancel();
    setState(() => _isCopied = true);

    // 用短暂的对勾替代底部通知条，减少详情页阅读过程中的视觉打断。
    _copiedTimer = Timer(_CopyableValue._copiedFeedbackDuration, () {
      if (!mounted) return;
      setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final copyTooltip = l10n?.copy ?? '复制';
    final copiedTooltip = l10n?.copied(widget.value) ?? '已复制：${widget.value}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTextWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth -
                    _CopyableValue._buttonSize -
                    _CopyableValue._buttonSpacing)
                .clamp(0.0, double.infinity)
                .toDouble()
            : double.infinity;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTextWidth),
              child: Text(widget.value),
            ),
            const SizedBox(width: _CopyableValue._buttonSpacing),
            SizedBox(
              width: _CopyableValue._buttonSize,
              height: _CopyableValue._buttonSize,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: _CopyableValue._buttonSize,
                  height: _CopyableValue._buttonSize,
                ),
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                tooltip: _isCopied ? copiedTooltip : copyTooltip,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                  shape: WidgetStateProperty.all(const CircleBorder()),
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return theme.colorScheme.primary.withValues(alpha: 0.08);
                    }
                    if (states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)) {
                      return theme.colorScheme.primary.withValues(alpha: 0.04);
                    }
                    return Colors.transparent;
                  }),
                ),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                        animation,
                      ),
                      child: child,
                    ),
                  ),
                  child: Icon(
                    _isCopied ? Icons.check_rounded : Icons.copy_outlined,
                    key: ValueKey<bool>(_isCopied),
                    color: _isCopied
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onPressed: _handleCopyPressed,
              ),
            ),
          ],
        );
      },
    );
  }
}
