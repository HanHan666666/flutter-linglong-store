import 'package:flutter/material.dart';

import '../../core/i18n/l10n/app_localizations.dart';

/// 详情页主操作右侧的次级操作区。
///
/// 只在当前应用存在本地安装实例时展示，避免未安装态暴露无效入口。
class AppDetailSecondaryActions extends StatelessWidget {
  const AppDetailSecondaryActions({
    required this.isVisible,
    required this.onCreateShortcut,
    required this.onUninstall,
    super.key,
  });

  final bool isVisible;
  final VoidCallback onCreateShortcut;
  final VoidCallback onUninstall;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final errorColor = theme.colorScheme.error;

    // 按钮高度与 InstallButton.large (40px) 保持一致
    const buttonHeight = 40.0;
    const iconSize = 18.0;

    // 次级动作保持紧凑横向排布，由外层决定何时整体换行。
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: buttonHeight,
          child: OutlinedButton.icon(
            onPressed: onCreateShortcut,
            icon: const Icon(Icons.shortcut_outlined, size: iconSize),
            label: Text(l10n?.createDesktopShortcut ?? '创建桌面快捷方式'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: buttonHeight,
          child: OutlinedButton.icon(
            onPressed: onUninstall,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: iconSize,
              color: errorColor,
            ),
            label: Text(
              l10n?.uninstall ?? '卸载',
              style: TextStyle(color: errorColor),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: errorColor,
              side: BorderSide(color: errorColor),
            ),
          ),
        ),
      ],
    );
  }
}
