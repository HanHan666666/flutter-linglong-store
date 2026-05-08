import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/theme.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/platform/linux_renderer_service.dart';
import '../../../../core/utils/app_notification_helpers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/copyable_command_block.dart';

/// 设置页中的 Linux 渲染偏好开关。
///
/// 单独抽成组件后，设置页可以继续负责布局，
/// 而渲染模式的提示文案、风险确认与保存反馈则聚焦在这里，
/// 便于做轻量 Widget 测试，避免整页初始化链路拖慢验证。
typedef PersistRendererPreference =
    Future<void> Function(LinuxRendererPreference preference);

class RendererPreferenceTile extends StatelessWidget {
  const RendererPreferenceTile({
    super.key,
    required this.rendererRuntime,
    required this.rendererPreference,
    required this.rendererService,
    required this.onPreferenceSelected,
  });

  final AsyncValue<LinuxRendererRuntimeState> rendererRuntime;
  final LinuxRendererPreference rendererPreference;
  final LinuxRendererService rendererService;
  final PersistRendererPreference onPreferenceSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final runtimeState = rendererRuntime.asData?.value;
    final nextLaunchUsesSoftware = runtimeState == null
        ? rendererPreference == LinuxRendererPreference.software
        : rendererService.resolveNextLaunchUsesSoftwareRendering(
            runtimeState: runtimeState,
            preference: rendererPreference,
          );

    final onChanged = runtimeState == null || runtimeState.isEnvironmentLocked
        ? null
        : (bool value) => _handleRendererPreferenceToggle(
            context,
            runtimeState: runtimeState,
            enableSoftwareRendering: value,
          );

    return SwitchListTile(
      title: Text(l10n.softwareRendering),
      subtitle: _RendererPreferenceSubtitle(
        rendererRuntime: rendererRuntime,
        rendererPreference: rendererPreference,
        nextLaunchUsesSoftware: nextLaunchUsesSoftware,
      ),
      value: nextLaunchUsesSoftware,
      isThreeLine: true,
      onChanged: onChanged,
    );
  }

  Future<void> _handleRendererPreferenceToggle(
    BuildContext context, {
    required LinuxRendererRuntimeState runtimeState,
    required bool enableSoftwareRendering,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (runtimeState.isEnvironmentLocked) {
      return;
    }

    if (!enableSoftwareRendering && !runtimeState.isCpuWhitelisted) {
      final confirmed = await _showDisableSoftwareRenderingWarning(
        context,
        runtimeState: runtimeState,
      );
      if (confirmed != true) {
        return;
      }
    }

    final nextPreference = enableSoftwareRendering
        ? LinuxRendererPreference.software
        : LinuxRendererPreference.hardware;

    try {
      await onPreferenceSelected(nextPreference);
      if (!context.mounted) {
        return;
      }

      showAppSuccess(
        context,
        enableSoftwareRendering
            ? l10n.rendererModeSavedSoftware
            : l10n.rendererModeSavedHardware,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      showAppError(context, l10n.rendererModeSaveFailed);
    }
  }

  Future<bool?> _showDisableSoftwareRenderingWarning(
    BuildContext context, {
    required LinuxRendererRuntimeState runtimeState,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final recoveryInfo = rendererService.buildRecoveryInfo();
    final cpuLabel = [
      runtimeState.cpuVendor,
      runtimeState.cpuModel,
    ].where((part) => part.trim().isNotEmpty).join(' · ');

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => ConfirmDialog(
        title: l10n.rendererModeDisableWarningTitle,
        confirmText: l10n.rendererModeDisableConfirm,
        cancelText: l10n.cancel,
        confirmStyle: ConfirmButtonStyle.warning,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.rendererModeDisableWarningMessage),
                if (cpuLabel.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.rendererModeDetectedCpu(cpuLabel),
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(dialogContext).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.rendererModeDisableBlackScreenHint,
                          style: Theme.of(dialogContext).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                if (recoveryInfo.dataDirectoryPath != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.rendererModeDataDirectoryLabel,
                    style: Theme.of(dialogContext).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    recoveryInfo.dataDirectoryPath!,
                    style: Theme.of(
                      dialogContext,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
                if (recoveryInfo.deleteDataDirectoryCommand != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.rendererModeDeleteCommandLabel,
                    style: Theme.of(dialogContext).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  CopyableCommandBlock(
                    command: recoveryInfo.deleteDataDirectoryCommand!,
                    semanticLabel: l10n.rendererModeDeleteCommandLabel,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.rendererModeSaveCommandHint,
                    style: Theme.of(dialogContext).textTheme.bodySmall
                        ?.copyWith(
                          color: Theme.of(
                            dialogContext,
                          ).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RendererPreferenceSubtitle extends StatelessWidget {
  const _RendererPreferenceSubtitle({
    required this.rendererRuntime,
    required this.rendererPreference,
    required this.nextLaunchUsesSoftware,
  });

  final AsyncValue<LinuxRendererRuntimeState> rendererRuntime;
  final LinuxRendererPreference rendererPreference;
  final bool nextLaunchUsesSoftware;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final helperStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.4,
    );

    return rendererRuntime.when(
      loading: () => Text(l10n.rendererModeDetecting, style: helperStyle),
      error: (_, __) => Text(l10n.rendererModeDetectFailed, style: helperStyle),
      data: (runtimeState) {
        final currentModeLabel = runtimeState.isSoftware
            ? l10n.softwareRenderingEnabled
            : l10n.hardwareRenderingEnabled;
        final nextLaunchModeLabel = nextLaunchUsesSoftware
            ? l10n.softwareRenderingEnabled
            : l10n.hardwareRenderingEnabled;

        final currentReason = switch (runtimeState.decisionSource) {
          LinuxRendererDecisionSource.environment =>
            l10n.rendererModeReasonEnvironment(
              runtimeState.environmentValue ?? 'FLUTTER_LINUX_RENDERER',
            ),
          LinuxRendererDecisionSource.userPreference =>
            l10n.rendererModeReasonUserPreference,
          LinuxRendererDecisionSource.cpuFallback =>
            l10n.rendererModeReasonCpuFallback,
          LinuxRendererDecisionSource.defaultMode =>
            l10n.rendererModeReasonDefault,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.rendererModeCurrentStatus(currentModeLabel, currentReason),
              style: helperStyle,
            ),
            const SizedBox(height: 4),
            if (runtimeState.isEnvironmentLocked)
              Text(
                l10n.rendererModeEnvLocked(
                  runtimeState.environmentValue ?? 'FLUTTER_LINUX_RENDERER',
                ),
                style: helperStyle,
              )
            else
              Text(
                l10n.rendererModeNextLaunchStatus(nextLaunchModeLabel),
                style: helperStyle,
              ),
            if (!runtimeState.isCpuWhitelisted &&
                !runtimeState.isEnvironmentLocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  rendererPreference == LinuxRendererPreference.hardware
                      ? l10n.rendererModeHardwareRiskHint
                      : l10n.rendererModeWhitelistHint,
                  style: helperStyle,
                ),
              ),
          ],
        );
      },
    );
  }
}
