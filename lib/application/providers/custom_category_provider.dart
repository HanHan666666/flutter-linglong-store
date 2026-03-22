import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/api_dto.dart';
import '../../domain/models/recommend_models.dart';
import 'api_provider.dart';
import 'sidebar_config_provider.dart';
import '../../core/config/local_sidebar_menu_catalog.dart';

part 'custom_category_provider.freezed.dart';
part 'custom_category_provider.g.dart';

const int _customCategoryPageSize = 30;

/// 自定义分类页状态 Provider
@riverpod
class CustomCategory extends _$CustomCategory {
  bool _didScheduleInitialLoad = false;
  // 来自侧边栏菜单 rule 的排序/过滤规则，在 loadData 时提取并复用
  String? _sortType;
  bool? _filter;

  /// 将 Flutter locale 归一成后端约定的语言值（zh_CN / en_US）
  static String _resolveApiLang(String? locale) {
    final norm = locale?.trim().replaceAll('-', '_').toLowerCase();
    if (norm == null || norm.isEmpty) return 'zh_CN';
    if (norm.startsWith('en')) return 'en_US';
    return 'zh_CN';
  }

  @override
  CustomCategoryState build(String code) {
    ref.listen<AsyncValue<List<SidebarMenuDTO>>>(sidebarConfigProvider, (
      previous,
      next,
    ) {
      if (previous == null || state.isLoading) return;
      if (next.hasValue) {
        Future.microtask(loadData);
      }
    });

    if (!_didScheduleInitialLoad) {
      _didScheduleInitialLoad = true;
      Future.microtask(loadData);
    }

    return CustomCategoryState(isLoading: true, categoryCode: code);
  }

  /// 加载数据
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(appApiServiceProvider);

      final menus = await ref.read(sidebarConfigProvider.future);
      final menu = menus.where((m) => m.menuCode == code).firstOrNull;
      _sortType = menu?.rule?.sortBy;
      final minScore = menu?.rule?.filterMinScore ?? 0;
      _filter = minScore > 0 ? true : null;

      // 使用侧边栏应用接口获取应用
      final appsResponse = await apiService.getSidebarApps(
        SidebarAppsRequest(
          menuCode: code,
          pageNo: 1,
          pageSize: _customCategoryPageSize,
          sortType: _sortType,
          filter: _filter,
          lan: _resolveApiLang(ApiClient.getLocale?.call()),
        ),
      );

      final apps = _convertApps(appsResponse.data.data);
      final categoryInfo = _buildCategoryInfo(menu, apps.total);

      state = state.copyWith(
        isLoading: false,
        data: CustomCategoryData(categoryInfo: categoryInfo, apps: apps),
        currentPage: 1,
        categoryCode: code,
      );
    } catch (e, s) {
      AppLogger.error('加载自定义分类数据失败', e, s);
      state = state.copyWith(isLoading: false, error: presentAppError(e));
    }
  }

  /// 根据菜单配置和真实分页总数构建分类头部信息
  CategoryInfo _buildCategoryInfo(SidebarMenuDTO? menu, int total) {
    final locale = resolveSidebarMenuLocale(ApiClient.getLocale?.call());
    if (menu != null) {
      return CategoryInfo(
        code: menu.menuCode,
        name: resolveSidebarMenuLabel(
          menuCode: menu.menuCode,
          locale: locale,
          fallbackName: menu.menuName,
        ),
        icon: menu.menuIcon,
        appCount: total,
      );
    }

    // 未找到时返回默认
    return CategoryInfo(code: code, name: code, appCount: total);
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadData();
  }

  /// 加载更多应用
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || state.data?.apps.hasMore == false) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final apiService = ref.read(appApiServiceProvider);
      final nextPage = state.currentPage + 1;

      final response = await apiService.getSidebarApps(
        SidebarAppsRequest(
          menuCode: code,
          pageNo: nextPage,
          pageSize: _customCategoryPageSize,
          sortType: _sortType,
          filter: _filter,
          lan: _resolveApiLang(ApiClient.getLocale?.call()),
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
            pageSize: _customCategoryPageSize,
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
        pageSize: _customCategoryPageSize,
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
