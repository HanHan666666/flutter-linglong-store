import 'package:freezed_annotation/freezed_annotation.dart';

part 'ranking_models.freezed.dart';

/// 排行榜类型
enum RankingType {
  /// 最新上架榜
  rising('rising'),

  /// 下载量榜
  download('download');

  const RankingType(this.code);

  final String code;
}

/// 排行榜应用信息
@freezed
sealed class RankingAppInfo with _$RankingAppInfo {
  const factory RankingAppInfo({
    required String appId,
    required String name,
    required String version,
    String? description,
    String? icon,
    String? developer,
    String? category,
    String? size,
    double? rating,
    int? downloadCount,
    String? createTime, // 上架时间（新增）
    required int rank,
    @Default(false) bool isInstalled,
    @Default(false) bool hasUpdate,
  }) = _RankingAppInfo;
}

/// 排行榜数据
class RankingData {
  const RankingData({required this.type, required this.apps});

  final RankingType type;
  final List<RankingAppInfo> apps;

  RankingData copyWith({RankingType? type, List<RankingAppInfo>? apps}) {
    return RankingData(type: type ?? this.type, apps: apps ?? this.apps);
  }
}

/// 排行榜状态
@freezed
sealed class RankingState with _$RankingState {
  const factory RankingState({
    @Default(false) bool isLoading,
    String? error,
    RankingData? data,
    @Default(RankingType.rising) RankingType selectedType, // 默认进入最新上架榜
  }) = _RankingState;
}
