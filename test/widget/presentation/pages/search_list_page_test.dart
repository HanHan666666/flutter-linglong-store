import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/application_card_state_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/presentation/pages/search_list/search_list_page.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  testWidgets(
    'search list page uses top header search as the only input entry',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SearchListPage(),
          ),
        ),
      );

      expect(find.byType(TextField), findsNothing);
      expect(find.text('在顶部搜索框输入关键词'), findsOneWidget);
      expect(find.text('按 Enter 开始搜索应用'), findsOneWidget);
    },
  );

  testWidgets('auto loads next page when search results cannot fill viewport', (
    tester,
  ) async {
    final mockApiService = MockAppApiService();

    when(mockApiService.getSearchAppList(any)).thenAnswer((invocation) async {
      final request =
          invocation.positionalArguments.single as SearchAppListRequest;

      if (request.pageNo == 1) {
        return _buildSearchResponse(
          const [
            AppListItemDTO(
              appId: 'search.one',
              appName: 'Search One',
              appVersion: '1.0.0',
            ),
          ],
          currentPage: 1,
          total: 2,
          pages: 2,
        );
      }

      return _buildSearchResponse(
        const [
          AppListItemDTO(
            appId: 'search.two',
            appName: 'Search Two',
            appVersion: '2.0.0',
          ),
        ],
        currentPage: 2,
        total: 2,
        pages: 2,
      );
    });

    await tester.binding.setSurfaceSize(const Size(1600, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appApiServiceProvider.overrideWithValue(mockApiService),
          applicationCardStateIndexProvider.overrideWithValue(
            const ApplicationCardStateIndex(
              installedVersionByAppId: {},
              updateAppIds: {},
              activeTasksByAppId: {},
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SearchListPage(initialQuery: 'browser'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Search One'), findsOneWidget);
    expect(find.text('Search Two'), findsOneWidget);

    final captured = verify(
      mockApiService.getSearchAppList(captureAny),
    ).captured.cast<SearchAppListRequest>();

    expect(captured.map((r) => r.pageNo), containsAllInOrder([1, 2]));
    expect(captured.every((r) => r.keyword == 'browser'), isTrue);
    expect(captured.every((r) => r.pageSize == 20), isTrue);
  });
}

HttpResponse<AppListResponse> _buildSearchResponse(
  List<AppListItemDTO> records, {
  required int currentPage,
  required int total,
  required int pages,
}) {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: records,
        total: total,
        size: 20,
        current: currentPage,
        pages: pages,
      ),
    ),
    Response(requestOptions: RequestOptions(path: '/visit/getSearchAppList')),
  );
}
