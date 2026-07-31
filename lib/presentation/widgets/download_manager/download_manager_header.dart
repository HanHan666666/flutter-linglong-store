/// 下载管理工作面板标题栏。
///
/// 该文件只展示标题、清空记录入口和桌面关闭按钮，所有操作通过回调注入。
library;

import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';

/// 下载管理工作面板的固定标题栏。
class DownloadManagerHeader extends StatelessWidget {
  /// 创建下载管理标题栏。
  const DownloadManagerHeader({
    required this.hasHistory,
    required this.onClearHistory,
    required this.onClose,
    super.key,
  });

  /// 当前是否存在可清空的历史记录。
  final bool hasHistory;

  /// 清空安装历史的回调。
  final VoidCallback onClearHistory;

  /// 关闭弹窗但不影响任务的回调。
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      key: const Key('downloadManagerTitleBar'),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: appColors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: appColors.borderSecondary)),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.download_rounded,
              color: appColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.downloadManager,
            style: context.appTextStyles.bodyMedium.copyWith(
              color: appColors.textPrimary,
              fontWeight: context.appFontWeight(FontWeight.w600),
            ),
          ),
          const Spacer(),
          if (hasHistory)
            TextButton(
              onPressed: onClearHistory,
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 32),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.clearRecords),
            ),
          const SizedBox(width: AppSpacing.sm),
          _DownloadManagerCloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

class _DownloadManagerCloseButton extends StatefulWidget {
  const _DownloadManagerCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_DownloadManagerCloseButton> createState() =>
      _DownloadManagerCloseButtonState();
}

class _DownloadManagerCloseButtonState
    extends State<_DownloadManagerCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final backgroundColor = _hovered
        ? AppColors.error.withValues(alpha: 0.88)
        : appColors.textPrimary.withValues(alpha: 0.06);
    final iconColor = _hovered
        ? AppColors.textLight
        : appColors.textSecondary.withValues(alpha: 0.86);

    return Tooltip(
      message: l10n.close,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(Icons.close, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }
}
