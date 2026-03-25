import 'package:flutter/material.dart';

import '../../core/i18n/l10n/app_localizations.dart';

/// 当有正在进行的安装/更新任务时，点击卸载按钮所展示的拦截弹窗结果枚举
enum UninstallBlockedAction {
  /// 用户点击「我知道了」，关闭弹窗，不做额外操作
  acknowledge,

  /// 用户点击「查看下载管理」，关闭弹窗后跳转到下载管理
  openDownloadManager,
}

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
  final displayName =
      activeTaskName.isNotEmpty ? activeTaskName : fallbackAppId;

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
          onPressed: () => Navigator.of(context)
              .pop(UninstallBlockedAction.openDownloadManager),
          child: Text(l10n.viewDownloadManager),
        ),
      ],
    );
  }
}
