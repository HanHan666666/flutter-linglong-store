// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_search_index_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 应用搜索索引 Provider。
///
/// 启动时优先从 Hive 本地缓存读取精简索引（毫秒级）；新鲜期（24h）内命中
/// 则直接使用，不再重跑 ll-cli，过期或未命中才执行 `ll-cli search . --json`
/// 刷新。落盘只存候选所需的最小字段，避免原始 JSON 整串常驻。
///
/// keepAlive: true — 搜索索引是应用级全局数据，不应被 auto-dispose 回收。

@ProviderFor(AppSearchIndex)
final appSearchIndexProvider = AppSearchIndexProvider._();

/// 应用搜索索引 Provider。
///
/// 启动时优先从 Hive 本地缓存读取精简索引（毫秒级）；新鲜期（24h）内命中
/// 则直接使用，不再重跑 ll-cli，过期或未命中才执行 `ll-cli search . --json`
/// 刷新。落盘只存候选所需的最小字段，避免原始 JSON 整串常驻。
///
/// keepAlive: true — 搜索索引是应用级全局数据，不应被 auto-dispose 回收。
final class AppSearchIndexProvider
    extends
        $NotifierProvider<
          AppSearchIndex,
          AsyncValue<List<SearchSuggestionEntry>>
        > {
  /// 应用搜索索引 Provider。
  ///
  /// 启动时优先从 Hive 本地缓存读取精简索引（毫秒级）；新鲜期（24h）内命中
  /// 则直接使用，不再重跑 ll-cli，过期或未命中才执行 `ll-cli search . --json`
  /// 刷新。落盘只存候选所需的最小字段，避免原始 JSON 整串常驻。
  ///
  /// keepAlive: true — 搜索索引是应用级全局数据，不应被 auto-dispose 回收。
  AppSearchIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSearchIndexProvider',
        isAutoDispose: false,
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

String _$appSearchIndexHash() => r'dee5d4d0916b0090cf56bd279ca07e48aa7aea24';

/// 应用搜索索引 Provider。
///
/// 启动时优先从 Hive 本地缓存读取精简索引（毫秒级）；新鲜期（24h）内命中
/// 则直接使用，不再重跑 ll-cli，过期或未命中才执行 `ll-cli search . --json`
/// 刷新。落盘只存候选所需的最小字段，避免原始 JSON 整串常驻。
///
/// keepAlive: true — 搜索索引是应用级全局数据，不应被 auto-dispose 回收。

abstract class _$AppSearchIndex
    extends $Notifier<AsyncValue<List<SearchSuggestionEntry>>> {
  AsyncValue<List<SearchSuggestionEntry>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
