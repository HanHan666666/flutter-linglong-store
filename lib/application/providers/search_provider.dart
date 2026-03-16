import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/recommend_models.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/api_dto.dart';
import 'api_provider.dart';
import 'global_provider.dart';

part 'search_provider.freezed.dart';
part 'search_provider.g.dart';

/// 搜索状态
@freezed
sealed class SearchState with _$SearchState {
  const factory SearchState({
    /// 搜索关键词
    required String query,

    /// 搜索结果
    required List<RecommendAppInfo> results,

    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 是否正在加载更多
    @Default(false) bool isLoadingMore,

    /// 错误信息
    String? error,

    /// 当前页码
    @Default(1) int currentPage,

    /// 是否还有更多数据
    @Default(true) bool hasMore,

    /// 总结果数
    @Default(0) int total,
  }) = _SearchState;
}

/// 搜索 Provider
@riverpod
class Search extends _$Search {
  @override
  SearchState build() {
    return const SearchState(query: '', results: []);
  }

  /// 获取当前架构
  String get _arch => ref.read(globalAppProvider).arch ?? 'x86_64';

  /// 搜索应用
  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState(query: '', results: []);
      return;
    }

    // 设置加载状态，保留搜索关键词
    state = SearchState(
      query: query,
      results: const [],
      isLoading: true,
      currentPage: 1,
      hasMore: true,
    );

    try {
      final apiService = ref.read(appApiServiceProvider);

      final response = await apiService.getSearchAppList(
        SearchAppListRequest(
          keyword: query,
          pageNo: 1,
          pageSize: 20,
          arch: _arch,
        ),
      );

      final results = _convertApps(response.data.data);

      state = state.copyWith(
        isLoading: false,
        results: results.items,
        total: results.total,
        currentPage: 1,
        hasMore: results.hasMore,
      );
    } catch (e, s) {
      AppLogger.error('搜索应用失败: $query', e, s);
      state = state.copyWith(isLoading: false, error: presentAppError(e));
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.query.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final apiService = ref.read(appApiServiceProvider);
      final nextPage = state.currentPage + 1;

      final response = await apiService.getSearchAppList(
        SearchAppListRequest(
          keyword: state.query,
          pageNo: nextPage,
          pageSize: 20,
          arch: _arch,
        ),
      );

      final newResults = _convertApps(response.data.data);

      state = state.copyWith(
        isLoadingMore: false,
        results: [...state.results, ...newResults.items],
        currentPage: nextPage,
        hasMore: newResults.hasMore,
        total: newResults.total,
      );
    } catch (e, s) {
      AppLogger.error('加载更多搜索结果失败', e, s);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// 清空搜索
  void clear() {
    state = const SearchState(query: '', results: []);
  }

  /// 刷新搜索
  Future<void> refresh() async {
    await search(state.query);
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
