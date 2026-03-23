import 'package:freezed_annotation/freezed_annotation.dart';

part 'ranking_models.freezed.dart';

/// 排行榜类型
enum RankingType {
  /// 下载榜
  download('download'),

  /// 新秀榜
  rising('rising'),

  /// 更新榜
  update('update'),

  /// 热门榜
  hot('hot');

  const RankingType(this.code);

  final String code;

  String get label => switch (this) {
        RankingType.download => '下载榜',
        RankingType.rising => '新秀榜',
        RankingType.update => '更新榜',
        RankingType.hot => '热门榜',
      };
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
    required int rank,
    @Default(false) bool isInstalled,
    @Default(false) bool hasUpdate,
  }) = _RankingAppInfo;
}

/// 排行榜数据
class RankingData {
  const RankingData({
    required this.type,
    required this.apps,
  });

  final RankingType type;
  final List<RankingAppInfo> apps;

  RankingData copyWith({
    RankingType? type,
    List<RankingAppInfo>? apps,
  }) {
    return RankingData(
      type: type ?? this.type,
      apps: apps ?? this.apps,
    );
  }
}

/// 排行榜状态
@freezed
sealed class RankingState with _$RankingState {
  const factory RankingState({
    @Default(false) bool isLoading,
    String? error,
    RankingData? data,
    @Default(RankingType.download) RankingType selectedType,
  }) = _RankingState;
}
