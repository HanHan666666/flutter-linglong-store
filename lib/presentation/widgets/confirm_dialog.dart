import 'package:flutter/material.dart';
import '../../core/i18n/l10n/app_localizations.dart';

/// 确认对话框组件
///
/// 显示标题、内容和确认/取消按钮的对话框
class ConfirmDialog extends StatelessWidget {
  /// 对话框标题
  final String? title;

  /// 对话框内容
  final Widget? content;

  /// 对话框文本内容
  final String? message;

  /// 确认按钮文本
  final String? confirmText;

  /// 取消按钮文本
  final String? cancelText;

  /// 确认按钮样式
  final ConfirmButtonStyle confirmStyle;

  /// 确认按钮回调
  final VoidCallback? onConfirm;

  /// 取消按钮回调
  final VoidCallback? onCancel;

  /// 是否显示取消按钮
  final bool showCancelButton;

  /// 点击外部是否可关闭
  final bool barrierDismissible;

  const ConfirmDialog({
    super.key,
    this.title,
    this.content,
    this.message,
    this.confirmText,
    this.cancelText,
    this.confirmStyle = ConfirmButtonStyle.primary,
    this.onConfirm,
    this.onCancel,
    this.showCancelButton = true,
    this.barrierDismissible = true,
  });

  /// 创建删除确认对话框
  const ConfirmDialog.delete({
    super.key,
    this.title,
    this.content,
    this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.showCancelButton = true,
    this.barrierDismissible = true,
  }) : confirmStyle = ConfirmButtonStyle.danger;

  /// 创建卸载确认对话框
  const ConfirmDialog.uninstall({
    super.key,
    this.title,
    this.content,
    this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.showCancelButton = true,
    this.barrierDismissible = true,
  }) : confirmStyle = ConfirmButtonStyle.warning;

  /// 显示确认对话框
  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
    Widget? content,
    String? confirmText,
    String? cancelText,
    ConfirmButtonStyle confirmStyle = ConfirmButtonStyle.primary,
    bool showCancelButton = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmStyle: confirmStyle,
        showCancelButton: showCancelButton,
      ),
    );
  }

  /// 显示删除确认对话框
  static Future<bool?> showDelete(
    BuildContext context, {
    String? title,
    String? message,
    String? itemName,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConfirmDialog.delete(
        title: title ?? (l10n?.confirmDelete ?? '确认删除'),
        message: message ?? (l10n?.confirmDeleteMessage ?? '确定要删除此项吗？此操作无法撤销。'),
        confirmText: l10n?.uninstall ?? '删除',
        cancelText: l10n?.cancel ?? '取消',
      ),
    );
  }

  /// 显示卸载确认对话框
  static Future<bool?> showUninstall(BuildContext context, {String? appName}) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConfirmDialog.uninstall(
        title: l10n?.confirmUninstall ?? '确认卸载',
        message: l10n?.confirmUninstallMessage ?? '确定要卸载此应用吗？',
        confirmText: l10n?.uninstall ?? '卸载',
        cancelText: l10n?.cancel ?? '取消',
      ),
    );
  }

  /// 显示「应用正在运行中」强制关闭并卸载的确认对话框
  static Future<bool?> showUninstallRunning(
    BuildContext context, {
    String? appName,
  }) {
    final l10n = AppLocalizations.of(context);
    final name = appName ?? '该应用';
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConfirmDialog.delete(
        title: l10n?.appRunningTitle ?? '应用正在运行',
        message: l10n?.appRunningUninstallMessage(name) ??
            '$name 当前正在运行中，卸载前需要强制关闭所有运行实例。\n是否强制关闭并卸载？',
        confirmText: l10n?.forceCloseAndUninstall ?? '强制关闭并卸载',
        cancelText: l10n?.cancel ?? '取消',
      ),
    );
  }

  /// 显示降级安装确认对话框
  ///
  /// 当用户尝试安装一个低于当前已安装版本的版本时调用。
  static Future<bool?> showDowngradeConfirm(
    BuildContext context, {
    required String appName,
    required String currentVersion,
    required String targetVersion,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConfirmDialog(
        title: l10n?.confirmDowngrade ?? '确认降级',
        message: l10n?.downgradeMessageWithVersion(
              appName,
              currentVersion,
              targetVersion,
            ) ??
            '当前已安装 $appName v$currentVersion，'
                '您尝试安装较低的版本 v$targetVersion。\n'
                '降级安装可能导致功能异常，是否继续？',
        confirmText: l10n?.confirmDowngrade ?? '确认降级',
        cancelText: l10n?.cancel ?? '取消',
        confirmStyle: ConfirmButtonStyle.warning,
      ),
    );
  }

  /// 显示强制重装确认对话框
  ///
  /// 当用户尝试安装一个已安装版本时调用。
  static Future<bool?> showReinstallConfirm(
    BuildContext context, {
    required String appName,
    required String version,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConfirmDialog(
        title: l10n?.alreadyInstalledVersion ?? '已安装此版本',
        message: l10n?.reinstallMessage(appName, version) ??
            '$appName v$version 已安装。\n是否重新安装（将覆盖现有安装）？',
        confirmText: l10n?.forceReinstall ?? '强制重装',
        cancelText: l10n?.cancel ?? '取消',
        confirmStyle: ConfirmButtonStyle.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final defaultTitle = title ?? l10n.confirm;
    final defaultConfirmText = confirmText ?? l10n.confirm;
    final defaultCancelText = cancelText ?? l10n.cancel;

    return AlertDialog(
      title: Text(defaultTitle),
      content: content ?? (message != null ? Text(message!) : null),
      actions: [
        if (showCancelButton)
          Semantics(
            button: true,
            label: l10n.cancel,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                onCancel?.call();
              },
              child: Text(defaultCancelText),
            ),
          ),
        Semantics(
          button: true,
          label: l10n.confirm,
          child: _buildConfirmButton(context, defaultConfirmText),
        ),
      ],
    );
  }

  /// 构建确认按钮
  Widget _buildConfirmButton(BuildContext context, String text) {
    switch (confirmStyle) {
      case ConfirmButtonStyle.primary:
        return ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          child: Text(text),
        );

      case ConfirmButtonStyle.danger:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          child: Text(text),
        );

      case ConfirmButtonStyle.warning:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          child: Text(text),
        );
    }
  }
}

/// 确认按钮样式枚举
enum ConfirmButtonStyle {
  /// 主要样式
  primary,

  /// 危险样式（红色）
  danger,

  /// 警告样式（橙色）
  warning,
}
