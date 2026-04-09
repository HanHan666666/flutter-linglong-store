import 'package:flutter/material.dart';

import '../i18n/l10n/app_localizations.dart';

/// 显示成功/普通通知
void showAppNotification(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// 显示错误通知
void showAppError(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// 显示警告通知
void showAppWarning(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.orange,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// 显示成功通知（绿色背景）
void showAppSuccess(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF52C41A),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// 显示链接无法打开的错误通知
void showLinkOpenError(BuildContext context, String url) {
  final l10n = AppLocalizations.of(context);
  if (!context.mounted) return;
  showAppError(
    context,
    l10n?.cannotOpenLink(url) ?? '无法打开链接: $url',
  );
}

/// 显示应用启动通知
void showAppLaunching(BuildContext context, String appName) {
  final l10n = AppLocalizations.of(context);
  if (!context.mounted) return;
  showAppNotification(
    context,
    l10n?.launching(appName) ?? '正在启动 $appName...',
  );
}

/// 显示应用启动失败通知
void showAppLaunchFailed(BuildContext context, String error) {
  final l10n = AppLocalizations.of(context);
  if (!context.mounted) return;
  showAppError(
    context,
    l10n?.launchFailed(error) ?? '启动失败: $error',
  );
}
