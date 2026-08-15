import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/storage/recommend_page_cache.dart';
import '../../core/utils/locale_utils.dart';
import '../../data/mappers/app_list_mapper.dart';
import '../../data/models/api_dto.dart';
import '../../domain/models/recommend_models.dart';
import 'api_provider.dart';
import 'global_provider.dart';

part 'recommend_provider.g.dart';

/// 推荐页状态 Provider
@riverpod
class Recommend extends _$Recommend {
  // 首页首屏请求提升到 30 条，减少首次进入时依赖自动补页才能铺满内容区。
  static const int _pageSize = 30;

  String get _arch => resolveRequestArch(ref);
  // 推荐页缓存必须同时按语言和架构分片，避免不同架构的快照互相污染。
  String get _cacheScope =>
      '${resolveApiLang(ApiClient.getLocale?.call())}|$_arch';

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
            arch: _arch,
            lan: resolveApiLang(ApiClient.getLocale?.call()),
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
          arch: _arch,
          lan: resolveApiLang(ApiClient.getLocale?.call()),
        ),
      );
      final apps = mapAppListToRecommendApps(appResponse.data.data, pageSize: _pageSize);
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

    // 达到列表内存上限：置 hasMore=false 终止自动补页（页面常驻 IndexedStack，
    // 无限累积会让多份全量列表同时驻留内存），更深的检索应走搜索/分类。
    if (state.data!.apps.items.length >= AppConfig.maxListItems) {
      final apps = state.data!.apps;
      state = state.copyWith(
        data: state.data!.copyWith(
          apps: PaginatedResponse<RecommendAppInfo>(
            items: apps.items,
            total: apps.total,
            page: apps.page,
            pageSize: apps.pageSize,
            hasMore: false,
          ),
        ),
      );
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
          arch: _arch,
          lan: resolveApiLang(ApiClient.getLocale?.call()),
        ),
      );

      final currentApps = state.data!.apps.items;
      final newApps = mapAppListToRecommendApps(response.data.data, pageSize: _pageSize);
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
      // 快照只服务于下次启动的首屏水合，仅由 loadData 写入第一页；
      // 翻页合并结果若反复整表落盘，写入量会随翻页深度呈 O(n²) 增长。
    } catch (e, s) {
      AppLogger.error('加载更多推荐应用失败', e, s);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _hydrateFromCacheIfPresent() async {
    final cacheStore = ref.read(recommendPageCacheStoreProvider);
    final snapshot = await cacheStore.read(_cacheScope);
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
      _cacheScope,
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
            version: dto.appVersion ?? '',
            arch: dto.arch,
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
}
