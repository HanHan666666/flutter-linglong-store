import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/menu_badge_provider.dart';
import '../../application/providers/sidebar_config_provider.dart';
import '../../core/config/routes.dart';
import '../../core/config/theme.dart';
import '../../core/config/local_sidebar_menu_catalog.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../data/models/api_dto.dart';
import 'download_manager_dialog.dart';
import 'sidebar_interaction_surface.dart';

/// 侧边栏菜单项定义
enum SidebarMenuItem {
  recommend(Icons.favorite_border, Icons.favorite, AppRoutes.recommend),
  allApps(Icons.apps_outlined, Icons.apps, AppRoutes.allApps),
  ranking(Icons.leaderboard_outlined, Icons.leaderboard, AppRoutes.ranking),
  update(Icons.update_outlined, Icons.update, AppRoutes.updateApps);

  const SidebarMenuItem(this.icon, this.selectedIcon, this.route);

  final IconData icon;
  final IconData selectedIcon;
  final String route;

  /// 获取本地化标签
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      SidebarMenuItem.recommend => l10n.recommend,
      SidebarMenuItem.allApps => l10n.sidebarAllApps,
      SidebarMenuItem.ranking => l10n.sidebarRanking,
      SidebarMenuItem.update => l10n.update,
    };
  }
}

/// 侧边栏
///
/// 包含：静态导航菜单 + 服务端动态菜单区域 + 底部固定动作菜单
/// 支持响应式折叠（≤768px）
class Sidebar extends ConsumerWidget {
  const Sidebar({required this.currentPath, this.updateCount = 0, super.key});

  /// 当前路由路径
  final String currentPath;

  /// 更新数量（用于红点显示）
  final int updateCount;

  /// 侧边栏默认宽度 - 176px
  ///
  /// 为英文展开态菜单预留稳定单行空间，避免 `Recommend` 等文案换行。
  static const double defaultWidth = 176.0;

  /// 侧边栏折叠宽度 - 56px (3.5rem)
  static const double collapsedWidth = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCollapsed = screenWidth <= 768;
    final downloadBadgeCount = ref.watch(menuInstallingBadgeCountProvider);

    // 读取服务端下发的动态菜单（失败时默认返回空列表，不影响静态菜单）
    final dynamicMenus = ref
        .watch(sidebarConfigProvider)
        .maybeWhen<List<SidebarMenuDTO>>(
          data: (menus) => menus,
          orElse: () => const <SidebarMenuDTO>[],
        );

    // decoration 需要读取 context 颜色，不能使用 const
    return AnimatedContainer(
      duration: AppAnimation.fast,
      width: isCollapsed ? collapsedWidth : defaultWidth,
      decoration: BoxDecoration(color: context.appColors.background),
      child: Column(
        children: [
          // 菜单区域
          Expanded(
            child: _MenuSection(
              currentPath: currentPath,
              updateCount: updateCount,
              isCollapsed: isCollapsed,
              dynamicMenus: dynamicMenus,
            ),
          ),
          // 底部固定入口保持“展开态横排、折叠态竖排”的既定桌面交互。
          _BottomSection(
            currentPath: currentPath,
            isCollapsed: isCollapsed,
            downloadBadgeCount: downloadBadgeCount,
          ),
        ],
      ),
    );
  }
}

/// 菜单区域
class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.currentPath,
    required this.updateCount,
    required this.isCollapsed,
    required this.dynamicMenus,
  });

  final String currentPath;
  final int updateCount;
  final bool isCollapsed;

  /// 服务端下发的动态菜单列表
  final List<SidebarMenuDTO> dynamicMenus;

  /// 将9秤宽的分隔带（在静态菜单和动态菜单之间）
  Widget _buildDivider(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    child: Divider(height: 1, color: context.appColors.border.withAlpha(80)),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          // 静态菜单项
          ...SidebarMenuItem.values.map((item) {
            return _MenuItemTile(
              item: item,
              isSelected: currentPath == item.route,
              updateCount: item == SidebarMenuItem.update ? updateCount : 0,
              isCollapsed: isCollapsed,
            );
          }),
          // 动态菜单分隔线（有动态菜单时才显示）
          if (dynamicMenus.isNotEmpty) _buildDivider(context),
          // 服务端下发动态菜单项
          ...dynamicMenus.map((menu) {
            final route = '/custom_category/${menu.menuCode}';
            return _DynamicMenuItemTile(
              menu: menu,
              isSelected: currentPath == route,
              isCollapsed: isCollapsed,
            );
          }),
        ],
      ),
    );
  }
}

