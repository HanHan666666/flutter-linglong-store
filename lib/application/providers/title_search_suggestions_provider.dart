import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_search_index_provider.dart';

part 'title_search_suggestions_provider.g.dart';

/// 候选条目，用于标题栏候选面板展示。
class SuggestionItem {
  const SuggestionItem({
    required this.appId,
    required this.name,
    this.version,
    this.arch,
    this.repoName,
    this.module,
  });

  /// 应用唯一标识
  final String appId;

  /// 应用名称
  final String name;

  /// 详情页精确查询所需的身份字段，来自本地搜索索引。
  final String? version;
  final String? arch;
  final String? repoName;
  final String? module;
}

/// 标题栏搜索候选状态。
class TitleSearchSuggestionsState {
  const TitleSearchSuggestionsState({this.items = const []});

  final List<SuggestionItem> items;

  TitleSearchSuggestionsState copyWith({List<SuggestionItem>? items}) {
    return TitleSearchSuggestionsState(items: items ?? this.items);
  }
}

/// 标题栏候选 provider。
///
/// 消费本地搜索索引做同步匹配，不再调用后端 API。
@riverpod
class TitleSearchSuggestions extends _$TitleSearchSuggestions {
  @override
  TitleSearchSuggestionsState build() {
    return const TitleSearchSuggestionsState();
  }

  /// 根据输入词同步更新候选列表。
  void updateQuery(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      state = const TitleSearchSuggestionsState();
      return;
    }

    final asyncIndex = ref.read(appSearchIndexProvider);
    final entries = asyncIndex is AsyncData<List<SearchSuggestionEntry>>
        ? asyncIndex.value
        : const <SearchSuggestionEntry>[];

    final results = searchSuggestions(entries, normalizedQuery);
    state = TitleSearchSuggestionsState(
      items: results
          .map(
            (e) => SuggestionItem(
              appId: e.appId,
              name: e.name,
              version: e.version,
              arch: e.arch,
              repoName: e.repoName,
              module: e.module,
            ),
          )
          .toList(),
    );
  }

  /// 清空候选。
  void clear() {
    state = const TitleSearchSuggestionsState();
  }
}
