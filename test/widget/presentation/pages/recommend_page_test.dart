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
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/storage/recommend_page_cache.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:linglong_store/presentation/pages/recommend/recommend_page.dart';
import 'package:linglong_store/presentation/widgets/category_filter_section.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  group('RecommendPage banner refresh', () {
    testWidgets(
      'renders brand banner with extracted background and simplified copy',
      (tester) async {
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
                    description: 'Banner description',
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
        expect(find.text('Banner description'), findsOneWidget);
        expect(
          find.byKey(const Key('recommend-banner-background')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('recommend-banner-info-dock')),
          findsOneWidget,
        );
        expect(find.text('版本：-'), findsNothing);
        expect(find.text('分类：-'), findsNothing);
        expect(find.byType(CategoryFilterSection), findsNothing);
      },
    );

    testWidgets('keeps banner taller and indicator below info dock', (
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
                  description: 'Banner description',
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

      final backgroundRect = tester.getRect(
        find.byKey(const Key('recommend-banner-background')),
      );
      final infoDockRect = tester.getRect(
        find.byKey(const Key('recommend-banner-info-dock')),
      );
      final activeIndicatorRect = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AnimatedContainer &&
              widget.constraints ==
                  const BoxConstraints.tightFor(width: 20, height: 8),
        ),
      );

      expect(backgroundRect.height, 236);
      expect(
        activeIndicatorRect.top,
        greaterThanOrEqualTo(infoDockRect.bottom + 4),
      );
    });

    testWidgets('offsets banner info dock to avoid left carousel control', (
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
                  description: 'Banner description',
                ),
                BannerInfo(
                  id: 'banner-2',
                  title: 'Banner App 2',
                  imageUrl: '',
                  targetAppId: 'banner.app.2',
                  description: 'Banner description 2',
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

      final backgroundRect = tester.getRect(
        find.byKey(const Key('recommend-banner-background')),
      );
      final infoDockRect = tester.getRect(
        find.byKey(const Key('recommend-banner-info-dock')),
      );
      final leftControlRect = tester.getRect(
        find.ancestor(
          of: find.byIcon(Icons.chevron_left),
          matching: find.byType(SizedBox),
        ),
      );

      expect(infoDockRect.left, greaterThan(leftControlRect.right + 8));
      expect(infoDockRect.left, greaterThan(backgroundRect.left + 80));
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

    testWidgets('renders banner refresh structure in dark mode', (
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
                  description: 'Banner description',
                ),
              ],
              categories: [CategoryInfo(code: 'all', name: '全部')],
              apps: PaginatedResponse<RecommendAppInfo>(
                items: [],
                total: 0,
                page: 1,
                pageSize: 10,
                hasMore: false,
              ),
            ),
          ),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();

      expect(find.text('Banner App'), findsOneWidget);
      expect(
        find.byKey(const Key('recommend-banner-background')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('recommend-banner-info-dock')),
        findsOneWidget,
      );
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

Widget _buildTestApp(
  RecommendState state, {
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [recommendProvider.overrideWithValue(state)],
    child: MaterialApp(
      locale: const Locale('zh'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: RecommendPage()),
    ),
  );
}

Widget _buildProviderDrivenTestApp({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('zh'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: RecommendPage()),
    ),
  );
}

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
