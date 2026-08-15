import '../../core/utils/brief_text.dart';
import '../../data/models/api_dto.dart';
import '../../domain/models/recommend_models.dart';

/// 将后端 `AppListPagedData` 映射为前端统一的 `PaginatedResponse<RecommendAppInfo>`。
///
/// [data] 为后端返回的分页应用列表原始数据；[pageSize] 为当前页的默认分页大小。
PaginatedResponse<RecommendAppInfo> mapAppListToRecommendApps(
  AppListPagedData? data, {
  required int pageSize,
}) {
  if (data == null) {
    return PaginatedResponse<RecommendAppInfo>(
      items: const [],
      total: 0,
      page: 1,
      pageSize: pageSize,
      hasMore: false,
    );
  }

  final apps = data.records
      .map(
        (dto) => RecommendAppInfo(
          appId: dto.appId,
          name: dto.appName,
          version: dto.appVersion ?? '',
          // 简要描述超长时截断，避免列表常驻整串长文本（卡片仅展示单行）
          description: truncateBriefDescription(dto.appDesc),
          icon: dto.appIcon,
          developer: dto.developerName,
          category: dto.categoryName,
          size: dto.packageSize,
          arch: dto.arch,
          // 搜索结果进入详情时必须保留后端返回的真实条目身份。
          module: dto.module,
          // 搜索结果进入详情时必须保留后端返回的真实条目身份。
          repoName: dto.repoName,
          downloadCount: dto.downloadTimes,
        ),
      )
      .toList();

  return PaginatedResponse<RecommendAppInfo>(
    items: apps,
    total: data.total,
    page: data.current,
    pageSize: data.size,
    hasMore: data.current < data.pages,
  );
}
