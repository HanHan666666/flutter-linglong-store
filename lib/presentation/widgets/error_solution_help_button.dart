import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/accessibility/a11y_semantics.dart';
import '../../core/config/app_config.dart';
import '../../core/config/theme.dart';
import '../../core/di/providers.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/utils/app_notification_helpers.dart';
import '../../domain/models/error_solution.dart';
import '../helpers/guided_repair_flow.dart';
import 'error_solution_dialog.dart';

/// 安装失败信息旁的错误解决方案入口。
///
/// 查询状态仅属于当前按钮，使用局部状态避免下载队列或整个对话框重建。每次点击
/// 都重新访问后端；未命中和查询失败使用锚定小浮窗反馈，不误导为已有解决方案。
class ErrorSolutionHelpButton extends ConsumerStatefulWidget {
  /// 创建帮助入口。
  const ErrorSolutionHelpButton({
    super.key,
    required this.message,
    this.onRepairRequested,
  });

  /// 用于后端匹配的 ll-cli 原始 message。
  final String message;

  /// 已验签脚本进入审计流程的统一回调。
  final Future<void> Function(BuildContext context, ErrorSolution solution)?
  onRepairRequested;

  @override
  ConsumerState<ErrorSolutionHelpButton> createState() =>
      _ErrorSolutionHelpButtonState();
}

/// 帮助入口的局部交互状态。
class _ErrorSolutionHelpButtonState
    extends ConsumerState<ErrorSolutionHelpButton> {
  /// 浮窗与按钮之间的布局锚点。
  final LayerLink _layerLink = LayerLink();

  /// 锚定浮窗显示控制器。
  final OverlayPortalController _popoverController = OverlayPortalController();

  /// 查询进行中标记，用于防止重复请求。
  bool _isLoading = false;

  /// 当前浮窗反馈类型。
  _HelpPopoverKind _popoverKind = _HelpPopoverKind.noSolution;

  /// 查询并按结果打开解决方案或锚定反馈。
  Future<void> _handleTap() async {
    if (_isLoading) {
      return;
    }
    _hidePopover();
    setState(() => _isLoading = true);

    try {
      final solution = await ref
          .read(errorSolutionLookupServiceProvider)
          .find(
            message: widget.message,
            language: Localizations.localeOf(context).languageCode,
          );
      if (!mounted) {
        return;
      }

      if (solution == null) {
        _showPopover(_HelpPopoverKind.noSolution);
        return;
      }

      await showErrorSolutionDialog(
        context,
        solution: solution,
        onRepairRequested: solution.hasRepairScript
            ? () {
                final customHandler = widget.onRepairRequested;
                return customHandler != null
                    ? customHandler(context, solution)
                    : showGuidedRepairFlow(context, ref, solution);
              }
            : null,
      );
    } catch (_) {
      if (mounted) {
        _showPopover(_HelpPopoverKind.queryFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 显示指定类型的锚定反馈浮窗。
  void _showPopover(_HelpPopoverKind kind) {
    setState(() => _popoverKind = kind);
    _popoverController.show();
  }

  /// 隐藏锚定反馈浮窗。
  void _hidePopover() {
    if (_popoverController.isShowing) {
      _popoverController.hide();
    }
  }

  /// 打开统一社区发帖入口。
  Future<void> _openCommunity() async {
    _hidePopover();
    final uri = Uri.parse(AppConfig.communityForumUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      showLinkOpenError(context, AppConfig.communityForumUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _popoverController,
        overlayChildBuilder: (overlayContext) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hidePopover,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.bottomRight,
              offset: const Offset(0, -AppSpacing.xs),
              showWhenUnlinked: false,
              child: _HelpPopover(
                kind: _popoverKind,
                onClose: _hidePopover,
                onRetry: _handleTap,
                onCommunityPost: _openCommunity,
              ),
            ),
          ],
        ),
        child: A11yIconButton(
          key: const Key('errorSolutionHelpButton'),
          semanticsLabel: l10n?.a11yErrorSolutionHelp ?? '查询该安装错误的解决方案',
          tooltip: l10n?.errorSolutionHelpTooltip ?? '查看解决方案',
          enabled: !_isLoading,
          iconSize: 18,
          onTap: _handleTap,
          icon: _isLoading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
        ),
      ),
    );
  }
}

/// 锚定反馈的业务类型。
enum _HelpPopoverKind {
  /// 后端没有匹配规则。
  noSolution,

  /// 网络或后端配置导致查询失败。
  queryFailed,
}

/// 未命中或查询失败时的小型交互浮窗。
class _HelpPopover extends StatelessWidget {
  /// 创建反馈浮窗。
  const _HelpPopover({
    required this.kind,
    required this.onClose,
    required this.onRetry,
    required this.onCommunityPost,
  });

  /// 当前反馈类型。
  final _HelpPopoverKind kind;

  /// 关闭浮窗回调。
  final VoidCallback onClose;

  /// 重新查询回调。
  final VoidCallback onRetry;

  /// 打开社区入口回调。
  final VoidCallback onCommunityPost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appColors = context.appColors;
    final isNoSolution = kind == _HelpPopoverKind.noSolution;

    return Material(
      key: const Key('errorSolutionHelpPopover'),
      color: Colors.transparent,
      child: Semantics(
        liveRegion: true,
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: appColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: appColors.borderSecondary),
            boxShadow: AppShadows.modal,
          ),
          child: FocusScope(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        isNoSolution
                            ? Icons.info_outline
                            : Icons.refresh_rounded,
                        size: 18,
                        color: isNoSolution
                            ? appColors.textSecondary
                            : appColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        isNoSolution
                            ? l10n?.errorSolutionNoSolution ?? '暂无解决方案'
                            : l10n?.errorSolutionQueryFailed ?? '查询失败，请重试',
                        style: context.appTextStyles.bodyMedium.copyWith(
                          color: appColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: l10n?.close ?? '关闭',
                        onPressed: onClose,
                        icon: const ExcludeSemantics(
                          child: Icon(Icons.close, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (!isNoSolution)
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: const ExcludeSemantics(
                          child: Icon(Icons.refresh, size: 16),
                        ),
                        label: Text(l10n?.errorSolutionRetry ?? '重新查询'),
                      ),
                    TextButton.icon(
                      key: const Key('errorSolutionCommunityPostButton'),
                      onPressed: onCommunityPost,
                      icon: const ExcludeSemantics(
                        child: Icon(Icons.forum_outlined, size: 16),
                      ),
                      label: Text(l10n?.errorSolutionCommunityPost ?? '社区发帖'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
