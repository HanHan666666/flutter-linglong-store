// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_search_index_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 应用搜索索引 Provider。
///
/// 启动时异步执行 `ll-cli search . --json`，解析后常驻内存。
/// 加载失败时静默回退为空列表，不阻塞启动。

@ProviderFor(AppSearchIndex)
final appSearchIndexProvider = AppSearchIndexProvider._();

/// 应用搜索索引 Provider。
///
/// 启动时异步执行 `ll-cli search . --json`，解析后常驻内存。
/// 加载失败时静默回退为空列表，不阻塞启动。
final class AppSearchIndexProvider
    extends
        $NotifierProvider<
          AppSearchIndex,
          AsyncValue<List<SearchSuggestionEntry>>
        > {
  /// 应用搜索索引 Provider。
  ///
  /// 启动时异步执行 `ll-cli search . --json`，解析后常驻内存。
  /// 加载失败时静默回退为空列表，不阻塞启动。
  AppSearchIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSearchIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSearchIndexHash();

  @$internal
  @override
  AppSearchIndex create() => AppSearchIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<SearchSuggestionEntry>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<SearchSuggestionEntry>>>(value),
    );
  }
}

String _$appSearchIndexHash() => r'c5a30c70273a85d10e9fc8fd00bb799cb10d3374';

/// 应用搜索索引 Provider。
///
/// 启动时异步执行 `ll-cli search . --json`，解析后常驻内存。
/// 加载失败时静默回退为空列表，不阻塞启动。

abstract class _$AppSearchIndex
    extends $Notifier<AsyncValue<List<SearchSuggestionEntry>>> {
  AsyncValue<List<SearchSuggestionEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<SearchSuggestionEntry>>,
              AsyncValue<List<SearchSuggestionEntry>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<SearchSuggestionEntry>>,
                AsyncValue<List<SearchSuggestionEntry>>
              >,
              AsyncValue<List<SearchSuggestionEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
