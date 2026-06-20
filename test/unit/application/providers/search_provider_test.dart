import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/search_provider.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/domain/models/app_detail.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';
import '../../../mocks/mock_classes.mocks.dart';

HttpResponse<AppListResponse> _response({
  required int page,
  required int pages,
}) {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: [
          AppListItemDTO(
            appId: 'app.$page',
            appName: 'App $page',
            appVersion: '1.0.0',
          ),
        ],
        total: pages,
        size: 20,
        current: page,
        pages: pages,
      ),
    ),
    Response(requestOptions: RequestOptions(path: '/visit/getSearchAppList')),
  );
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('SearchProvider', () {
    group('SearchState', () {
      test('should have correct default values', () {
        // Arrange & Act
        const state = SearchState(query: '', results: []);

        // Assert
        expect(state.query, isEmpty);
        expect(state.results, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.isLoadingMore, isFalse);
        expect(state.error, isNull);
        expect(state.currentPage, equals(1));
        expect(state.hasMore, isTrue);
        expect(state.total, equals(0));
      });

      test('should support copyWith', () {
        // Arrange
        const state = SearchState(query: '', results: []);

        // Act
        final newState = state.copyWith(
          query: 'test query',
          isLoading: true,
          total: 10,
        );

        // Assert
        expect(newState.query, equals('test query'));
        expect(newState.isLoading, isTrue);
        expect(newState.total, equals(10));
        expect(newState.results, isEmpty);
      });

      test('should handle search results', () {
        // Arrange
        final results = [
          const RecommendAppInfo(
            appId: 'com.example.app1',
            name: 'App 1',
            version: '1.0.0',
          ),
          const RecommendAppInfo(
            appId: 'com.example.app2',
            name: 'App 2',
            version: '2.0.0',
          ),
        ];

        // Act
        final state = SearchState(
          query: 'test',
          results: results,
          total: 2,
          hasMore: false,
        );

        // Assert
        expect(state.query, equals('test'));
        expect(state.results.length, equals(2));
        expect(state.total, equals(2));
        expect(state.hasMore, isFalse);
      });

      test('should track pagination state', () {
        // Arrange
        const state = SearchState(
          query: 'test',
          results: [],
          currentPage: 2,
          hasMore: true,
          total: 50,
        );

        // Assert
        expect(state.currentPage, equals(2));
        expect(state.hasMore, isTrue);
        expect(state.total, equals(50));
      });

      test('should track loading states independently', () {
        // Arrange
        const stateLoading = SearchState(
          query: 'test',
          results: [],
          isLoading: true,
        );
        const stateLoadingMore = SearchState(
          query: 'test',
          results: [],
          isLoadingMore: true,
        );

        // Assert
        expect(stateLoading.isLoading, isTrue);
        expect(stateLoading.isLoadingMore, isFalse);
        expect(stateLoadingMore.isLoading, isFalse);
        expect(stateLoadingMore.isLoadingMore, isTrue);
      });

      test('should handle error state', () {
        // Arrange & Act
        const state = SearchState(
          query: 'test',
          results: [],
          error: 'Network error',
        );

        // Assert
        expect(state.error, equals('Network error'));
        expect(state.isLoading, isFalse);
      });
    });

    test('tag search and loadMore preserve tagName and tagLan', () async {
      // 标签搜索：首屏 + loadMore 都必须持续携带 tagName/tagLan，
      // 且 keyword 为空，禁止把标签伪装成普通关键词
      final api = MockAppApiService();
      when(api.getSearchAppList(any)).thenAnswer((invocation) async {
        final request =
            invocation.positionalArguments.single as SearchAppListRequest;
        return _response(page: request.pageNo, pages: 2);
      });
      final container = ProviderContainer(
        overrides: [appApiServiceProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      await container
          .read(searchProvider.notifier)
          .searchByTag(const AppTag(name: '办公', language: 'zh_CN'));
      await container.read(searchProvider.notifier).loadMore();

      final requests = verify(api.getSearchAppList(captureAny))
          .captured
          .cast<SearchAppListRequest>();
      expect(requests.map((item) => item.pageNo), [1, 2]);
      expect(requests.every((item) => item.keyword.isEmpty), isTrue);
      expect(requests.every((item) => item.tagName == '办公'), isTrue);
      expect(requests.every((item) => item.tagLan == 'zh_CN'), isTrue);
    });
  });
}