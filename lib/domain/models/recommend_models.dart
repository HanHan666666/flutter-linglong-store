import 'package:freezed_annotation/freezed_annotation.dart';

import 'installed_app.dart';

part 'recommend_models.freezed.dart';

/// 轮播图信息
@freezed
sealed class BannerInfo with _$BannerInfo {
  const factory BannerInfo({
    required String id,
    required String title,
    required String imageUrl,
    @Default('') String version,
    String? arch,
    String? targetAppId,
    String? targetUrl,
    String? description,
  }) = _BannerInfo;
}

extension BannerInfoInstalledAppX on BannerInfo {
  InstalledApp toInstalledApp() {
    return InstalledApp(
      appId: targetAppId ?? id,
      name: title,
      version: version,
      arch: arch,
      description: description,
      icon: imageUrl,
    );
  }
}

/// 分类信息
@freezed
sealed class CategoryInfo with _$CategoryInfo {
  const factory CategoryInfo({
    required String code,
    required String name,
    String? icon,
    int? appCount,
  }) = _CategoryInfo;
}

/// 推荐应用信息
@freezed
sealed class RecommendAppInfo with _$RecommendAppInfo {
  const factory RecommendAppInfo({
    required String appId,
    required String name,
    required String version,
    String? description,
    String? icon,
    String? developer,
    String? category,
    String? size,
    String? arch,
    double? rating,
    int? downloadCount,
    @Default(false) bool isInstalled,
    @Default(false) bool hasUpdate,
  }) = _RecommendAppInfo;
}

extension RecommendAppInfoInstalledAppX on RecommendAppInfo {
  InstalledApp toInstalledApp() {
    return InstalledApp(
      appId: appId,
      name: name,
      version: version,
      arch: arch,
      description: description,
      icon: icon,
      size: size,
    );
  }
}

/// 分页响应 - 用于推荐应用列表
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
}

/// 推荐页数据
class RecommendData {
  const RecommendData({
    required this.banners,
    required this.categories,
    required this.apps,
  });

  final List<BannerInfo> banners;
  final List<CategoryInfo> categories;
  final PaginatedResponse<RecommendAppInfo> apps;

  /// 创建副本
  RecommendData copyWith({
    List<BannerInfo>? banners,
    List<CategoryInfo>? categories,
    PaginatedResponse<RecommendAppInfo>? apps,
  }) {
    return RecommendData(
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      apps: apps ?? this.apps,
    );
  }
}

/// 推荐页状态
@freezed
sealed class RecommendState with _$RecommendState {
  const factory RecommendState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasHydratedFromCache,
    String? error,
    RecommendData? data,
    @Default(1) int currentPage,
  }) = _RecommendState;
}
