import '../models/installed_app.dart';
import '../models/running_app.dart';
import '../models/install_progress.dart';

/// ll-cli 操作 Repository 接口
abstract class LinglongCliRepository {
  /// 获取已安装应用列表
  Future<List<InstalledApp>> getInstalledApps({
    bool includeBaseService = false,
  });

  /// 获取运行中进程
  Future<List<RunningApp>> getRunningApps();

  /// 安装应用（返回进度流）
  ///
  /// [appId] 应用ID
  /// [version] 目标版本，不指定则安装最新版
  /// [force] 是否强制重新安装
  Stream<InstallProgress> installApp(
    String appId, {
    String? version,
    bool force = false,
  });

  /// 更新应用（返回进度流）
  ///
  /// [appId] 应用ID
  /// [version] 目标版本，不指定则更新到最新版
  Stream<InstallProgress> updateApp(
    String appId, {
    String? version,
  });

  /// 取消安装
  Future<void> cancelInstall(String appId);

  /// 卸载应用
  Future<String> uninstallApp(String appId, String version);

  /// 运行应用
  Future<void> runApp(String appId);

  /// 停止应用
  Future<String> killApp(String appName);

  /// 创建桌面快捷方式
  Future<String> createDesktopShortcut(String appId);

  /// 搜索版本
  Future<List<InstalledApp>> searchVersions(String appId);

  /// 清理废弃服务
  Future<String> pruneApps();

  /// 获取 ll-cli 版本
  Future<String> getLlCliVersion();
}