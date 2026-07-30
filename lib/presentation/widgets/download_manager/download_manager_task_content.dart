/// 下载管理当前、等待和历史任务区域。
///
/// 该文件显式表达三类任务的卡片差异和操作能力，不读取 Provider，
/// 不决定 taskId/appId 的命令参数语义。
library;

import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/install_progress.dart';
import '../../../domain/models/install_task.dart';
import 'download_task_card.dart';
import 'download_task_view_data.dart';

/// 展示下载任务内容并把任务操作委托给容器。
class DownloadManagerTaskContent extends StatelessWidget {
  /// 创建下载任务内容区域。
  const DownloadManagerTaskContent({
    required this.currentTask,
    required this.queuedTasks,
    required this.historyTasks,
    required this.currentDownloadSpeed,
    required this.onCancelCurrent,
    required this.onRemoveQueued,
    required this.onOpenHistory,
    required this.onRetryHistory,
    required this.onRemoveHistory,
    super.key,
  });

  /// 当前执行任务的展示数据。
  final DownloadTaskViewData? currentTask;

  /// 等待任务的展示数据。
  final List<DownloadTaskViewData> queuedTasks;

  /// 历史任务的展示数据。
  final List<DownloadTaskViewData> historyTasks;

  /// 当前任务的 CLI 或系统回退速度。
  final String currentDownloadSpeed;

  /// 取消当前任务的回调。
  final ValueChanged<InstallTask> onCancelCurrent;

  /// 移除指定等待任务的回调。
  final ValueChanged<InstallTask> onRemoveQueued;

  /// 打开成功历史任务应用的回调。
  final ValueChanged<InstallTask> onOpenHistory;

  /// 重试指定失败历史任务的回调。
  final ValueChanged<InstallTask> onRetryHistory;

  /// 删除指定历史任务的回调。
  final ValueChanged<InstallTask> onRemoveHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (currentTask == null && queuedTasks.isEmpty && historyTasks.isEmpty) {
      return _DownloadManagerEmptyState(label: l10n.noDownloadTasks);
    }

    return Scrollbar(
      child: SingleChildScrollView(
        key: const Key('downloadManagerTaskList'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentTask case final data?) ...[
              _DownloadManagerSectionHeader(title: l10n.installingLabel),
              DownloadTaskCard(
                key: ValueKey(data.task.id),
                data: data,
                featured: true,
                showProgress: true,
                downloadSpeed: currentDownloadSpeed,
                onCancel: () => onCancelCurrent(data.task),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (queuedTasks.isNotEmpty) ...[
              _DownloadManagerSectionHeader(
                title: l10n.waitingCount(queuedTasks.length),
              ),
              ...queuedTasks.map(
                (data) => DownloadTaskCard(
                  key: ValueKey(data.task.id),
                  data: data,
                  onCancel: () => onRemoveQueued(data.task),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (historyTasks.isNotEmpty) ...[
              _DownloadManagerSectionHeader(title: l10n.completed),
              ...historyTasks.map(
                (data) => DownloadTaskCard(
                  key: ValueKey(data.task.id),
                  data: data,
                  onOpen: data.task.status == InstallStatus.success
                      ? () => onOpenHistory(data.task)
                      : null,
                  onRetry: data.task.isFailed
                      ? () => onRetryHistory(data.task)
                      : null,
                  onRemove: () => onRemoveHistory(data.task),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DownloadManagerEmptyState extends StatelessWidget {
  const _DownloadManagerEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_done,
              size: 64,
              color: context.appColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              label,
              style: context.appTextStyles.body.copyWith(
                color: context.appColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadManagerSectionHeader extends StatelessWidget {
  const _DownloadManagerSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: appColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: context.appTextStyles.caption.copyWith(
              color: appColors.textSecondary,
              fontWeight: context.appFontWeight(FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
