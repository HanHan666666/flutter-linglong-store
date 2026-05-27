import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/locale_utils.dart';
import '../../data/mappers/app_list_mapper.dart';
import '../../data/models/api_dto.dart';
import '../../domain/models/recommend_models.dart';
import 'api_provider.dart';
import 'global_provider.dart';

part 'title_search_suggestions_provider.g.dart';

/// 标题栏搜索候选的轻量状态。
///
/// 这里只承载候选列表与加载态，不复用搜索结果页的完整状态机。
class TitleSearchSuggestionsState {
  const TitleSearchSuggestionsState({
    this.items = const [],
    this.isLoading = false,
  });

  final List<RecommendAppInfo> items;
  final bool isLoading;

  TitleSearchSuggestionsState copyWith({
    List<RecommendAppInfo>? items,
    bool? isLoading,
  }) {
    return TitleSearchSuggestionsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 标题栏候选 provider。
///
/// 候选请求始终只取第一页小页量数据，并与搜索结果页状态解耦。
@riverpod
class TitleSearchSuggestions extends _$TitleSearchSuggestions {
  int _requestId = 0;

  @override
  TitleSearchSuggestionsState build() {
    return const TitleSearchSuggestionsState();
  }

  Future<void> loadSuggestions(String query) async {
    final normalizedQuery = query.trim();
    final requestId = ++_requestId;

    if (normalizedQuery.isEmpty) {
      state = const TitleSearchSuggestionsState();
      return;
    }

    // 标题栏候选不保留旧结果，避免新旧关键词交替时出现错位候选。
    state = const TitleSearchSuggestionsState(isLoading: true);

    try {
      final response = await ref.read(appApiServiceProvider).getSearchAppList(
        SearchAppListRequest(
          keyword: normalizedQuery,
          pageNo: 1,
          pageSize: 8,
          arch: resolveRequestArch(ref),
          lan: resolveApiLang(ApiClient.getLocale?.call()),
        ),
      );

      if (requestId != _requestId) {
        return;
      }

      final mapped = mapAppListToRecommendApps(response.data.data, pageSize: 8);
      state = TitleSearchSuggestionsState(items: mapped.items);
    } catch (_) {
      if (requestId != _requestId) {
        return;
      }

      // 候选失败不阻塞用户继续 Enter 搜索，静默回收即可。
      state = const TitleSearchSuggestionsState();
    }
  }

  void clear() {
    _requestId++;
    state = const TitleSearchSuggestionsState();
  }
}
