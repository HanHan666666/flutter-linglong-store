// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 排行榜状态 Provider

@ProviderFor(Ranking)
final rankingProvider = RankingProvider._();

/// 排行榜状态 Provider
final class RankingProvider extends $NotifierProvider<Ranking, RankingState> {
  /// 排行榜状态 Provider
  RankingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rankingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rankingHash();

  @$internal
  @override
  Ranking create() => Ranking();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RankingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RankingState>(value),
    );
  }
}

String _$rankingHash() => r'd837afd02d5eb52000ce1ec82ee72f6fc2db2ed8';

/// 排行榜状态 Provider

abstract class _$Ranking extends $Notifier<RankingState> {
  RankingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RankingState, RankingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RankingState, RankingState>,
              RankingState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
