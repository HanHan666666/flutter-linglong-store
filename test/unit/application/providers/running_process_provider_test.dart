import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/running_process_provider.dart';
import 'package:linglong_store/domain/models/running_app.dart';

void main() {
  group('RunningProcessState', () {
    test('should create state with default values', () {
      const state = RunningProcessState();

      expect(state.apps, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('should create state with custom values', () {
      final app = RunningApp(
        appId: 'com.example.app',
        name: 'Test App',
        pid: 12345,
      );

      final state = RunningProcessState(
        apps: [app],
        isLoading: true,
        error: 'Test error',
      );

      expect(state.apps.length, equals(1));
      expect(state.isLoading, isTrue);
      expect(state.error, equals('Test error'));
    });

    test('should copy with new values', () {
      const state = RunningProcessState();

      final newState = state.copyWith(
        isLoading: true,
      );

      expect(newState.isLoading, isTrue);
      expect(newState.apps, isEmpty);
      expect(newState.error, isNull);
    });

    test('should clear error when clearError is true', () {
      final state = RunningProcessState(
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
      final state = RunningProcessState(
        error: 'Test error',
      );

      final newState = state.copyWith(
        isLoading: true,
      );

      expect(newState.isLoading, isTrue);
      expect(newState.error, equals('Test error'));
    });

    test('should update apps list', () {
      const state = RunningProcessState();

      final app = RunningApp(
        appId: 'com.example.app',
        name: 'Test App',
        pid: 12345,
      );

      final newState = state.copyWith(apps: [app]);

      expect(newState.apps.length, equals(1));
      expect(newState.apps[0].appId, equals('com.example.app'));
    });

    test('should handle multiple running apps', () {
      final apps = List.generate(
        5,
        (i) => RunningApp(
          appId: 'com.example.app$i',
          name: 'App $i',
          pid: 10000 + i,
        ),
      );

      final state = RunningProcessState(apps: apps);

      expect(state.apps.length, equals(5));
    });
  });

  group('RunningProcessState error handling', () {
    test('should handle error state', () {
      const errorMessage = 'Failed to get running apps';

      final state = RunningProcessState(
        error: errorMessage,
      );

      expect(state.error, equals(errorMessage));
      expect(state.isLoading, isFalse);
    });

    test('should transition from loading to error', () {
      var state = const RunningProcessState();
      state = state.copyWith(isLoading: true);
      expect(state.isLoading, isTrue);
      expect(state.error, isNull);

      state = state.copyWith(
        isLoading: false,
        error: 'Error occurred',
      );

      expect(state.isLoading, isFalse);
      expect(state.error, equals('Error occurred'));
    });
  });
}