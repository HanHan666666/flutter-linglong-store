import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

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

/// 侧边栏宽度 Provider
final sidebarWidthProvider = StateProvider<double>((ref) => 160.0);

/// 侧边栏是否折叠 Provider
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// 侧边栏
///
/// 包含：导航菜单 + 动态菜单区域 + 底部图标
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

    // 更新折叠状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sidebarCollapsedProvider.notifier).state = isCollapsed;
    });

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
  });

  final String currentPath;
  final int updateCount;
  final bool isCollapsed;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 19.2, minHeight: 19.2),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: AppTextStyles.tiny.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
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
