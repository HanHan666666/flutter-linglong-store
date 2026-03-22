import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/sidebar_config_provider.dart';
import '../../core/config/routes.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import 'download_manager_dialog.dart';

/// 侧边栏菜单项定义
enum SidebarMenuItem {
  recommend(Icons.favorite_border, Icons.favorite, AppRoutes.recommend),
  allApps(Icons.apps_outlined, Icons.apps, AppRoutes.allApps),
  ranking(Icons.leaderboard_outlined, Icons.leaderboard, AppRoutes.ranking);

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
    };
  }
}

/// 侧边栏
///
/// 包含：静态导航菜单 + 服务端动态菜单区域 + 底部固定动作菜单
/// 支持响应式折叠（≤768px）
class Sidebar extends ConsumerWidget {
  const Sidebar({required this.currentPath, super.key});

  /// 当前路由路径
  final String currentPath;

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

    // 读取服务端下发的动态菜单（失败时默认返回空列表，不影响静态菜单）
    final dynamicMenus = ref
        .watch(sidebarConfigProvider)
        .maybeWhen(data: (menus) => menus, orElse: () => []);

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
              isCollapsed: isCollapsed,
              dynamicMenus: dynamicMenus,
            ),
          ),
          // 底部固定入口使用和主菜单一致的纵向结构，避免额外的横向布局层级。
          _BottomSection(currentPath: currentPath, isCollapsed: isCollapsed),
        ],
      ),
    );
  }
}

/// 菜单区域
class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.currentPath,
    required this.isCollapsed,
    required this.dynamicMenus,
  });

  final String currentPath;
  final bool isCollapsed;

  /// 服务端下发的动态菜单列表
  final List dynamicMenus;

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
class _MenuItemTile extends StatefulWidget {
  const _MenuItemTile({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
  });

  final SidebarMenuItem item;
  final bool isSelected;
  final bool isCollapsed;

  @override
  State<_MenuItemTile> createState() => _MenuItemTileState();
}

class _MenuItemTileState extends State<_MenuItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => context.go(widget.item.route),
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            height: 36,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 0 : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              // 默认态使用目标色的透明版本，避免 Colors.transparent（透明黑）
              // 在动画插值时产生深色闪烁
              color: widget.isSelected
                  ? context.appColors.primaryLight
                  : (_isHovered
                        ? context.appColors.surfaceContainerLow
                        : context.appColors.surfaceContainerLow.withAlpha(0)),
              borderRadius: AppRadius.xsRadius,
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                // 选中指示器
                if (!widget.isCollapsed) ...[
                  AnimatedContainer(
                    duration: AppAnimation.fast,
                    width: widget.isSelected ? 3 : 0,
                    height: widget.isSelected ? 16 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(
                    width: widget.isSelected
                        ? AppSpacing.sm
                        : AppSpacing.sm + 3,
                  ),
                ],
                // 图标
                Icon(
                  widget.isSelected
                      ? widget.item.selectedIcon
                      : widget.item.icon,
                  size: 20,
                  color: widget.isSelected
                      ? AppColors.primary
                      : context.appColors.textSecondary,
                ),
                // 文字
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.item.localizedLabel(l10n),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.menuActive.copyWith(
                        color: widget.isSelected
                            ? AppColors.primary
                            : context.appColors.textPrimary,
                        fontWeight: widget.isSelected
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
  const _BottomSection({required this.currentPath, required this.isCollapsed});

  final String currentPath;
  final bool isCollapsed;

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
                  ),
              ],
            ),
    );
  }
}

/// 服务端下发的动态菜单项
///
/// 点击后导航至对应的自定义专题页 `/custom_category/:code`。
class _DynamicMenuItemTile extends StatefulWidget {
  const _DynamicMenuItemTile({
    required this.menu,
    required this.isSelected,
    required this.isCollapsed,
  });

  final dynamic menu;
  final bool isSelected;
  final bool isCollapsed;

  @override
  State<_DynamicMenuItemTile> createState() => _DynamicMenuItemTileState();
}

class _DynamicMenuItemTileState extends State<_DynamicMenuItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final route = '/custom_category/${widget.menu.menuCode}';
    final label = widget.menu.menuName as String;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => context.go(route),
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            height: 36,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 0 : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? context.appColors.primaryLight
                  : (_isHovered
                        ? context.appColors.surfaceContainerLow
                        // 默认态使用目标色的透明版本，避免 Colors.transparent（透明黑）
                        // 在动画插值时产生深色闪烁
                        : context.appColors.surfaceContainerLow.withAlpha(0)),
              borderRadius: AppRadius.xsRadius,
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (!widget.isCollapsed) ...[
                  AnimatedContainer(
                    duration: AppAnimation.fast,
                    width: widget.isSelected ? 3 : 0,
                    height: widget.isSelected ? 16 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(
                    width: widget.isSelected
                        ? AppSpacing.sm
                        : AppSpacing.sm + 3,
                  ),
                ],
                // 图标：优先使用 menuIcon 资源名，不可用时显示默认图标
                Icon(
                  Icons.category_outlined,
                  size: 20,
                  color: widget.isSelected
                      ? AppColors.primary
                      : context.appColors.textSecondary,
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.menuActive.copyWith(
                        color: widget.isSelected
                            ? AppColors.primary
                            : context.appColors.textPrimary,
                        fontWeight: widget.isSelected
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
class _BottomIconButton extends StatefulWidget {
  const _BottomIconButton({required this.item, required this.isSelected});

  final _BottomSidebarItem item;
  final bool isSelected;

  @override
  State<_BottomIconButton> createState() => _BottomIconButtonState();
}

class _BottomIconButtonState extends State<_BottomIconButton> {
  bool _isHovered = false;

  void _handleTap(BuildContext context) {
    if (widget.item == _BottomSidebarItem.downloadManager) {
      showDownloadManagerDialog(context);
      return;
    }

    final route = widget.item.route;
    if (route != null) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: widget.item.localizedLabel(l10n),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => _handleTap(context),
          child: Container(
            width: AppSpacing.x2l,
            height: AppSpacing.x2l,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? context.appColors.primaryLight
                  : (_isHovered
                        ? context.appColors.surfaceContainerLow
                        : context.appColors.surfaceContainerLow.withAlpha(0)),
              borderRadius: AppRadius.xsRadius,
            ),
            child: Icon(
              widget.isSelected ? widget.item.selectedIcon : widget.item.icon,
              size: 20,
              color: widget.isSelected
                  ? AppColors.primary
                  : (_isHovered
                        ? AppColors.primary
                        : context.appColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
