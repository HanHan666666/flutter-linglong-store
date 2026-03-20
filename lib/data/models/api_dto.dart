import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/config/app_config.dart';

part 'api_dto.freezed.dart';
part 'api_dto.g.dart';

Object? _readFirstNonNull(Map<dynamic, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) {
      return value;
    }
  }
  return null;
}

int? _toIntValue(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

Object? _readCategoryIcon(Map json, String _) =>
    _readFirstNonNull(json, ['icon', 'categoryIcon']);

Object? _readCategoryCount(Map json, String _) =>
    _toIntValue(_readFirstNonNull(json, ['count']));

Object? _readAppName(Map json, String _) =>
    _readFirstNonNull(json, ['zhName', 'appName', 'name']);

Object? _readAppVersion(Map json, String _) =>
    _readFirstNonNull(json, ['version', 'appVersion']);

Object? _readAppIcon(Map json, String _) =>
    _readFirstNonNull(json, ['icon', 'appIcon']);

Object? _readAppDescription(Map json, String _) =>
    _readFirstNonNull(json, ['description', 'appDesc']);

Object? _readAppKind(Map json, String _) =>
    _readFirstNonNull(json, ['kind', 'appKind']);

Object? _readDeveloperName(Map json, String _) =>
    _readFirstNonNull(json, ['devName', 'developerName']);

Object? _readDownloadCount(Map json, String _) =>
    _toIntValue(_readFirstNonNull(json, ['installCount', 'downloadTimes']));

Object? _readPackageSize(Map json, String _) =>
    _readFirstNonNull(json, ['size', 'packageSize']);

Object? _readVersionReleaseTime(Map json, String _) =>
    _readFirstNonNull(json, ['createTime', 'updateTime']);

Object? _readVersionInstallCount(Map json, String _) =>
    _toIntValue(_readFirstNonNull(json, ['installCount']));

Object? _readBannerId(Map json, String _) =>
    _readFirstNonNull(json, ['appId', 'carouselId']);

Object? _readBannerTitle(Map json, String _) =>
    _readFirstNonNull(json, ['zhName', 'name', 'carouselTitle']);

Object? _readBannerImage(Map json, String _) =>
    _readFirstNonNull(json, ['icon', 'carouselImage']);

Object? _readBannerTargetUrl(Map json, String _) =>
    _readFirstNonNull(json, ['carouselUrl']);

Object? _readBannerDescription(Map json, String _) =>
    _readFirstNonNull(json, ['description', 'carouselDesc']);

// ============== 通用分页请求参数 ==============

/// 分页请求参数
@freezed
sealed class PageParams with _$PageParams {
  const factory PageParams({
    @JsonKey(name: 'pageNo') @Default(1) int pageNo,
    @JsonKey(name: 'pageSize') @Default(20) int pageSize,
    @JsonKey(name: 'repoName')
    @Default(AppConfig.defaultStoreRepoName)
    String repoName,
    String? arch,
    String? lan,
    String? sort,
    String? order,
  }) = _PageParams;

  factory PageParams.fromJson(Map<String, dynamic> json) =>
      _$PageParamsFromJson(json);
}

// ============== 分类相关 ==============

/// 应用详情请求 - 批量获取应用基础信息
/// 对应后端 AppDetailsBO，用于 getAppDetails 接口
@freezed
sealed class AppDetailsBO with _$AppDetailsBO {
  const factory AppDetailsBO({
    @JsonKey(name: 'appId') required String appId,
    String? name,
    String? version,
    String? channel,
    String? module,
    String? arch,
  }) = _AppDetailsBO;

  factory AppDetailsBO.fromJson(Map<String, dynamic> json) =>
      _$AppDetailsBOFromJson(json);
}

/// 分类项 DTO
@freezed
sealed class CategoryDTO with _$CategoryDTO {
  const factory CategoryDTO({
    @JsonKey(name: 'categoryId') required String categoryId,
    @JsonKey(name: 'categoryName') required String categoryName,
    @JsonKey(readValue: _readCategoryIcon) String? categoryIcon,
    @JsonKey(readValue: _readCategoryCount) int? appCount,
    @JsonKey(name: 'sort') int? sort,
  }) = _CategoryDTO;

  factory CategoryDTO.fromJson(Map<String, dynamic> json) =>
      _$CategoryDTOFromJson(json);
}

/// 分类列表响应
@freezed
sealed class CategoryListResponse with _$CategoryListResponse {
  const factory CategoryListResponse({
    required int code,
    String? message,
    required List<CategoryDTO> data,
  }) = _CategoryListResponse;

  factory CategoryListResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoryListResponseFromJson(json);
}

// ============== 应用详情相关 ==============

/// 应用详情请求 - 批量
@freezed
sealed class AppDetailSearchBO with _$AppDetailSearchBO {
  const factory AppDetailSearchBO({
    required String appId,
    required String arch,
    // /app/getAppDetail 会按语言精确过滤截图和标签，必须显式传入 lang。
    String? lang,
  }) = _AppDetailSearchBO;

  factory AppDetailSearchBO.fromJson(Map<String, dynamic> json) =>
      _$AppDetailSearchBOFromJson(json);
}

/// 检查更新请求
@freezed
sealed class AppCheckVersionBO with _$AppCheckVersionBO {
  const factory AppCheckVersionBO({
    required String appId,
    required String arch,
    required String version,
  }) = _AppCheckVersionBO;

  factory AppCheckVersionBO.fromJson(Map<String, dynamic> json) =>
      _$AppCheckVersionBOFromJson(json);
}

/// 应用截图 DTO
@freezed
sealed class AppScreenshotDTO with _$AppScreenshotDTO {
  const factory AppScreenshotDTO({
    @JsonKey(name: 'screenshotKey') required String screenshotUrl,
    @JsonKey(name: 'lan') String? language,
  }) = _AppScreenshotDTO;

  factory AppScreenshotDTO.fromJson(Map<String, dynamic> json) =>
      _$AppScreenshotDTOFromJson(json);
}

/// 应用标签 DTO
@freezed
sealed class AppTagDTO with _$AppTagDTO {
  const factory AppTagDTO({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'lan') String? language,
  }) = _AppTagDTO;

  factory AppTagDTO.fromJson(Map<String, dynamic> json) =>
      _$AppTagDTOFromJson(json);
}

