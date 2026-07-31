/// 下载管理工作面板底部状态栏。
///
/// 该文件只展示容器计算后的速度和记录数量，不订阅网速或安装队列。
library;

import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';

/// 展示下载实时速度和历史记录数量。
class DownloadManagerFooter extends StatelessWidget {
  /// 创建下载管理底部状态栏。
  const DownloadManagerFooter({
    required this.speed,
    required this.historyCount,
    super.key,
  });

  /// 当前任务 CLI 速度或系统网速回退值。
  final String speed;

  /// 当前历史记录数量。
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('downloadManagerStatusBar'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: appColors.surfaceContainerLow,
        border: Border(top: BorderSide(color: appColors.borderSecondary)),
      ),
      child: Row(
        children: [
          Icon(Icons.speed_outlined, size: 16, color: appColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              speed.isEmpty
                  ? l10n.downloadWaitingForTask
                  : l10n.downloadRealtimeSpeed(speed),
              style: context.appTextStyles.caption.copyWith(
                color: appColors.textSecondary,
              ),
            ),
          ),
          Text(
            l10n.downloadHistoryCount(historyCount),
            style: context.appTextStyles.caption.copyWith(
              color: appColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
