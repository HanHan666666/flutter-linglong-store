import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/recommend_models.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/api_dto.dart';
import 'api_provider.dart';

part 'recommend_provider.g.dart';

/// 推荐页状态 Provider
@riverpod
class Recommend extends _$Recommend {
  @override
  RecommendState build() {
    // 初始化时加载数据
    Future.microtask(() => loadData());
    return const RecommendState();
  }

  /// 加载初始数据
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(appApiServiceProvider);

      // 轮播接口在新后端上已改为必须携带请求体，且失败时不应拖垮首页主体
      List<BannerInfo> banners = const [];
      try {
        final carouselResponse = await apiService.getWelcomeCarouselList(
          const AppWelcomeSearchRequest(),
        );
        banners = _convertBanners(carouselResponse.data.data);
      } catch (e, s) {
        AppLogger.warning('加载轮播数据失败，降级为空轮播', e, s);
      }

      final categoryResponse = await apiService.getDisCategoryList();
      final appResponse = await apiService.getWelcomeAppList(
        const PageParams(pageNo: 1, pageSize: 20),
      );

      // 解析分类
      final categories = _convertCategories(categoryResponse.data.data);

      // 解析推荐应用
      final apps = _convertApps(appResponse.data.data);

      state = state.copyWith(
        isLoading: false,
        data: RecommendData(
          banners: banners,
          categories: categories,
          apps: apps,
        ),
        currentPage: 1,
      );
    } catch (e, s) {
      AppLogger.error('加载推荐数据失败', e, s);
      state = state.copyWith(isLoading: false, error: presentAppError(e));
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadData();
  }

  /// 加载更多应用
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.data?.apps.hasMore == false) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final apiService = ref.read(appApiServiceProvider);
      final nextPage = state.currentPage + 1;

      final response = await apiService.getWelcomeAppList(
        PageParams(pageNo: nextPage, pageSize: 20),
      );

      final currentApps = state.data?.apps.items ?? [];
      final newApps = _convertApps(response.data.data);
      final mergedApps = <RecommendAppInfo>[...currentApps, ...newApps.items];

      state = state.copyWith(
        isLoadingMore: false,
        currentPage: nextPage,
        data: state.data?.copyWith(
          apps: PaginatedResponse<RecommendAppInfo>(
            items: mergedApps,
            total: newApps.total,
            page: nextPage,
            pageSize: 20,
            hasMore: newApps.hasMore,
          ),
        ),
      );
    } catch (e, s) {
      AppLogger.error('加载更多推荐应用失败', e, s);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// 选择分类
  void selectCategory(int index) {
    if (index == state.selectedCategoryIndex) return;

    state = state.copyWith(selectedCategoryIndex: index);
    // 切换分类时重新加载数据
    loadData();
  }

  /// 转换轮播图数据
  ///
  /// 注意：后端返回的是应用列表（AppMainDto），不是专门的轮播图结构
  /// 我们将应用图标作为轮播图，应用ID作为目标
  List<BannerInfo> _convertBanners(List<AppListItemDTO> dtos) {
    if (dtos.isEmpty) return const [];

    return dtos
        .map(
          (dto) => BannerInfo(
            id: dto.appId,
            title: dto.appName,
            imageUrl: dto.appIcon ?? '',
            targetAppId: dto.appId,
            targetUrl: null,
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

  /// 转换分类数据
  List<CategoryInfo> _convertCategories(List<CategoryDTO> dtos) {
    // 添加"全部"分类
    final categories = <CategoryInfo>[
      const CategoryInfo(code: 'all', name: '全部', appCount: 0),
    ];

    categories.addAll(
      dtos.map(
        (dto) => CategoryInfo(
          code: dto.categoryId,
          name: dto.categoryName,
          icon: dto.categoryIcon,
          appCount: dto.appCount ?? 0,
        ),
      ),
    );

    return categories;
  }

  /// 转换应用列表数据
  PaginatedResponse<RecommendAppInfo> _convertApps(AppListPagedData? data) {
    if (data == null) {
      return const PaginatedResponse<RecommendAppInfo>(
        items: [],
        total: 0,
        page: 1,
        pageSize: 20,
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
