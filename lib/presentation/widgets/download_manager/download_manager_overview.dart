/// 下载管理工作面板概览区域。
///
/// 该文件只展示当前、等待和历史任务数量，不读取安装队列 Provider。
library;

import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';

/// 展示下载管理三个稳定任务指标。
class DownloadManagerOverview extends StatelessWidget {
  /// 创建任务概览条。
  const DownloadManagerOverview({
    required this.activeCount,
    required this.queuedCount,
    required this.historyCount,
    super.key,
  });

  /// 当前执行中的任务数量。
  final int activeCount;

  /// 等待执行的任务数量。
  final int queuedCount;

  /// 历史记录数量。
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('downloadManagerOverviewBar'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      color: context.appColors.surface,
      child: Row(
        children: [
          Expanded(
            child: _DownloadManagerOverviewTile(
              icon: Icons.downloading_rounded,
              label: l10n.installStatusProcessing,
              count: activeCount,
              highlighted: activeCount > 0,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _DownloadManagerOverviewTile(
              icon: Icons.schedule_rounded,
              label: l10n.waiting,
              count: queuedCount,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _DownloadManagerOverviewTile(
              icon: Icons.done_all_rounded,
              label: l10n.completed,
              count: historyCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadManagerOverviewTile extends StatelessWidget {
  const _DownloadManagerOverviewTile({
    required this.icon,
    required this.label,
    required this.count,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? appColors.primaryLight.withValues(alpha: 0.62)
            : appColors.cardBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: highlighted
              ? appColors.primary.withValues(alpha: 0.18)
              : appColors.borderSecondary,
        ),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              size: 18,
              color: highlighted ? appColors.primary : appColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: context.appTextStyles.caption.copyWith(
                color: highlighted
                    ? appColors.primary
                    : appColors.textSecondary,
                fontWeight: context.appFontWeight(FontWeight.w600),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count',
            style: context.appTextStyles.caption.copyWith(
              color: highlighted ? appColors.primary : appColors.textPrimary,
              fontWeight: context.appFontWeight(FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
