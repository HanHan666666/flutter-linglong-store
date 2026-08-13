// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommend_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 推荐页状态 Provider

@ProviderFor(Recommend)
final recommendProvider = RecommendProvider._();

/// 推荐页状态 Provider
final class RecommendProvider
    extends $NotifierProvider<Recommend, RecommendState> {
  /// 推荐页状态 Provider
  RecommendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendHash();

  @$internal
  @override
  Recommend create() => Recommend();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecommendState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecommendState>(value),
    );
  }
}

String _$recommendHash() => r'395d53798f1e2d7e40f6e918bb18bdfa2d8e5312';

/// 推荐页状态 Provider

abstract class _$Recommend extends $Notifier<RecommendState> {
  RecommendState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RecommendState, RecommendState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecommendState, RecommendState>,
              RecommendState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
