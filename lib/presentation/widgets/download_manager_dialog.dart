import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/network_speed_provider.dart';
import '../../core/config/theme.dart';
import '../../core/di/providers.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_task.dart';
import 'app_icon.dart';

/// 下载管理弹窗
///
/// 以轻工作面板形式显示安装队列和安装历史记录，业务动作仍统一回到安装队列。
class DownloadManagerDialog extends ConsumerWidget {
  const DownloadManagerDialog({super.key});

  /// 工作面板宽度；比旧弹窗更宽，用于容纳当前任务和行级操作区。
  static const double _dialogWidth = 640;

  /// 工作面板最小高度，避免短列表时弹窗视觉塌缩。
  static const double _dialogMinHeight = 480;

  /// 工作面板最大高度，避免大屏上任务面板过高影响扫描效率。
  static const double _dialogMaxHeight = 620;

  /// 面板圆角与截图预览灯箱保持一致，减少弹层风格割裂。
  static const double _dialogRadius = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(installQueueProvider);
    final appColors = context.appColors;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2l,
        vertical: AppSpacing.xl,
      ),
      backgroundColor: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight =
              MediaQuery.sizeOf(context).height - AppSpacing.x5l;
          final dialogHeight = availableHeight
              .clamp(_dialogMinHeight, _dialogMaxHeight)
              .toDouble();

          return SizedBox(
            width: _dialogWidth,
            height: dialogHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: appColors.surface,
                borderRadius: BorderRadius.circular(_dialogRadius),
                border: Border.all(color: appColors.borderSecondary),
                boxShadow: AppShadows.modal,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_dialogRadius),
                child: Column(
                  children: [
                    _buildTitleBar(context, ref, queueState),
                    _buildOverview(context, queueState),
                    Divider(height: 1, color: appColors.divider),
                    Expanded(child: _buildContent(context, ref, queueState)),
                    _buildFooter(context, ref, queueState),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建固定顶栏，参考截图预览灯箱的桌面面板结构。
  Widget _buildTitleBar(
    BuildContext context,
    WidgetRef ref,
    InstallQueueState queueState,
  ) {
    final appColors = context.appColors;
    final l10n = AppLocalizations.of(context);

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
            l10n?.downloadManager ?? '下载管理',
            style: context.appTextStyles.bodyMedium.copyWith(
              color: appColors.textPrimary,
              fontWeight: context.appFontWeight(FontWeight.w600),
            ),
          ),
          const Spacer(),
          if (queueState.history.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(installQueueProvider.notifier).clearHistory();
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 32),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n?.clearRecords ?? '清空记录'),
            ),
          const SizedBox(width: AppSpacing.sm),
          _PanelCloseButton(onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  /// 构建任务概览条，承担工作面板的全局状态总览。
  Widget _buildOverview(BuildContext context, InstallQueueState queueState) {
    final activeCount = queueState.currentTask == null ? 0 : 1;
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
            child: _OverviewTile(
              icon: Icons.downloading_rounded,
              label: '进行中',
              count: activeCount,
              highlighted: activeCount > 0,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _OverviewTile(
              icon: Icons.schedule_rounded,
              label: '等待中',
              count: queueState.queue.length,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _OverviewTile(
              icon: Icons.done_all_rounded,
              label: '已完成',
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
    final l10n = AppLocalizations.of(context)!;
    final hasActiveTasks = queueState.hasActiveTasks();
    final hasHistory = queueState.history.isNotEmpty;

    if (!hasActiveTasks && !hasHistory) {
      return _buildEmptyState(context);
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
            if (queueState.currentTask != null) ...[
              _buildSectionTitle(context, l10n.installingLabel),
              _buildCurrentTask(context, ref, queueState.currentTask!),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (queueState.queue.isNotEmpty) ...[
              _buildSectionTitle(
                context,
                l10n.waitingCount(queueState.queue.length),
              ),
              ...queueState.queue.map(
                (task) => _buildQueueItem(context, ref, task),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (queueState.history.isNotEmpty) ...[
              _buildSectionTitle(context, l10n.completed),
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
              AppLocalizations.of(context)?.noDownloadTasks ?? '暂无下载任务',
              style: context.appTextStyles.body.copyWith(
                color: context.appColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建区域标题
  Widget _buildSectionTitle(BuildContext context, String title) {
    return _SectionHeader(title: title);
  }

  /// 构建当前任务（带进度条）
  Widget _buildCurrentTask(
    BuildContext context,
    WidgetRef ref,
    InstallTask task,
  ) {
    // 优先使用 CLI 返回的精确下载速度，回退到系统级网速
    final cliSpeed = task.cliSpeed;
    final downloadSpeed = cliSpeed ?? ref.watch(networkSpeedProvider).formatted;

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
        ref.read(installQueueProvider.notifier).removeQueuedTask(task.id);
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
              ref.read(installQueueProvider.notifier).retryFailedTask(task.id);
            }
          : null,
      onRemove: () {
        ref.read(installQueueProvider.notifier).removeHistoryTask(task.id);
      },
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    InstallQueueState queueState,
  ) {
    final appColors = context.appColors;
    // 优先使用当前任务的 CLI 速度，回退到系统级网速
    final cliSpeed = queueState.currentTask?.cliSpeed;
    final speed = cliSpeed ?? ref.watch(networkSpeedProvider).formatted;
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
              speed.isEmpty ? '等待下载任务开始' : '实时速度 $speed',
              style: context.appTextStyles.caption.copyWith(
                color: appColors.textSecondary,
              ),
            ),
          ),
          Text(
            '${queueState.history.length} 条记录',
            style: context.appTextStyles.caption.copyWith(
              color: appColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 任务卡片组件
class _TaskCard extends StatefulWidget {
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
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  static const _copyFeedbackDuration = Duration(milliseconds: 1200);

  Timer? _ticker;
  Timer? _copyFeedbackTimer;
  DateTime _now = DateTime.now();
  bool _isOutputCopied = false;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant _TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showProgress != widget.showProgress ||
        oldWidget.task != widget.task) {
      _syncTicker();
    }
    if (oldWidget.task.id != widget.task.id ||
        oldWidget.task.commandOutput != widget.task.commandOutput) {
      _copyFeedbackTimer?.cancel();
      _isOutputCopied = false;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _copyFeedbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleCopyOutputPressed() async {
    final output = widget.task.commandOutput.trim();
    if (output.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: output));
    if (!mounted) {
      return;
    }

    // 复制反馈只影响当前按钮，避免下载中心触发全局底部通知。
    _copyFeedbackTimer?.cancel();
    setState(() => _isOutputCopied = true);
    _copyFeedbackTimer = Timer(_copyFeedbackDuration, () {
      if (!mounted) {
        return;
      }
      setState(() => _isOutputCopied = false);
    });
  }

  void _syncTicker() {
    _ticker?.cancel();
    _now = DateTime.now();

    final shouldTick =
        widget.showProgress &&
        widget.task.status == InstallStatus.installing &&
        widget.task.progressValue >= 0.95;
    if (!shouldTick) {
      return;
    }

    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appColors = context.appColors;

    return Semantics(
      label: l10n.a11yDownloadItem(
        widget.task.appName,
        widget.task.progressPercentLabel,
      ),
      value: widget.task.isProcessing ? widget.task.progressPercentLabel : null,
      child: widget.featured
          ? _buildFeaturedCard(context, l10n, appColors)
          : _buildCompactCard(context, appColors),
    );
  }

  /// 构建当前任务主卡片，突出进度和可取消动作。
  Widget _buildFeaturedCard(
    BuildContext context,
    AppLocalizations l10n,
    AppColorPalette appColors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: appColors.primaryLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: appColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(
                iconUrl: widget.task.icon,
                size: 48,
                borderRadius: 14,
                appName: widget.task.appName,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildTaskText(context, featured: true)),
              const SizedBox(width: AppSpacing.md),
              _buildActionButtons(context),
            ],
          ),
          if (widget.showProgress &&
              (widget.task.isProcessing ||
                  widget.task.status == InstallStatus.downloading)) ...[
            const SizedBox(height: AppSpacing.md),
            _buildProgressBar(context),
          ],
          if (widget.task.shouldShowSlowInstallHint(_now)) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: appColors.warning),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.downloadManagerSlowInstallHint,
                    style: context.appTextStyles.caption.copyWith(
                      color: appColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          _buildErrorText(context),
        ],
      ),
    );
  }

  /// 构建等待队列和历史记录行，保持信息密度但不抢当前任务焦点。
  Widget _buildCompactCard(BuildContext context, AppColorPalette appColors) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: appColors.cardBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: appColors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppIcon(
                iconUrl: widget.task.icon,
                size: 40,
                borderRadius: 12,
                appName: widget.task.appName,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildTaskText(context, featured: false)),
              const SizedBox(width: AppSpacing.sm),
              _buildActionButtons(context),
            ],
          ),
          _buildErrorText(context),
        ],
      ),
    );
  }

  /// 构建任务标题和副标题，避免卡片布局直接读业务字段散落多处。
  Widget _buildTaskText(BuildContext context, {required bool featured}) {
    final appColors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.task.appName,
          style:
              (featured
                      ? context.appTextStyles.body
                      : context.appTextStyles.bodyMedium)
                  .copyWith(
                    color: appColors.textPrimary,
                    fontWeight: context.appFontWeight(FontWeight.w600),
                  ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _buildSubtitle(context),
          style: context.appTextStyles.caption.copyWith(
            color: appColors.textSecondary,
          ),
          maxLines: featured ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 构建失败信息，失败原因必须完整展示，不能为了行高裁剪。
  Widget _buildErrorText(BuildContext context) {
    if (!widget.task.isFailed || widget.task.errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        widget.task.errorMessage!,
        style: context.appTextStyles.caption.copyWith(color: AppColors.error),
        softWrap: true,
      ),
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(BuildContext context) {
    final appColors = context.appColors;
    final message = widget.task.displayMessage?.trim();
    final speed = widget.downloadSpeed?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: message != null && message.isNotEmpty
                    ? message
                    : '处理中',
                constraints: const BoxConstraints(maxWidth: 500),
                child: Text(
                  message != null && message.isNotEmpty ? message : '处理中',
                  style: context.appTextStyles.caption.copyWith(
                    color: appColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Text(
              widget.task.progressPercentLabel,
              style: context.appTextStyles.caption.copyWith(
                color: appColors.textPrimary,
                fontWeight: context.appFontWeight(FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: widget.task.progressValue,
          minHeight: 8,
          borderRadius: BorderRadius.circular(AppRadius.full),
          backgroundColor: appColors.surfaceContainerHighest,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          [
            if (speed != null && speed.isNotEmpty) speed,
            if (widget.task.version != null && widget.task.version!.isNotEmpty)
              widget.task.version!,
            if ((speed == null || speed.isEmpty))
              widget.task.progressPercentLabel,
          ].join(' · '),
          style: context.appTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildStatusPill(BuildContext context) {
    final appColors = context.appColors;
    final (label, color) = switch (widget.task.status) {
      InstallStatus.pending => ('等待中', appColors.textSecondary),
      InstallStatus.downloading => ('下载中', appColors.primary),
      InstallStatus.installing => ('安装中', appColors.primary),
      InstallStatus.success => ('已完成', appColors.success),
      InstallStatus.failed => ('失败', appColors.error),
      InstallStatus.cancelled => ('已取消', appColors.warning),
    };
    final resolvedLabel = widget.featured ? '当前任务' : label;
    final resolvedColor = widget.featured ? appColors.primary : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        resolvedLabel,
        style: context.appTextStyles.tiny.copyWith(
          color: resolvedColor,
          fontWeight: context.appFontWeight(FontWeight.w600),
        ),
      ),
    );
  }

  String _buildSubtitle(BuildContext context) {
    if (widget.task.isFailed &&
        widget.task.errorMessage != null &&
        widget.task.errorMessage!.isNotEmpty) {
      return widget.task.errorMessage!;
    }
    final parts = <String>[
      if (widget.task.version != null && widget.task.version!.isNotEmpty)
        widget.task.version!,
      if (widget.task.displayMessage != null &&
          widget.task.displayMessage!.trim().isNotEmpty)
        widget.task.displayMessage!.trim(),
      if ((widget.task.displayMessage == null ||
          widget.task.displayMessage!.trim().isEmpty))
        switch (widget.task.status) {
          InstallStatus.pending => widget.task.waitingMessage,
          InstallStatus.downloading => '正在下载资源',
          InstallStatus.installing => '正在安装',
          InstallStatus.success => widget.task.successMessage,
          InstallStatus.failed => '安装失败',
          InstallStatus.cancelled => widget.task.cancelledMessage,
        },
    ];
    return parts.join(' · ');
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    final actionWidgets = <Widget>[
      _buildStatusPill(context),
      if (widget.task.commandOutput.trim().isNotEmpty)
        _buildCopyOutputButton(context),
      ..._buildTaskActionWidgets(context),
    ];

    if (actionWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _spacedActionWidgets(actionWidgets),
    );
  }

  /// 为状态标签和行级动作补充固定间距，避免不同任务状态下按钮贴在一起。
  List<Widget> _spacedActionWidgets(List<Widget> actionWidgets) {
    final result = <Widget>[];
    for (var i = 0; i < actionWidgets.length; i++) {
      if (i > 0) {
        result.add(const SizedBox(width: AppSpacing.xs));
      }
      result.add(actionWidgets[i]);
    }
    return result;
  }

  Widget _buildCopyOutputButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appColors = context.appColors;
    final buttonLabel = _isOutputCopied
        ? (l10n?.copySucceeded ?? '复制成功')
        : (l10n?.copyLog ?? '复制日志');

    return Tooltip(
      message: buttonLabel,
      child: TextButton(
        onPressed: _handleCopyOutputPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: Text(
          buttonLabel,
          style: context.appTextStyles.caption.copyWith(
            color: appColors.primary,
            fontWeight: context.appFontWeight(FontWeight.w600),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTaskActionWidgets(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.task.isProcessing ||
        widget.task.status == InstallStatus.downloading ||
        widget.task.status == InstallStatus.pending) {
      // 可取消
      return [
        _buildIconActionButton(
          icon: Icons.close,
          onPressed: widget.onCancel,
          tooltip: l10n?.cancel ?? '取消',
        ),
      ];
    }

    if (widget.task.isFailed && widget.onRetry != null) {
      // 可重试
      return [
        _buildIconActionButton(
          icon: Icons.refresh,
          onPressed: widget.onRetry,
          tooltip: l10n?.retry ?? '重试',
        ),
        if (widget.onRemove != null)
          _buildIconActionButton(
            icon: Icons.close,
            onPressed: widget.onRemove,
            tooltip: l10n?.remove ?? '移除',
          ),
      ];
    }

    if (widget.task.status == InstallStatus.success && widget.onOpen != null) {
      return [
        _buildIconActionButton(
          icon: Icons.open_in_new,
          onPressed: widget.onOpen,
          tooltip: l10n?.open ?? '打开',
        ),
        if (widget.onRemove != null)
          _buildIconActionButton(
            icon: Icons.close,
            onPressed: widget.onRemove,
            tooltip: l10n?.remove ?? '移除',
          ),
      ];
    }

    if (widget.onRemove != null) {
      return [
        _buildIconActionButton(
          icon: Icons.close,
          onPressed: widget.onRemove,
          tooltip: l10n?.remove ?? '移除',
        ),
      ];
    }

    return const [];
  }

  /// 构建紧凑行级图标按钮，确保不同动作在任务行内保持相同视觉重心。
  Widget _buildIconActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      iconSize: 18,
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

/// 显示下载管理弹窗
Future<void> showDownloadManagerDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const DownloadManagerDialog(),
  );
}

/// 分组标题，使用轻量强调线帮助用户快速扫描任务区域。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  /// 分组标题文案，来自当前下载任务区块语义。
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

/// 工作面板概览指标，展示当前任务、等待队列和历史记录数量。
class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.label,
    required this.count,
    this.highlighted = false,
  });

  /// 指标图标，仅用于视觉扫描，语义由外层文本承载。
  final IconData icon;

  /// 指标名称，例如进行中、等待中、已完成。
  final String label;

  /// 指标数量，直接由安装队列状态派生。
  final int count;

  /// 是否强调当前指标；目前仅进行中任务存在时启用。
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

/// 顶栏关闭按钮，复用截图灯箱的小尺寸桌面关闭控件语言。
class _PanelCloseButton extends StatefulWidget {
  const _PanelCloseButton({required this.onTap});

  /// 关闭下载中心弹窗，不影响安装队列任务本身。
  final VoidCallback onTap;

  @override
  State<_PanelCloseButton> createState() => _PanelCloseButtonState();
}

class _PanelCloseButtonState extends State<_PanelCloseButton> {
  /// 桌面端 hover 状态，用于呈现危险关闭色。
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final backgroundColor = _hovered
        ? AppColors.error.withValues(alpha: 0.88)
        : appColors.textPrimary.withValues(alpha: 0.06);
    final iconColor = _hovered
        ? AppColors.textLight
        : appColors.textSecondary.withValues(alpha: 0.86);

    return Tooltip(
      message: l10n?.close ?? '关闭',
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
