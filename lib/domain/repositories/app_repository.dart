import '../models/installed_app.dart';
import '../models/app_detail.dart';
import '../models/app_comment.dart';
import '../models/app_version.dart';

/// 应用相关 API Repository 接口
abstract class AppRepository {
  /// 获取推荐应用列表
  Future<List<InstalledApp>> getRecommendApps({
    int page = 1,
    int pageSize = 20,
  });

  /// 获取全部应用列表
  Future<List<InstalledApp>> getAllApps({
    int page = 1,
    int pageSize = 20,
    String? category,
  });

  /// 搜索应用
  Future<List<InstalledApp>> searchApps(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  });

  /// 获取应用详情（含截图）
  Future<AppDetail> getAppDetail(String appId, {String? arch});

  /// 获取应用评论列表
  Future<List<AppComment>> getAppComments(String appId);

  /// 提交应用评论
  Future<bool> saveAppComment({
    required String appId,
    required String remark,
    String? version,
  });

  /// 获取应用历史版本列表
  Future<List<AppVersion>> getVersions(
    String appId, {
    String? repoName,
    String? arch,
    int page = 1,
    int pageSize = 20,
  });

  /// 获取排行榜
  Future<List<InstalledApp>> getRanking({String type = 'new', int limit = 100});

  /// 批量获取应用详情，用于富化已安装应用列表
  ///
  /// [apps] 需要富化的已安装应用列表
  /// 返回包含图标、中文名等详情的已安装应用列表
  Future<List<InstalledApp>> enrichInstalledAppsWithDetails(
    List<InstalledApp> apps,
  );

  /// 批量检查应用更新
  ///
  /// [apps] 需要检查更新的已安装应用列表
  /// 返回有更新的应用的详情列表（领域模型），仅包含版本号比已安装版本新的应用
  Future<List<AppDetail>> checkAppUpdates(List<InstalledApp> apps);
}
