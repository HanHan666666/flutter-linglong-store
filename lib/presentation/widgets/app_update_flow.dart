/// 应用自更新任务的观察型弹窗。
///
/// 任务生命周期由应用级 [AppSelfUpdateController] 独占；本组件只展示状态并发送
/// 取消、重试和关闭事件。安装完成后明确要求用户手动关闭并重新打开应用。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_self_update_provider.dart';
import '../../application/services/app_self_update_service.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../domain/models/app_self_update.dart';

/// 展示当前应用级自更新任务。
class AppUpdateFlowDialog extends ConsumerWidget {
  /// 创建不拥有任务生命周期的进度弹窗。
  const AppUpdateFlowDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(appSelfUpdateControllerProvider);
    final controller = ref.read(appSelfUpdateControllerProvider.notifier);
    final phase = state.phase;
    final error = state.error;

    return PopScope(
      // 下载与系统安装期间禁止 Escape/窗口外点击让用户误以为任务已经停止。
      canPop: state.isTerminal,
      child: AlertDialog(
        title: Text(l10n.checkUpdate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              phase == null ? l10n.checkingUpdate : _localizePhase(l10n, phase),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: phase == null ? null : state.progress.clamp(0.0, 1.0),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                _localizeError(l10n, error),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: _buildActions(context, l10n, state, controller),
      ),
    );
  }
}

/// 按稳定阶段映射当前语言文案。
String _localizePhase(AppLocalizations l10n, AppSelfUpdatePhase phase) {
  return switch (phase) {
    AppSelfUpdatePhase.detectingInstallation =>
      l10n.updateDetectingInstallation,
    AppSelfUpdatePhase.resolvingAsset => l10n.updateResolvingAsset,
    AppSelfUpdatePhase.downloading => l10n.updateDownloading,
    AppSelfUpdatePhase.verifying => l10n.updateVerifying,
    AppSelfUpdatePhase.installing => l10n.updateInstalling,
    AppSelfUpdatePhase.done => l10n.updateSucceeded,
    AppSelfUpdatePhase.failed => l10n.updateFailed,
    AppSelfUpdatePhase.cancelled => l10n.updateCancelled,
  };
}

/// 把领域错误映射为稳定本地化文案，原始异常只保留在日志中。
String _localizeError(AppLocalizations l10n, Object error) {
  if (error is AppSelfUpdateUnsupportedException) {
    return switch (error.reason) {
      AppSelfUpdateUnsupportedReason.manualInstall =>
        l10n.updateManualInstallHint,
      AppSelfUpdateUnsupportedReason.unsupportedArch =>
        l10n.updateUnsupportedArch,
      AppSelfUpdateUnsupportedReason.missingChecksumFile =>
        l10n.updateChecksumMissing,
      AppSelfUpdateUnsupportedReason.checksumMismatch =>
        l10n.updateChecksumFailed,
    };
  }
  return l10n.updateFailed;
}

/// 根据状态暴露最小事件集合；系统安装阶段不允许取消。
List<Widget>? _buildActions(
  BuildContext context,
  AppLocalizations l10n,
  AppSelfUpdateState state,
  AppSelfUpdateController controller,
) {
  if (state.canCancel) {
    return [TextButton(onPressed: controller.cancel, child: Text(l10n.cancel))];
  }
  if (!state.isTerminal) {
    return null;
  }

  final closeButton = TextButton(
    onPressed: () {
      controller.reset();
      Navigator.of(context).pop();
    },
    child: Text(l10n.close),
  );
  if (state.phase == AppSelfUpdatePhase.done) {
    return [closeButton];
  }
  return [
    FilledButton(onPressed: controller.retry, child: Text(l10n.updateRetry)),
    closeButton,
  ];
}
