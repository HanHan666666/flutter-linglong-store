import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';

class CopyableCommandBlock extends StatefulWidget {
  const CopyableCommandBlock({
    required this.command,
    this.semanticLabel,
    super.key,
  });

  final String command;
  final String? semanticLabel;

  @override
  State<CopyableCommandBlock> createState() => _CopyableCommandBlockState();
}

class _CopyableCommandBlockState extends State<CopyableCommandBlock> {
  static const _copiedFeedbackDuration = Duration(milliseconds: 1200);

  Timer? _copiedTimer;
  bool _isCopied = false;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleCopyPressed() async {
    await Clipboard.setData(ClipboardData(text: widget.command));
    if (!mounted) return;

    _copiedTimer?.cancel();
    setState(() => _isCopied = true);
    _copiedTimer = Timer(_copiedFeedbackDuration, () {
      if (!mounted) return;
      setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final tooltip = _isCopied
        ? (l10n?.copied(widget.command) ?? '已复制命令')
        : (l10n?.copy ?? '复制');

    return Semantics(
      label: widget.semanticLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SelectableText(
                widget.command,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: tooltip,
              onPressed: _handleCopyPressed,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Icon(
                  _isCopied ? Icons.check_rounded : Icons.copy_outlined,
                  key: ValueKey<bool>(_isCopied),
                  color: _isCopied
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
