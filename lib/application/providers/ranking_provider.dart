import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import '../../domain/models/ranking_models.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/brief_text.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/api_dto.dart';
import 'api_provider.dart';
import 'global_provider.dart';

part 'ranking_provider.g.dart';

/// 排行榜分页大小。
///
/// 旧版一次拉 100 条导致首屏请求体积与卡片渲染量偏大；改为 30 条 + 触底
/// 加载，滚动加载体验与其它列表页保持一致。
const int _rankingPageSize = 30;

/// 单个排行榜类型的缓存数据
class _RankingTypeCache {
  const _RankingTypeCache({
    this.data,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasLoadedOnce = false,
    this.hasMore = false,
    this.currentPage = 1,
  });

  final RankingData? data;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasLoadedOnce;
  final bool hasMore;
  final int currentPage;

  _RankingTypeCache copyWith({
    RankingData? data,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasLoadedOnce,
  }) {
    return _RankingTypeCache(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      hasMore: hasMore,
      currentPage: currentPage,
    );
  }
}

/// 排行榜状态 Provider
@riverpod
class Ranking extends _$Ranking {
  /// 为每个 RankingType 分别缓存数据，切换 Tab 时立即展示旧数据。
  final Map<RankingType, _RankingTypeCache> _typeCaches = {
    for (final type in RankingType.values) type: const _RankingTypeCache(),
  };

  String get _arch => resolveRequestArch(ref);

  @override
  RankingState build() {
    // 初始化时加载数据
    Future.microtask(() => loadData());
    return const RankingState();
  }

  /// 加载数据（首页）
  Future<void> loadData() async {
    final type = state.selectedType;
    final cache = _typeCaches[type]!;

    // 标记加载中，但保留旧数据供 UI 展示
    _typeCaches[type] = cache.copyWith(isLoading: true, error: null);
    _syncStateToCurrentType();

    try {
      final page = await _fetchRankingPage(type, 1);

      _typeCaches[type] = _RankingTypeCache(
        data: RankingData(type: type, apps: page.apps),
        hasLoadedOnce: true,
        hasMore: page.hasMore,
        currentPage: 1,
      );
      _syncStateToCurrentType();
    } catch (e, s) {
      AppLogger.error('加载排行榜数据失败', e, s);
      _typeCaches[type] = _RankingTypeCache(
        data: cache.data,
        isLoading: false,
        error: presentAppError(e),
        hasLoadedOnce: cache.hasLoadedOnce || cache.data != null,
        hasMore: cache.hasMore,
        currentPage: cache.currentPage,
      );
      _syncStateToCurrentType();
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadData();
  }

  /// 加载更多（触底分页）
  Future<void> loadMore() async {
    final type = state.selectedType;
    final cache = _typeCaches[type]!;
    if (cache.isLoading ||
        cache.isLoadingMore ||
        !cache.hasMore ||
        cache.data == null) {
      return;
    }

    // 与其它列表一致的内存上限保护：触顶后终止自动补页
    if (cache.data!.apps.length >= AppConfig.maxListItems) {
      _typeCaches[type] = _RankingTypeCache(
        data: cache.data,
        hasLoadedOnce: true,
        hasMore: false,
        currentPage: cache.currentPage,
      );
      _syncStateToCurrentType();
      return;
    }

    _typeCaches[type] = cache.copyWith(isLoadingMore: true);
    _syncStateToCurrentType();

    try {
      final nextPageNo = cache.currentPage + 1;
      // 名次从已加载条数继续编号，保证跨页名次连续
      final page = await _fetchRankingPage(
        type,
        nextPageNo,
        rankOffset: cache.data!.apps.length,
      );
      final merged = [...cache.data!.apps, ...page.apps];

      _typeCaches[type] = _RankingTypeCache(
        data: RankingData(type: type, apps: merged),
        hasLoadedOnce: true,
        hasMore: page.hasMore && merged.length < AppConfig.maxListItems,
        currentPage: nextPageNo,
      );
      _syncStateToCurrentType();
    } catch (e, s) {
      AppLogger.error('加载更多排行榜数据失败', e, s);
      _typeCaches[type] = _typeCaches[type]!.copyWith(isLoadingMore: false);
      _syncStateToCurrentType();
    }
  }

  /// 切换排行榜类型
  ///
  /// 一次性合并 selectedType + 缓存数据到 state，避免多次赋值触发不必要的重建。
  Future<void> selectType(RankingType type) async {
    if (type == state.selectedType) return;

    // 从缓存中取出目标类型的旧数据，与 selectedType 一起一次性写入
    final cache = _typeCaches[type]!;
    _applyCacheToState(type, cache);

    // 后台刷新新类型的数据
    await loadData();
  }

  /// 将当前选中类型的缓存同步到 RankingState
  void _syncStateToCurrentType() {
    final type = state.selectedType;
    _applyCacheToState(type, _typeCaches[type]!);
  }

  void _applyCacheToState(RankingType type, _RankingTypeCache cache) {
    state = RankingState(
      isLoading: cache.isLoading,
      isLoadingMore: cache.isLoadingMore,
      error: cache.error,
      data: cache.data,
      hasMore: cache.hasMore,
      currentPage: cache.currentPage,
      selectedType: type,
    );
  }

  /// 获取指定页的排行榜应用
  ///
  /// [rankOffset] 为名次起始偏移（触底加载时从已加载条数继续编号）。
  Future<({List<RankingAppInfo> apps, bool hasMore})> _fetchRankingPage(
    RankingType type,
    int pageNo, {
    int rankOffset = 0,
  }) async {
    final apiService = ref.read(appApiServiceProvider);

    final response = await switch (type) {
      RankingType.download => apiService.getInstallAppList(
        PageParams(pageNo: pageNo, pageSize: _rankingPageSize, arch: _arch),
      ),
      RankingType.rising => apiService.getNewAppList(
        PageParams(pageNo: pageNo, pageSize: _rankingPageSize, arch: _arch),
      ),
    };

    final paged = response.data.data;
    return (
      apps: _convertToRankingApps(paged, type, rankOffset: rankOffset),
      hasMore: paged != null && paged.current < paged.pages,
    );
  }

  /// 转换为排行榜应用列表
  List<RankingAppInfo> _convertToRankingApps(
    AppListPagedData? data,
    RankingType type, {
    int rankOffset = 0,
  }) {
    if (data == null) return [];

    return data.records.asMap().entries.map((entry) {
      final index = entry.key;
      final dto = entry.value;
      final rank = rankOffset + index + 1;

      return RankingAppInfo(
        appId: dto.appId,
        name: dto.appName,
        version: dto.appVersion ?? '',
        // 简要描述超长时截断，避免排行榜常驻整串长文本（卡片仅展示单行）
        description: truncateBriefDescription(dto.appDesc),
        icon: dto.appIcon,
        developer: dto.developerName,
        category: dto.categoryName,
        size: dto.packageSize,
        arch: dto.arch,
        downloadCount: dto.downloadTimes, // 总安装次数（对应后端的 installCount）
        createTime: dto.createTime,        // 上架时间
        rank: rank,
      );
    }).toList();
  }
}
