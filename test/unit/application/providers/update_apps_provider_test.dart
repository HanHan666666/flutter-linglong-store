import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/core/di/repository_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/data/repositories/app_repository_impl.dart';
import 'package:linglong_store/domain/models/installed_app.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('UpdatableApp', () {
    test('should create UpdatableApp with correct properties', () {
      const installedApp = InstalledApp(
        appId: 'com.example.app',
        name: 'Test App',
        version: '1.0.0',
        icon: 'https://example.com/icon.png',
      );

      const updatableApp = UpdatableApp(
        installedApp: installedApp,
        latestVersion: '2.0.0',
        latestVersionDescription: 'Bug fixes and improvements',
        latestVersionSize: '20 MB',
      );

      expect(updatableApp.appId, equals('com.example.app'));
      expect(updatableApp.name, equals('Test App'));
      expect(updatableApp.currentVersion, equals('1.0.0'));
      expect(updatableApp.latestVersion, equals('2.0.0'));
      expect(updatableApp.latestVersionDescription, equals('Bug fixes and improvements'));
      expect(updatableApp.latestVersionSize, equals('20 MB'));
      expect(updatableApp.icon, equals('https://example.com/icon.png'));
    });

    test('should handle null optional fields', () {
      const installedApp = InstalledApp(
        appId: 'com.example.app',
        name: 'Test App',
        version: '1.0.0',
      );

      const updatableApp = UpdatableApp(
        installedApp: installedApp,
        latestVersion: '2.0.0',
      );

      expect(updatableApp.latestVersionDescription, isNull);
      expect(updatableApp.latestVersionSize, isNull);
      expect(updatableApp.icon, isNull);
    });
  });

  group('UpdateAppsState', () {
    test('should create state with default values', () {
      const state = UpdateAppsState();

      expect(state.apps, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasLoadedOnce, isFalse);
      expect(state.error, isNull);
      expect(state.count, equals(0));
      expect(state.isEmpty, isTrue);
    });

    test('should create state with custom values', () {
      const installedApp = InstalledApp(
        appId: 'com.example.app',
        name: 'Test App',
        version: '1.0.0',
      );

      const updatableApp = UpdatableApp(
        installedApp: installedApp,
        latestVersion: '2.0.0',
      );

      const state = UpdateAppsState(
        apps: [updatableApp],
        isLoading: true,
        hasLoadedOnce: true,
        error: 'Test error',
      );

      expect(state.apps.length, equals(1));
      expect(state.isLoading, isTrue);
      expect(state.hasLoadedOnce, isTrue);
      expect(state.error, equals('Test error'));
      expect(state.count, equals(1));
      expect(state.isEmpty, isFalse);
    });

    test('should copy with new values', () {
      const state = UpdateAppsState();

      final newState = state.copyWith(
        isLoading: true,
        hasLoadedOnce: true,
      );

      expect(newState.isLoading, isTrue);
      expect(newState.hasLoadedOnce, isTrue);
      expect(newState.apps, isEmpty);
      expect(newState.error, isNull);
    });

    test('should clear error when clearError is true', () {
      const state = UpdateAppsState(
        error: 'Test error',
      );

      final newState = state.copyWith(
        isLoading: true,
        clearError: true,
      );

      expect(newState.isLoading, isTrue);
      expect(newState.error, isNull);
    });

    test('should preserve error when not clearing', () {
      const state = UpdateAppsState(
        error: 'Test error',
      );

      final newState = state.copyWith(
        isLoading: true,
      );

      expect(newState.isLoading, isTrue);
      expect(newState.error, equals('Test error'));
    });

    test('should update apps list', () {
      const state = UpdateAppsState();

      const installedApp = InstalledApp(
        appId: 'com.example.app',
        name: 'Test App',
        version: '1.0.0',
      );

      const updatableApp = UpdatableApp(
        installedApp: installedApp,
        latestVersion: '2.0.0',
      );

      final newState = state.copyWith(apps: [updatableApp]);

      expect(newState.apps.length, equals(1));
      expect(newState.count, equals(1));
      expect(newState.isEmpty, isFalse);
    });
  });

  group('UpdateAppsState count', () {
    test('should return correct count for multiple apps', () {
      final apps = List.generate(
        5,
        (i) => UpdatableApp(
          installedApp: InstalledApp(
            appId: 'com.example.app$i',
            name: 'App $i',
            version: '1.0.0',
          ),
          latestVersion: '2.0.0',
        ),
      );

      final state = UpdateAppsState(apps: apps);

      expect(state.count, equals(5));
    });
  });

  group('UpdateApps provider lifecycle', () {
    test(
      'keeps startup update results after listeners are removed',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final mockApiService = MockAppApiService();
        const installedApp = InstalledApp(
          appId: 'com.example.app',
          name: 'Test App',
          version: '1.0.0',
          arch: 'x86_64',
        );

        when(mockApiService.appCheckUpdate(any)).thenAnswer(
          (_) async => HttpResponse(
            const AppDetailListResponse(
              code: 200,
              data: [
                AppDetailDTO(
                  appId: 'com.example.app',
                  appName: 'Test App',
                  appVersion: '2.0.0',
                ),
              ],
            ),
            Response(
              requestOptions: RequestOptions(path: '/app/appCheckUpdate'),
            ),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appApiServiceProvider.overrideWithValue(mockApiService),
            appRepositoryProvider.overrideWithValue(
              AppRepositoryImpl.withService(mockApiService),
            ),
            installedAppsProvider.overrideWithValue(
              const InstalledAppsState(apps: [installedApp]),
            ),
          ],
        );
        addTearDown(container.dispose);

        final subscription = container.listen<UpdateAppsState>(
          updateAppsProvider,
          (_, __) {},
          fireImmediately: true,
        );

        await container.read(updateAppsProvider.notifier).checkUpdates();

        expect(container.read(updateAppsProvider).count, 1);
        expect(
          container.read(updateAppsProvider).apps.single.latestVersion,
          '2.0.0',
        );

        subscription.close();
        await Future<void>.delayed(Duration.zero);

        final retainedState = container.read(updateAppsProvider);

        expect(retainedState.count, 1);
        expect(retainedState.apps.single.latestVersion, '2.0.0');
        verify(mockApiService.appCheckUpdate(any)).called(1);
      },
    );

    test(
      'deduplicates installed apps by appId and keeps only the highest local version',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final mockApiService = MockAppApiService();

        when(mockApiService.appCheckUpdate(any)).thenAnswer(
          (_) async => HttpResponse(
            const AppDetailListResponse(
              code: 200,
              data: [
                AppDetailDTO(
                  appId: 'org.example.demo',
                  appName: 'Demo',
                  appVersion: '3.0.0',
                ),
              ],
            ),
            Response(
              requestOptions: RequestOptions(path: '/app/appCheckUpdate'),
            ),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appApiServiceProvider.overrideWithValue(mockApiService),
            appRepositoryProvider.overrideWithValue(
              AppRepositoryImpl.withService(mockApiService),
            ),
            installedAppsProvider.overrideWithValue(
              const InstalledAppsState(
                apps: [
                  InstalledApp(
                    appId: 'org.example.demo',
                    name: 'Demo',
                    version: '1.0.0',
                    arch: 'x86_64',
                  ),
                  InstalledApp(
                    appId: 'org.example.demo',
                    name: 'Demo',
                    version: '2.0.0',
                    arch: 'x86_64',
                  ),
                ],
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(updateAppsProvider.notifier).checkUpdates();

        final captured = verify(
          mockApiService.appCheckUpdate(captureAny),
        ).captured.single as List<AppCheckVersionBO>;

        expect(captured, hasLength(1));
        expect(captured.single.appId, 'org.example.demo');
        expect(captured.single.version, '2.0.0');
        expect(
          container.read(updateAppsProvider).apps.single.currentVersion,
          '2.0.0',
        );
      },
    );
  });

  group('UpdateApps provider concurrency', () {
    test(
      'keeps the freshest result when overlapping checks finish out of order',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final mockApiService = MockAppApiService();
        final installedApps = MutableInstalledApps(
          initialApps: const [
            InstalledApp(
              appId: 'org.example.demo',
              name: 'Demo',
              version: '1.0.0',
              arch: 'x86_64',
            ),
          ],
        );

        when(mockApiService.appCheckUpdate(any)).thenAnswer((invocation) async {
          final payload =
              invocation.positionalArguments.single as List<AppCheckVersionBO>;
          final version = payload.single.version;

          if (version == '1.0.0') {
            await Future<void>.delayed(const Duration(milliseconds: 60));
            return HttpResponse(
              const AppDetailListResponse(
                code: 200,
                data: [
                  AppDetailDTO(
                    appId: 'org.example.demo',
                    appName: 'Demo',
                    appVersion: '2.0.0',
                  ),
                ],
              ),
              Response(
                requestOptions: RequestOptions(path: '/app/appCheckUpdate'),
              ),
            );
          }

          await Future<void>.delayed(const Duration(milliseconds: 10));
          return HttpResponse(
            const AppDetailListResponse(code: 200, data: []),
            Response(
              requestOptions: RequestOptions(path: '/app/appCheckUpdate'),
            ),
          );
        });

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appApiServiceProvider.overrideWithValue(mockApiService),
            appRepositoryProvider.overrideWithValue(
              AppRepositoryImpl.withService(mockApiService),
            ),
            installedAppsProvider.overrideWith(() => installedApps),
          ],
        );
        addTearDown(container.dispose);

        final firstCheck =
            container.read(updateAppsProvider.notifier).checkUpdates();

        await Future<void>.delayed(const Duration(milliseconds: 5));
        installedApps.setApps(
          const [
            InstalledApp(
              appId: 'org.example.demo',
              name: 'Demo',
              version: '2.0.0',
              arch: 'x86_64',
            ),
          ],
        );

        final secondCheck =
            container.read(updateAppsProvider.notifier).checkUpdates();

        await Future.wait([firstCheck, secondCheck]);

        expect(container.read(updateAppsProvider).apps, isEmpty);
      },
    );
  });
}

class MutableInstalledApps extends InstalledApps {
  MutableInstalledApps({required this.initialApps});

  final List<InstalledApp> initialApps;

  @override
  InstalledAppsState build() {
    return InstalledAppsState(apps: initialApps);
  }

  void setApps(List<InstalledApp> apps) {
    state = InstalledAppsState(apps: apps);
  }
}
