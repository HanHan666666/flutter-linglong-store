// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PageParams _$PageParamsFromJson(Map<String, dynamic> json) => _PageParams(
  pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
  repoName: json['repoName'] as String? ?? AppConfig.defaultStoreRepoName,
  arch: json['arch'] as String?,
  lan: json['lan'] as String?,
  sort: json['sort'] as String?,
  order: json['order'] as String?,
);

Map<String, dynamic> _$PageParamsToJson(_PageParams instance) =>
    <String, dynamic>{
      'pageNo': instance.pageNo,
      'pageSize': instance.pageSize,
      'repoName': instance.repoName,
      'arch': instance.arch,
      'lan': instance.lan,
      'sort': instance.sort,
      'order': instance.order,
    };

_AppDetailsBO _$AppDetailsBOFromJson(Map<String, dynamic> json) =>
    _AppDetailsBO(
      appId: json['appId'] as String,
      name: json['name'] as String?,
      version: json['version'] as String?,
      channel: json['channel'] as String?,
      module: json['module'] as String?,
      arch: json['arch'] as String?,
    );

Map<String, dynamic> _$AppDetailsBOToJson(_AppDetailsBO instance) =>
    <String, dynamic>{
      'appId': instance.appId,
      'name': instance.name,
      'version': instance.version,
      'channel': instance.channel,
      'module': instance.module,
      'arch': instance.arch,
    };

_CategoryDTO _$CategoryDTOFromJson(Map<String, dynamic> json) => _CategoryDTO(
  categoryId: json['categoryId'] as String,
  categoryName: json['categoryName'] as String,
  categoryIcon: _readCategoryIcon(json, 'categoryIcon') as String?,
  appCount: (_readCategoryCount(json, 'appCount') as num?)?.toInt(),
  sort: (json['sort'] as num?)?.toInt(),
);

Map<String, dynamic> _$CategoryDTOToJson(_CategoryDTO instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'categoryIcon': instance.categoryIcon,
      'appCount': instance.appCount,
      'sort': instance.sort,
    };

