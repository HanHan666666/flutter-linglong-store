import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/recommend_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/storage/recommend_page_cache.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';

import '../../../mocks/mock_classes.mocks.dart';

class _InMemoryRecommendPageCacheStore implements RecommendPageCacheStore {
  RecommendPageCacheSnapshot? snapshot;

  @override
  Future<RecommendPageCacheSnapshot?> read(String locale) async => snapshot;

  @override
  Future<void> write(RecommendPageCacheSnapshot snapshot, String locale) async {
    this.snapshot = snapshot;
  }

  @override
  Future<void> clear(String locale) async {
    snapshot = null;
  }
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('RecommendState', () {
    test('should have rust parity default values', () {
      const state = RecommendState();

      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNull);
      expect(state.data, isNull);
      expect(state.hasHydratedFromCache, isFalse);
      expect(state.currentPage, equals(1));
    });

    test('should support cache hydration flag in copyWith', () {
      const state = RecommendState();

      final newState = state.copyWith(
        isLoading: true,
        hasHydratedFromCache: true,
      );

      expect(newState.isLoading, isTrue);
      expect(newState.hasHydratedFromCache, isTrue);
      expect(newState.error, isNull);
    });
  });

  group('Recommend provider rust parity', () {
    late MockAppApiService mockApiService;
    late _InMemoryRecommendPageCacheStore cacheStore;

    setUp(() {
      mockApiService = MockAppApiService();
      cacheStore = _InMemoryRecommendPageCacheStore();
    });

    test('hydrates cached data before remote refresh', () async {
      final carouselCompleter = Completer<HttpResponse<AppListArrayResponse>>();
      final listCompleter = Completer<HttpResponse<AppListResponse>>();

      cacheStore.snapshot = const RecommendPageCacheSnapshot(
        banners: [
          BannerInfo(
            id: 'cached-banner',
            title: 'Cached Banner',
            imageUrl: 'https://example.com/cached-banner.png',
            targetAppId: 'cached.app',
          ),
        ],
        apps: PaginatedResponse<RecommendAppInfo>(
          items: [
            RecommendAppInfo(
              appId: 'cached.app',
              name: 'Cached App',
              version: '1.0.0',
            ),
          ],
          total: 1,
          page: 1,
          pageSize: 10,
          hasMore: false,
        ),
        currentPage: 1,
      );

      when(mockApiService.getWelcomeCarouselList(any)).thenAnswer(
        (_) => carouselCompleter.future,
      );
      when(mockApiService.getWelcomeAppList(any)).thenAnswer(
        (_) => listCompleter.future,
      );

      final container = ProviderContainer(
        overrides: [
          appApiServiceProvider.overrideWithValue(mockApiService),
          recommendPageCacheStoreProvider.overrideWithValue(cacheStore),
        ],
      );
      addTearDown(container.dispose);

      container.listen<RecommendState>(recommendProvider, (_, __) {});
      await _flushAsyncWork();

      final hydratedState = container.read(recommendProvider);
      expect(hydratedState.hasHydratedFromCache, isTrue);
      expect(hydratedState.data?.apps.items.single.name, equals('Cached App'));

      carouselCompleter.complete(
        _buildCarouselResponse(
          const [
            AppListItemDTO(
              appId: 'remote-banner',
              appName: 'Remote Banner',
              appIcon: 'https://example.com/remote-banner.png',
            ),
          ],
        ),
      );
      listCompleter.complete(
        _buildPagedResponse(
          const [
            AppListItemDTO(
              appId: 'remote.app',
              appName: 'Remote App',
              appVersion: '2.0.0',
            ),
          ],
          currentPage: 1,
          pageSize: 10,
          total: 1,
          pages: 1,
        ),
      );
      await _flushAsyncWork();

      final refreshedState = container.read(recommendProvider);
      expect(refreshedState.data?.apps.items.single.name, equals('Remote App'));
      expect(cacheStore.snapshot?.apps.items.single.name, equals('Remote App'));
    });

    test('loads more with rust page size 10', () async {
      when(mockApiService.getWelcomeCarouselList(any)).thenAnswer(
        (_) async => _buildCarouselResponse(const []),
      );
      when(mockApiService.getWelcomeAppList(any)).thenAnswer((invocation) async {
        final request = invocation.positionalArguments.single as PageParams;
        if (request.pageNo == 1) {
          return _buildPagedResponse(
            const [
              AppListItemDTO(
                appId: 'app.one',
                appName: 'App One',
                appVersion: '1.0.0',
              ),
            ],
            currentPage: 1,
            pageSize: request.pageSize,
            total: 2,
            pages: 2,
          );
        }

        return _buildPagedResponse(
          const [
            AppListItemDTO(
              appId: 'app.two',
              appName: 'App Two',
              appVersion: '2.0.0',
            ),
          ],
          currentPage: 2,
          pageSize: request.pageSize,
          total: 2,
          pages: 2,
        );
      });

      final container = ProviderContainer(
        overrides: [
          appApiServiceProvider.overrideWithValue(mockApiService),
          recommendPageCacheStoreProvider.overrideWithValue(cacheStore),
        ],
      );
      addTearDown(container.dispose);

      container.listen<RecommendState>(recommendProvider, (_, __) {});
      await _flushAsyncWork();

      await container.read(recommendProvider.notifier).loadMore();

      final state = container.read(recommendProvider);
      expect(state.data?.apps.items, hasLength(2));

      final captured =
          verify(mockApiService.getWelcomeAppList(captureAny)).captured
              .cast<PageParams>();
      expect(captured[0].pageSize, equals(10));
      expect(captured[1].pageNo, equals(2));
      expect(captured[1].pageSize, equals(10));
    });

    test('keeps app list available when carousel request fails', () async {
      when(
        mockApiService.getWelcomeCarouselList(any),
      ).thenThrow(Exception('carousel failed'));
      when(mockApiService.getWelcomeAppList(any)).thenAnswer(
        (_) async => _buildPagedResponse(
          const [
            AppListItemDTO(
              appId: 'app.one',
              appName: 'App One',
              appVersion: '1.0.0',
            ),
          ],
          currentPage: 1,
          pageSize: 10,
          total: 1,
          pages: 1,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          appApiServiceProvider.overrideWithValue(mockApiService),
          recommendPageCacheStoreProvider.overrideWithValue(cacheStore),
        ],
      );
      addTearDown(container.dispose);

      container.listen<RecommendState>(recommendProvider, (_, __) {});
      await _flushAsyncWork();

      final state = container.read(recommendProvider);
      expect(state.error, isNull);
      expect(state.data?.apps.items.single.name, equals('App One'));
      expect(state.data?.banners, isEmpty);
    });
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

HttpResponse<AppListArrayResponse> _buildCarouselResponse(
  List<AppListItemDTO> data,
) {
  return HttpResponse(
    AppListArrayResponse(code: 200, data: data),
    Response(requestOptions: RequestOptions(path: '/visit/getWelcomeCarouselList')),
  );
}

HttpResponse<AppListResponse> _buildPagedResponse(
  List<AppListItemDTO> records, {
  required int currentPage,
  required int pageSize,
  required int total,
  required int pages,
}) {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: records,
        total: total,
        size: pageSize,
        current: currentPage,
        pages: pages,
      ),
    ),
    Response(requestOptions: RequestOptions(path: '/visit/getWelcomeAppList')),
  );
}
