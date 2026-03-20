import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/storage/recommend_page_cache.dart';
import '../../data/models/api_dto.dart';
import '../../domain/models/recommend_models.dart';
import 'api_provider.dart';

part 'recommend_provider.g.dart';

/// 推荐页状态 Provider
@riverpod
class Recommend extends _$Recommend {
  static const int _pageSize = 10;

  /// 将 Flutter locale 归一成后端约定的语言值（zh_CN / en_US）
  static String _resolveApiLang(String? locale) {
    final norm = locale?.trim().replaceAll('-', '_').toLowerCase();
    if (norm == null || norm.isEmpty) return 'zh_CN';
    if (norm.startsWith('en')) return 'en_US';
    return 'zh_CN';
  }

  @override
  RecommendState build() {
    Future.microtask(loadData);
    return const RecommendState();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    await _hydrateFromCacheIfPresent();

    try {
      final apiService = ref.read(appApiServiceProvider);
      final cachedData = state.data;

      List<BannerInfo> banners = cachedData?.banners ?? const [];
      try {
        final carouselResponse = await apiService.getWelcomeCarouselList(
          AppWelcomeSearchRequest(
            lan: _resolveApiLang(ApiClient.getLocale?.call()),
          ),
        );
        banners = _convertBanners(carouselResponse.data.data);
      } catch (e, s) {
        AppLogger.warning('加载轮播数据失败，降级为缓存或空轮播', e, s);
      }

      final appResponse = await apiService.getWelcomeAppList(
        PageParams(
          pageNo: 1,
          pageSize: _pageSize,
          lan: _resolveApiLang(ApiClient.getLocale?.call()),
        ),
      );
      final apps = _convertApps(appResponse.data.data);
      final data = RecommendData(
        banners: banners,
        categories: const [],
        apps: apps,
      );

      state = state.copyWith(
        isLoading: false,
        error: null,
        data: data,
        currentPage: 1,
      );
      await _persistSnapshot(data: data, currentPage: 1);
    } catch (e, s) {
      AppLogger.error('加载推荐数据失败', e, s);
      if (state.data != null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      state = state.copyWith(isLoading: false, error: presentAppError(e));
    }
  }

  Future<void> refresh() async {
    await loadData();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        state.data == null ||
        !state.data!.apps.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final apiService = ref.read(appApiServiceProvider);
      final nextPage = state.currentPage + 1;
      final response = await apiService.getWelcomeAppList(
        PageParams(
          pageNo: nextPage,
          pageSize: _pageSize,
          lan: _resolveApiLang(ApiClient.getLocale?.call()),
        ),
      );

      final currentApps = state.data!.apps.items;
      final newApps = _convertApps(response.data.data);
      final mergedApps = <RecommendAppInfo>[...currentApps, ...newApps.items];
      final mergedData = state.data!.copyWith(
        apps: PaginatedResponse<RecommendAppInfo>(
          items: mergedApps,
          total: newApps.total,
          page: nextPage,
          pageSize: _pageSize,
          hasMore: newApps.hasMore,
        ),
      );

      state = state.copyWith(
        isLoadingMore: false,
        currentPage: nextPage,
        data: mergedData,
      );
      await _persistSnapshot(data: mergedData, currentPage: nextPage);
    } catch (e, s) {
      AppLogger.error('加载更多推荐应用失败', e, s);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _hydrateFromCacheIfPresent() async {
    final cacheStore = ref.read(recommendPageCacheStoreProvider);
    final snapshot = await cacheStore.read();
    if (snapshot == null) {
      return;
    }

    state = state.copyWith(
      data: RecommendData(
        banners: snapshot.banners,
        categories: const [],
        apps: snapshot.apps,
      ),
      currentPage: snapshot.currentPage,
      hasHydratedFromCache: true,
    );
  }

  Future<void> _persistSnapshot({
    required RecommendData data,
    required int currentPage,
  }) async {
    final cacheStore = ref.read(recommendPageCacheStoreProvider);
    await cacheStore.write(
      RecommendPageCacheSnapshot(
        banners: data.banners,
        apps: data.apps,
        currentPage: currentPage,
      ),
    );
  }

  List<BannerInfo> _convertBanners(List<AppListItemDTO> dtos) {
    if (dtos.isEmpty) {
      return const [];
    }

    return dtos
        .map(
          (dto) => BannerInfo(
            id: dto.appId,
            title: dto.appName,
            imageUrl: dto.appIcon ?? '',
            targetAppId: dto.appId,
            description: dto.appDesc,
          ),
        )
        .where(
          (banner) =>
              banner.id.isNotEmpty &&
              banner.title.isNotEmpty &&
              banner.imageUrl.isNotEmpty,
        )
        .toList();
  }

  PaginatedResponse<RecommendAppInfo> _convertApps(AppListPagedData? data) {
    if (data == null) {
      return const PaginatedResponse<RecommendAppInfo>(
        items: [],
        total: 0,
        page: 1,
        pageSize: _pageSize,
        hasMore: false,
      );
    }

    final apps = data.records
        .map(
          (dto) => RecommendAppInfo(
            appId: dto.appId,
            name: dto.appName,
            version: dto.appVersion ?? '',
            description: dto.appDesc,
            icon: dto.appIcon,
            developer: dto.developerName,
            category: dto.categoryName,
            size: dto.packageSize,
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
}
