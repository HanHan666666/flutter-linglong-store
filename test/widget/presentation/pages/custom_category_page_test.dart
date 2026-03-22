import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/sidebar_config_provider.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/network/api_client.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/presentation/pages/custom_category/custom_category_page.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('CustomCategoryPage', () {
    late MockAppApiService mockApiService;
    late String Function()? previousLocaleGetter;

    setUp(() {
      mockApiService = MockAppApiService();
      previousLocaleGetter = ApiClient.getLocale;
      ApiClient.getLocale = () => 'en';
    });

    tearDown(() {
      ApiClient.getLocale = previousLocaleGetter;
    });

    testWidgets('switches category when code changes without provider lifecycle exception', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      when(mockApiService.getSidebarApps(any)).thenAnswer((invocation) async {
        final request = invocation.positionalArguments.single as SidebarAppsRequest;

        return HttpResponse(
          AppListResponse(
            code: 200,
            data: AppListPagedData(
              records: const [],
              total: request.menuCode == 'office' ? 3 : 7,
              size: request.pageSize,
              current: request.pageNo,
              pages: 1,
            ),
          ),
          Response(requestOptions: RequestOptions(path: '/app/sidebar/apps')),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appApiServiceProvider.overrideWithValue(mockApiService),
            sidebarConfigProvider.overrideWith(
              (ref) async => const [
                SidebarMenuDTO(menuCode: 'office', menuName: '办公'),
                SidebarMenuDTO(menuCode: 'system', menuName: '系统'),
              ],
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: CustomCategoryPage(code: 'office')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Office'), findsOneWidget);
      expect(find.text('(3)'), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appApiServiceProvider.overrideWithValue(mockApiService),
            sidebarConfigProvider.overrideWith(
              (ref) async => const [
                SidebarMenuDTO(menuCode: 'office', menuName: '办公'),
                SidebarMenuDTO(menuCode: 'system', menuName: '系统'),
              ],
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: CustomCategoryPage(code: 'system')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('(7)'), findsOneWidget);
    });
  });
}
