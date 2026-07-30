/// 下载管理任务卡片。
///
/// 该文件保留单张任务卡自己的慢安装计时器和复制反馈状态。卡片只接收已经
/// 格式化的展示数据和业务回调，不订阅全局 Provider。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/install_progress.dart';
import '../../../domain/models/install_task.dart';
import '../app_icon.dart';
import '../error_solution_help_button.dart';
import 'download_task_view_data.dart';

/// 展示当前、等待或历史安装任务，并管理卡片局部即时反馈。
class DownloadTaskCard extends StatefulWidget {
  /// 创建下载任务卡片。
  const DownloadTaskCard({
    super.key,
    required this.data,
    this.showProgress = false,
    this.featured = false,
    this.downloadSpeed,
    this.onCancel,
    this.onOpen,
    this.onRetry,
    this.onRemove,
  });

  /// 当前 locale 下的任务展示数据。
  final DownloadTaskViewData data;

  /// 是否展示任务进度区域。
  final bool showProgress;

  /// 是否使用当前任务主卡片样式。
  final bool featured;

  /// 当前任务的 CLI 或系统回退下载速度。
  final String? downloadSpeed;

  /// 取消当前任务或移除等待项的回调。
  final VoidCallback? onCancel;

  /// 启动成功安装应用的回调。
  final VoidCallback? onOpen;

  /// 重试失败任务的回调。
  final VoidCallback? onRetry;

  /// 删除历史任务的回调。
  final VoidCallback? onRemove;

  /// 原始安装任务，供卡片布局读取不可变事实。
  InstallTask get task => data.task;

  /// 已按当前 locale 格式化的状态文案。
  String get statusMessage => data.statusMessage;

  /// 已按当前 locale 格式化的失败摘要。
  String? get errorMessage => data.errorMessage;

  @override
  State<DownloadTaskCard> createState() => _DownloadTaskCardState();
}

class _DownloadTaskCardState extends State<DownloadTaskCard> {
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
  void didUpdateWidget(covariant DownloadTaskCard oldWidget) {
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

  /// 复制当前任务完整命令输出，并短暂更新本卡片按钮反馈。
  Future<void> _handleCopyOutputPressed() async {
    final output = widget.task.commandOutput.trim();
    if (output.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: output));
    if (!mounted) {
      return;
    }

    _copyFeedbackTimer?.cancel();
    setState(() => _isOutputCopied = true);
    _copyFeedbackTimer = Timer(_copyFeedbackDuration, () {
      if (!mounted) {
        return;
      }
      setState(() => _isOutputCopied = false);
    });
  }

  /// 只在当前任务进入慢安装提示窗口时启动低频时间刷新。
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
                _buildSlowInstallHintIcon(appColors),
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
    final subtitle = _buildSubtitle(includeProgressMessage: !featured);
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
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: context.appTextStyles.caption.copyWith(
              color: appColors.textSecondary,
            ),
            maxLines: featured ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// 构建完整失败摘要和错误解决方案入口。
  Widget _buildErrorText(BuildContext context) {
    final errorMessage = widget.errorMessage;
    if (!widget.task.isFailed || errorMessage == null || errorMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    final diagnosticMessage = widget.task.diagnosticMessage;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              errorMessage,
              style: context.appTextStyles.caption.copyWith(
                color: AppColors.error,
              ),
              softWrap: true,
            ),
          ),
          if (diagnosticMessage != null && diagnosticMessage.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.xs),
            ErrorSolutionHelpButton(message: diagnosticMessage),
          ],
        ],
      ),
    );
  }

  /// 构建与中文 caption 首行视觉对齐的慢安装提示图标。
  Widget _buildSlowInstallHintIcon(AppColorPalette appColors) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Icon(Icons.info_outline, size: 14, color: appColors.warning),
    );
  }

  /// 构建当前任务阶段、百分比、进度条、速度和版本信息。
  Widget _buildProgressBar(BuildContext context) {
    final appColors = context.appColors;
    final message = widget.statusMessage.trim();
    final speed = widget.downloadSpeed?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: message.isNotEmpty ? message : '处理中',
                constraints: const BoxConstraints(maxWidth: 500),
                child: Text(
                  message.isNotEmpty ? message : '处理中',
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
            if (speed == null || speed.isEmpty)
              widget.task.progressPercentLabel,
          ].join(' · '),
          style: context.appTextStyles.caption,
        ),
      ],
    );
  }

  /// 构建任务当前状态的紧凑标签。
  Widget _buildStatusPill(BuildContext context) {
    final appColors = context.appColors;
    final (label, color) = switch (widget.task.status) {
      InstallStatus.pending => ('等待中', appColors.textSecondary),
      InstallStatus.downloading => ('下载中', appColors.primary),
      InstallStatus.installing => ('安装中', appColors.primary),
      InstallStatus.success => ('已完成', appColors.success),
      InstallStatus.failed => ('失败', appColors.error),
      InstallStatus.cancelled => ('已取消', appColors.warning),
      InstallStatus.interrupted => ('已中断', appColors.warning),
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

  /// 构建任务副标题；当前任务阶段只由进度区承载，避免重复展示。
  String _buildSubtitle({bool includeProgressMessage = true}) {
    final errorMessage = widget.errorMessage;
    if (widget.task.isFailed &&
        errorMessage != null &&
        errorMessage.isNotEmpty) {
      return errorMessage;
    }
    final displayMessage = widget.statusMessage.trim();
    final parts = <String>[
      if (widget.task.version != null && widget.task.version!.isNotEmpty)
        widget.task.version!,
      if (includeProgressMessage && displayMessage.isNotEmpty) displayMessage,
      if (includeProgressMessage && displayMessage.isEmpty)
        widget.statusMessage,
    ];
    return parts.join(' · ');
  }

  /// 组合状态标签、复制入口和当前任务可用操作。
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

  /// 为状态标签和行级动作补充固定间距。
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

  /// 构建只复制 `InstallTask.commandOutput` 的日志按钮。
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

  /// 根据任务状态生成取消、重试、打开或移除操作。
  List<Widget> _buildTaskActionWidgets(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.task.isProcessing ||
        widget.task.status == InstallStatus.downloading ||
        widget.task.status == InstallStatus.pending) {
      return [
        _buildIconActionButton(
          icon: Icons.close,
          onPressed: widget.onCancel,
          tooltip: l10n?.cancel ?? '取消',
        ),
      ];
    }

    if (widget.task.isFailed && widget.onRetry != null) {
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

  /// 构建紧凑行级图标按钮，保持不同动作的视觉重心一致。
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
