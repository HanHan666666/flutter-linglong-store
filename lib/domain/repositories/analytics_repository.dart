/// 统计上报 Repository 接口定义。
///
/// 安装/卸载统计统一走差量模型（见 [reportInstalledAppsDiff]），
/// 与旧版 Electron 客户端的统计口径保持一致。
library;

import '../models/installed_app.dart';

abstract class AnalyticsRepository {
  /// 预热匿名统计会话（visitorId / clientIp 等），用于在启动阶段提前准备上报上下文。
  Future<void> initializeSession();

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

  /// 上报已安装列表差量（对齐旧版 Electron 的差量统计模型）。
  ///
  /// [addedItems] 相对上次快照新增安装的应用，启动首轮快照为空时即为
  /// 全量基线上报；[removedItems] 为已卸载的应用，更新场景下表现为
  /// 旧版本记录被移除、新版本记录被新增。
  Future<void> reportInstalledAppsDiff({
    required List<InstalledApp> addedItems,
    required List<InstalledApp> removedItems,
  });
}
