import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/core/config/routes.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/presentation/widgets/title_bar.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/icons/logo.svg') {
            final bytes = Uint8List.fromList(
              utf8.encode(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"></svg>',
              ),
            );
            return ByteData.view(bytes.buffer);
          }
          return null;
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  testWidgets('submitting header search navigates to search page with q query', (
    tester,
  ) async {
    final mockApiService = MockAppApiService();
    when(
      mockApiService.getSearchAppList(any),
    ).thenAnswer((_) async => _buildSearchResponse());

    await tester.pumpWidget(_buildRouterApp(mockApiService));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'firefox');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('route:/search_list?q=firefox'), findsOneWidget);
  });

  testWidgets('typing in header search shows remote suggestions', (tester) async {
    final mockApiService = MockAppApiService();
    when(
      mockApiService.getSearchAppList(any),
    ).thenAnswer((_) async => _buildSearchResponse());

    await tester.pumpWidget(_buildRouterApp(mockApiService));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '浏览');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('浏览器'), findsOneWidget);
  });

  testWidgets('tapping header suggestion opens detail page', (tester) async {
    final mockApiService = MockAppApiService();
    when(
      mockApiService.getSearchAppList(any),
    ).thenAnswer((_) async => _buildSearchResponse());

    await tester.pumpWidget(_buildRouterApp(mockApiService));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '浏览');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('浏览器'));
    await tester.pumpAndSettle();

    expect(find.text('detail:org.example.browser:repo:binary'), findsOneWidget);
  });

  testWidgets('header search uses single-layer pill styling by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomTitleBar(
              isMaximized: false,
              onMinimize: () {},
              onMaximize: () {},
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    final decoration = textField.decoration!;
    final searchContainerFinder = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxWidth == 534,
    );
    final searchContainer = tester.widget<Container>(searchContainerFinder);
    final boxDecoration = searchContainer.decoration! as BoxDecoration;
    final searchSize = tester.getSize(searchContainerFinder);
    final border = boxDecoration.border as Border?;

    expect(decoration.filled, isFalse);
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
    expect(border, isNotNull);
    expect(border!.top.color, AppColors.borderSecondary);
    expect(border.top.width, 1);
    expect(boxDecoration.color, AppColors.surfaceContainerHighest);
    expect(searchSize.height, 32);
  });

  testWidgets('header search border turns blue when focused', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomTitleBar(
              isMaximized: false,
              onMinimize: () {},
              onMaximize: () {},
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final searchContainerFinder = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxWidth == 534,
    );
    final searchContainer = tester.widget<Container>(searchContainerFinder);
    final boxDecoration = searchContainer.decoration! as BoxDecoration;
    final border = boxDecoration.border as Border?;

    expect(border, isNotNull);
    expect(border!.top.color, AppColors.primary);
    expect(border.top.width, 1);
  });
}

Widget _buildRouterApp(MockAppApiService mockApiService) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: CustomTitleBar(
            isMaximized: false,
            onMinimize: () {},
            onMaximize: () {},
            onClose: () {},
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.searchList,
        builder: (context, state) => Scaffold(
          body: Text(
            'route:${state.uri.path}?q=${state.uri.queryParameters['q'] ?? ''}',
          ),
        ),
      ),
      GoRoute(
        path: '/app/:id',
        builder: (context, state) {
          final appInfo = state.extra as InstalledApp?;
          return Scaffold(
            body: Text(
              'detail:${state.pathParameters['id']}:${appInfo?.repoName ?? ''}:${appInfo?.module ?? ''}',
            ),
          );
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [appApiServiceProvider.overrideWithValue(mockApiService)],
    child: MaterialApp.router(
      locale: const Locale('zh'),
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

HttpResponse<AppListResponse> _buildSearchResponse() {
  return HttpResponse(
    const AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: [
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
