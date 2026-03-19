import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../presentation/widgets/app_shell.dart';
import '../../presentation/pages/all_apps/all_apps_page.dart';
import '../../presentation/pages/app_detail/app_detail_page.dart';
import '../../presentation/pages/custom_category/custom_category_page.dart';
import '../../presentation/pages/launch/launch_page.dart';
import '../../presentation/pages/my_apps/my_apps_page.dart';
import '../../presentation/pages/ranking/ranking_page.dart';
import '../../presentation/pages/recommend/recommend_page.dart';
import '../../presentation/pages/search_list/search_list_page.dart';
import '../../presentation/pages/setting/setting_page.dart';
import '../../presentation/pages/update_app/update_app_page.dart';
import '../../domain/models/installed_app.dart';
import '../../application/providers/launch_provider.dart';
import 'keepalive_visibility_sync.dart';
import 'page_visibility.dart';

/// 页面变为可见通知
///
/// 由 KeepAlivePageWrapper 发送，用于通知子组件页面变为可见
class PageBecameVisibleNotification extends Notification {
  PageBecameVisibleNotification({required this.routePath});
  final String routePath;
}

/// 页面变为隐藏通知
///
/// 由 KeepAlivePageWrapper 发送，用于通知子组件页面变为隐藏
class PageBecameHiddenNotification extends Notification {
  PageBecameHiddenNotification({required this.routePath});
  final String routePath;
}

/// 路由路径常量
abstract class AppRoutes {
  AppRoutes._();

  /// 启动页
  static const launch = '/launch';

  /// 首页（推荐页）
  static const recommend = '/';

  /// 全部应用
  static const allApps = '/all-apps';

  /// 排行榜
  static const ranking = '/ranking';

  /// 我的应用
  static const myApps = '/my-apps';

  /// 应用详情（带参数）
  static const appDetail = '/app/:id';

  /// 搜索列表
  static const searchList = '/search_list';

  /// 设置
  static const setting = '/setting';

  /// 更新管理
  static const updateApps = '/update_apps';

  /// 自定义分类（带参数）
  static const customCategory = '/custom_category/:code';
}

/// 底部导航栏索引对应的路由分支
enum NavigationBranch { recommend, allApps, ranking, myApps }

/// KeepAlive 白名单 - 这些页面需要保活
const keepAliveRoutes = {
  AppRoutes.recommend,
  AppRoutes.allApps,
  AppRoutes.ranking,
  AppRoutes.myApps,
};

/// 最大缓存页面数量
const maxCachedPages = 10;

/// 当前导航分支索引 Provider
final navigationIndexProvider =
    StateNotifierProvider<NavigationIndexNotifier, int>((ref) {
      return NavigationIndexNotifier();
    });

/// 导航索引状态管理器
class NavigationIndexNotifier extends StateNotifier<int> {
  NavigationIndexNotifier() : super(0);

  /// 设置当前导航索引
  void setIndex(int index) {
    state = index;
  }
}

