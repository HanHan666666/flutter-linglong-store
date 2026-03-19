import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/application_card_state_provider.dart';
import 'package:linglong_store/application/providers/recommend_provider.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/storage/recommend_page_cache.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:linglong_store/presentation/pages/recommend/recommend_page.dart';
import 'package:linglong_store/presentation/widgets/category_filter_section.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  group('RecommendPage rust parity', () {
    testWidgets('renders carousel title and list without category filter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          const RecommendState(
            data: RecommendData(
              banners: [
                BannerInfo(
                  id: 'banner-1',
                  title: 'Banner App',
                  imageUrl: '',
                  targetAppId: 'banner.app',
                ),
              ],
              categories: [CategoryInfo(code: 'all', name: '全部')],
              apps: PaginatedResponse<RecommendAppInfo>(
                items: [
                  RecommendAppInfo(
                    appId: 'app.one',
                    name: 'App One',
                    version: '1.0.0',
                  ),
                ],
                total: 1,
                page: 1,
                pageSize: 10,
                hasMore: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('玲珑推荐'), findsOneWidget);
      expect(find.text('App One'), findsOneWidget);
      expect(find.text('Banner App'), findsOneWidget);
      expect(find.byType(CategoryFilterSection), findsNothing);
    });

    testWidgets('shows rust no-more copy', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const RecommendState(
            data: RecommendData(
              banners: [],
              categories: [CategoryInfo(code: 'all', name: '全部')],
              apps: PaginatedResponse<RecommendAppInfo>(
                items: [
                  RecommendAppInfo(
                    appId: 'app.one',
                    name: 'App One',
                    version: '1.0.0',
                  ),
                ],
                total: 1,
                page: 1,
                pageSize: 10,
                hasMore: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('没有更多数据了'), findsOneWidget);
    });

    testWidgets('auto loads more when first page cannot scroll', (
      tester,
    ) async {
      final mockApiService = MockAppApiService();
      final cacheStore = _InMemoryRecommendPageCacheStore();

      when(
        mockApiService.getWelcomeCarouselList(any),
      ).thenAnswer((_) async => _buildCarouselResponse(const []));
      when(mockApiService.getWelcomeAppList(any)).thenAnswer((
        invocation,
      ) async {
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

      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1600, 1400));

      await tester.pumpWidget(
        _buildProviderDrivenTestApp(
          overrides: [
            appApiServiceProvider.overrideWithValue(mockApiService),
            recommendPageCacheStoreProvider.overrideWithValue(cacheStore),
            applicationCardStateIndexProvider.overrideWithValue(
              const ApplicationCardStateIndex(
                installedVersionByAppId: {},
                updateAppIds: {},
                activeTasksByAppId: {},
              ),
            ),
          ],
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('App One'), findsOneWidget);
      expect(find.text('App Two'), findsOneWidget);

      final captured = verify(
        mockApiService.getWelcomeAppList(captureAny),
      ).captured.cast<PageParams>();
      expect(captured, hasLength(2));
      expect(captured[0].pageNo, equals(1));
      expect(captured[1].pageNo, equals(2));
    });
  });
}

Widget _buildTestApp(RecommendState state) {
  return ProviderScope(
    overrides: [recommendProvider.overrideWithValue(state)],
    child: const MaterialApp(
      locale: Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: RecommendPage()),
    ),
  );
}

Widget _buildProviderDrivenTestApp({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      locale: Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: RecommendPage()),
    ),
  );
}

class _InMemoryRecommendPageCacheStore implements RecommendPageCacheStore {
  RecommendPageCacheSnapshot? snapshot;

  @override
  Future<RecommendPageCacheSnapshot?> read() async => snapshot;

  @override
  Future<void> write(RecommendPageCacheSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}

HttpResponse<AppListArrayResponse> _buildCarouselResponse(
  List<AppListItemDTO> data,
) {
  return HttpResponse(
    AppListArrayResponse(code: 200, data: data),
    Response(
      requestOptions: RequestOptions(path: '/visit/getWelcomeCarouselList'),
    ),
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
