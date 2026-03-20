import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/install_queue_provider.dart';
import '../../application/providers/network_speed_provider.dart';
import '../../core/config/theme.dart';
import '../../core/di/providers.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_task.dart';

/// 下载管理弹窗
///
/// 显示安装队列和安装历史记录
class DownloadManagerDialog extends ConsumerWidget {
  const DownloadManagerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(installQueueProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildHeader(context, ref, queueState),
            const Divider(height: 1),
            // 内容区域
            Flexible(child: _buildContent(context, ref, queueState)),
          ],
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    InstallQueueState queueState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)?.downloadManager ?? '下载管理',
            style: AppTextStyles.title3,
          ),
          const Spacer(),
          // 清空历史按鈕
          if (queueState.history.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(installQueueProvider.notifier).clearHistory();
              },
              child: Text(AppLocalizations.of(context)?.clearRecords ?? '清空记录'),
            ),
          // 关闭按钮
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    InstallQueueState queueState,
  ) {
    final l10n = AppLocalizations.of(context);
    final hasActiveTasks = queueState.hasActiveTasks();
    final hasHistory = queueState.history.isNotEmpty;

    if (!hasActiveTasks && !hasHistory) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前任务
          if (queueState.currentTask != null) ...[
            _buildSectionTitle(
              context,
              l10n?.installingLabel ?? '正在安装',
            ),
            _buildCurrentTask(context, ref, queueState.currentTask!),
            const SizedBox(height: AppSpacing.sm),
          ],
          // 等待队列
          if (queueState.queue.isNotEmpty) ...[
            _buildSectionTitle(
              context,
              l10n?.waitingCount(queueState.queue.length) ??
                  '等待中 (${queueState.queue.length})',
            ),
            ...queueState.queue.map(
              (task) => _buildQueueItem(context, ref, task),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          // 历史记录
          if (queueState.history.isNotEmpty) ...[
            _buildSectionTitle(context, l10n?.completed ?? '已完成'),
            ...queueState.history.map(
              (task) => _buildHistoryItem(context, ref, task),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x2l),
      child: Center(
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
              AppLocalizations.of(context)?.noDownloadTasks ?? '暂无下载任务',
              style: AppTextStyles.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建区域标题
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: context.appColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建当前任务（带进度条）
  Widget _buildCurrentTask(
    BuildContext context,
    WidgetRef ref,
    InstallTask task,
  ) {
    final downloadSpeed = ref.watch(networkSpeedProvider).formatted;

    return _TaskCard(
      task: task,
      showProgress: true,
      downloadSpeed: downloadSpeed,
      onCancel: () async {
        await ref.read(installQueueProvider.notifier).cancelTask(task.appId);
      },
    );
  }

  /// 构建队列项
  Widget _buildQueueItem(
    BuildContext context,
    WidgetRef ref,
    InstallTask task,
  ) {
    return _TaskCard(
      task: task,
      onCancel: () {
        ref.read(installQueueProvider.notifier).removeFromQueue(task.appId);
      },
    );
  }

  /// 构建历史项
  Widget _buildHistoryItem(
    BuildContext context,
    WidgetRef ref,
    InstallTask task,
  ) {
    return _TaskCard(
      task: task,
      onOpen: task.status == InstallStatus.success
          ? () async {
              await ref.read(linglongCliRepositoryProvider).runApp(task.appId);
            }
          : null,
      onRetry: task.isFailed
          ? () {
              ref.read(installQueueProvider.notifier).retryFailed(task.appId);
            }
          : null,
      onRemove: () {
        ref.read(installQueueProvider.notifier).removeFromQueue(task.appId);
      },
    );
  }
}

/// 任务卡片组件
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    this.showProgress = false,
    this.downloadSpeed,
    this.onCancel,
    this.onOpen,
    this.onRetry,
    this.onRemove,
  });

  final InstallTask task;
  final bool showProgress;
  final String? downloadSpeed;
  final VoidCallback? onCancel;
  final VoidCallback? onOpen;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 状态图标
                _buildStatusIcon(context),
                const SizedBox(width: AppSpacing.sm),
                // 应用名称和版本
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.appName,
                        style: AppTextStyles.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.version != null)
                        Text(task.version!, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                // 操作按钮
                _buildActionButtons(context),
              ],
            ),
            // 进度条（仅当前任务显示）
            if (showProgress &&
                (task.isProcessing ||
                    task.status == InstallStatus.downloading)) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildProgressBar(context),
            ],
            // 错误信息
            if (task.isFailed && task.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                task.errorMessage!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建状态图标
  Widget _buildStatusIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (task.status) {
      case InstallStatus.pending:
        icon = Icons.schedule;
        color = context.appColors.textTertiary;
      case InstallStatus.downloading:
        icon = Icons.downloading;
        color = AppColors.primary;
      case InstallStatus.installing:
        icon = Icons.downloading;
        color = AppColors.primary;
      case InstallStatus.success:
        icon = Icons.check_circle;
        color = AppColors.success;
      case InstallStatus.failed:
        icon = Icons.error;
        color = AppColors.error;
      case InstallStatus.cancelled:
        icon = Icons.cancel;
        color = context.appColors.textTertiary;
    }

    return Icon(icon, size: 20, color: color);
  }

  /// 构建进度条
  Widget _buildProgressBar(BuildContext context) {
    final progressText = '${task.progress.toStringAsFixed(0)}%';
    final message = task.message?.trim();
    final speed = downloadSpeed?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: task.progress / 100,
          backgroundColor: context.appColors.cardBackground,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          [
            if (message != null && message.isNotEmpty) message,
            if (speed != null && speed.isNotEmpty) speed,
            if ((message == null || message.isEmpty) &&
                (speed == null || speed.isEmpty))
              progressText,
          ].join(' · '),
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (task.isProcessing ||
        task.status == InstallStatus.downloading ||
        task.status == InstallStatus.pending) {
      // 可取消
      return IconButton(
        icon: const Icon(Icons.close, size: 18),
        onPressed: onCancel,
        tooltip: l10n?.cancel ?? '取消',
      );
    }

    if (task.isFailed && onRetry != null) {
      // 可重试
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: onRetry,
            tooltip: l10n?.retry ?? '重试',
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              tooltip: l10n?.remove ?? '移除',
            ),
        ],
      );
    }

    if (task.status == InstallStatus.success && onOpen != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 18),
            onPressed: onOpen,
            tooltip: l10n?.open ?? '打开',
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              tooltip: l10n?.remove ?? '移除',
            ),
        ],
      );
    }

    if (onRemove != null) {
      return IconButton(
        icon: const Icon(Icons.close, size: 18),
        onPressed: onRemove,
        tooltip: l10n?.remove ?? '移除',
      );
    }

    return const SizedBox.shrink();
  }
}

/// 显示下载管理弹窗
Future<void> showDownloadManagerDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const DownloadManagerDialog(),
  );
}
