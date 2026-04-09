import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/ranking_models.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/api_dto.dart';
import 'api_provider.dart';

part 'ranking_provider.g.dart';

/// 单个排行榜类型的缓存数据
class _RankingTypeCache {
  const _RankingTypeCache({
    this.data,
    this.isLoading = false,
    this.error,
    this.hasLoadedOnce = false,
  });

  final RankingData? data;
  final bool isLoading;
  final String? error;
  final bool hasLoadedOnce;

  _RankingTypeCache copyWith({
    RankingData? data,
    bool? isLoading,
    String? error,
    bool? hasLoadedOnce,
  }) {
    return _RankingTypeCache(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
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

  @override
  RankingState build() {
    // 初始化时加载数据
    Future.microtask(() => loadData());
    return const RankingState();
  }

  /// 加载数据
  Future<void> loadData() async {
    final type = state.selectedType;
    final cache = _typeCaches[type]!;

    // 标记加载中，但保留旧数据供 UI 展示
    _typeCaches[type] = cache.copyWith(isLoading: true, error: null);
    _syncStateToCurrentType();

    try {
      final apps = await _fetchRankingApps(type);
      final data = RankingData(type: type, apps: apps);

      _typeCaches[type] = cache.copyWith(
        isLoading: false,
        data: data,
        hasLoadedOnce: true,
      );
      _syncStateToCurrentType();
    } catch (e, s) {
      AppLogger.error('加载排行榜数据失败', e, s);
      _typeCaches[type] = cache.copyWith(
        isLoading: false,
        error: presentAppError(e),
        hasLoadedOnce: cache.hasLoadedOnce || cache.data != null,
      );
      _syncStateToCurrentType();
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadData();
  }

  /// 切换排行榜类型
  Future<void> selectType(RankingType type) async {
    if (type == state.selectedType) return;

    // 立即切换 selectedType，UI 先展示该类型的旧缓存数据
    state = state.copyWith(selectedType: type);
    _syncStateToCurrentType();

    // 后台刷新新类型的数据
    await loadData();
  }

  /// 将当前选中类型的缓存同步到 RankingState
  void _syncStateToCurrentType() {
    final type = state.selectedType;
    final cache = _typeCaches[type]!;

    state = RankingState(
      isLoading: cache.isLoading,
      error: cache.error,
      data: cache.data,
      selectedType: type,
    );
  }

  /// 获取排行榜应用
  Future<List<RankingAppInfo>> _fetchRankingApps(RankingType type) async {
    final apiService = ref.read(appApiServiceProvider);

    final response = await switch (type) {
      RankingType.download => apiService.getInstallAppList(
        const PageParams(pageNo: 1, pageSize: 100),
      ),
      RankingType.rising => apiService.getNewAppList(
        const PageParams(pageNo: 1, pageSize: 100),
      ),
      RankingType.update => apiService.getNewAppList(
        const PageParams(pageNo: 1, pageSize: 100),
      ),
      RankingType.hot => apiService.getInstallAppList(
        const PageParams(pageNo: 1, pageSize: 100),
      ),
    };

    return _convertToRankingApps(response.data.data, type);
  }

  /// 转换为排行榜应用列表
  List<RankingAppInfo> _convertToRankingApps(
    AppListPagedData? data,
    RankingType type,
  ) {
    if (data == null) return [];

    return data.records.asMap().entries.map((entry) {
      final index = entry.key;
      final dto = entry.value;
      final rank = index + 1;

      return RankingAppInfo(
        appId: dto.appId,
        name: dto.appName,
        version: dto.appVersion ?? '',
        description: dto.appDesc,
        icon: dto.appIcon,
        developer: dto.developerName,
        category: dto.categoryName,
        size: dto.packageSize,
        downloadCount: _getDownloadCount(dto.downloadTimes, type, rank),
        rank: rank,
      );
    }).toList();
  }

  /// 根据排行榜类型调整下载/热度数值显示
  int _getDownloadCount(int? baseCount, RankingType type, int rank) {
    final count = baseCount ?? 0;

    return switch (type) {
      RankingType.download => count,
      RankingType.rising => count,
      RankingType.update => 100 - rank + 1, // 更新次数
      RankingType.hot => 100 - rank + 1, // 热度值
    };
  }
}
