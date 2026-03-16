/// 统计上报 Repository 接口
abstract class AnalyticsRepository {
  /// 上报应用安装事件
  Future<void> reportInstall(String appId, String version);

  /// 上报应用卸载事件
  Future<void> reportUninstall(String appId, String version);

  /// 上报应用启动事件
  Future<void> reportLaunch(String appId);

  /// 上报搜索事件
  Future<void> reportSearch(String keyword, int resultCount);

  /// 上报页面访问事件
  Future<void> reportPageView(String pageName);
}