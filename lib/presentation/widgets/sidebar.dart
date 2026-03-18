import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/sidebar_config_provider.dart';
import '../../core/config/routes.dart';
import '../../core/config/theme.dart';
import 'download_manager_dialog.dart';

/// 侧边栏菜单项定义
enum SidebarMenuItem {
  recommend('推荐', Icons.favorite_border, Icons.favorite, AppRoutes.recommend),
  allApps('全 部', Icons.apps_outlined, Icons.apps, AppRoutes.allApps),
  ranking(
    '排 行',
    Icons.leaderboard_outlined,
    Icons.leaderboard,
    AppRoutes.ranking,
  ),
  myApps('我 的', Icons.folder_outlined, Icons.folder, AppRoutes.myApps),
  update('更 新', Icons.refresh, Icons.refresh, AppRoutes.updateApps),
  setting('设 置', Icons.settings_outlined, Icons.settings, AppRoutes.setting);

  const SidebarMenuItem(this.label, this.icon, this.selectedIcon, this.route);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}

/// 侧边栏
///
/// 包含：静态导航菜单 + 服务端动态菜单区域 + 底部图标
/// 支持响应式折叠（≤768px）
class Sidebar extends ConsumerWidget {
  const Sidebar({required this.currentPath, this.updateCount = 0, super.key});

  /// 当前路由路径
  final String currentPath;

  /// 更新数量（用于红点显示）
  final int updateCount;

  /// 侧边栏默认宽度 - 160px (10rem)
  static const double defaultWidth = 160.0;

  /// 侧边栏折叠宽度 - 56px (3.5rem)
  static const double collapsedWidth = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCollapsed = screenWidth <= 768;

    // 读取服务端下发的动态菜单（失败时默认返回空列表，不影响静态菜单）
    final dynamicMenus = ref.watch(sidebarConfigProvider).maybeWhen(
      data: (menus) => menus,
      orElse: () => [],
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
          // 底部图标区域
          _BottomSection(isCollapsed: isCollapsed),
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
  final List dynamicMenus;

  /// 将9秤宽的分隔带（在静态菜单和动态菜单之间）
  Widget _buildDivider(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    child: Divider(
      height: 1,
      color: context.appColors.border.withAlpha(80),
    ),
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
class _MenuItemTile extends StatefulWidget {
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
  State<_MenuItemTile> createState() => _MenuItemTileState();
}

class _MenuItemTileState extends State<_MenuItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
              color: widget.isSelected
                  ? context.appColors.primaryLight
                  : (_isHovered
                        ? context.appColors.surfaceContainerLow
                        : Colors.transparent),
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
                      widget.item.label,
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
                  // 红点
                  if (widget.updateCount > 0) _Badge(count: widget.updateCount),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 红点/徽章组件
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

/// 底部图标区域
class _BottomSection extends StatelessWidget {
  const _BottomSection({required this.isCollapsed});

  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: isCollapsed
          ? _buildVerticalLayout(context)
          : _buildHorizontalLayout(context),
    );
  }

  /// 水平布局（展开状态）
  Widget _buildHorizontalLayout(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _BottomIconButton(
          icon: Icons.folder_outlined,
          tooltip: '我的应用',
          onTap: () => context.go(AppRoutes.myApps),
        ),
        _BottomIconButton(
          icon: Icons.download_outlined,
          tooltip: '下载管理',
          onTap: () => showDownloadManagerDialog(context),
        ),
        _BottomIconButton(
          icon: Icons.settings_outlined,
          tooltip: '设置',
          onTap: () => context.go(AppRoutes.setting),
        ),
      ],
    );
  }

  /// 垂直布局（折叠状态）
  Widget _buildVerticalLayout(BuildContext context) {
    return Column(
      children: [
        _BottomIconButton(
          icon: Icons.folder_outlined,
          tooltip: '我的应用',
          onTap: () => context.go(AppRoutes.myApps),
        ),
        _BottomIconButton(
          icon: Icons.download_outlined,
          tooltip: '下载管理',
          onTap: () => showDownloadManagerDialog(context),
        ),
        _BottomIconButton(
          icon: Icons.settings_outlined,
          tooltip: '设置',
          onTap: () => context.go(AppRoutes.setting),
        ),
      ],
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
                        : Colors.transparent),
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

/// 底部图标按钮
class _BottomIconButton extends StatefulWidget {
  const _BottomIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_BottomIconButton> createState() => _BottomIconButtonState();
}

class _BottomIconButtonState extends State<_BottomIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: AppSpacing.x2l,
            height: AppSpacing.x2l,
            decoration: BoxDecoration(
              color: _isHovered
                  ? context.appColors.surfaceContainerLow
                  : Colors.transparent,
              borderRadius: AppRadius.xsRadius,
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _isHovered
                  ? AppColors.primary
                  : context.appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
