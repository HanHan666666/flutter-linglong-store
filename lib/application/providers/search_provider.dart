import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/mappers/app_list_mapper.dart';
import '../../domain/models/app_detail.dart';
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
  const SearchState._();

  const factory SearchState({
    /// 搜索关键词（普通文本搜索模式使用）
    required String query,

    /// 标签搜索条件（标签模式使用；与 query 互斥，标签模式下 query 为空）
    AppTag? tag,

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

  /// 是否存在有效的搜索条件（文本关键词或标签二选一）
  bool get hasCriteria => query.isNotEmpty || tag != null;
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

  /// 按当前状态构造分页请求
  ///
  /// 设计原因：文本搜索与标签搜索共用分页状态机，统一的请求构造器保证
  /// loadMore/refresh 始终携带正确的查询维度（keyword 或 tagName+tagLan），
  /// 避免标签分页时丢失标签身份或混入普通关键词。
  SearchAppListRequest _buildRequest(int page) {
    return SearchAppListRequest(
      keyword: state.query,
      tagName: state.tag?.name,
      tagLan: state.tag?.language,
      pageNo: page,
      pageSize: 20,
      arch: _arch,
      // 标签搜索时按标签语言筛选，普通文本搜索时由上层决定 lan
      lan: state.tag?.language,
    );
  }

  /// 搜索应用（普通文本搜索模式）
  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState(query: '', results: []);
      return;
    }

    // 设置加载状态，清除标签条件（文本与标签互斥）
    state = SearchState(
      query: query,
      results: const [],
      isLoading: true,
      currentPage: 1,
      hasMore: true,
    );

    try {
      final apiService = ref.read(appApiServiceProvider);

      final response = await apiService.getSearchAppList(_buildRequest(1));

      final results = mapAppListToRecommendApps(
        response.data.data,
        pageSize: 20,
      );

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

  /// 按标签搜索应用（标签搜索模式）
  ///
  /// 标签模式与文本模式互斥：进入标签模式时清空 query，只发送 tagName+tagLan。
  Future<void> searchByTag(AppTag tag) async {
    // 设置加载状态，清除文本关键词，记录标签条件
    state = SearchState(
      query: '',
      tag: tag,
      results: const [],
      isLoading: true,
      currentPage: 1,
      hasMore: true,
    );

    try {
      final apiService = ref.read(appApiServiceProvider);

      final response = await apiService.getSearchAppList(_buildRequest(1));

      final results = mapAppListToRecommendApps(
        response.data.data,
        pageSize: 20,
      );

      state = state.copyWith(
        isLoading: false,
        results: results.items,
        total: results.total,
        currentPage: 1,
        hasMore: results.hasMore,
      );
    } catch (e, s) {
      AppLogger.error('按标签搜索应用失败: ${tag.name}', e, s);
      state = state.copyWith(isLoading: false, error: presentAppError(e));
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    // 文本与标签模式都允许分页，只在没有有效条件时阻断
    if (state.isLoadingMore || !state.hasMore || !state.hasCriteria) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final apiService = ref.read(appApiServiceProvider);
      final nextPage = state.currentPage + 1;

      final response = await apiService.getSearchAppList(_buildRequest(nextPage));

      final newResults = mapAppListToRecommendApps(
        response.data.data,
        pageSize: 20,
      );

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
  ///
  /// 根据当前模式（标签或文本）分别复用对应入口，确保刷新后查询维度不变。
  Future<void> refresh() async {
    if (state.tag != null) {
      await searchByTag(state.tag!);
    } else {
      await search(state.query);
    }
  }
}
