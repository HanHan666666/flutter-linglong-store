import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/utils/app_notification_helpers.dart';

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

class _CopyableValue extends StatelessWidget {
  const _CopyableValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(value)),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 16,
            tooltip: '复制',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                showAppNotification(
                  context,
                  AppLocalizations.of(context)?.copied(value) ??
                      '已复制：$value',
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
