import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/recommend_provider.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:linglong_store/presentation/pages/recommend/recommend_page.dart';
import 'package:linglong_store/presentation/widgets/category_filter_section.dart';

void main() {
  group('RecommendPage rust parity', () {
    testWidgets(
      'renders carousel title and list without category filter',
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
                  ),
                ],
                categories: [
                  CategoryInfo(code: 'all', name: '全部'),
                ],
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
      },
    );

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
  });
}

Widget _buildTestApp(RecommendState state) {
  return ProviderScope(
    overrides: [recommendProvider.overrideWithValue(state)],
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: RecommendPage()),
    ),
  );
}
