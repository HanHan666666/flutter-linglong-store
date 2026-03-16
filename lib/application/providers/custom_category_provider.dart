import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/recommend_models.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/api_dto.dart';
import 'api_provider.dart';

part 'custom_category_provider.freezed.dart';
part 'custom_category_provider.g.dart';

/// 自定义分类页状态 Provider
@riverpod
class CustomCategory extends _$CustomCategory {
  String _categoryCode = '';

  @override
  CustomCategoryState build() {
    return const CustomCategoryState();
  }

  /// 初始化分类
  void initCategory(String code) {
    if (_categoryCode == code) return;
    _categoryCode = code;
    loadData();
  }

  /// 加载数据
  Future<void> loadData() async {
    if (_categoryCode.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(appApiServiceProvider);

      // 获取侧边栏配置
      final menuResponse = await apiService.getSidebarConfig();
      final categoryInfo = _findCategoryInfo(
        menuResponse.data.data?.menus ?? [],
        _categoryCode,
      );

      // 使用侧边栏应用接口获取应用
      final appsResponse = await apiService.getSidebarApps(
        SidebarAppsRequest(
          menuCode: _categoryCode,
          pageNo: 1,
          pageSize: 20,
        ),
      );

      final apps = _convertApps(appsResponse.data.data);

      state = state.copyWith(
        isLoading: false,
        data: CustomCategoryData(categoryInfo: categoryInfo, apps: apps),
        currentPage: 1,
        categoryCode: _categoryCode,
      );
    } catch (e, s) {
      AppLogger.error('加载自定义分类数据失败', e, s);
      state = state.copyWith(isLoading: false, error: presentAppError(e));
    }
  }

  /// 从配置中查找分类信息
  CategoryInfo _findCategoryInfo(
    List<SidebarMenuDTO> menus,
    String code,
  ) {
    for (final menu in menus) {
      if (menu.menuCode == code) {
        return CategoryInfo(
          code: menu.menuCode,
          name: menu.menuName,
          icon: menu.menuIcon,
          appCount: menu.categoryIds.length,
        );
      }
    }

    // 未找到时返回默认
    return CategoryInfo(code: code, name: '未知分类', appCount: 0);
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

      final response = await apiService.getSidebarApps(
        SidebarAppsRequest(
          menuCode: _categoryCode,
          pageNo: nextPage,
          pageSize: 20,
        ),
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
      AppLogger.error('加载更多分类应用失败', e, s);
      state = state.copyWith(isLoadingMore: false);
    }
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

/// 自定义分类页数据
class CustomCategoryData {
  const CustomCategoryData({required this.categoryInfo, required this.apps});

  final CategoryInfo categoryInfo;
  final PaginatedResponse<RecommendAppInfo> apps;

  /// 创建副本
  CustomCategoryData copyWith({
    CategoryInfo? categoryInfo,
    PaginatedResponse<RecommendAppInfo>? apps,
  }) {
    return CustomCategoryData(
      categoryInfo: categoryInfo ?? this.categoryInfo,
      apps: apps ?? this.apps,
    );
  }
}

/// 自定义分类页状态
@freezed
sealed class CustomCategoryState with _$CustomCategoryState {
  const factory CustomCategoryState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    String? error,
    CustomCategoryData? data,
    @Default('') String categoryCode,
    @Default(1) int currentPage,
  }) = _CustomCategoryState;
}