/// 导航键
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// 获取分支对应的 Navigator
List<RouteBase> _buildShellRoutes() {
  return [
    // 启动页面 - 不在 Shell 内
    GoRoute(
      path: AppRoutes.launch,
      name: 'launch',
      builder: (context, state) => const LaunchPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        // 底部导航页面 - 使用 KeepAlive
        GoRoute(
          path: AppRoutes.recommend,
          name: 'recommend',
          pageBuilder: (context, state) => _buildKeepAlivePage(
            key: const ValueKey('recommend'),
            child: const RecommendPage(),
            routePath: AppRoutes.recommend,
          ),
        ),
        GoRoute(
          path: AppRoutes.allApps,
          name: 'allApps',
          pageBuilder: (context, state) => const _BuildKeepAlivePage(
            key: ValueKey('allApps'),
            child: AllAppsPage(),
            routePath: AppRoutes.allApps,
          ),
        ),
        GoRoute(
          path: AppRoutes.ranking,
          name: 'ranking',
          pageBuilder: (context, state) => const _BuildKeepAlivePage(
            key: ValueKey('ranking'),
            child: RankingPage(),
            routePath: AppRoutes.ranking,
          ),
        ),
        GoRoute(
          path: AppRoutes.myApps,
          name: 'myApps',
          pageBuilder: (context, state) => const _BuildKeepAlivePage(
            key: ValueKey('myApps'),
            child: MyAppsPage(),
            routePath: AppRoutes.myApps,
          ),
        ),
        // 其他页面 - 不需要保活
        GoRoute(
          path: AppRoutes.searchList,
          name: 'searchList',
          builder: (context, state) {
            final query = state.uri.queryParameters['q'] ?? '';
            return SearchListPage(initialQuery: query);
          },
        ),
        GoRoute(
          path: AppRoutes.setting,
          name: 'setting',
          builder: (context, state) => const SettingPage(),
        ),
        GoRoute(
          path: AppRoutes.updateApps,
          name: 'updateApps',
          builder: (context, state) => const UpdateAppPage(),
        ),
        GoRoute(
          path: AppRoutes.customCategory,
          name: 'customCategory',
          builder: (context, state) {
            final code = state.pathParameters['code']!;
            return CustomCategoryPage(code: code);
          },
        ),
        GoRoute(
          path: AppRoutes.appDetail,
          name: 'appDetail',
          builder: (context, state) {
            final appId = state.pathParameters['id']!;
            final extra = state.extra;

            InstalledApp? appInfo;
            if (extra is InstalledApp) {
              appInfo = extra;
            }

            return AppDetailPage(appId: appId, appInfo: appInfo);
          },
        ),
      ],
    ),
  ];
}

/// 构建保活页面
Page<void> _buildKeepAlivePage({
  required LocalKey key,
  required Widget child,
  required String routePath,
}) {
  return MaterialPage(
    key: key,
    child: KeepAlivePageWrapper(routePath: routePath, child: child),
  );
}

/// 路由配置 Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.launch,
    debugLogDiagnostics: true,
    routes: _buildShellRoutes(),
    errorBuilder: (context, state) => AppErrorPage(error: state.error),
    redirect: (context, state) {
      final launchState = ref.read(launchSequenceProvider);
      final currentPath = state.matchedLocation;

      // 如果启动序列未完成且不在启动页，重定向到启动页
      if (!launchState.isCompleted && currentPath != AppRoutes.launch) {
        return AppRoutes.launch;
      }

      // 如果启动序列已完成且在启动页，重定向到首页
      if (launchState.isCompleted && currentPath == AppRoutes.launch) {
        return AppRoutes.recommend;
      }

      return null;
    },
  );
});

/// 保活页面包装器
///
/// 使用 AutomaticKeepAliveClientMixin 实现页面状态保活
/// 同时提供可见性状态管理，用于暂停/恢复副作用
class KeepAlivePageWrapper extends StatefulWidget {
  const KeepAlivePageWrapper({
    required this.routePath,
    required this.child,
    super.key,
  });

  final String routePath;
  final Widget child;

  @override
  State<KeepAlivePageWrapper> createState() => KeepAlivePageWrapperState();
}

