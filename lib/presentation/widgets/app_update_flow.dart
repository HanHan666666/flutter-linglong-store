import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_self_update_provider.dart';
import '../../application/services/app_self_update_service.dart';
import '../../application/services/version_check_service.dart';
import '../../core/i18n/l10n/app_localizations.dart';

/// 应用自更新流程弹窗。
///
/// 打开后自动执行「检测安装方式 → 下载 → 校验 → 安装 → 重启」，
/// 通过 [AppSelfUpdateService] 的进度回调驱动进度条与阶段文案。
/// 失败时展示错误并允许「重试 / 关闭」；安装成功后应用会自动重启关闭。
class AppUpdateFlowDialog extends ConsumerStatefulWidget {
  const AppUpdateFlowDialog({super.key, required this.update});

  final VersionCheckResultUpdateAvailable update;

  @override
  ConsumerState<AppUpdateFlowDialog> createState() =>
      _AppUpdateFlowDialogState();
}

class _AppUpdateFlowDialogState extends ConsumerState<AppUpdateFlowDialog> {
  AppSelfUpdatePhase? _phase;
  double _progress = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final service = ref.read(appSelfUpdateServiceProvider);
    setState(() {
      _error = null;
      _phase = null;
      _progress = 0;
    });
    try {
      await service.performUpdate(
        update: widget.update,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _phase = progress.phase;
            _progress = progress.progress;
            if (progress.phase == AppSelfUpdatePhase.failed) {
              _error = progress.error;
            }
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final phaseText = _phase == null
        ? l10n.checkingUpdate
        : _localizePhase(l10n, _phase!);

    return AlertDialog(
      title: Text(l10n.checkUpdate),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(phaseText, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          // done 阶段用确定值 1.0，避免不确定动画导致测试 pumpAndSettle 卡死。
          LinearProgressIndicator(
            value: switch (_phase) {
              null => null,
              AppSelfUpdatePhase.done => 1.0,
              _ => _progress.clamp(0, 1),
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _localizeError(l10n, _error!),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: _error != null
          ? [
              TextButton(
                onPressed: _start,
                child: Text(l10n.updateRetry),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
            ]
          : null,
    );
  }

  String _localizePhase(AppLocalizations l10n, AppSelfUpdatePhase phase) {
    return switch (phase) {
      AppSelfUpdatePhase.detectingInstallation => l10n.updateDetectingInstallation,
      AppSelfUpdatePhase.resolvingAsset => l10n.updateResolvingAsset,
      AppSelfUpdatePhase.downloading => l10n.updateDownloading,
      AppSelfUpdatePhase.verifying => l10n.updateVerifying,
      AppSelfUpdatePhase.installing => l10n.updateInstalling,
      AppSelfUpdatePhase.restarting => l10n.updateRestarting,
      AppSelfUpdatePhase.done => l10n.updateSucceeded,
      AppSelfUpdatePhase.failed => l10n.updateFailed,
    };
  }

  String _localizeError(AppLocalizations l10n, Object error) {
    if (error is AppSelfUpdateUnsupportedException) {
      return switch (error.reason) {
        AppSelfUpdateUnsupportedReason.manualInstall => l10n.updateManualInstallHint,
        AppSelfUpdateUnsupportedReason.unsupportedArch => l10n.updateUnsupportedArch,
        AppSelfUpdateUnsupportedReason.missingChecksumFile => l10n.updateChecksumMissing,
        AppSelfUpdateUnsupportedReason.checksumMismatch => l10n.updateChecksumFailed,
      };
    }
    return l10n.updateFailed;
  }
}
