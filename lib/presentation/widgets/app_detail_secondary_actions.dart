import 'package:flutter/material.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import 'expandable_icon_button.dart';

/// 详情页主操作右侧的次级操作区。
///
/// 只在当前应用存在本地安装实例时展示，避免未安装态暴露无效入口。
/// 默认以圆形图标按钮排列，悬浮时单个按钮向右展开显示文字，
/// 在保持操作可达性的同时降低头部视觉噪音。
class AppDetailSecondaryActions extends StatelessWidget {
  /// 创建详情页次级操作区。
  const AppDetailSecondaryActions({
    required this.isVisible,
    required this.onCreateShortcut,
    required this.onUninstall,
    required this.onShare,
    super.key,
  });

  /// 是否展示次级操作区。
  final bool isVisible;

  /// 创建桌面快捷方式回调。
  final VoidCallback onCreateShortcut;

  /// 卸载回调。
  final VoidCallback onUninstall;

  /// 分享回调。
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // 次级动作保持紧凑横向排布，由外层决定何时整体换行。
    // 默认只显示图标，悬浮时单个按钮向右展开显示文字。
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpandableIconButton(
          icon: Icons.shortcut_outlined,
          label: l10n.createDesktopShortcut,
          onTap: onCreateShortcut,
        ),
        const SizedBox(width: 8),
        ExpandableIconButton(
          icon: Icons.delete_outline_rounded,
          label: l10n.uninstall,
          onTap: onUninstall,
          iconColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.error,
        ),
        const SizedBox(width: 8),
        ExpandableIconButton(
          icon: Icons.share_outlined,
          label: l10n.shareLink,
          onTap: onShare,
        ),
      ],
    );
  }
}