/// 应用详情 DTO
///
/// 注意：后端返回的详情包含截图列表、标签列表等额外信息
@freezed
sealed class AppDetailDTO with _$AppDetailDTO {
  const factory AppDetailDTO({
    @JsonKey(name: 'appId') required String appId,
    @JsonKey(name: 'zhName') required String appName,
    @JsonKey(name: 'version') required String appVersion,
    @JsonKey(name: 'icon') String? appIcon,
    @JsonKey(name: 'description') String? appDesc,
    @JsonKey(name: 'kind') String? appKind,
    @JsonKey(name: 'runtime') String? appRuntime,
    @JsonKey(name: 'module') String? appModule,
    @JsonKey(name: 'base') String? appBase,
    String? arch,
    String? channel,
    @JsonKey(name: 'devName') String? developerName,
    @JsonKey(name: 'categoryName') String? categoryName,
    @JsonKey(name: 'categoryId') String? categoryId,
    @JsonKey(name: 'installCount') int? downloadTimes,
    @JsonKey(name: 'size') String? packageSize,
    @JsonKey(name: 'appScreenshotList') List<AppScreenshotDTO>? screenshotList,
    @JsonKey(name: 'appTagList') List<AppTagDTO>? tagList,
    @JsonKey(name: 'descInfo') String? detailDescription,
    @JsonKey(name: 'repoName') String? repoName,
    @JsonKey(name: 'repoUrl') String? repoUrl,
    @JsonKey(name: 'homePage') String? homePage,
    @JsonKey(name: 'license') String? license,
    @JsonKey(name: 'releaseNote') String? releaseNote,
  }) = _AppDetailDTO;

  factory AppDetailDTO.fromJson(Map<String, dynamic> json) =>
      _$AppDetailDTOFromJson(json);
}

/// 应用详情响应
///
/// 注意：后端返回的数据结构是 Map<String, List<AppDetailDTO>>
/// 其中 key 是 appId，value 是该应用的详情列表（可能包含多个版本）
@freezed
sealed class AppDetailResponse with _$AppDetailResponse {
  const factory AppDetailResponse({
    required int code,
    String? message,

    /// 后端返回 Map<String, List<AppDetailDTO>> 格式
    /// 使用 dynamic 以支持自动解析
    Map<String, dynamic>? data,
  }) = _AppDetailResponse;

  factory AppDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$AppDetailResponseFromJson(json);
}

