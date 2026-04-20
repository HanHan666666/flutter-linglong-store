import 'package:dio/dio.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'app_api_service.g.dart';

/// 应用 API 服务 (Retrofit 接口定义)
///
/// 对应原仓库 HTTP API 接口清单：
/// - getDisCategoryList: GET /visit/getDisCategoryList
/// - getSearchAppList: POST /visit/getSearchAppList
/// - getAppDetails: POST /visit/getAppDetails
/// - getAppDetail: POST /app/getAppDetail
/// - getWelcomeCarouselList: POST /visit/getWelcomeCarouselList
/// - getWelcomeAppList: POST /visit/getWelcomeAppList
/// - appCheckUpdate: POST /app/appCheckUpdate
/// - getNewAppList: POST /visit/getNewAppList
/// - getInstallAppList: POST /visit/getInstallAppList
/// - getSearchAppVersionList: POST /visit/getSearchAppVersionList
/// - getSidebarConfig: GET /app/sidebar/config
/// - getSidebarApps: POST /app/sidebar/apps
@RestApi()
abstract class AppApiService {
  factory AppApiService(Dio dio, {String baseUrl}) = _AppApiService;

  // ============== 分类接口 ==============

  /// 获取分类列表
  /// GET /visit/getDisCategoryList
  @GET('/visit/getDisCategoryList')
  Future<HttpResponse<CategoryListResponse>> getDisCategoryList();

  // ============== 搜索接口 ==============

  /// 搜索应用（分页）
  /// POST /visit/getSearchAppList
  /// 请求体字段名: name (不是 keyword)
  @POST('/visit/getSearchAppList')
  Future<HttpResponse<AppListResponse>> getSearchAppList(
    @Body() SearchAppListRequest request,
  );

  // ============== 应用详情接口 ==============

  /// 获取应用详情（批量）
  /// POST /visit/getAppDetails
  /// 请求体: List<AppDetailsBO> (数组格式)
  @POST('/visit/getAppDetails')
  Future<HttpResponse<AppListArrayResponse>> getAppDetails(
    @Body() List<AppDetailsBO> body,
  );

  /// 获取应用详情（带截图）
  /// POST /app/getAppDetail
  /// 请求体: List<AppDetailSearchBO> (数组格式!)
  /// 响应: Map<String, List<AppDetailDTO>>
  @POST('/app/getAppDetail')
  Future<HttpResponse<AppDetailResponse>> getAppDetail(
    @Body() List<AppDetailSearchBO> request,
  );

  /// 获取应用评论列表
  /// POST /app/getAppCommentList
  @POST('/app/getAppCommentList')
  Future<HttpResponse<AppCommentListResponse>> getAppCommentList(
    @Body() AppCommentSearchBO request,
  );

  /// 提交应用评论
  /// POST /app/saveAppComment
  @POST('/app/saveAppComment')
  Future<HttpResponse<BooleanResponse>> saveAppComment(
    @Body() AppCommentSaveBO request,
  );

  /// 获取玲珑环境自动安装脚本
  /// GET /app/findShellString
  @GET('/app/findShellString')
  Future<HttpResponse<StringResponse>> findShellString();

  // ============== 轮播图/推荐接口 ==============

  /// 轮播图列表
  /// POST /visit/getWelcomeCarouselList
  /// 注意：返回的是 AppMainDto 列表，不是专门的轮播图结构
  @POST('/visit/getWelcomeCarouselList')
  Future<HttpResponse<AppListArrayResponse>> getWelcomeCarouselList(
    @Body() AppWelcomeSearchRequest request,
  );

  /// 推荐应用列表
  /// POST /visit/getWelcomeAppList
  @POST('/visit/getWelcomeAppList')
  Future<HttpResponse<AppListResponse>> getWelcomeAppList(
    @Body() PageParams request,
  );

  // ============== 更新检查接口 ==============

  /// 检查更新（单个或批量）
  /// POST /app/appCheckUpdate
  /// 请求体: List<AppCheckVersionBO> (数组格式!)
  /// 响应: List<AppDetailDTO> (仅返回有更新的应用)
  @POST('/app/appCheckUpdate')
  Future<HttpResponse<AppDetailListResponse>> appCheckUpdate(
    @Body() List<AppCheckVersionBO> request,
  );

  // ============== 排行榜接口 ==============

  /// 最新应用
  /// POST /visit/getNewAppList
  @POST('/visit/getNewAppList')
  Future<HttpResponse<AppListResponse>> getNewAppList(
    @Body() PageParams request,
  );

  /// 下载排行
  /// POST /visit/getInstallAppList
  @POST('/visit/getInstallAppList')
  Future<HttpResponse<AppListResponse>> getInstallAppList(
    @Body() PageParams request,
  );

  // ============== 版本接口 ==============

  /// 版本列表
  /// POST /visit/getSearchAppVersionList
  /// 请求体: {"appId": "xxx", "pageNo": 1, "pageSize": 20}
  @POST('/visit/getSearchAppVersionList')
  Future<HttpResponse<VersionListResponse>> getSearchAppVersionList(
    @Body() AppVersionListRequest request,
  );

  // ============== 侧边栏接口 ==============

  /// 获取侧边栏菜单配置
  /// GET /app/sidebar/config
  @GET('/app/sidebar/config')
  Future<HttpResponse<SidebarConfigResponse>> getSidebarConfig();

  /// 根据菜单获取应用列表
  /// POST /app/sidebar/apps
  @POST('/app/sidebar/apps')
  Future<HttpResponse<AppListResponse>> getSidebarApps(
    @Body() SidebarAppsRequest request,
  );

  // ============== 统计上报接口 ==============

  /// 保存启动访问记录（设备信息+环境信息）
  /// POST /app/saveVisitRecord
  @POST('/app/saveVisitRecord')
  Future<HttpResponse<dynamic>> saveVisitRecord(
    @Body() SaveVisitRecordRequest request,
  );

  /// 保存安装/卸载记录
  /// POST /app/saveInstalledRecord
  @POST('/app/saveInstalledRecord')
  Future<HttpResponse<dynamic>> saveInstalledRecord(
    @Body() SaveInstalledRecordRequest request,
  );
}
