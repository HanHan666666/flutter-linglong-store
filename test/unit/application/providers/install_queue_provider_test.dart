import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/install_task.dart';

void main() {
  group('InstallQueueState', () {
    test('should create state with default values', () {
      const state = InstallQueueState();

      expect(state.queue, isEmpty);
      expect(state.currentTask, isNull);
      expect(state.history, isEmpty);
      expect(state.isProcessing, isFalse);
    });

    test('should create state with custom values', () {
      final task = InstallTask(
        id: 'test-id',
        appId: 'com.example.test',
        appName: 'Test App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final state = InstallQueueState(
        queue: [task],
        currentTask: task,
        history: [task],
        isProcessing: true,
      );

      expect(state.queue.length, equals(1));
      expect(state.currentTask, isNotNull);
      expect(state.history.length, equals(1));
      expect(state.isProcessing, isTrue);
    });

    test('should check if app is in queue', () {
      final task = InstallTask(
        id: 'test-id',
        appId: 'com.example.test',
        appName: 'Test App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final state = InstallQueueState(queue: [task]);

      expect(state.isAppInQueue('com.example.test'), isTrue);
      expect(state.isAppInQueue('com.example.other'), isFalse);
    });

    test('should get app install status', () {
      final task = InstallTask(
        id: 'test-id',
        appId: 'com.example.test',
        appName: 'Test App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final state = InstallQueueState(queue: [task]);

      final status = state.getAppInstallStatus('com.example.test');
      expect(status, isNotNull);
      expect(status!.appId, equals('com.example.test'));

      final noStatus = state.getAppInstallStatus('com.example.other');
      expect(noStatus, isNull);
    });

    test('should check hasActiveTasks', () {
      const emptyState = InstallQueueState();
      expect(emptyState.hasActiveTasks(), isFalse);

      final task = InstallTask(
        id: 'test-id',
        appId: 'com.example.test',
        appName: 'Test App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final stateWithQueue = InstallQueueState(queue: [task]);
      expect(stateWithQueue.hasActiveTasks(), isTrue);

      final stateWithCurrent = InstallQueueState(currentTask: task);
      expect(stateWithCurrent.hasActiveTasks(), isTrue);
    });
  });

  group('InstallTask', () {
    test('should create task with required fields', () {
      final task = InstallTask(
        id: 'test-id',
        appId: 'com.example.test',
        appName: 'Test App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(task.id, equals('test-id'));
      expect(task.appId, equals('com.example.test'));
      expect(task.appName, equals('Test App'));
      expect(task.status, equals(InstallStatus.pending));
      expect(task.progress, equals(0.0));
    });

    test('should support copyWith', () {
      final task = InstallTask(
        id: 'test-id',
        appId: 'com.example.test',
        appName: 'Test App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final updatedTask = task.copyWith(
        status: InstallStatus.installing,
        progress: 50.0,
        message: 'Installing...',
      );

      expect(updatedTask.id, equals('test-id'));
      expect(updatedTask.status, equals(InstallStatus.installing));
      expect(updatedTask.progress, equals(50.0));
      expect(updatedTask.message, equals('Installing...'));
    });

    test('should check task states correctly', () {
      final pendingTask = InstallTask(
        id: 'test-id',
        appId: 'com.example.test',
        appName: 'Test App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(pendingTask.isProcessing, isFalse);
      expect(pendingTask.isCompleted, isFalse);
      expect(pendingTask.isFailed, isFalse);

      final installingTask = pendingTask.copyWith(
        status: InstallStatus.installing,
      );
      expect(installingTask.isProcessing, isTrue);
      expect(installingTask.isCompleted, isFalse);

      final successTask = installingTask.copyWith(
        status: InstallStatus.success,
      );
      expect(successTask.isProcessing, isFalse);
      expect(successTask.isCompleted, isTrue);
      expect(successTask.isSuccess, isTrue);

      final failedTask = installingTask.copyWith(status: InstallStatus.failed);
      expect(failedTask.isProcessing, isFalse);
      expect(failedTask.isCompleted, isTrue);
      expect(failedTask.isFailed, isTrue);
    });
  });

  group('EnqueueTaskParams', () {
    test('should create params correctly', () {
      const params = EnqueueTaskParams(
        kind: InstallTaskKind.install,
        appId: 'com.example.app',
        appName: 'Test App',
        icon: 'https://example.com/icon.png',
        version: '1.0.0',
        force: true,
      );

      expect(params.appId, 'com.example.app');
      expect(params.kind, InstallTaskKind.install);
      expect(params.appName, 'Test App');
      expect(params.icon, 'https://example.com/icon.png');
      expect(params.version, '1.0.0');
      expect(params.force, true);
    });
  });
}
