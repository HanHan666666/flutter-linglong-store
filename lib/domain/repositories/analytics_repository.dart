/// 统计上报 Repository 接口
abstract class AnalyticsRepository {
  /// 上报应用启动访问记录（携带设备/环境信息）
  Future<void> reportVisit({
    String? arch,
    String? llVersion,
    String? llBinVersion,
    String? detailMsg,
    String? osVersion,
    String? repoName,
    String? appVersion,
  });

  /// 上报应用安装事件
  Future<void> reportInstall(String appId, String version, {String? appName});

  /// 上报应用卸载事件
  Future<void> reportUninstall(String appId, String version, {String? appName});
}
