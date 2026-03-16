import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/recommend_models.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/api_dto.dart';
import 'api_provider.dart';

part 'all_apps_provider.freezed.dart';
part 'all_apps_provider.g.dart';

/// 全部应用页数据
class AllAppsData {
  const AllAppsData({required this.categories, required this.apps});

  final List<CategoryInfo> categories;
  final PaginatedResponse<RecommendAppInfo> apps;

  /// 创建副本
  AllAppsData copyWith({
    List<CategoryInfo>? categories,
    PaginatedResponse<RecommendAppInfo>? apps,
  }) {
    return AllAppsData(
      categories: categories ?? this.categories,
      apps: apps ?? this.apps,
    );
  }
}

/// 全部应用页状态
@freezed
sealed class AllAppsState with _$AllAppsState {
  const factory AllAppsState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    String? error,
    AllAppsData? data,
    @Default(0) int selectedCategoryIndex,
    @Default(1) int currentPage,
  }) = _AllAppsState;
}

/// 全部应用页状态 Provider
@riverpod
class AllApps extends _$AllApps {
  @override
  AllAppsState build() {
    // 初始化时加载数据
    Future.microtask(() => loadData());
    return const AllAppsState();
  }

  /// 加载初始数据
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(appApiServiceProvider);

      // 获取选中的分类
      final categoryCode = _getSelectedCategoryCode();

      // 获取分类列表
      final categoryResponse = await apiService.getDisCategoryList();
      final categories = _convertCategories(categoryResponse.data.data);

      // 获取应用列表
      final apps = await _fetchApps(1, categoryCode);

      state = state.copyWith(
        isLoading: false,
        data: AllAppsData(categories: categories, apps: apps),
        currentPage: 1,
      );
    } catch (e, s) {
      AppLogger.error('加载全部应用数据失败', e, s);
      state = state.copyWith(isLoading: false, error: presentAppError(e));
    }
  }

  /// 获取选中的分类代码
  String? _getSelectedCategoryCode() {
    final categories = state.data?.categories ?? [];
    if (categories.isEmpty || state.selectedCategoryIndex == 0) {
      return null; // 全部分类
    }
    if (state.selectedCategoryIndex < categories.length) {
      return categories[state.selectedCategoryIndex].code;
    }
    return null;
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
      final nextPage = state.currentPage + 1;
      final categoryCode = _getSelectedCategoryCode();
      final newApps = await _fetchApps(nextPage, categoryCode);

      final currentApps = state.data?.apps.items ?? [];
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
      AppLogger.error('加载更多应用失败', e, s);
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

  /// 获取应用列表
  Future<PaginatedResponse<RecommendAppInfo>> _fetchApps(
    int page,
    String? categoryCode,
  ) async {
    final apiService = ref.read(appApiServiceProvider);

    // 如果选择了分类，使用侧边栏应用接口
    if (categoryCode != null && categoryCode != 'all') {
      final response = await apiService.getSidebarApps(
        SidebarAppsRequest(
          menuCode: categoryCode,
          pageNo: page,
          pageSize: 20,
        ),
      );
      return _convertApps(response.data.data);
    }

    // 全部分类：使用推荐应用接口
    final response = await apiService.getWelcomeAppList(
      PageParams(pageNo: page, pageSize: 20),
    );
    return _convertApps(response.data.data);
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
