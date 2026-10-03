/// 详情页次级操作入口的自适应排列。
///
/// 复用既有回调和图标按钮，在头部宽度受限时通过换行保持操作可达。
library;

import 'package:flutter/material.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import 'expandable_icon_button.dart';

/// 详情页主操作右侧的次级操作区。
///
/// 只在当前应用存在本地安装实例时展示，避免未安装态暴露无效入口。
/// 默认以圆形图标按钮排列，悬浮时单个按钮沿阅读方向展开显示文字，
/// 在保持操作可达性的同时降低头部视觉噪音。
class AppDetailSecondaryActions extends StatelessWidget {
  /// 创建详情页次级操作区。
  const AppDetailSecondaryActions({
    required this.isVisible,
    required this.onCreateShortcut,
    required this.onUninstall,
    required this.onShare,
    this.alignment = WrapAlignment.start,
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

  /// 跟随主操作对齐，行尾布局在 RTL 下由 Wrap 自动镜像。
  final WrapAlignment alignment;

  /// 为相邻收起态图标预留空间，避免悬浮按钮因换行离开鼠标并反复展开收起。
  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // 不为悬浮文案预留固定大面板。单个按钮展开时仍保留相邻两个图标的宽度，
    // 尤其在 RTL 下防止第二、第三个按钮被自身长标签推到下一行而丢失悬浮。
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxButtonWidth =
            (constraints.maxWidth -
                    2 * ExpandableIconButton.collapsedWidth -
                    2 * 8)
                .clamp(ExpandableIconButton.collapsedWidth, double.infinity);
        final buttonConstraints = BoxConstraints(maxWidth: maxButtonWidth);
        return Wrap(
          alignment: alignment,
          spacing: 8,
          runSpacing: 8,
          children: [
            ConstrainedBox(
              constraints: buttonConstraints,
              child: ExpandableIconButton(
                key: const Key('app_detail_create_shortcut'),
                icon: Icons.shortcut_outlined,
                label: l10n.createDesktopShortcut,
                onTap: onCreateShortcut,
              ),
            ),
            ConstrainedBox(
              constraints: buttonConstraints,
              child: ExpandableIconButton(
                key: const Key('app_detail_uninstall'),
                icon: Icons.delete_outline_rounded,
                label: l10n.uninstall,
                onTap: onUninstall,
                iconColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.error,
              ),
            ),
            ConstrainedBox(
              constraints: buttonConstraints,
              child: ExpandableIconButton(
                key: const Key('app_detail_share'),
                icon: Icons.share_outlined,
                label: l10n.shareLink,
                onTap: onShare,
              ),
            ),
          ],
        );
      },
    );
  }
}
