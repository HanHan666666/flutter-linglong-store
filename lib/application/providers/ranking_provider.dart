import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/ranking_models.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/api_dto.dart';
import 'api_provider.dart';

part 'ranking_provider.g.dart';

/// 排行榜状态 Provider
@riverpod
class Ranking extends _$Ranking {
  @override
  RankingState build() {
    // 初始化时加载数据
    Future.microtask(() => loadData());
    return const RankingState();
  }

  /// 加载数据
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apps = await _fetchRankingApps(state.selectedType);

      state = state.copyWith(
        isLoading: false,
        data: RankingData(type: state.selectedType, apps: apps),
      );
    } catch (e, s) {
      AppLogger.error('加载排行榜数据失败', e, s);
      state = state.copyWith(isLoading: false, error: presentAppError(e));
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadData();
  }

  /// 切换排行榜类型
  Future<void> selectType(RankingType type) async {
    if (type == state.selectedType) return;

    state = state.copyWith(selectedType: type);
    await loadData();
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
