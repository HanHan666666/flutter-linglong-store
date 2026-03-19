import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/recommend_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:linglong_store/presentation/pages/recommend/recommend_page.dart';
import 'package:linglong_store/presentation/widgets/category_filter_section.dart';

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
