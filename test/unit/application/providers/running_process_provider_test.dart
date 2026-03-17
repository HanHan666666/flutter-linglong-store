import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/running_process_provider.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:mockito/mockito.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  group('enrichRunningAppsWithDetails', () {
    late MockAppRepository appRepository;

    setUp(() {
      appRepository = MockAppRepository();
    });

    test(
      'should reuse installed app detail enrichment for running app icons',
      () async {
        const runningApps = [
          RunningApp(
            id: 'container-1',
            appId: 'org.deepin.calculator',
            name: 'org.deepin.calculator',
            version: '6.5.31.1',
            arch: 'x86_64',
            channel: 'main',
            source: 'main',
            pid: 12345,
            containerId: 'container-1',
          ),
        ];

        when(appRepository.enrichInstalledAppsWithDetails(any)).thenAnswer(
          (_) async => const [
            InstalledApp(
              appId: 'org.deepin.calculator',
              name: '计算器',
              version: '6.5.31.1',
              icon: 'https://example.com/calculator.png',
            ),
          ],
        );

        final enrichedApps = await enrichRunningAppsWithDetails(
          appRepository: appRepository,
          apps: runningApps,
        );

        expect(enrichedApps, hasLength(1));
        expect(enrichedApps.first.name, equals('计算器'));
        expect(
          enrichedApps.first.icon,
          equals('https://example.com/calculator.png'),
        );
        verify(appRepository.enrichInstalledAppsWithDetails(any)).called(1);
      },
    );

    test(
      'should keep original running app data when enrichment returns no match',
      () async {
        const runningApps = [
          RunningApp(
            id: 'container-1',
            appId: 'org.deepin.calculator',
            name: 'deepin-calculator',
            version: '6.5.31.1',
            arch: 'x86_64',
            channel: 'main',
            source: 'main',
            pid: 12345,
            containerId: 'container-1',
          ),
        ];

        when(
          appRepository.enrichInstalledAppsWithDetails(any),
        ).thenAnswer((_) async => const []);

        final enrichedApps = await enrichRunningAppsWithDetails(
          appRepository: appRepository,
          apps: runningApps,
        );

        expect(enrichedApps.first.name, equals('deepin-calculator'));
        expect(enrichedApps.first.icon, isNull);
      },
    );
  });

  group('RunningProcessState', () {
    const app = RunningApp(
      id: 'container-1',
      appId: 'org.example.app',
      name: 'Example App',
      version: '1.0.0',
      arch: 'x86_64',
      channel: 'main',
      source: 'main',
      pid: 12345,
      containerId: 'container-1',
    );

    test('should create state with default values', () {
      const state = RunningProcessState();

      expect(state.apps, isEmpty);
      expect(state.isInitialLoading, isFalse);
      expect(state.isRefreshing, isFalse);
      expect(state.error, isNull);
      expect(state.killLoadingIds, isEmpty);
      expect(state.lastRefreshedAt, isNull);
    });

    test('should create state with custom values', () {
      final refreshedAt = DateTime(2026, 3, 17, 12, 0);
      final state = RunningProcessState(
        apps: const [app],
        isInitialLoading: true,
        isRefreshing: true,
        error: 'Test error',
        lastRefreshedAt: refreshedAt,
        killLoadingIds: const {'container-1'},
      );

      expect(state.apps.length, equals(1));
      expect(state.isInitialLoading, isTrue);
      expect(state.isRefreshing, isTrue);
      expect(state.error, equals('Test error'));
      expect(state.lastRefreshedAt, equals(refreshedAt));
      expect(state.killLoadingIds, contains('container-1'));
    });

    test('should copy with new values', () {
      const state = RunningProcessState();

      final newState = state.copyWith(
        apps: const [app],
        isInitialLoading: true,
        isRefreshing: true,
        lastRefreshedAt: DateTime(2026, 3, 17, 18, 30),
      );

      expect(newState.apps, hasLength(1));
      expect(newState.isInitialLoading, isTrue);
      expect(newState.isRefreshing, isTrue);
      expect(newState.lastRefreshedAt, isNotNull);
    });

    test('should clear error when clearError is true', () {
      const state = RunningProcessState(error: 'Test error');

      final newState = state.copyWith(isRefreshing: true, clearError: true);

      expect(newState.isRefreshing, isTrue);
      expect(newState.error, isNull);
    });

    test('should report hasData when apps are present', () {
      const state = RunningProcessState(apps: [app]);

      expect(state.hasData, isTrue);
    });

    test('should preserve kill loading ids on copyWith', () {
      const state = RunningProcessState(killLoadingIds: {'container-1'});

      final newState = state.copyWith(apps: const [app]);

      expect(newState.killLoadingIds, contains('container-1'));
      expect(newState.apps.first.appId, equals('org.example.app'));
    });
  });
}