/// 应用详情列表响应
///
/// 用于 getAppDetail 接口，后端返回 Map<String, List<AppDetailDTO>>
@freezed
sealed class AppDetailMapResponse with _$AppDetailMapResponse {
  const factory AppDetailMapResponse({
    required int code,
    String? message,
    Map<String, List<AppDetailDTO>>? data,
  }) = _AppDetailMapResponse;

  factory AppDetailMapResponse.fromJson(Map<String, dynamic> json) =>
      _$AppDetailMapResponseFromJson(json);
}

/// 应用详情列表响应（用于检查更新等接口）
@freezed
sealed class AppDetailListResponse with _$AppDetailListResponse {
  const factory AppDetailListResponse({
    required int code,
    String? message,
    @Default([]) List<AppDetailDTO> data,
  }) = _AppDetailListResponse;

  factory AppDetailListResponse.fromJson(Map<String, dynamic> json) =>
      _$AppDetailListResponseFromJson(json);
}

// ============== 应用列表相关 ==============

/// 应用列表项 DTO
@freezed
sealed class AppListItemDTO with _$AppListItemDTO {
  const factory AppListItemDTO({
    @JsonKey(name: 'appId') required String appId,
    @JsonKey(readValue: _readAppName) required String appName,
    @JsonKey(readValue: _readAppVersion) String? appVersion,
    @JsonKey(readValue: _readAppIcon) String? appIcon,
    @JsonKey(readValue: _readAppDescription) String? appDesc,
    @JsonKey(readValue: _readAppKind) String? appKind,
    @JsonKey(readValue: _readDeveloperName) String? developerName,
    @JsonKey(name: 'categoryName') String? categoryName,
    @JsonKey(readValue: _readDownloadCount) int? downloadTimes,
    @JsonKey(readValue: _readPackageSize) String? packageSize,
  }) = _AppListItemDTO;

  factory AppListItemDTO.fromJson(Map<String, dynamic> json) =>
      _$AppListItemDTOFromJson(json);
}

/// 应用列表分页数据
@freezed
sealed class AppListPagedData with _$AppListPagedData {
  const factory AppListPagedData({
    required List<AppListItemDTO> records,
    required int total,
    @JsonKey(name: 'size') required int size,
    @JsonKey(name: 'current') required int current,
    required int pages,
  }) = _AppListPagedData;

  factory AppListPagedData.fromJson(Map<String, dynamic> json) =>
      _$AppListPagedDataFromJson(json);
}

/// 应用列表响应
@freezed
sealed class AppListResponse with _$AppListResponse {
  const factory AppListResponse({
    required int code,
    String? message,
    AppListPagedData? data,
  }) = _AppListResponse;

  factory AppListResponse.fromJson(Map<String, dynamic> json) =>
      _$AppListResponseFromJson(json);
}

/// 应用列表数组响应
///
/// 用于 `/visit/getAppDetails`、`/visit/getWelcomeCarouselList` 这类直接返回
/// `List<AppMainDto>` 的接口。和分页响应拆开建模，避免把数组误当成 records 分页结构。
@freezed
sealed class AppListArrayResponse with _$AppListArrayResponse {
  const factory AppListArrayResponse({
    required int code,
    String? message,
    @Default([]) List<AppListItemDTO> data,
  }) = _AppListArrayResponse;

  factory AppListArrayResponse.fromJson(Map<String, dynamic> json) =>
      _$AppListArrayResponseFromJson(json);
}

// ============== 搜索相关 ==============

/// 搜索请求
///
/// 注意：后端期望的字段名是 `name` 而不是 `keyword`
@freezed
sealed class SearchAppListRequest with _$SearchAppListRequest {
  const factory SearchAppListRequest({
    /// 搜索关键词，后端字段名为 `name`
    @JsonKey(name: 'name') required String keyword,
    @JsonKey(name: 'pageNo') @Default(1) int pageNo,
    @JsonKey(name: 'pageSize') @Default(20) int pageSize,
    @JsonKey(name: 'repoName')
    @Default(AppConfig.defaultStoreRepoName)
    String repoName,
    String? arch,
    String? lan,
    String? sort,
    String? order,
  }) = _SearchAppListRequest;

  factory SearchAppListRequest.fromJson(Map<String, dynamic> json) =>
      _$SearchAppListRequestFromJson(json);
}

// ============== 轮播图相关 ==============

