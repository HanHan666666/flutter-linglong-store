import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/domain/models/installed_app.dart';

void main() {
  group('UpdatableApp', () {
    test('should create UpdatableApp with correct properties', () {
      final installedApp = InstalledApp(
        appId: 'com.example.app',
        name: 'Test App',
        version: '1.0.0',
        icon: 'https://example.com/icon.png',
      );

      final updatableApp = UpdatableApp(
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
      final installedApp = InstalledApp(
        appId: 'com.example.app',
        name: 'Test App',
        version: '1.0.0',
      );

      final updatableApp = UpdatableApp(
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
      expect(state.error, isNull);
      expect(state.count, equals(0));
      expect(state.isEmpty, isTrue);
    });

    test('should create state with custom values', () {
      final installedApp = InstalledApp(
        appId: 'com.example.app',
        name: 'Test App',
        version: '1.0.0',
      );

      final updatableApp = UpdatableApp(
        installedApp: installedApp,
        latestVersion: '2.0.0',
      );

      final state = UpdateAppsState(
        apps: [updatableApp],
        isLoading: true,
        error: 'Test error',
      );

      expect(state.apps.length, equals(1));
      expect(state.isLoading, isTrue);
      expect(state.error, equals('Test error'));
      expect(state.count, equals(1));
      expect(state.isEmpty, isFalse);
    });

    test('should copy with new values', () {
      const state = UpdateAppsState();

      final newState = state.copyWith(
        isLoading: true,
      );

      expect(newState.isLoading, isTrue);
      expect(newState.apps, isEmpty);
      expect(newState.error, isNull);
    });

    test('should clear error when clearError is true', () {
      final state = UpdateAppsState(
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
      final state = UpdateAppsState(
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

      final installedApp = InstalledApp(
        appId: 'com.example.app',
        name: 'Test App',
        version: '1.0.0',
      );

      final updatableApp = UpdatableApp(
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
}