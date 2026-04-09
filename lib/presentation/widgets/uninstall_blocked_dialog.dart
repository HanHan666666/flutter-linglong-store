import 'package:flutter/material.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../domain/models/uninstall_blocked_action.dart';

export '../../domain/models/uninstall_blocked_action.dart' show UninstallBlockedAction;

/// 展示安装中卸载拦截弹窗
///
/// 当 [activeTaskName] 为空时，使用 [fallbackAppId] 作为显示名称。
///
/// 返回用户的决策：[UninstallBlockedAction]
Future<UninstallBlockedAction> showUninstallBlockedDialog(
  BuildContext context, {
  required String activeTaskName,
  String fallbackAppId = '',
}) {
  final displayName = activeTaskName.isNotEmpty
      ? activeTaskName
      : fallbackAppId;

  return showDialog<UninstallBlockedAction>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) =>
        _UninstallBlockedDialog(activeTaskName: displayName),
  ).then((result) => result ?? UninstallBlockedAction.acknowledge);
}

/// 安装中卸载拦截弹窗组件（内部使用）
class _UninstallBlockedDialog extends StatelessWidget {
  const _UninstallBlockedDialog({required this.activeTaskName});

  final String activeTaskName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.uninstallBlockedTitle),
      content: Text(l10n.uninstallBlockedMessage(activeTaskName)),
      actions: [
        // 次要按钮：我知道了（关闭弹窗）
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(UninstallBlockedAction.acknowledge),
          child: Text(l10n.iKnow),
        ),
        // 主要按钮：查看下载管理
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(UninstallBlockedAction.openDownloadManager),
          child: Text(l10n.viewDownloadManager),
        ),
      ],
    );
  }
}
