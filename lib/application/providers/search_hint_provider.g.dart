// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_hint_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 搜索框 placeholder 轮播数据 Provider。
///
/// 数据来源为下载量榜 `/visit/getInstallAppList`，与排行页 `Ranking` provider
/// 保持独立：
/// 1. 避免被排行页 Tab 切换污染当前选中类型；
/// 2. 直接消费底层 `AppListItemDTO`（含 repoName/module），而排行页裁剪过的
///    `RankingAppInfo` 缺失跳转详情页所需身份字段。
///
/// 仅取前 20 条，由搜索框每 5 秒顺序轮播；网络失败或结果为空时返回空列表，
/// 调用方回退到静态 placeholder 文案，不抛错。

@ProviderFor(SearchHintApps)
final searchHintAppsProvider = SearchHintAppsProvider._();

/// 搜索框 placeholder 轮播数据 Provider。
///
/// 数据来源为下载量榜 `/visit/getInstallAppList`，与排行页 `Ranking` provider
/// 保持独立：
/// 1. 避免被排行页 Tab 切换污染当前选中类型；
/// 2. 直接消费底层 `AppListItemDTO`（含 repoName/module），而排行页裁剪过的
///    `RankingAppInfo` 缺失跳转详情页所需身份字段。
///
/// 仅取前 20 条，由搜索框每 5 秒顺序轮播；网络失败或结果为空时返回空列表，
/// 调用方回退到静态 placeholder 文案，不抛错。
final class SearchHintAppsProvider
    extends $NotifierProvider<SearchHintApps, List<SearchHintApp>> {
  /// 搜索框 placeholder 轮播数据 Provider。
  ///
  /// 数据来源为下载量榜 `/visit/getInstallAppList`，与排行页 `Ranking` provider
  /// 保持独立：
  /// 1. 避免被排行页 Tab 切换污染当前选中类型；
  /// 2. 直接消费底层 `AppListItemDTO`（含 repoName/module），而排行页裁剪过的
  ///    `RankingAppInfo` 缺失跳转详情页所需身份字段。
  ///
  /// 仅取前 20 条，由搜索框每 5 秒顺序轮播；网络失败或结果为空时返回空列表，
  /// 调用方回退到静态 placeholder 文案，不抛错。
  SearchHintAppsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchHintAppsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchHintAppsHash();

  @$internal
  @override
  SearchHintApps create() => SearchHintApps();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SearchHintApp> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SearchHintApp>>(value),
    );
  }
}

String _$searchHintAppsHash() => r'7b04f4d464a2a771ace9dc8703ea3aa5dce3a65c';

/// 搜索框 placeholder 轮播数据 Provider。
///
/// 数据来源为下载量榜 `/visit/getInstallAppList`，与排行页 `Ranking` provider
/// 保持独立：
/// 1. 避免被排行页 Tab 切换污染当前选中类型；
/// 2. 直接消费底层 `AppListItemDTO`（含 repoName/module），而排行页裁剪过的
///    `RankingAppInfo` 缺失跳转详情页所需身份字段。
///
/// 仅取前 20 条，由搜索框每 5 秒顺序轮播；网络失败或结果为空时返回空列表，
/// 调用方回退到静态 placeholder 文案，不抛错。

abstract class _$SearchHintApps extends $Notifier<List<SearchHintApp>> {
  List<SearchHintApp> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<SearchHintApp>, List<SearchHintApp>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<SearchHintApp>, List<SearchHintApp>>,
              List<SearchHintApp>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