/// KeepAlivePageWrapper 的公开 State
///
/// 允许外部通过 GlobalKey 访问并控制可见性状态
class KeepAlivePageWrapperState extends State<KeepAlivePageWrapper>
    with AutomaticKeepAliveClientMixin {
  /// 当前是否可见
  bool _isVisible = true;
  bool? _pendingVisibility;
  late final KeepAliveVisibilityBinding _visibilityBinding =
      KeepAliveVisibilityBinding(
        show: setAsVisible,
        hide: setAsHidden,
        isMounted: () => mounted,
      );

  @override
  bool get wantKeepAlive => keepAliveRoutes.contains(widget.routePath);

  /// 获取当前可见性状态
  bool get isVisible => _isVisible;

  @override
  void initState() {
    super.initState();
    KeepAlivePageRegistry.register(
      routePath: widget.routePath,
      binding: _visibilityBinding,
    );
    // 页面首次创建时，通知管理器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PageVisibilityManager.instance.notifyPageMounted(widget.routePath);
    });
  }

  @override
  void didUpdateWidget(KeepAlivePageWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routePath != widget.routePath) {
      KeepAlivePageRegistry.unregister(
        routePath: oldWidget.routePath,
        binding: _visibilityBinding,
      );
      KeepAlivePageRegistry.register(
        routePath: widget.routePath,
        binding: _visibilityBinding,
      );
      _updateVisibility(true);
    }
  }

  @override
  void dispose() {
    KeepAlivePageRegistry.unregister(
      routePath: widget.routePath,
      binding: _visibilityBinding,
    );
    super.dispose();
  }

  /// 更新可见性状态
  void _updateVisibility(bool visible) {
    final manager = PageVisibilityManager.instance;
    final managerStatus = manager.getVisibilityStatus(widget.routePath);
    final managerMatches = visible
        ? managerStatus == PageVisibilityStatus.mountedVisible
        : managerStatus == PageVisibilityStatus.mountedHidden;

    if (_pendingVisibility == visible ||
        (_pendingVisibility == null &&
            _isVisible == visible &&
            managerMatches)) {
      return;
    }

    _pendingVisibility = visible;
    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    final shouldDefer =
        schedulerPhase == SchedulerPhase.transientCallbacks ||
        schedulerPhase == SchedulerPhase.midFrameMicrotasks ||
        schedulerPhase == SchedulerPhase.persistentCallbacks;

    if (shouldDefer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _flushPendingVisibility();
      });
      return;
    }

    _flushPendingVisibility();
  }

  void _flushPendingVisibility() {
    if (!mounted) {
      _pendingVisibility = null;
      return;
    }

    final nextVisibility = _pendingVisibility;
    _pendingVisibility = null;
    if (nextVisibility == null) {
      return;
    }

    final manager = PageVisibilityManager.instance;
    final managerStatus = manager.getVisibilityStatus(widget.routePath);
    final managerMatches = nextVisibility
        ? managerStatus == PageVisibilityStatus.mountedVisible
        : managerStatus == PageVisibilityStatus.mountedHidden;

    final shouldUpdateWidgetState = _isVisible != nextVisibility;
    if (!shouldUpdateWidgetState && managerMatches) {
      return;
    }

    if (shouldUpdateWidgetState) {
      setState(() {
        _isVisible = nextVisibility;
      });
    }

    if (nextVisibility) {
      manager.notifyPageVisible(widget.routePath);
    } else {
      manager.notifyPageHidden(widget.routePath);
    }

    if (shouldUpdateWidgetState) {
      _notifyChildVisibilityChanged();
    }
  }

  /// 通知子组件可见性变化
  void _notifyChildVisibilityChanged() {
    // 通过 Notification 机制通知子树中的 VisibilityAwareMixin
    if (_isVisible) {
      PageBecameVisibleNotification(
        routePath: widget.routePath,
      ).dispatch(context);
    } else {
      PageBecameHiddenNotification(
        routePath: widget.routePath,
      ).dispatch(context);
    }
  }

  /// 手动设置为可见（用于路由切换时）
  void setAsVisible() {
    _updateVisibility(true);
  }

  /// 手动设置为隐藏（用于路由切换时）
  void setAsHidden() {
    _updateVisibility(false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 使用 InheritedWidget 传递可见性状态
    return _VisibilityInherited(
      isVisible: _isVisible,
      routePath: widget.routePath,
      child: widget.child,
    );
  }
}

/// 可见性状态 InheritedWidget
///
/// 用于在子组件树中传递页面可见性状态
/// 当可见性变化时，会通知依赖的子组件
class VisibilityInherited extends InheritedWidget {
  const VisibilityInherited({
    required this.isVisible,
    required this.routePath,
    super.key,
    required super.child,
  });

  /// 当前页面是否可见
  final bool isVisible;

  /// 当前页面的路由路径
  final String routePath;

