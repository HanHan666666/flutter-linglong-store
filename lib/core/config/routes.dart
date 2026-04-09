import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/widgets/app_shell.dart';
import '../../presentation/pages/app_detail/app_detail_page.dart';
import '../../presentation/pages/custom_category/custom_category_page.dart';
import '../../presentation/pages/launch/launch_page.dart';
import '../../presentation/pages/search_list/search_list_page.dart';
import '../../presentation/pages/setting/setting_page.dart';
import '../../presentation/pages/update_app/update_app_page.dart';
import '../../domain/models/installed_app.dart';
import '../../application/providers/launch_provider.dart';

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

/// 导航键
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// 主页面 Shell 占位符
///
/// 4 个主页面（recommend、allApps、ranking、myApps）的实际内容由
/// `AppShell` 的 `IndexedStack` 提供。路由只负责路径匹配，返回此占位符。
class _PrimaryShellPlaceholder extends StatelessWidget {
  const _PrimaryShellPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// 构建 Shell 路由
List<RouteBase> _buildShellRoutes() {
  return [
    // 启动页面 - 不在 Shell 内
    GoRoute(
      path: AppRoutes.launch,
      name: 'launch',
      builder: (context, state) => const LaunchPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(
        // ShellRoute 在 push 二级页时，matchedLocation 可能仍停在上一个主页面。
        // Shell 内容可见性必须跟随当前 URI path，避免 /app/:id 被误判成主页面而不显示。
        currentPath: state.uri.path,
        currentUri: state.uri,
        child: child,
      ),
      routes: [
        // 4 个主页面 - 只返回占位符，实际页面由 AppShell 的 IndexedStack 提供
        GoRoute(
          path: AppRoutes.recommend,
          name: 'recommend',
          builder: (context, state) => const _PrimaryShellPlaceholder(),
        ),
        GoRoute(
          path: AppRoutes.allApps,
          name: 'allApps',
          builder: (context, state) => const _PrimaryShellPlaceholder(),
        ),
        GoRoute(
          path: AppRoutes.ranking,
          name: 'ranking',
          builder: (context, state) => const _PrimaryShellPlaceholder(),
        ),
        GoRoute(
          path: AppRoutes.myApps,
          name: 'myApps',
          builder: (context, state) => const _PrimaryShellPlaceholder(),
        ),
        // 二级页面 - 保持真实 builder，由 AppShell 作为覆盖层显示
        GoRoute(
          path: AppRoutes.searchList,
          name: 'searchList',
          builder: (context, state) {
            final query = state.uri.queryParameters['q']?.trim() ?? '';
            return SearchListPage(
              key: ValueKey('searchList:$query'),
              initialQuery: query,
            );
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
    final normalizedQuery = query?.trim() ?? '';
    if (normalizedQuery.isNotEmpty) {
      go(
        '${AppRoutes.searchList}?q=${Uri.encodeQueryComponent(normalizedQuery)}',
      );
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
