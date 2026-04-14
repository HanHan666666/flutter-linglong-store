import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../application/providers/app_collection_sync_provider.dart';
import '../../application/providers/update_apps_provider.dart';
import '../../core/config/shell_branch_visibility.dart';
import '../../core/config/shell_primary_route.dart';
import '../../core/config/theme.dart';
import '../../core/di/providers.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/window_service.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_task.dart';
import '../../presentation/pages/all_apps/all_apps_page.dart';
import '../../presentation/pages/my_apps/my_apps_page.dart';
import '../../presentation/pages/ranking/ranking_page.dart';
import '../../presentation/pages/recommend/recommend_page.dart';
import 'sidebar.dart';
import 'title_bar.dart';

/// 应用外壳 - 主布局框架
///
/// 包含：TitleBar（顶部）+ Sidebar（左侧）+ Content（右侧）
/// 支持响应式布局和窗口控制
///
/// **KeepAlive 改造要点：**
/// - 4 个主页面（recommend、allApps、ranking、myApps）由本 Shell 托管在 IndexedStack 中
/// - 二级路由（setting、app/:id 等）作为覆盖层显示在主页面栈之上
/// - 主页面切换时状态保持，二级路由离开时释放
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    required this.child,
    required this.currentPath,
    required this.currentUri,
    super.key,
  });

  /// 当前路由匹配的路径（二级路由覆盖时，主页面栈仍在树中）
  final String currentPath;

  /// 当前路由的完整 URI（包含 query 参数）
  final Uri currentUri;

  /// 路由系统传入的子组件（二级路由时为真实页面，主路由时为占位符）
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WindowListener {
  /// 窗口是否最大化
  bool _isMaximized = false;

  /// 当前激活的主路由
  ShellPrimaryRoute _activePrimaryRoute = ShellPrimaryRoute.recommend;

  /// 已访问过的主路由集合（用于懒加载）
  final Set<ShellPrimaryRoute> _visitedPrimaryRoutes = {
    ShellPrimaryRoute.recommend,
  };

  ProviderSubscription<InstallQueueState>? _installQueueSubscription;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
    _installQueueSubscription = ref.listenManual<InstallQueueState>(
      installQueueProvider,
      (previous, next) {
        if (previous?.currentTask != null && next.currentTask == null) {
          final completedTask = next.history.firstOrNull;
          if (completedTask?.status == InstallStatus.success) {
            // 乐观移除：立即从待更新列表中移除已完成的应用，
            // 不等异步刷新，避免 UI 显示过时条目。
            ref.read(updateAppsProvider.notifier).removeApp(completedTask!.appId);

            unawaited(
              ref
                  .read(appCollectionSyncServiceProvider)
                  .syncAfterSuccessfulOperation(),
            );

            // 如果开启了『安装后自动打开』，且是安装任务（不是更新），自动启动应用
            final prefs = ref.read(globalAppProvider).userPreferences;
            if (prefs.autoRunAfterInstall &&
                completedTask!.kind == InstallTaskKind.install) {
              _tryRunApp(completedTask.appId);
            }
          }
        }
      },
    );
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 路径变化时同步主路由状态
    _syncPrimaryRouteFromPath();
  }

  /// 同步主路由状态
  ///
  /// 当路径变化时，判断是否为主路由，并更新激活/已访问状态。
  void _syncPrimaryRouteFromPath() {
    final matched = ShellPrimaryRoute.tryParse(widget.currentPath);
    if (matched == null) {
      // 二级路由，不改变激活的主路由
      return;
    }
    if (_activePrimaryRoute == matched &&
        _visitedPrimaryRoutes.contains(matched)) {
      // 已经是当前激活的主路由且已访问，无需更新
      return;
    }
    setState(() {
      _activePrimaryRoute = matched;
      _visitedPrimaryRoutes.add(matched);
    });
  }

  /// 判断当前路径是否为二级路由
  bool _isSecondaryRoute() {
    return !ShellPrimaryRoute.isPrimaryPath(widget.currentPath);
  }

  @override
  void dispose() {
    _installQueueSubscription?.close();
    windowManager.removeListener(this);
    super.dispose();
  }

  /// WindowListener 回调 - 窗口最大化
  @override
  void onWindowMaximize() {
    if (mounted && !_isMaximized) {
      setState(() => _isMaximized = true);
    }
  }

  /// WindowListener 回调 - 窗口取消最大化
  @override
  void onWindowUnmaximize() {
    if (mounted && _isMaximized) {
      setState(() => _isMaximized = false);
    }
  }

  /// 检查窗口最大化状态
  Future<void> _checkMaximized() async {
    final isMaximized = await WindowService.isMaximized();
    if (mounted && _isMaximized != isMaximized) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  /// 安装成功后自动启动应用（autoRunAfterInstall=true 时触发）
  Future<void> _tryRunApp(String appId) async {
    try {
      await ref.read(linglongCliRepositoryProvider).runApp(appId);
    } catch (e) {
      AppLogger.warning('自动启动应用失败: $appId, 错误: $e');
    }
  }

  /// 处理窗口最小化
  void _onMinimize() {
    WindowService.minimize();
  }

  /// 处理窗口最大化/还原
  void _onMaximize() {
    WindowService.toggleMaximize();
    // 延迟检查状态，确保窗口动画完成
    Future.delayed(const Duration(milliseconds: 100), _checkMaximized);
  }

  /// 处理窗口关闭
  void _onClose() {
    // 检查是否有正在进行的安装任务
    final hasActiveTasks = ref.read(hasActiveInstallTasksProvider);
    if (hasActiveTasks) {
      // 如果有任务，显示确认对话框
      _showCloseConfirmDialog();
    } else {
      WindowService.close();
    }
  }

  /// 显示关闭确认对话框
  void _showCloseConfirmDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.confirmExit),
          content: Text(l10n.exitWithInstalling),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                WindowService.close();
              },
              child: Text(l10n.exitBtn),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSearchQuery = widget.currentPath == '/search_list'
        ? (widget.currentUri.queryParameters['q'] ?? '')
        : '';
    final updateCount = ref.watch(updatableAppsCountProvider);

    return Scaffold(
      body: Column(
        children: [
          // 自定义标题栏
          CustomTitleBar(
            isMaximized: _isMaximized,
            onMinimize: _onMinimize,
            onMaximize: _onMaximize,
            onClose: _onClose,
            currentSearchQuery: currentSearchQuery,
          ),
          // 主内容区域
          Expanded(
            child: Row(
              children: [
                // 左侧导航栏
                Sidebar(
                  currentPath: widget.currentPath,
                  updateCount: updateCount,
                ),
                // 右侧内容区域，背景跟随主题
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.appColors.surfaceContainerLow,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.sm),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.sm),
                      ),
                      child: _buildContentArea(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域
  ///
  /// - 主路由时：显示 IndexedStack 托管的 4 个主页面
  /// - 二级路由时：主页面栈隐藏，二级页面作为覆盖层显示
  Widget _buildContentArea() {
    final showOverlay = _isSecondaryRoute();
    // 二级路由覆盖时，主页面栈仍保留在树中，但 activeRoute 为 null
    final activeRoute = showOverlay ? null : _activePrimaryRoute;

    return Stack(
      // 二级路由显示时，Offstage 会让主页面栈尺寸变成 0；
      // 这里显式 expand，避免 Stack 被 0 尺寸子节点“带瘦”，导致覆盖层视口塌成空白页。
      fit: StackFit.expand,
      children: [
        // 主页面 IndexedStack（始终在树中，二级路由时隐藏）
        Offstage(
          offstage: showOverlay,
          child: _PrimaryIndexedStack(
            activeRoute: activeRoute,
            visitedRoutes: _visitedPrimaryRoutes,
          ),
        ),
        // 二级路由覆盖层
        if (showOverlay) Positioned.fill(child: widget.child),
      ],
    );
  }
}

/// 主页面 IndexedStack
///
/// 懒加载托管 4 个主页面（recommend、allApps、ranking、myApps）。
/// 每个页面通过 ShellBranchVisibilityScope 接收激活状态。
class _PrimaryIndexedStack extends StatelessWidget {
  const _PrimaryIndexedStack({
    required this.activeRoute,
    required this.visitedRoutes,
  });

  /// 当前激活的主路由（二级路由覆盖时为 null）
  final ShellPrimaryRoute? activeRoute;

  /// 已访问过的主路由集合
  final Set<ShellPrimaryRoute> visitedRoutes;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _getActiveIndex(),
      children: ShellPrimaryRoute.values.map((route) {
        return _buildPrimarySlot(route);
      }).toList(),
    );
  }

  /// 获取当前激活的主路由索引
  int _getActiveIndex() {
    if (activeRoute == null) {
      // 二级路由覆盖时，保持当前激活主页面的索引（但仍隐藏）
      return ShellPrimaryRoute.values.first.index;
    }
    return activeRoute!.index;
  }

  /// 构建单个主页面槽位
  ///
  /// 未访问过的主页面返回空的 SizedBox，实现懒加载。
  Widget _buildPrimarySlot(ShellPrimaryRoute route) {
    final hasVisited = visitedRoutes.contains(route);
    final isActive = activeRoute != null && route == activeRoute;

    if (!hasVisited) {
      // 未访问过的主页面，返回空占位符（懒加载）
      return const SizedBox.shrink();
    }

    // 使用 TickerMode + ExcludeFocus + IgnorePointer 完整隔离非激活页面
    // 避免隐藏页面偷走焦点、动画 ticker 继续运行等问题
    return TickerMode(
      enabled: isActive,
      child: ExcludeFocus(
        excluding: !isActive,
        child: IgnorePointer(
          ignoring: !isActive,
          child: ShellBranchVisibilityScope(
            activeRoute: activeRoute,
            currentRoute: route,
            child: _buildPrimaryPage(route),
          ),
        ),
      ),
    );
  }

  /// 构建主页面组件
  Widget _buildPrimaryPage(ShellPrimaryRoute route) {
    return switch (route) {
      ShellPrimaryRoute.recommend => const RecommendPage(),
      ShellPrimaryRoute.allApps => const AllAppsPage(),
      ShellPrimaryRoute.ranking => const RankingPage(),
      ShellPrimaryRoute.myApps => const MyAppsPage(),
    };
  }
}
