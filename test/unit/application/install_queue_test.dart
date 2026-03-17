import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';

void main() {
  group('InstallQueueProvider', () {
    test('should create InstallTask with correct initial state', () {
      final task = InstallTask(
        id: 'test-id',
        appId: 'com.example.app',
        appName: 'Test App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(task.id, 'test-id');
      expect(task.appId, 'com.example.app');
      expect(task.appName, 'Test App');
      expect(task.status, InstallStatus.pending);
      expect(task.progress, 0.0);
    });

    test('InstallTask extension should work correctly', () {
      final pendingTask = InstallTask(
        id: 'test-id',
        appId: 'com.example.app',
        appName: 'Test App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(pendingTask.isProcessing, false);
      expect(pendingTask.isCompleted, false);
      expect(pendingTask.isFailed, false);
      expect(pendingTask.isSuccess, false);

      final installingTask = pendingTask.copyWith(
        status: InstallStatus.installing,
      );
      expect(installingTask.isProcessing, true);
      expect(installingTask.isCompleted, false);

      final successTask = installingTask.copyWith(
        status: InstallStatus.success,
      );
      expect(successTask.isProcessing, false);
      expect(successTask.isCompleted, true);
      expect(successTask.isSuccess, true);

      final failedTask = installingTask.copyWith(
        status: InstallStatus.failed,
      );
      expect(failedTask.isProcessing, false);
      expect(failedTask.isCompleted, true);
      expect(failedTask.isFailed, true);
    });

    test('InstallQueueState should check if app is in queue', () {
      final task1 = InstallTask(
        id: 'task-1',
        appId: 'com.example.app1',
        appName: 'App 1',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final task2 = InstallTask(
        id: 'task-2',
        appId: 'com.example.app2',
        appName: 'App 2',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final state = InstallQueueState(
        queue: [task2],
        currentTask: task1,
      );

      expect(state.isAppInQueue('com.example.app1'), true);
      expect(state.isAppInQueue('com.example.app2'), true);
      expect(state.isAppInQueue('com.example.app3'), false);
    });

    test('InstallQueueState should get app install status', () {
      final currentTask = InstallTask(
        id: 'current',
        appId: 'com.example.current',
        appName: 'Current App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final queuedTask = InstallTask(
        id: 'queued',
        appId: 'com.example.queued',
        appName: 'Queued App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final historyTask = InstallTask(
        id: 'history',
        appId: 'com.example.history',
        appName: 'History App',
        status: InstallStatus.success,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final state = InstallQueueState(
        queue: [queuedTask],
        currentTask: currentTask,
        history: [historyTask],
      );

      expect(state.getAppInstallStatus('com.example.current'), currentTask);
      expect(state.getAppInstallStatus('com.example.queued'), queuedTask);
      expect(state.getAppInstallStatus('com.example.history'), historyTask);
      expect(state.getAppInstallStatus('com.example.unknown'), null);
    });

    test('InstallQueueState hasActiveTasks should work correctly', () {
      const emptyState = InstallQueueState();
      expect(emptyState.hasActiveTasks(), false);

      final task = InstallTask(
        id: 'task',
        appId: 'com.example.app',
        appName: 'App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final stateWithQueue = InstallQueueState(queue: [task]);
      expect(stateWithQueue.hasActiveTasks(), true);

      final stateWithCurrentTask = InstallQueueState(currentTask: task);
      expect(stateWithCurrentTask.hasActiveTasks(), true);
    });

    test('EnqueueTaskParams should create correctly', () {
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

  group('InstallQueue Provider Logic', () {
    test('should process queue sequentially', () {
      // TODO: 添加串行处理测试
      // 需要 mock LinglongCliRepository
    });

    test('should persist current task', () {
      // TODO: 添加持久化测试
    });

    test('should recover from crash', () {
      // TODO: 添加崩溃恢复测试
    });
  });
}