/// 菜单项组件
///
/// 使用 [SidebarInteractionSurface] 封装 hover/tap 交互，
/// 组件内部只负责内容布局和语义标注。
class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    this.updateCount = 0,
  });

  final SidebarMenuItem item;
  final bool isSelected;
  final bool isCollapsed;
  final int updateCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = item.localizedLabel(l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: label,
          selected: isSelected,
          child: SidebarInteractionSurface(
            isSelected: isSelected,
            onTap: () => context.go(item.route),
            height: 48,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 0 : AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  // 选中指示器（左侧 3px 竖条）
                  if (!isCollapsed) ...[
                    AnimatedContainer(
                      duration: AppAnimation.fast,
                      width: isSelected ? 3 : 0,
                      height: isSelected ? 16 : 0,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(
                      width: isSelected ? AppSpacing.sm : AppSpacing.sm + 3,
                    ),
                  ],
                  // 图标
                  Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    size: 20,
                    color: isSelected
                        ? AppColors.primary
                        : context.appColors.textSecondary,
                  ),
                  // 文字
                  if (!isCollapsed) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item.localizedLabel(l10n),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.menuActive.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : context.appColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                  // 红点徽章
                  if (updateCount > 0) _Badge(count: updateCount),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 红点/徽章组件
///
/// 用于显示更新数量等通知徽章，固定在 20px 圆形容器内。
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;
  static const double _badgeSize = 20;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _badgeSize,
      height: _badgeSize,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
      child: Center(
        // 固定直径并缩放文字，确保 1 位和 2 位数字都保持圆形徽章。
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _BottomSidebarItem {
  myApps(Icons.folder_outlined, Icons.folder, AppRoutes.myApps),
  downloadManager(Icons.download_outlined, Icons.download_outlined, null),
  setting(Icons.settings_outlined, Icons.settings, AppRoutes.setting);

  const _BottomSidebarItem(this.icon, this.selectedIcon, this.route);

  final IconData icon;
  final IconData selectedIcon;
  final String? route;

  /// 获取本地化标签
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      _BottomSidebarItem.myApps => l10n.myApps,
      _BottomSidebarItem.downloadManager => l10n.downloadManager,
      _BottomSidebarItem.setting => l10n.settings,
    };
  }
}

/// 底部固定动作区域
class _BottomSection extends StatelessWidget {
  const _BottomSection({
    required this.currentPath,
    required this.isCollapsed,
    required this.downloadBadgeCount,
  });

  final String currentPath;
  final bool isCollapsed;
  final int downloadBadgeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: isCollapsed
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in _BottomSidebarItem.values)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                    child: _BottomIconButton(
                      item: item,
                      isSelected:
                          item.route != null && currentPath == item.route,
                      badgeCount: item == _BottomSidebarItem.downloadManager
                          ? downloadBadgeCount
                          : 0,
                    ),
                  ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final item in _BottomSidebarItem.values)
                  _BottomIconButton(
                    item: item,
                    isSelected: item.route != null && currentPath == item.route,
                    badgeCount: item == _BottomSidebarItem.downloadManager
                        ? downloadBadgeCount
                        : 0,
                  ),
              ],
            ),
    );
  }
}

/// 服务端下发的动态菜单项
///
/// 点击后导航至对应的自定义专题页 `/custom_category/:code`。
/// 使用 [SidebarInteractionSurface] 封装 hover/tap 交互。
class _DynamicMenuItemTile extends StatelessWidget {
  const _DynamicMenuItemTile({
    required this.menu,
    required this.isSelected,
    required this.isCollapsed,
  });

  final SidebarMenuDTO menu;
  final bool isSelected;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final route = '/custom_category/${menu.menuCode}';
    final locale = Localizations.localeOf(context);
    final presentation = buildSidebarMenuPresentation(
      menuCode: menu.menuCode,
      locale: locale,
      fallbackName: menu.menuName,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      child: Tooltip(
        message: presentation.label,
        child: SidebarInteractionSurface(
          isSelected: isSelected,
          onTap: () => context.go(route),
          // 菜单行高 40px ：适配 16px 菜单文字的桌面可读性密度
          height: 40,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                // 选中指示器（左侧 3px 竖条）
                if (!isCollapsed) ...[
                  AnimatedContainer(
                    duration: AppAnimation.fast,
                    width: isSelected ? 3 : 0,
                    height: isSelected ? 16 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(
                    width: isSelected ? AppSpacing.sm : AppSpacing.sm + 3,
                  ),
                ],
                Icon(
                  isSelected ? presentation.selectedIcon : presentation.icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : context.appColors.textSecondary,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      presentation.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.menuActive.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : context.appColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部动作图标按钮
///
/// 使用 [SidebarInteractionSurface] 封装 hover/tap 交互。
/// 固定 48x48 尺寸（AppSpacing.x2l），图标颜色在 hover 时变化。
class _BottomIconButton extends StatelessWidget {
  const _BottomIconButton({
    required this.item,
    required this.isSelected,
    this.badgeCount = 0,
  });

  final _BottomSidebarItem item;
  final bool isSelected;
  final int badgeCount;

  void _handleTap(BuildContext context) {
    if (item == _BottomSidebarItem.downloadManager) {
      showDownloadManagerDialog(context);
      return;
    }

    final route = item.route;
    if (route != null) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: item.localizedLabel(l10n),
      child: SidebarInteractionSurface(
        isSelected: isSelected,
        onTap: () => _handleTap(context),
        width: AppSpacing.x2l,
        height: AppSpacing.x2l,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Center(
                child: _BottomIconContent(item: item, isSelected: isSelected),
              ),
            ),
            if (badgeCount > 0)
              Positioned(top: -4, right: -4, child: _Badge(count: badgeCount)),
          ],
        ),
      ),
    );
  }
}

/// 底部图标内容组件
///
/// 封装图标颜色的 hover 状态变化逻辑。
/// 与菜单项不同，底部图标在 hover 时图标颜色也会变为 primary。
class _BottomIconContent extends StatefulWidget {
  const _BottomIconContent({required this.item, required this.isSelected});

  final _BottomSidebarItem item;
  final bool isSelected;

  @override
  State<_BottomIconContent> createState() => _BottomIconContentState();
}

class _BottomIconContentState extends State<_BottomIconContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 监听父级 SidebarInteractionSurface 的 hover 状态变化
    // 通过 MouseRegion 捕获 hover 状态，实现图标颜色变化
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      hitTestBehavior: HitTestBehavior.translucent,
      child: Icon(
        widget.isSelected ? widget.item.selectedIcon : widget.item.icon,
        size: 20,
        color: widget.isSelected
            ? AppColors.primary
            : (_isHovered
                  ? AppColors.primary
                  : context.appColors.textSecondary),
      ),
    );
  }
}
