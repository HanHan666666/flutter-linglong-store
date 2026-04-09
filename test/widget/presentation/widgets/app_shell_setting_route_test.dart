import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/recommend_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/core/config/routes.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:linglong_store/presentation/pages/setting/setting_page.dart';
import 'package:linglong_store/presentation/widgets/app_shell.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const windowManagerChannel = MethodChannel('window_manager');

  setUpAll(() async {
    await AppLogger.init();

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

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowManagerChannel, (call) async {
          switch (call.method) {
            case 'isMaximized':
              return false;
            case 'isMinimized':
              return false;
            case 'isVisible':
              return true;
            case 'isFocused':
              return true;
            case 'startDragging':
            case 'minimize':
            case 'maximize':
            case 'unmaximize':
            case 'close':
              return null;
            default:
              return null;
          }
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowManagerChannel, null);
  });

  testWidgets('settings page content renders when opened inside AppShell', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockApiService = MockAppApiService();

    when(mockApiService.getSearchAppList(any)).thenAnswer(
      (_) async => HttpResponse(
        AppListResponse(
          code: 200,
          data: const AppListPagedData(
            records: [],
            total: 123,
            size: 1,
            current: 1,
            pages: 123,
          ),
        ),
        Response(
          requestOptions: RequestOptions(path: '/visit/getSearchAppList'),
        ),
      ),
    );

    final router = GoRouter(
      initialLocation: AppRoutes.recommend,
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(
            currentPath: state.uri.path,
            currentUri: state.uri,
            child: child,
          ),
          routes: [
            GoRoute(
              path: AppRoutes.recommend,
              builder: (context, state) => const SizedBox.shrink(),
            ),
            GoRoute(
              path: AppRoutes.myApps,
              builder: (context, state) => const SizedBox.shrink(),
            ),
            GoRoute(
              path: AppRoutes.setting,
              builder: (context, state) => const SettingPage(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appApiServiceProvider.overrideWithValue(mockApiService),
          recommendProvider.overrideWithValue(const RecommendState()),
          installQueueProvider.overrideWith(() => TestInstallQueue()),
          updateAppsProvider.overrideWith(() => TestUpdateApps()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.go(AppRoutes.setting);
    await tester.pumpAndSettle();

    expect(find.text('语言设置'), findsOneWidget);
    expect(find.text('主题设置'), findsOneWidget);
    final directNavigationScrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SettingPage),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      directNavigationScrollable.position.viewportDimension,
      greaterThan(0),
    );
  });

  testWidgets('settings page opens from the real sidebar action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockApiService = MockAppApiService();

    when(mockApiService.getSearchAppList(any)).thenAnswer(
      (_) async => HttpResponse(
        AppListResponse(
          code: 200,
          data: const AppListPagedData(
            records: [],
            total: 123,
            size: 1,
            current: 1,
            pages: 123,
          ),
        ),
        Response(
          requestOptions: RequestOptions(path: '/visit/getSearchAppList'),
        ),
      ),
    );

    final router = GoRouter(
      initialLocation: AppRoutes.recommend,
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(
            currentPath: state.uri.path,
            currentUri: state.uri,
            child: child,
          ),
          routes: [
            GoRoute(
              path: AppRoutes.recommend,
              builder: (context, state) => const SizedBox.shrink(),
            ),
            GoRoute(
              path: AppRoutes.myApps,
              builder: (context, state) => const SizedBox.shrink(),
            ),
            GoRoute(
              path: AppRoutes.setting,
              builder: (context, state) => const SettingPage(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appApiServiceProvider.overrideWithValue(mockApiService),
          recommendProvider.overrideWithValue(const RecommendState()),
          installQueueProvider.overrideWith(() => TestInstallQueue()),
          updateAppsProvider.overrideWith(() => TestUpdateApps()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    expect(find.text('语言设置'), findsOneWidget);
    expect(find.text('主题设置'), findsOneWidget);
    final sidebarNavigationScrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SettingPage),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      sidebarNavigationScrollable.position.viewportDimension,
      greaterThan(0),
    );
  });
}

class TestInstallQueue extends InstallQueue {
  @override
  InstallQueueState build() => const InstallQueueState();
}

class TestUpdateApps extends UpdateApps {
  @override
  UpdateAppsState build() => const UpdateAppsState();

  @override
  Future<void> checkUpdates() async {}

  @override
  Future<void> refresh() async {}
}
