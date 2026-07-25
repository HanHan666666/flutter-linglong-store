import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../application/services/guided_repair_service.dart';
import '../../core/accessibility/a11y_focus_traversal.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/platform/local_path_opener.dart';
import '../../core/platform/shell_command_executor.dart';

/// 一键修复执行与实时 STDIO 对话框。
///
/// 输出按固定间隔批量刷新，并只在界面保留最近行，避免高频脚本输出造成逐行重建和
/// 无限内存增长；完整 stdout/stderr 始终由执行器持续写入 XDG 日志。
class GuidedRepairExecutionDialog extends ConsumerStatefulWidget {
  /// 创建执行对话框。
  const GuidedRepairExecutionDialog({
    super.key,
    required this.service,
    required this.script,
    required this.signature,
  });

  /// 统一修复执行服务。
  final GuidedRepairService service;

  /// 用户已经审计的精确脚本文本。
  final String script;

  /// 与脚本对应的 Base64 Ed25519 签名。
  final String signature;

  @override
  ConsumerState<GuidedRepairExecutionDialog> createState() =>
      _GuidedRepairExecutionDialogState();
}

/// 执行对话框状态。
class _GuidedRepairExecutionDialogState
    extends ConsumerState<GuidedRepairExecutionDialog> {
  /// UI 最多保留的实时输出行数。
  static const int _maxVisibleLines = 2000;

  /// UI 输出刷新间隔。
  static const Duration _flushInterval = Duration(milliseconds: 80);

  /// 已渲染输出。
  final List<ShellOutputLine> _visibleLines = <ShellOutputLine>[];

  /// 等待批量刷新的输出。
  final List<ShellOutputLine> _pendingLines = <ShellOutputLine>[];

  /// 输出列表滚动控制器。
  final ScrollController _scrollController = ScrollController();

  /// 输出批量刷新定时器。
  Timer? _flushTimer;

  /// 已从界面移除但仍保存在日志中的行数。
  int _droppedLineCount = 0;

  /// 最终执行结果。
  GuidedRepairResult? _result;

  /// 无法启动或安全复验失败的异常。
  Object? _error;

  /// 脚本是否仍在执行。
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushOutput());
    unawaited(_execute());
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// 调用执行服务并保存最终状态。
  Future<void> _execute() async {
    try {
      final result = await widget.service.execute(
        script: widget.script,
        signature: widget.signature,
        onOutput: _enqueueOutput,
      );
      if (!mounted) {
        return;
      }
      _flushOutput();
      setState(() {
        _result = result;
        _isRunning = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _flushOutput();
      setState(() {
        _error = error;
        _isRunning = false;
      });
    }
  }

  /// 将实时输出放入待刷新队列。
  void _enqueueOutput(ShellOutputLine output) {
    if (mounted) {
      _pendingLines.add(output);
    }
  }

  /// 批量合并输出并滚动到最新位置。
  void _flushOutput() {
    if (!mounted || _pendingLines.isEmpty) {
      return;
    }
    setState(() {
      _visibleLines.addAll(_pendingLines);
      _pendingLines.clear();
      final overflow = _visibleLines.length - _maxVisibleLines;
      if (overflow > 0) {
        _visibleLines.removeRange(0, overflow);
        _droppedLineCount += overflow;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  /// 打开当前日志所在目录。
  Future<void> _openLogDirectory() async {
    final logFilePath = _result?.logFilePath;
    if (logFilePath == null) {
      return;
    }
    await ref
        .read(localPathOpenerProvider)
        .openDirectory(path.dirname(logFilePath));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appColors = context.appColors;
    return PopScope(
      canPop: !_isRunning,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2l,
          vertical: AppSpacing.xl,
        ),
        child: A11yFocusScope(
          debugLabel: 'GuidedRepairExecutionDialog',
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 600,
              maxWidth: 820,
              minHeight: 460,
              maxHeight: 680,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.repairExecutionTitle ?? '一键修复',
                    style: context.appTextStyles.title3.copyWith(
                      color: appColors.textPrimary,
                      fontWeight: context.appFontWeight(FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatus(context),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n?.repairOutputTitle ?? '实时输出',
                    style: context.appTextStyles.bodyMedium.copyWith(
                      color: appColors.textPrimary,
                      fontWeight: context.appFontWeight(FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(child: _buildOutput(context)),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_result != null)
                        TextButton.icon(
                          onPressed: _openLogDirectory,
                          icon: const ExcludeSemantics(
                            child: Icon(Icons.folder_open_outlined, size: 18),
                          ),
                          label: Text(l10n?.openRepairLog ?? '打开日志目录'),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: _isRunning
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l10n?.close ?? '关闭'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建执行状态提示。
  Widget _buildStatus(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appColors = context.appColors;
    String message;
    Color color;
    IconData icon;

    if (_isRunning) {
      message = l10n?.repairExecuting ?? '正在执行修复脚本…';
      color = appColors.primary;
      icon = Icons.sync_rounded;
    } else if (_error != null) {
      message = _error is InvalidTrustedContentSignatureException
          ? l10n?.repairInvalidSignature ?? '修复脚本签名无效，已阻止执行。'
          : l10n?.repairExecutionError(_error.toString()) ?? '修复脚本无法执行：$_error';
      color = AppColors.error;
      icon = Icons.error_outline;
    } else {
      final result = _result!;
      switch (result.status) {
        case GuidedRepairStatus.success:
          message = l10n?.repairCompleteRetry ?? '修复完成，请重新尝试安装。';
          color = appColors.success;
          icon = Icons.check_circle_outline;
        case GuidedRepairStatus.failed:
          message =
              l10n?.repairFailedWithExitCode(result.exitCode ?? -1) ??
              '修复脚本执行失败（退出码 ${result.exitCode ?? -1}）。';
          color = AppColors.error;
          icon = Icons.error_outline;
        case GuidedRepairStatus.timedOut:
          message = l10n?.repairTimedOut ?? '修复脚本执行超过 30 分钟，已停止等待。请查看日志确认系统状态。';
          color = appColors.warning;
          icon = Icons.timer_off_outlined;
      }
    }

    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          if (_isRunning)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            ExcludeSemantics(child: Icon(icon, size: 20, color: color)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.appTextStyles.bodyMedium.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建高性能实时输出列表。
  Widget _buildOutput(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appColors = context.appColors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: appColors.borderSecondary),
      ),
      child: _visibleLines.isEmpty
          ? Center(
              child: Text(
                l10n?.repairOutputEmpty ?? '等待脚本输出…',
                style: context.appTextStyles.caption.copyWith(
                  color: appColors.textSecondary,
                ),
              ),
            )
          : ListView.builder(
              key: const Key('guidedRepairOutputList'),
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _visibleLines.length + (_droppedLineCount > 0 ? 1 : 0),
              itemBuilder: (context, index) {
                if (_droppedLineCount > 0 && index == 0) {
                  return Text(
                    l10n?.repairOutputTruncated(_droppedLineCount) ??
                        '界面已省略较早的 $_droppedLineCount 行，完整内容请查看日志。',
                    style: context.appTextStyles.caption.copyWith(
                      color: appColors.warning,
                      fontFamily: 'monospace',
                    ),
                  );
                }
                final lineIndex = index - (_droppedLineCount > 0 ? 1 : 0);
                final output = _visibleLines[lineIndex];
                return SelectableText(
                  output.line,
                  style: context.appTextStyles.caption.copyWith(
                    color: output.channel == ShellOutputChannel.stderr
                        ? AppColors.error
                        : appColors.textPrimary,
                    fontFamily: 'monospace',
                    height: 1.35,
                  ),
                );
              },
            ),
    );
  }
}

/// 打开执行与实时输出对话框。
Future<void> showGuidedRepairExecutionDialog(
  BuildContext context, {
  required GuidedRepairService service,
  required String script,
  required String signature,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => GuidedRepairExecutionDialog(
      service: service,
      script: script,
      signature: signature,
    ),
  );
}