@freezed
sealed class AppWelcomeSearchRequest with _$AppWelcomeSearchRequest {
  const factory AppWelcomeSearchRequest({
    String? appId,
    String? name,
    @JsonKey(name: 'repoName')
    @Default(AppConfig.defaultStoreRepoName)
    String repoName,
    String? arch,
    String? lan,
    String? categoryId,
    @JsonKey(name: 'pageNo') int? pageNo,
    @JsonKey(name: 'pageSize') int? pageSize,
  }) = _AppWelcomeSearchRequest;

  factory AppWelcomeSearchRequest.fromJson(Map<String, dynamic> json) =>
      _$AppWelcomeSearchRequestFromJson(json);
}

// ============== 轮播图相关 ==============

/// 轮播图 DTO
@freezed
sealed class CarouselDTO with _$CarouselDTO {
  const factory CarouselDTO({
    @JsonKey(readValue: _readBannerId) required String carouselId,
    @JsonKey(readValue: _readBannerTitle) required String carouselTitle,
    @JsonKey(readValue: _readBannerTargetUrl) String? carouselUrl,
    @JsonKey(readValue: _readBannerImage) required String carouselImage,
    @JsonKey(readValue: _readBannerDescription) String? carouselDesc,
    @JsonKey(name: 'sort') int? sort,
  }) = _CarouselDTO;

  factory CarouselDTO.fromJson(Map<String, dynamic> json) =>
      _$CarouselDTOFromJson(json);
}

/// 轮播图列表响应
@freezed
sealed class CarouselListResponse with _$CarouselListResponse {
  const factory CarouselListResponse({
    required int code,
    String? message,
    required List<CarouselDTO> data,
  }) = _CarouselListResponse;

  factory CarouselListResponse.fromJson(Map<String, dynamic> json) =>
      _$CarouselListResponseFromJson(json);
}

// ============== 版本相关 ==============

/// 应用版本列表请求
/// 用于 getSearchAppVersionList 接口
@freezed
sealed class AppVersionListRequest with _$AppVersionListRequest {
  const factory AppVersionListRequest({
    @JsonKey(name: 'appId') required String appId,
    @JsonKey(name: 'repoName')
    @Default(AppConfig.defaultStoreRepoName)
    String repoName,
    String? arch,
    @JsonKey(name: 'pageNo') @Default(1) int pageNo,
    @JsonKey(name: 'pageSize') @Default(20) int pageSize,
    String? lan,
  }) = _AppVersionListRequest;

  factory AppVersionListRequest.fromJson(Map<String, dynamic> json) =>
      _$AppVersionListRequestFromJson(json);
}

/// 应用版本 DTO
///
/// 注意：后端返回的是 AppMainDto，字段与普通应用相同
/// 版本信息通过 version、size、updateTime 等字段表示
@freezed
sealed class AppVersionDTO with _$AppVersionDTO {
  const factory AppVersionDTO({
    @JsonKey(name: 'id') String? versionId,
    @JsonKey(name: 'version') required String versionNo,
    @JsonKey(name: 'zhName') String? versionName,
    String? description,
    @JsonKey(readValue: _readVersionReleaseTime) String? releaseTime,
    @JsonKey(name: 'size') String? packageSize,
    String? appId,
    String? icon,
    String? kind,
    String? module,
    String? channel,
    String? arch,
    @JsonKey(name: 'repoName') String? repoName,
    @JsonKey(readValue: _readVersionInstallCount) int? installCount,
  }) = _AppVersionDTO;

  factory AppVersionDTO.fromJson(Map<String, dynamic> json) =>
      _$AppVersionDTOFromJson(json);
}

/// 版本列表响应
///
/// 注意：后端返回的是 `Result<List<AppMainDto>>`
/// `data` 字段是直接的数组，不是分页对象
@freezed
sealed class VersionListResponse with _$VersionListResponse {
  const factory VersionListResponse({
    required int code,
    String? message,
    @Default([]) List<AppVersionDTO> data,
  }) = _VersionListResponse;

  factory VersionListResponse.fromJson(Map<String, dynamic> json) =>
      _$VersionListResponseFromJson(json);
}

// ============== 检查更新相关 ==============

/// 检查更新响应
@freezed
sealed class CheckUpdateResponse with _$CheckUpdateResponse {
  const factory CheckUpdateResponse({
    required int code,
    String? message,
    AppUpdateInfoDTO? data,
  }) = _CheckUpdateResponse;

  factory CheckUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckUpdateResponseFromJson(json);
}

/// 批量检查更新响应
@freezed
sealed class BatchCheckUpdateResponse with _$BatchCheckUpdateResponse {
  const factory BatchCheckUpdateResponse({
    required int code,
    String? message,
    @Default([]) List<AppUpdateInfoDTO> data,
  }) = _BatchCheckUpdateResponse;

