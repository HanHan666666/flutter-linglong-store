import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_operation_queue_provider.dart';
import '../../application/providers/install_queue_provider.dart';
import '../../core/utils/app_notification_helpers.dart';
import '../../domain/models/install_task.dart';
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
          .read(appOperationQueueControllerProvider)
          .enqueueAppOperation(
            EnqueueAppOperationParams(
              kind: InstallTaskKind.install,
              appId: appId,
              appName: appName,
              icon: icon,
              version: _normalizeVersion(version),
            ),
          );
      return;
    case InstallButtonState.update:
      ref
          .read(appOperationQueueControllerProvider)
          .enqueueAppOperation(
            EnqueueAppOperationParams(
              kind: InstallTaskKind.update,
              appId: appId,
              appName: appName,
              icon: icon,
              version: _normalizeVersion(version),
            ),
          );
      return;
    case InstallButtonState.installed:
    case InstallButtonState.open:
      try {
        await ref.read(linglongCliRepositoryProvider).runApp(appId);
        if (!context.mounted) {
          return;
        }
        showAppLaunching(context, appName);
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        showAppLaunchFailed(context, error.toString());
      }
      return;
    case InstallButtonState.installing:
    case InstallButtonState.pending:
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
