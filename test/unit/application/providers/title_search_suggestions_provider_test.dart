import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/app_search_index_provider.dart';
import 'package:linglong_store/application/providers/title_search_suggestions_provider.dart';

void main() {
  group('titleSearchSuggestionsProvider', () {
    test('empty query clears suggestions', () {
      final container = ProviderContainer(
        overrides: [
          appSearchIndexProvider.overrideWith(
            () => _FakeAppSearchIndex([
              const SearchSuggestionEntry(
                appId: 'org.example.browser',
                name: '浏览器',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(titleSearchSuggestionsProvider.notifier)
          .updateQuery('   ');

      final state = container.read(titleSearchSuggestionsProvider);
      expect(state.items, isEmpty);
    });

    test('non-empty query returns local matches', () {
      final container = ProviderContainer(
        overrides: [
          appSearchIndexProvider.overrideWith(
            () => _FakeAppSearchIndex([
              const SearchSuggestionEntry(
                appId: 'org.example.browser',
                name: '浏览器',
              ),
              const SearchSuggestionEntry(
                appId: 'org.example.editor',
                name: '文本编辑器',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(titleSearchSuggestionsProvider.notifier)
          .updateQuery('浏览');

      final state = container.read(titleSearchSuggestionsProvider);
      expect(state.items.length, 1);
      expect(state.items.first.appId, 'org.example.browser');
      expect(state.items.first.name, '浏览器');
    });

    test('clear resets state', () {
      final container = ProviderContainer(
        overrides: [
          appSearchIndexProvider.overrideWith(
            () => _FakeAppSearchIndex([
              const SearchSuggestionEntry(
                appId: 'org.example.browser',
                name: '浏览器',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(titleSearchSuggestionsProvider.notifier)
          .updateQuery('浏览');
      expect(
        container.read(titleSearchSuggestionsProvider).items,
        isNotEmpty,
      );

      container.read(titleSearchSuggestionsProvider.notifier).clear();
      expect(container.read(titleSearchSuggestionsProvider).items, isEmpty);
    });

    test('no matching results returns empty', () {
      final container = ProviderContainer(
        overrides: [
          appSearchIndexProvider.overrideWith(
            () => _FakeAppSearchIndex([
              const SearchSuggestionEntry(
                appId: 'org.example.browser',
                name: '浏览器',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(titleSearchSuggestionsProvider.notifier)
          .updateQuery('不存在');

      final state = container.read(titleSearchSuggestionsProvider);
      expect(state.items, isEmpty);
    });
  });
}

/// 假索引，直接返回预设数据
class _FakeAppSearchIndex extends AppSearchIndex {
  final List<SearchSuggestionEntry> _entries;

  _FakeAppSearchIndex(this._entries);

  @override
  AsyncValue<List<SearchSuggestionEntry>> build() => AsyncData(_entries);
}