  factory BatchCheckUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$BatchCheckUpdateResponseFromJson(json);
}

/// 更新信息 DTO
@freezed
sealed class AppUpdateInfoDTO with _$AppUpdateInfoDTO {
  const factory AppUpdateInfoDTO({
    @JsonKey(name: 'appId') required String appId,
    @JsonKey(name: 'appName') required String appName,
    @JsonKey(name: 'latestVersion') required String latestVersion,
    @JsonKey(name: 'currentVersion') String? currentVersion,
    @JsonKey(name: 'releaseNote') String? releaseNote,
    @JsonKey(name: 'releaseTime') String? releaseTime,
    @JsonKey(name: 'packageSize') String? packageSize,
    @JsonKey(name: 'needUpdate') @Default(false) bool needUpdate,
    @JsonKey(name: 'forceUpdate') @Default(false) bool forceUpdate,
  }) = _AppUpdateInfoDTO;

  factory AppUpdateInfoDTO.fromJson(Map<String, dynamic> json) =>
      _$AppUpdateInfoDTOFromJson(json);
}

// ============== 自定义菜单分类相关 ==============

/// 侧边栏菜单规则 DTO
@freezed
sealed class SidebarMenuRuleDTO with _$SidebarMenuRuleDTO {
  const factory SidebarMenuRuleDTO({
    @JsonKey(name: 'sortBy') String? sortBy,
    @JsonKey(name: 'sortOrder') String? sortOrder,
    @JsonKey(name: 'filterMinScore') int? filterMinScore,
  }) = _SidebarMenuRuleDTO;

  factory SidebarMenuRuleDTO.fromJson(Map<String, dynamic> json) =>
      _$SidebarMenuRuleDTOFromJson(json);
}

/// 侧边栏菜单项 DTO
@freezed
sealed class SidebarMenuDTO with _$SidebarMenuDTO {
  const factory SidebarMenuDTO({
    @JsonKey(name: 'code') required String menuCode,
    @JsonKey(name: 'name') required String menuName,
    @JsonKey(name: 'icon') String? menuIcon,
    @JsonKey(name: 'activeIcon') String? activeMenuIcon,
    @JsonKey(name: 'sortNo') int? sortOrder,
    @JsonKey(name: 'enabled') @Default(true) bool enabled,
    @JsonKey(name: 'categoryIds') @Default([]) List<String> categoryIds,
    @JsonKey(name: 'rule') SidebarMenuRuleDTO? rule,
  }) = _SidebarMenuDTO;

  factory SidebarMenuDTO.fromJson(Map<String, dynamic> json) =>
      _$SidebarMenuDTOFromJson(json);
}

/// 侧边栏配置响应
@freezed
sealed class SidebarConfigResponse with _$SidebarConfigResponse {
  const factory SidebarConfigResponse({
    required int code,
    String? message,
    SidebarConfigDTO? data,
  }) = _SidebarConfigResponse;

  factory SidebarConfigResponse.fromJson(Map<String, dynamic> json) =>
      _$SidebarConfigResponseFromJson(json);
}

/// 侧边栏配置数据
@freezed
sealed class SidebarConfigDTO with _$SidebarConfigDTO {
  const factory SidebarConfigDTO({
    @JsonKey(name: 'menus') @Default([]) List<SidebarMenuDTO> menus,
  }) = _SidebarConfigDTO;

  factory SidebarConfigDTO.fromJson(Map<String, dynamic> json) =>
      _$SidebarConfigDTOFromJson(json);
}

/// 侧边栏应用列表请求
@freezed
sealed class SidebarAppsRequest with _$SidebarAppsRequest {
  const factory SidebarAppsRequest({
    @JsonKey(name: 'menuCode') required String menuCode,
    @JsonKey(name: 'pageNo') @Default(1) int pageNo,
    @JsonKey(name: 'pageSize') @Default(20) int pageSize,
    @JsonKey(name: 'repoName')
    @Default(AppConfig.defaultStoreRepoName)
    String repoName,
    String? arch,
    String? lan,
    @JsonKey(name: 'sortType') String? sortType,
    @JsonKey(name: 'filter') bool? filter,
  }) = _SidebarAppsRequest;

  factory SidebarAppsRequest.fromJson(Map<String, dynamic> json) =>
      _$SidebarAppsRequestFromJson(json);
}

