// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'title_search_suggestions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 标题栏候选 provider。
///
/// 消费本地搜索索引做同步匹配，不再调用后端 API。

@ProviderFor(TitleSearchSuggestions)
final titleSearchSuggestionsProvider = TitleSearchSuggestionsProvider._();

/// 标题栏候选 provider。
///
/// 消费本地搜索索引做同步匹配，不再调用后端 API。
final class TitleSearchSuggestionsProvider
    extends
        $NotifierProvider<TitleSearchSuggestions, TitleSearchSuggestionsState> {
  /// 标题栏候选 provider。
  ///
  /// 消费本地搜索索引做同步匹配，不再调用后端 API。
  TitleSearchSuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'titleSearchSuggestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$titleSearchSuggestionsHash();

  @$internal
  @override
  TitleSearchSuggestions create() => TitleSearchSuggestions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TitleSearchSuggestionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TitleSearchSuggestionsState>(value),
    );
  }
}

String _$titleSearchSuggestionsHash() =>
    r'c0ab98ef153a913f7c836579b47234b89163982c';

/// 标题栏候选 provider。
///
/// 消费本地搜索索引做同步匹配，不再调用后端 API。

abstract class _$TitleSearchSuggestions
    extends $Notifier<TitleSearchSuggestionsState> {
  TitleSearchSuggestionsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<TitleSearchSuggestionsState, TitleSearchSuggestionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                TitleSearchSuggestionsState,
                TitleSearchSuggestionsState
              >,
              TitleSearchSuggestionsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
