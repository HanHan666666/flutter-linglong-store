import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/install_queue_provider.dart';
import '../../application/providers/network_speed_provider.dart';
import '../../core/config/theme.dart';
import '../../core/di/providers.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_task.dart';
import 'app_icon.dart';

/// 下载管理弹窗
///
/// 显示安装队列和安装历史记录
class DownloadManagerDialog extends ConsumerWidget {
  const DownloadManagerDialog({super.key});

  static const double _dialogWidth = 440;
  static const double _dialogHeight = 472;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(installQueueProvider);
    final appColors = context.appColors;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      backgroundColor: Colors.transparent,
      child: Container(
        width: _dialogWidth,
        height: _dialogHeight,
        decoration: BoxDecoration(
          color: appColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: appColors.borderSecondary),
          boxShadow: AppShadows.modal,
        ),
        child: Column(
          children: [
            _buildHeader(context, ref, queueState),
            _buildOverview(context, queueState),
            Divider(height: 1, color: appColors.divider),
            Expanded(child: _buildContent(context, ref, queueState)),
            _buildFooter(context, ref, queueState),
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
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: appColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.download_rounded, color: appColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.downloadManager ?? '下载管理',
                  style: AppTextStyles.title3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _buildHeaderSummary(context, queueState),
                  style: AppTextStyles.caption.copyWith(
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildOverview(BuildContext context, InstallQueueState queueState) {
    final l10n = AppLocalizations.of(context);
    final activeCount = queueState.currentTask == null ? 0 : 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewPill(
              label: l10n?.downloading ?? '下载中...',
              count: activeCount,
              highlighted: activeCount > 0,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _OverviewPill(
              label:
                  l10n?.waitingCount(queueState.queue.length) ??
                  '等待中 (${queueState.queue.length})',
              count: queueState.queue.length,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _OverviewPill(
              label: l10n?.completed ?? '已完成',
              count: queueState.history.length,
            ),
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

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (queueState.currentTask != null) ...[
              _buildSectionTitle(context, l10n?.installingLabel ?? '正在安装'),
              _buildCurrentTask(context, ref, queueState.currentTask!),
              const SizedBox(height: AppSpacing.md),
            ],
            if (queueState.queue.isNotEmpty) ...[
              _buildSectionTitle(
                context,
                l10n?.waitingCount(queueState.queue.length) ??
                    '等待中 (${queueState.queue.length})',
              ),
              ...queueState.queue.map(
                (task) => _buildQueueItem(context, ref, task),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (queueState.history.isNotEmpty) ...[
              _buildSectionTitle(context, l10n?.completed ?? '已完成'),
              ...queueState.history.map(
                (task) => _buildHistoryItem(context, ref, task),
              ),
            ],
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: context.appColors.textSecondary,
          fontWeight: FontWeight.w600,
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
      featured: true,
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
      compact: true,
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
      compact: true,
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

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    InstallQueueState queueState,
  ) {
    final appColors = context.appColors;
    final speed = ref.watch(networkSpeedProvider).formatted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: appColors.cardBackground.withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.speed_outlined, size: 16, color: appColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              speed.isEmpty ? '等待下载任务开始' : '实时速度 $speed',
              style: AppTextStyles.caption.copyWith(
                color: appColors.textSecondary,
              ),
            ),
          ),
          Text(
            '${queueState.history.length} 条记录',
            style: AppTextStyles.caption.copyWith(
              color: appColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _buildHeaderSummary(
    BuildContext context,
    InstallQueueState queueState,
  ) {
    final parts = <String>[];
    if (queueState.currentTask != null) {
      parts.add('1 个活跃任务');
    }
    if (queueState.queue.isNotEmpty) {
      parts.add('${queueState.queue.length} 个等待中');
    }
    if (queueState.history.isNotEmpty) {
      parts.add('${queueState.history.length} 条最近记录');
    }
    if (parts.isEmpty) {
      return AppLocalizations.of(context)?.noDownloadTasks ?? '暂无下载任务';
    }
    return parts.join('，');
  }
}

/// 任务卡片组件
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    this.showProgress = false,
    this.featured = false,
    this.compact = false,
    this.downloadSpeed,
    this.onCancel,
    this.onOpen,
    this.onRetry,
    this.onRemove,
  });

  final InstallTask task;
  final bool showProgress;
  final bool featured;
  final bool compact;
  final String? downloadSpeed;
  final VoidCallback? onCancel;
  final VoidCallback? onOpen;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(featured ? AppSpacing.lg : AppSpacing.md),
      decoration: BoxDecoration(
        color: featured
            ? appColors.primaryLight.withValues(alpha: 0.6)
            : appColors.cardBackground.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(featured ? 18 : 16),
        border: Border.all(
          color: featured ? appColors.primaryLight : appColors.borderSecondary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(
                iconUrl: task.icon,
                size: featured ? 48 : 42,
                borderRadius: featured ? 16 : 14,
                appName: task.appName,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.appName,
                            // featured 用 16px 正文级别，普通用 14px 说明级别
                            style:
                                (featured
                                        ? AppTextStyles.body
                                        : AppTextStyles.bodyMedium)
                                    .copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildStatusPill(context),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _buildSubtitle(context),
                      style: AppTextStyles.caption.copyWith(
                        color: appColors.textSecondary,
                      ),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildActionButtons(context),
            ],
          ),
          if (showProgress &&
              (task.isProcessing ||
                  task.status == InstallStatus.downloading)) ...[
            const SizedBox(height: AppSpacing.md),
            _buildProgressBar(context),
          ],
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
    );
  }

  /// 构建状态图标
  /// 构建进度条
  Widget _buildProgressBar(BuildContext context) {
    final appColors = context.appColors;
    final message = task.displayMessage?.trim();
    final speed = downloadSpeed?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                message != null && message.isNotEmpty ? message : '处理中',
                style: AppTextStyles.caption.copyWith(
                  color: appColors.textSecondary,
                ),
              ),
            ),
            Text(
              task.progressPercentLabel,
              style: AppTextStyles.caption.copyWith(
                color: appColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: task.progressValue,
          minHeight: 8,
          borderRadius: BorderRadius.circular(AppRadius.full),
          backgroundColor: appColors.surfaceContainerHighest,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          [
            if (speed != null && speed.isNotEmpty) speed,
            if (task.version != null && task.version!.isNotEmpty) task.version!,
            if ((speed == null || speed.isEmpty)) task.progressPercentLabel,
          ].join(' · '),
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildStatusPill(BuildContext context) {
    final appColors = context.appColors;
    final (label, color) = switch (task.status) {
      InstallStatus.pending => ('等待中', appColors.textSecondary),
      InstallStatus.downloading => ('下载中', appColors.primary),
      InstallStatus.installing => ('安装中', appColors.primary),
      InstallStatus.success => ('已完成', appColors.success),
      InstallStatus.failed => ('失败', appColors.error),
      InstallStatus.cancelled => ('已取消', appColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.tiny.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _buildSubtitle(BuildContext context) {
    if (task.isFailed &&
        task.errorMessage != null &&
        task.errorMessage!.isNotEmpty) {
      return task.errorMessage!;
    }
    final parts = <String>[
      if (task.version != null && task.version!.isNotEmpty) task.version!,
      if (task.displayMessage != null && task.displayMessage!.trim().isNotEmpty)
        task.displayMessage!.trim(),
      if ((task.displayMessage == null || task.displayMessage!.trim().isEmpty))
        switch (task.status) {
          InstallStatus.pending => task.waitingMessage,
          InstallStatus.downloading => '正在下载资源',
          InstallStatus.installing => '正在安装',
          InstallStatus.success => task.successMessage,
          InstallStatus.failed => '安装失败',
          InstallStatus.cancelled => task.cancelledMessage,
        },
    ];
    return parts.join(' · ');
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

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({
    required this.label,
    required this.count,
    this.highlighted = false,
  });

  final String label;
  final int count;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? appColors.primaryLight.withValues(alpha: 0.75)
            : appColors.cardBackground.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: highlighted
              ? appColors.primaryLight
              : appColors.borderSecondary,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: highlighted
                    ? appColors.primary
                    : appColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              color: highlighted ? appColors.primary : appColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
