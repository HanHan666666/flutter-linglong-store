import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/title_search_suggestions_provider.dart';
import 'package:linglong_store/data/models/api_dto.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  group('titleSearchSuggestionsProvider', () {
    test('empty query clears state and skips API request', () async {
      final mockApiService = MockAppApiService();
      final container = ProviderContainer(
        overrides: [appApiServiceProvider.overrideWithValue(mockApiService)],
      );
      addTearDown(container.dispose);

      await container
          .read(titleSearchSuggestionsProvider.notifier)
          .loadSuggestions('   ');

      final state = container.read(titleSearchSuggestionsProvider);

      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
      verifyNever(mockApiService.getSearchAppList(any));
    });

    test('loads first page with page size 8', () async {
      final mockApiService = MockAppApiService();
      when(
        mockApiService.getSearchAppList(any),
      ).thenAnswer((_) async => _buildSearchResponse());

      final container = ProviderContainer(
        overrides: [appApiServiceProvider.overrideWithValue(mockApiService)],
      );
      addTearDown(container.dispose);

      await container
          .read(titleSearchSuggestionsProvider.notifier)
          .loadSuggestions('browser');

      final state = container.read(titleSearchSuggestionsProvider);
      final captured = verify(
        mockApiService.getSearchAppList(captureAny),
      ).captured.single as SearchAppListRequest;

      expect(captured.keyword, 'browser');
      expect(captured.pageNo, 1);
      expect(captured.pageSize, 8);
      expect(state.items.map((item) => item.name), ['浏览器']);
      expect(state.isLoading, isFalse);
    });

    test('request failure clears suggestions and loading state', () async {
      final mockApiService = MockAppApiService();
      when(mockApiService.getSearchAppList(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/visit/getSearchAppList'),
        ),
      );

      final container = ProviderContainer(
        overrides: [appApiServiceProvider.overrideWithValue(mockApiService)],
      );
      addTearDown(container.dispose);

      await container
          .read(titleSearchSuggestionsProvider.notifier)
          .loadSuggestions('browser');

      final state = container.read(titleSearchSuggestionsProvider);

      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
    });
  });
}

HttpResponse<AppListResponse> _buildSearchResponse() {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: const [
          AppListItemDTO(
            appId: 'org.example.browser',
            appName: '浏览器',
            appVersion: '1.0.0',
            arch: 'x86_64',
            module: 'binary',
            repoName: 'repo',
          ),
        ],
        total: 1,
        size: 8,
        current: 1,
        pages: 1,
      ),
    ),
    Response(requestOptions: RequestOptions(path: '/visit/getSearchAppList')),
  );
}