/// 自定义分类菜单 DTO（保留旧接口兼容）
@freezed
sealed class CustomMenuCategoryDTO with _$CustomMenuCategoryDTO {
  const factory CustomMenuCategoryDTO({
    @JsonKey(name: 'menuId') required String menuId,
    @JsonKey(name: 'menuName') required String menuName,
    @JsonKey(name: 'menuIcon') String? menuIcon,
    @JsonKey(name: 'categoryIds') required List<String> categoryIds,
    @JsonKey(name: 'sort') int? sort,
  }) = _CustomMenuCategoryDTO;

  factory CustomMenuCategoryDTO.fromJson(Map<String, dynamic> json) =>
      _$CustomMenuCategoryDTOFromJson(json);
}

/// 自定义分类菜单响应
@freezed
sealed class CustomMenuCategoryResponse with _$CustomMenuCategoryResponse {
  const factory CustomMenuCategoryResponse({
    required int code,
    String? message,
    required List<CustomMenuCategoryDTO> data,
  }) = _CustomMenuCategoryResponse;

  factory CustomMenuCategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomMenuCategoryResponseFromJson(json);
}

/// 按分类ID获取应用请求
@freezed
sealed class AppsByCategoryRequest with _$AppsByCategoryRequest {
  const factory AppsByCategoryRequest({
    @JsonKey(name: 'categoryIds') required List<String> categoryIds,
    @JsonKey(name: 'pageNo') @Default(1) int pageNo,
    @JsonKey(name: 'pageSize') @Default(20) int pageSize,
    @JsonKey(name: 'repoName')
    @Default(AppConfig.defaultStoreRepoName)
    String repoName,
    String? arch,
    String? lan,
    String? sort,
    String? order,
  }) = _AppsByCategoryRequest;

  factory AppsByCategoryRequest.fromJson(Map<String, dynamic> json) =>
      _$AppsByCategoryRequestFromJson(json);
}

// ============================================================
// 匿名统计上报相关 DTO
// ============================================================

/// 启动访问记录请求体
///
/// POST /app/saveVisitRecord
@freezed
sealed class SaveVisitRecordRequest with _$SaveVisitRecordRequest {
  const factory SaveVisitRecordRequest({
    @JsonKey(name: 'visitorId') String? visitorId,
    @JsonKey(name: 'clientIp') String? clientIp,
    @JsonKey(name: 'arch') String? arch,
    @JsonKey(name: 'llVersion') String? llVersion,
    @JsonKey(name: 'llBinVersion') String? llBinVersion,
    @JsonKey(name: 'detailMsg') String? detailMsg,
    @JsonKey(name: 'osVersion') String? osVersion,
    @JsonKey(name: 'repoName') String? repoName,
    @JsonKey(name: 'appVersion') String? appVersion,
  }) = _SaveVisitRecordRequest;

  factory SaveVisitRecordRequest.fromJson(Map<String, dynamic> json) =>
      _$SaveVisitRecordRequestFromJson(json);
}

/// 安装/卸载记录中的单条应用信息
@freezed
sealed class InstalledRecordItemDTO with _$InstalledRecordItemDTO {
  const factory InstalledRecordItemDTO({
    @JsonKey(name: 'appId') String? appId,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'version') String? version,
    @JsonKey(name: 'arch') String? arch,
    @JsonKey(name: 'module') String? module,
    @JsonKey(name: 'channel') String? channel,
  }) = _InstalledRecordItemDTO;

  factory InstalledRecordItemDTO.fromJson(Map<String, dynamic> json) =>
      _$InstalledRecordItemDTOFromJson(json);
}

/// 安装/卸载记录请求体
///
/// POST /app/saveInstalledRecord
/// addedItems: 新装应用；removedItems: 卸载应用
@freezed
sealed class SaveInstalledRecordRequest with _$SaveInstalledRecordRequest {
  const factory SaveInstalledRecordRequest({
    @JsonKey(name: 'visitorId') String? visitorId,
    @JsonKey(name: 'clientIp') String? clientIp,
    @JsonKey(name: 'addedItems')
    @Default([])
    List<InstalledRecordItemDTO> addedItems,
    @JsonKey(name: 'removedItems')
    @Default([])
    List<InstalledRecordItemDTO> removedItems,
  }) = _SaveInstalledRecordRequest;

  factory SaveInstalledRecordRequest.fromJson(Map<String, dynamic> json) =>
      _$SaveInstalledRecordRequestFromJson(json);
}