_CategoryListResponse _$CategoryListResponseFromJson(
  Map<String, dynamic> json,
) => _CategoryListResponse(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>)
      .map((e) => CategoryDTO.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CategoryListResponseToJson(
  _CategoryListResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_AppDetailSearchBO _$AppDetailSearchBOFromJson(Map<String, dynamic> json) =>
    _AppDetailSearchBO(
      appId: json['appId'] as String,
      arch: json['arch'] as String,
      lang: json['lang'] as String?,
    );

Map<String, dynamic> _$AppDetailSearchBOToJson(_AppDetailSearchBO instance) =>
    <String, dynamic>{
      'appId': instance.appId,
      'arch': instance.arch,
      'lang': instance.lang,
    };

_AppCheckVersionBO _$AppCheckVersionBOFromJson(Map<String, dynamic> json) =>
    _AppCheckVersionBO(
      appId: json['appId'] as String,
      arch: json['arch'] as String,
      version: json['version'] as String,
    );

Map<String, dynamic> _$AppCheckVersionBOToJson(_AppCheckVersionBO instance) =>
    <String, dynamic>{
      'appId': instance.appId,
      'arch': instance.arch,
      'version': instance.version,
    };

_AppScreenshotDTO _$AppScreenshotDTOFromJson(Map<String, dynamic> json) =>
    _AppScreenshotDTO(
      screenshotUrl: json['screenshotKey'] as String,
      language: json['lan'] as String?,
    );

Map<String, dynamic> _$AppScreenshotDTOToJson(_AppScreenshotDTO instance) =>
    <String, dynamic>{
      'screenshotKey': instance.screenshotUrl,
      'lan': instance.language,
    };

_AppTagDTO _$AppTagDTOFromJson(Map<String, dynamic> json) =>
    _AppTagDTO(name: json['name'] as String, language: json['lan'] as String?);

Map<String, dynamic> _$AppTagDTOToJson(_AppTagDTO instance) =>
    <String, dynamic>{'name': instance.name, 'lan': instance.language};

_AppDetailDTO _$AppDetailDTOFromJson(Map<String, dynamic> json) =>
    _AppDetailDTO(
      appId: json['appId'] as String,
      appName: json['zhName'] as String,
      appVersion: json['version'] as String,
      appIcon: json['icon'] as String?,
      appDesc: json['description'] as String?,
      appKind: json['kind'] as String?,
      appRuntime: json['runtime'] as String?,
      appModule: json['module'] as String?,
      appBase: json['base'] as String?,
      arch: json['arch'] as String?,
      channel: json['channel'] as String?,
      developerName: json['devName'] as String?,
      categoryName: json['categoryName'] as String?,
      categoryId: json['categoryId'] as String?,
      downloadTimes: (json['installCount'] as num?)?.toInt(),
      packageSize: json['size'] as String?,
      screenshotList: (json['appScreenshotList'] as List<dynamic>?)
          ?.map((e) => AppScreenshotDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      tagList: (json['appTagList'] as List<dynamic>?)
          ?.map((e) => AppTagDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      detailDescription: json['descInfo'] as String?,
      repoName: json['repoName'] as String?,
      repoUrl: json['repoUrl'] as String?,
      homePage: json['homePage'] as String?,
      license: json['license'] as String?,
      releaseNote: json['releaseNote'] as String?,
    );

Map<String, dynamic> _$AppDetailDTOToJson(_AppDetailDTO instance) =>
    <String, dynamic>{
      'appId': instance.appId,
      'zhName': instance.appName,
      'version': instance.appVersion,
      'icon': instance.appIcon,
      'description': instance.appDesc,
      'kind': instance.appKind,
      'runtime': instance.appRuntime,
      'module': instance.appModule,
      'base': instance.appBase,
      'arch': instance.arch,
      'channel': instance.channel,
      'devName': instance.developerName,
      'categoryName': instance.categoryName,
      'categoryId': instance.categoryId,
      'installCount': instance.downloadTimes,
      'size': instance.packageSize,
      'appScreenshotList': instance.screenshotList,
      'appTagList': instance.tagList,
      'descInfo': instance.detailDescription,
      'repoName': instance.repoName,
      'repoUrl': instance.repoUrl,
      'homePage': instance.homePage,
      'license': instance.license,
      'releaseNote': instance.releaseNote,
    };

_AppDetailResponse _$AppDetailResponseFromJson(Map<String, dynamic> json) =>
    _AppDetailResponse(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AppDetailResponseToJson(_AppDetailResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_AppDetailMapResponse _$AppDetailMapResponseFromJson(
  Map<String, dynamic> json,
) => _AppDetailMapResponse(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String?,
  data: (json['data'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(
      k,
      (e as List<dynamic>)
          .map((e) => AppDetailDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  ),
);

Map<String, dynamic> _$AppDetailMapResponseToJson(
  _AppDetailMapResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_AppDetailListResponse _$AppDetailListResponseFromJson(
  Map<String, dynamic> json,
) => _AppDetailListResponse(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String?,
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => AppDetailDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$AppDetailListResponseToJson(
  _AppDetailListResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_AppListItemDTO _$AppListItemDTOFromJson(Map<String, dynamic> json) =>
    _AppListItemDTO(
      appId: json['appId'] as String,
      appName: _readAppName(json, 'appName') as String,
      appVersion: _readAppVersion(json, 'appVersion') as String?,
      appIcon: _readAppIcon(json, 'appIcon') as String?,
      appDesc: _readAppDescription(json, 'appDesc') as String?,
      appKind: _readAppKind(json, 'appKind') as String?,
      developerName: _readDeveloperName(json, 'developerName') as String?,
      categoryName: json['categoryName'] as String?,
      downloadTimes: (_readDownloadCount(json, 'downloadTimes') as num?)
          ?.toInt(),
      packageSize: _readPackageSize(json, 'packageSize') as String?,
    );

Map<String, dynamic> _$AppListItemDTOToJson(_AppListItemDTO instance) =>
    <String, dynamic>{
      'appId': instance.appId,
      'appName': instance.appName,
      'appVersion': instance.appVersion,
      'appIcon': instance.appIcon,
      'appDesc': instance.appDesc,
      'appKind': instance.appKind,
      'developerName': instance.developerName,
      'categoryName': instance.categoryName,
      'downloadTimes': instance.downloadTimes,
      'packageSize': instance.packageSize,
    };

_AppListPagedData _$AppListPagedDataFromJson(Map<String, dynamic> json) =>
    _AppListPagedData(
      records: (json['records'] as List<dynamic>)
          .map((e) => AppListItemDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      current: (json['current'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$AppListPagedDataToJson(_AppListPagedData instance) =>
    <String, dynamic>{
      'records': instance.records,
      'total': instance.total,
      'size': instance.size,
      'current': instance.current,
      'pages': instance.pages,
    };

_AppListResponse _$AppListResponseFromJson(Map<String, dynamic> json) =>
    _AppListResponse(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : AppListPagedData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppListResponseToJson(_AppListResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_AppListArrayResponse _$AppListArrayResponseFromJson(
  Map<String, dynamic> json,
) => _AppListArrayResponse(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String?,
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => AppListItemDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$AppListArrayResponseToJson(
  _AppListArrayResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_SearchAppListRequest _$SearchAppListRequestFromJson(
  Map<String, dynamic> json,
) => _SearchAppListRequest(
  keyword: json['name'] as String,
  pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
  repoName: json['repoName'] as String? ?? AppConfig.defaultStoreRepoName,
  arch: json['arch'] as String?,
  lan: json['lan'] as String?,
  sort: json['sort'] as String?,
  order: json['order'] as String?,
);

Map<String, dynamic> _$SearchAppListRequestToJson(
  _SearchAppListRequest instance,
) => <String, dynamic>{
  'name': instance.keyword,
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
  'repoName': instance.repoName,
  'arch': instance.arch,
  'lan': instance.lan,
  'sort': instance.sort,
  'order': instance.order,
};

_AppWelcomeSearchRequest _$AppWelcomeSearchRequestFromJson(
  Map<String, dynamic> json,
) => _AppWelcomeSearchRequest(
  appId: json['appId'] as String?,
  name: json['name'] as String?,
  repoName: json['repoName'] as String? ?? AppConfig.defaultStoreRepoName,
  arch: json['arch'] as String?,
  lan: json['lan'] as String? ?? AppConfig.defaultLocale,
  categoryId: json['categoryId'] as String?,
  pageNo: (json['pageNo'] as num?)?.toInt(),
  pageSize: (json['pageSize'] as num?)?.toInt(),
);

Map<String, dynamic> _$AppWelcomeSearchRequestToJson(
  _AppWelcomeSearchRequest instance,
) => <String, dynamic>{
  'appId': instance.appId,
  'name': instance.name,
  'repoName': instance.repoName,
  'arch': instance.arch,
  'lan': instance.lan,
  'categoryId': instance.categoryId,
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
};

_CarouselDTO _$CarouselDTOFromJson(Map<String, dynamic> json) => _CarouselDTO(
  carouselId: _readBannerId(json, 'carouselId') as String,
  carouselTitle: _readBannerTitle(json, 'carouselTitle') as String,
  carouselUrl: _readBannerTargetUrl(json, 'carouselUrl') as String?,
  carouselImage: _readBannerImage(json, 'carouselImage') as String,
  carouselDesc: _readBannerDescription(json, 'carouselDesc') as String?,
  sort: (json['sort'] as num?)?.toInt(),
);

Map<String, dynamic> _$CarouselDTOToJson(_CarouselDTO instance) =>
    <String, dynamic>{
      'carouselId': instance.carouselId,
      'carouselTitle': instance.carouselTitle,
      'carouselUrl': instance.carouselUrl,
      'carouselImage': instance.carouselImage,
      'carouselDesc': instance.carouselDesc,
      'sort': instance.sort,
    };

_CarouselListResponse _$CarouselListResponseFromJson(
  Map<String, dynamic> json,
) => _CarouselListResponse(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>)
      .map((e) => CarouselDTO.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CarouselListResponseToJson(
  _CarouselListResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_AppVersionListRequest _$AppVersionListRequestFromJson(
  Map<String, dynamic> json,
) => _AppVersionListRequest(
  appId: json['appId'] as String,
  repoName: json['repoName'] as String? ?? AppConfig.defaultStoreRepoName,
  arch: json['arch'] as String?,
  pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
);

Map<String, dynamic> _$AppVersionListRequestToJson(
  _AppVersionListRequest instance,
) => <String, dynamic>{
  'appId': instance.appId,
  'repoName': instance.repoName,
  'arch': instance.arch,
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
};

_AppVersionDTO _$AppVersionDTOFromJson(Map<String, dynamic> json) =>
    _AppVersionDTO(
      versionId: json['id'] as String?,
      versionNo: json['version'] as String,
      versionName: json['zhName'] as String?,
      description: json['description'] as String?,
      releaseTime: _readVersionReleaseTime(json, 'releaseTime') as String?,
      packageSize: json['size'] as String?,
      appId: json['appId'] as String?,
      icon: json['icon'] as String?,
      kind: json['kind'] as String?,
      module: json['module'] as String?,
      channel: json['channel'] as String?,
      arch: json['arch'] as String?,
      repoName: json['repoName'] as String?,
      installCount: (_readVersionInstallCount(json, 'installCount') as num?)
          ?.toInt(),
    );

Map<String, dynamic> _$AppVersionDTOToJson(_AppVersionDTO instance) =>
    <String, dynamic>{
      'id': instance.versionId,
      'version': instance.versionNo,
      'zhName': instance.versionName,
      'description': instance.description,
      'releaseTime': instance.releaseTime,
      'size': instance.packageSize,
      'appId': instance.appId,
      'icon': instance.icon,
      'kind': instance.kind,
      'module': instance.module,
      'channel': instance.channel,
      'arch': instance.arch,
      'repoName': instance.repoName,
      'installCount': instance.installCount,
    };

_VersionListResponse _$VersionListResponseFromJson(Map<String, dynamic> json) =>
    _VersionListResponse(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String?,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => AppVersionDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$VersionListResponseToJson(
  _VersionListResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_CheckUpdateResponse _$CheckUpdateResponseFromJson(Map<String, dynamic> json) =>
    _CheckUpdateResponse(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : AppUpdateInfoDTO.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CheckUpdateResponseToJson(
  _CheckUpdateResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_BatchCheckUpdateResponse _$BatchCheckUpdateResponseFromJson(
  Map<String, dynamic> json,
) => _BatchCheckUpdateResponse(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String?,
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => AppUpdateInfoDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$BatchCheckUpdateResponseToJson(
  _BatchCheckUpdateResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_AppUpdateInfoDTO _$AppUpdateInfoDTOFromJson(Map<String, dynamic> json) =>
    _AppUpdateInfoDTO(
      appId: json['appId'] as String,
      appName: json['appName'] as String,
      latestVersion: json['latestVersion'] as String,
      currentVersion: json['currentVersion'] as String?,
      releaseNote: json['releaseNote'] as String?,
      releaseTime: json['releaseTime'] as String?,
      packageSize: json['packageSize'] as String?,
      needUpdate: json['needUpdate'] as bool? ?? false,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
    );

Map<String, dynamic> _$AppUpdateInfoDTOToJson(_AppUpdateInfoDTO instance) =>
    <String, dynamic>{
      'appId': instance.appId,
      'appName': instance.appName,
      'latestVersion': instance.latestVersion,
      'currentVersion': instance.currentVersion,
      'releaseNote': instance.releaseNote,
      'releaseTime': instance.releaseTime,
      'packageSize': instance.packageSize,
      'needUpdate': instance.needUpdate,
      'forceUpdate': instance.forceUpdate,
    };

_SidebarMenuRuleDTO _$SidebarMenuRuleDTOFromJson(Map<String, dynamic> json) =>
    _SidebarMenuRuleDTO(
      sortBy: json['sortBy'] as String?,
      sortOrder: json['sortOrder'] as String?,
      filterMinScore: (json['filterMinScore'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SidebarMenuRuleDTOToJson(_SidebarMenuRuleDTO instance) =>
    <String, dynamic>{
      'sortBy': instance.sortBy,
      'sortOrder': instance.sortOrder,
      'filterMinScore': instance.filterMinScore,
    };

_SidebarMenuDTO _$SidebarMenuDTOFromJson(Map<String, dynamic> json) =>
    _SidebarMenuDTO(
      menuCode: json['code'] as String,
      menuName: json['name'] as String,
      menuIcon: json['icon'] as String?,
      activeMenuIcon: json['activeIcon'] as String?,
      sortOrder: (json['sortNo'] as num?)?.toInt(),
      enabled: json['enabled'] as bool? ?? true,
      categoryIds:
          (json['categoryIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      rule: json['rule'] == null
          ? null
          : SidebarMenuRuleDTO.fromJson(json['rule'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SidebarMenuDTOToJson(_SidebarMenuDTO instance) =>
    <String, dynamic>{
      'code': instance.menuCode,
      'name': instance.menuName,
      'icon': instance.menuIcon,
      'activeIcon': instance.activeMenuIcon,
      'sortNo': instance.sortOrder,
      'enabled': instance.enabled,
      'categoryIds': instance.categoryIds,
      'rule': instance.rule,
    };

_SidebarConfigResponse _$SidebarConfigResponseFromJson(
  Map<String, dynamic> json,
) => _SidebarConfigResponse(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : SidebarConfigDTO.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SidebarConfigResponseToJson(
  _SidebarConfigResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_SidebarConfigDTO _$SidebarConfigDTOFromJson(Map<String, dynamic> json) =>
    _SidebarConfigDTO(
      menus:
          (json['menus'] as List<dynamic>?)
              ?.map((e) => SidebarMenuDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SidebarConfigDTOToJson(_SidebarConfigDTO instance) =>
    <String, dynamic>{'menus': instance.menus};

_SidebarAppsRequest _$SidebarAppsRequestFromJson(Map<String, dynamic> json) =>
    _SidebarAppsRequest(
      menuCode: json['menuCode'] as String,
      pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      repoName: json['repoName'] as String? ?? AppConfig.defaultStoreRepoName,
      arch: json['arch'] as String?,
      lan: json['lan'] as String?,
      sortType: json['sortType'] as String?,
      filter: json['filter'] as bool?,
    );

Map<String, dynamic> _$SidebarAppsRequestToJson(_SidebarAppsRequest instance) =>
    <String, dynamic>{
      'menuCode': instance.menuCode,
      'pageNo': instance.pageNo,
      'pageSize': instance.pageSize,
      'repoName': instance.repoName,
      'arch': instance.arch,
      'lan': instance.lan,
      'sortType': instance.sortType,
      'filter': instance.filter,
    };

_CustomMenuCategoryDTO _$CustomMenuCategoryDTOFromJson(
  Map<String, dynamic> json,
) => _CustomMenuCategoryDTO(
  menuId: json['menuId'] as String,
  menuName: json['menuName'] as String,
  menuIcon: json['menuIcon'] as String?,
  categoryIds: (json['categoryIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  sort: (json['sort'] as num?)?.toInt(),
);

Map<String, dynamic> _$CustomMenuCategoryDTOToJson(
  _CustomMenuCategoryDTO instance,
) => <String, dynamic>{
  'menuId': instance.menuId,
  'menuName': instance.menuName,
  'menuIcon': instance.menuIcon,
  'categoryIds': instance.categoryIds,
  'sort': instance.sort,
};

_CustomMenuCategoryResponse _$CustomMenuCategoryResponseFromJson(
  Map<String, dynamic> json,
) => _CustomMenuCategoryResponse(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>)
      .map((e) => CustomMenuCategoryDTO.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CustomMenuCategoryResponseToJson(
  _CustomMenuCategoryResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_AppsByCategoryRequest _$AppsByCategoryRequestFromJson(
  Map<String, dynamic> json,
) => _AppsByCategoryRequest(
  categoryIds: (json['categoryIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
  repoName: json['repoName'] as String? ?? AppConfig.defaultStoreRepoName,
  arch: json['arch'] as String?,
  lan: json['lan'] as String?,
  sort: json['sort'] as String?,
  order: json['order'] as String?,
);

Map<String, dynamic> _$AppsByCategoryRequestToJson(
  _AppsByCategoryRequest instance,
) => <String, dynamic>{
  'categoryIds': instance.categoryIds,
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
  'repoName': instance.repoName,
  'arch': instance.arch,
  'lan': instance.lan,
  'sort': instance.sort,
  'order': instance.order,
};

_SaveVisitRecordRequest _$SaveVisitRecordRequestFromJson(
  Map<String, dynamic> json,
) => _SaveVisitRecordRequest(
  visitorId: json['visitorId'] as String?,
  clientIp: json['clientIp'] as String?,
  arch: json['arch'] as String?,
  llVersion: json['llVersion'] as String?,
  llBinVersion: json['llBinVersion'] as String?,
  detailMsg: json['detailMsg'] as String?,
  osVersion: json['osVersion'] as String?,
  repoName: json['repoName'] as String?,
  appVersion: json['appVersion'] as String?,
);

Map<String, dynamic> _$SaveVisitRecordRequestToJson(
  _SaveVisitRecordRequest instance,
) => <String, dynamic>{
  'visitorId': instance.visitorId,
  'clientIp': instance.clientIp,
  'arch': instance.arch,
  'llVersion': instance.llVersion,
  'llBinVersion': instance.llBinVersion,
  'detailMsg': instance.detailMsg,
  'osVersion': instance.osVersion,
  'repoName': instance.repoName,
  'appVersion': instance.appVersion,
};

_InstalledRecordItemDTO _$InstalledRecordItemDTOFromJson(
  Map<String, dynamic> json,
) => _InstalledRecordItemDTO(
  appId: json['appId'] as String?,
  name: json['name'] as String?,
  version: json['version'] as String?,
  arch: json['arch'] as String?,
  module: json['module'] as String?,
  channel: json['channel'] as String?,
);

Map<String, dynamic> _$InstalledRecordItemDTOToJson(
  _InstalledRecordItemDTO instance,
) => <String, dynamic>{
  'appId': instance.appId,
  'name': instance.name,
  'version': instance.version,
  'arch': instance.arch,
  'module': instance.module,
  'channel': instance.channel,
};

_SaveInstalledRecordRequest _$SaveInstalledRecordRequestFromJson(
  Map<String, dynamic> json,
) => _SaveInstalledRecordRequest(
  visitorId: json['visitorId'] as String?,
  clientIp: json['clientIp'] as String?,
  addedItems:
      (json['addedItems'] as List<dynamic>?)
          ?.map(
            (e) => InstalledRecordItemDTO.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  removedItems:
      (json['removedItems'] as List<dynamic>?)
          ?.map(
            (e) => InstalledRecordItemDTO.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$SaveInstalledRecordRequestToJson(
  _SaveInstalledRecordRequest instance,
) => <String, dynamic>{
  'visitorId': instance.visitorId,
  'clientIp': instance.clientIp,
  'addedItems': instance.addedItems,
  'removedItems': instance.removedItems,
};
