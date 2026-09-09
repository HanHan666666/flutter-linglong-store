/// 设置页「安装时免密码确认」开关（docs/50 §5）。
///
/// 单独抽成组件的原因与 [RendererPreferenceTile] 一致：设置页只负责布局，
/// 风险确认、loading 与结果反馈聚焦在这里，便于做轻量 Widget 测试。
/// Presentation 不执行文件、进程或偏好写入，也不保存第二份业务开关状态：
/// 它只把用户点击的目标值交给控制器，并观察控制器状态。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/polkit_rule_provider.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/utils/app_notification_helpers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/copyable_command_block.dart';

/// 免密安装开关列表项。
class PasswordFreeInstallTile extends ConsumerWidget {
  const PasswordFreeInstallTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(polkitRuleProvider);
    final isApplying = state.phase == PasswordFreeInstallPhase.applying;

    return SwitchListTile(
      // 装饰性图标必须排除语义；处理中改为本地化 loading 语义。
      secondary: isApplying
          ? Semantics(
              label: l10n.loading,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : const ExcludeSemantics(child: Icon(Icons.lock_open_outlined)),
      title: Text(l10n.passwordFreeInstallTitle),
      subtitle: _PasswordFreeInstallSubtitle(state: state),
      isThreeLine: state.needsSync,
      // 非 ready 状态禁用开关，防止重复确认框与重复提权（§5.2）。
      value: state.enabled,
      onChanged: state.isInteractive
          ? (value) => _handleToggle(context, ref, value)
          : null,
    );
  }

  /// 处理开关点击。
  ///
  /// 开启方向先取单飞锁并展示风险确认；关闭方向无需再次确认，直接进入系统
  /// 授权与同步流程。确认框被取消时必须释放单飞锁，让开关回到可交互状态。
  Future<void> _handleToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // 提前取到 notifier：页面离开后仍要让控制器正确收尾。
    final controller = ref.read(polkitRuleProvider.notifier);

    if (value) {
      if (!controller.beginEnableRequest()) {
        return;
      }
      final confirmed = await ConfirmDialog.show(
        context,
        title: l10n.passwordFreeInstallConfirmTitle,
        content: Text(l10n.passwordFreeInstallRiskDescription),
        confirmText: l10n.passwordFreeInstallConfirmAction,
        cancelText: l10n.passwordFreeInstallCancelAction,
        confirmStyle: ConfirmButtonStyle.warning,
      );
      if (confirmed != true) {
        controller.cancelEnableRequest();
        return;
      }
    }

    final feedback = await controller.applyTarget(enabled: value);
    if (!context.mounted) {
      return;
    }
    await _showFeedback(context, ref, feedback);
  }

  /// 把控制器反馈映射为本地化提示。
  ///
  /// 成功与可自解释的失败使用轻量提示；带诊断摘要的失败额外提供可复制、
  /// 可聚焦的详情，完整日志已写入既有 XDG 日志。
  Future<void> _showFeedback(
    BuildContext context,
    WidgetRef ref,
    PasswordFreeInstallFeedback feedback,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    switch (feedback) {
      case PasswordFreeInstallFeedback.none:
        return;
      case PasswordFreeInstallFeedback.enabled:
        showAppSuccess(context, l10n.passwordFreeInstallEnabled);
      case PasswordFreeInstallFeedback.disabled:
        showAppSuccess(context, l10n.passwordFreeInstallDisabled);
      case PasswordFreeInstallFeedback.authorizationCancelled:
        showAppError(context, l10n.passwordFreeInstallAuthCancelled);
      case PasswordFreeInstallFeedback.authorizationUnavailable:
        showAppError(context, l10n.passwordFreeInstallFailed);
        await _showDiagnostic(context, ref, l10n.passwordFreeInstallFailed);
      case PasswordFreeInstallFeedback.ruleConflict:
        showAppError(context, l10n.passwordFreeInstallRuleConflict);
      case PasswordFreeInstallFeedback.unsupported:
        showAppError(context, l10n.passwordFreeInstallUnsupported);
      case PasswordFreeInstallFeedback.cacheSaveFailed:
        showAppError(context, l10n.passwordFreeInstallCacheSaveFailed);
      case PasswordFreeInstallFeedback.failed:
        showAppError(context, l10n.passwordFreeInstallFailed);
        await _showDiagnostic(context, ref, l10n.passwordFreeInstallFailed);
    }
  }

  /// 展示可复制的失败诊断摘要。
  Future<void> _showDiagnostic(
    BuildContext context,
    WidgetRef ref,
    String summary,
  ) async {
    final diagnostic = ref.read(polkitRuleProvider).lastDiagnostic?.trim();
    if (diagnostic == null || diagnostic.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.passwordFreeInstallTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: diagnostic,
                  child: Text(summary),
                ),
                const SizedBox(height: 16),
                CopyableCommandBlock(
                  command: diagnostic,
                  semanticLabel: summary,
                ),
              ],
            ),
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: l10n.confirm,
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.confirm),
            ),
          ),
        ],
      ),
    );
  }
}

/// 开关副标题：固定说明 + 待同步提示。
class _PasswordFreeInstallSubtitle extends StatelessWidget {
  const _PasswordFreeInstallSubtitle({required this.state});

  final PasswordFreeInstallState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.passwordFreeInstallSubtitle),
        if (state.needsSync)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.passwordFreeInstallNeedsSync,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