  static VisibilityInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<VisibilityInherited>();
  }

  /// 获取可见性状态（不建立依赖关系）
  static VisibilityInherited? read(BuildContext context) {
    final inherited = context
        .getInheritedWidgetOfExactType<VisibilityInherited>();
    return inherited;
  }

  @override
  bool updateShouldNotify(VisibilityInherited oldWidget) {
    // 只在可见性状态变化时通知
    return isVisible != oldWidget.isVisible;
  }
}

/// 兼容旧 API 的别名（已废弃，请使用 VisibilityInherited）
@Deprecated('Use VisibilityInherited instead')
typedef _VisibilityInherited = VisibilityInherited;

/// 页面可见性扩展
///
/// 用于在 BuildContext 中快速获取页面可见性状态
extension PageVisibilityExtension on BuildContext {
  /// 获取当前页面是否可见
  bool get isPageVisible {
    final inherited = _VisibilityInherited.read(this);
    return inherited?.isVisible ?? true;
  }

  /// 获取当前页面的路由路径
  String? get currentRoutePath {
    final inherited = _VisibilityInherited.read(this);
    return inherited?.routePath;
  }
}

/// 带保活功能的页面构建器
class _BuildKeepAlivePage extends Page<void> {
  const _BuildKeepAlivePage({
    required super.key,
    required this.child,
    required this.routePath,
  });

  final Widget child;
  final String routePath;

  @override
  Route<void> createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (context) =>
          KeepAlivePageWrapper(routePath: routePath, child: child),
    );
  }
}

/// LRU 页面缓存管理器
///
/// 用于管理页面级别的缓存，最大缓存10个页面
class PageCacheManager {
  PageCacheManager._();

  static final PageCacheManager instance = PageCacheManager._();

  /// 缓存的页面路径列表（LRU顺序，最近使用的在末尾）
  final List<String> _cachedPages = [];

  /// 获取缓存的页面列表
  List<String> get cachedPages => List.unmodifiable(_cachedPages);

  /// 访问页面（更新LRU）
  void visitPage(String routePath) {
    // 如果已存在，移到队尾（最近使用）
    if (_cachedPages.contains(routePath)) {
      _cachedPages.remove(routePath);
    }

    // 添加到队尾
    _cachedPages.add(routePath);

    // 如果超过最大缓存数量，移除最早使用的
    while (_cachedPages.length > maxCachedPages) {
      _cachedPages.removeAt(0);
    }
  }

  /// 检查页面是否在缓存中
  bool isCached(String routePath) => _cachedPages.contains(routePath);

  /// 清除所有缓存
  void clearCache() {
    _cachedPages.clear();
  }

  /// 移除指定页面的缓存
  void removeCache(String routePath) {
    _cachedPages.remove(routePath);
  }
}

/// 应用错误页面
class AppErrorPage extends StatelessWidget {
  const AppErrorPage({required this.error, super.key});

  final GoException? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            Text('抱歉，页面未找到', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.recommend),
              icon: const Icon(Icons.home),
              label: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 路由扩展方法
extension GoRouterExtension on GoRouter {
  /// 安全导航到指定路由
  void goSafe(String location, {Object? extra}) {
    try {
      go(location, extra: extra);
    } catch (e) {
      // 导航失败时回退到首页
      go(AppRoutes.recommend);
    }
  }
}

/// BuildContext 路由扩展
extension ContextRouterExtension on BuildContext {
  /// 导航到应用详情页
  void goToAppDetail(String appId, {InstalledApp? appInfo}) {
    push('/app/$appId', extra: appInfo);
  }

  /// 导航到搜索页
  void goToSearch([String? query]) {
    if (query != null && query.isNotEmpty) {
      go('${AppRoutes.searchList}?q=${Uri.encodeQueryComponent(query)}');
    } else {
      go(AppRoutes.searchList);
    }
  }

  /// 导航到自定义分类页
  void goToCustomCategory(String code) {
    go('/custom_category/$code');
  }

  /// 导航到设置页
  void goToSetting() {
    go(AppRoutes.setting);
  }

  /// 导航到更新管理页
  void goToUpdates() {
    go(AppRoutes.updateApps);
  }
}
