import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/install_queue_provider.dart';
import '../../application/providers/update_apps_provider.dart';
import 'install_button.dart';

/// 统一处理列表卡片主按钮动作，保证各列表页行为一致。
Future<void> handleAppCardPrimaryAction({
  required BuildContext context,
  required WidgetRef ref,
  required InstallButtonState buttonState,
  required String appId,
  required String appName,
  String? icon,
  String? version,
}) async {
  switch (buttonState) {
    case InstallButtonState.notInstalled:
      ref
          .read(installQueueProvider.notifier)
          .enqueueInstall(
            appId: appId,
            appName: appName,
            icon: icon,
            version: _normalizeVersion(version),
          );
      return;
    case InstallButtonState.update:
      ref
          .read(updateAppsProvider.notifier)
          .updateApp(
            appId,
            fallbackName: appName,
            fallbackIcon: icon,
            fallbackVersion: _normalizeVersion(version),
          );
      return;
    case InstallButtonState.installed:
    case InstallButtonState.open:
      try {
        await ref.read(linglongCliRepositoryProvider).runApp(appId);
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('正在启动 $appName...')));
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('启动失败: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    case InstallButtonState.installing:
    case InstallButtonState.uninstall:
      return;
  }
}

String? _normalizeVersion(String? version) {
  if (version == null || version.isEmpty) {
    return null;
  }
  return version;
}
