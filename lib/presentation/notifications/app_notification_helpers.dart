import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/notifications/app_notification.dart';
import '../../application/providers/app_notification_provider.dart';
import '../../application/services/app_uninstall_service.dart';
import '../../core/i18n/l10n/app_localizations.dart';

String showInfoNotification(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  String? actionId,
  AppNotificationActionHandler? onAction,
}) {
  return ProviderScope.containerOf(context, listen: false)
      .read(appNotificationProvider.notifier)
      .showInfo(
        message: message,
        duration: duration,
        actionLabel: actionLabel,
        actionId: actionId,
        onAction: onAction,
      );
}

String showSuccessNotification(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  String? actionId,
  AppNotificationActionHandler? onAction,
}) {
  return ProviderScope.containerOf(context, listen: false)
      .read(appNotificationProvider.notifier)
      .showSuccess(
        message: message,
        duration: duration,
        actionLabel: actionLabel,
        actionId: actionId,
        onAction: onAction,
      );
}

String showWarningNotification(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  String? actionId,
  AppNotificationActionHandler? onAction,
}) {
  return ProviderScope.containerOf(context, listen: false)
      .read(appNotificationProvider.notifier)
      .showWarning(
        message: message,
        duration: duration,
        actionLabel: actionLabel,
        actionId: actionId,
        onAction: onAction,
      );
}

String showErrorNotification(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 5),
  String? actionLabel,
  String? actionId,
  AppNotificationActionHandler? onAction,
}) {
  return ProviderScope.containerOf(context, listen: false)
      .read(appNotificationProvider.notifier)
      .showError(
        message: message,
        duration: duration,
        actionLabel: actionLabel,
        actionId: actionId,
        onAction: onAction,
      );
}

void showAppUninstallResultNotification(
  BuildContext context, {
  required String appName,
  required AppUninstallResult result,
}) {
  final l10n = AppLocalizations.of(context);

  switch (result.type) {
    case AppUninstallResultType.success:
      showSuccessNotification(
        context,
        message: l10n?.uninstallSuccess(appName) ?? '$appName 已卸载',
      );
      return;
    case AppUninstallResultType.cancelled:
      return;
    case AppUninstallResultType.stopFailed:
      showErrorNotification(
        context,
        message: result.detail == null
            ? (l10n?.stopFailedWithError(l10n.errorUnknown) ?? '终止失败')
            : (l10n?.stopFailedWithError(result.detail!) ??
                  '终止失败: ${result.detail}'),
      );
      return;
    case AppUninstallResultType.failed:
      showErrorNotification(
        context,
        message: result.detail == null
            ? (l10n?.errorUninstallFailed ?? '卸载失败')
            : (l10n?.uninstallFailedWithError(result.detail!) ??
                  '卸载失败: ${result.detail}'),
      );
      return;
  }
}
