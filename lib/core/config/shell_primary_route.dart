import 'routes.dart';

/// Shell 主路由枚举
///
/// 定义哪些页面是 Shell 的"主路由"（底部导航的4个一级页面）。
/// 用于 IndexedStack 方式实现 KeepAlive 的页面选择。
enum ShellPrimaryRoute {
  recommend,
  allApps,
  ranking,
  myApps;

  /// 获取对应的路由路径
  String get path => switch (this) {
    ShellPrimaryRoute.recommend => AppRoutes.recommend,
    ShellPrimaryRoute.allApps => AppRoutes.allApps,
    ShellPrimaryRoute.ranking => AppRoutes.ranking,
    ShellPrimaryRoute.myApps => AppRoutes.myApps,
  };

  /// 从路径解析 ShellPrimaryRoute
  ///
  /// 如果路径不是主路由，返回 null。
  static ShellPrimaryRoute? tryParse(String path) {
    for (final value in ShellPrimaryRoute.values) {
      if (value.path == path) {
        return value;
      }
    }
    return null;
  }

  /// 判断路径是否为主路由
  static bool isPrimaryPath(String path) => tryParse(path) != null;
}