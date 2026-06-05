import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/install_task.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

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

    test('should return only active tasks for app', () {
      final currentTask = InstallTask(
        id: 'current-id',
        appId: 'com.example.test',
        appName: 'Current Task',
        status: InstallStatus.installing,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final queuedTask = InstallTask(
        id: 'queued-id',
        appId: 'com.example.test',
        appName: 'Queued Task',
        version: '1.0.0',
        status: InstallStatus.pending,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final historyTask = InstallTask(
        id: 'history-id',
        appId: 'com.example.test',
        appName: 'History Task',
        status: InstallStatus.success,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final state = InstallQueueState(
        currentTask: currentTask,
        queue: [queuedTask],
        history: [historyTask],
      );

      final tasks = state.getActiveTasksForApp('com.example.test');

      expect(tasks, hasLength(2));
      expect(tasks.first.id, 'current-id');
      expect(tasks.last.id, 'queued-id');
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

  group('InstallQueue precise item operations', () {
    test('removeHistoryTask removes only the selected history item', () {
      final container = ProviderContainer(
        overrides: [
          installQueueProvider.overrideWith(
            () => TestInstallQueue(
              initialState: InstallQueueState(
                history: [
                  _task(
                    id: 'wechat-history-1',
                    appId: 'com.tencent.wechat',
                    status: InstallStatus.success,
                  ),
                  _task(
                    id: 'wechat-history-2',
                    appId: 'com.tencent.wechat',
                    status: InstallStatus.success,
                  ),
                  _task(id: 'other-history', status: InstallStatus.success),
                ],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(installQueueProvider.notifier)
          .removeHistoryTask('wechat-history-1');

      final historyIds = container
          .read(installQueueProvider)
          .history
          .map((task) => task.id)
          .toList();
      expect(historyIds, ['wechat-history-2', 'other-history']);
    });

    test(
      'removeQueuedTask removes one queued item without touching history',
      () {
        final container = ProviderContainer(
          overrides: [
            installQueueProvider.overrideWith(
              () => TestInstallQueue(
                initialState: InstallQueueState(
                  queue: [
                    _task(id: 'wechat-queue-1', appId: 'com.tencent.wechat'),
                    _task(id: 'wechat-queue-2', appId: 'com.tencent.wechat'),
                  ],
                  history: [
                    _task(
                      id: 'wechat-history',
                      appId: 'com.tencent.wechat',
                      status: InstallStatus.success,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(installQueueProvider.notifier)
            .removeQueuedTask('wechat-queue-1');

        final state = container.read(installQueueProvider);
        expect(state.queue.map((task) => task.id), ['wechat-queue-2']);
        expect(state.history.map((task) => task.id), ['wechat-history']);
      },
    );

    test(
      'retryFailedTask preserves kind and removes only selected failure',
      () {
        final container = ProviderContainer(
          overrides: [
            installQueueProvider.overrideWith(
              () => TestInstallQueue(
                initialState: InstallQueueState(
                  history: [
                    _task(
                      id: 'failed-update',
                      appId: 'com.tencent.wechat',
                      kind: InstallTaskKind.update,
                      status: InstallStatus.failed,
                    ),
                    _task(
                      id: 'failed-install',
                      appId: 'com.tencent.wechat',
                      kind: InstallTaskKind.install,
                      status: InstallStatus.failed,
                      version: '1.0.0',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(installQueueProvider.notifier)
            .retryFailedTask('failed-update');

        final state = container.read(installQueueProvider);
        expect(state.history.map((task) => task.id), ['failed-install']);
        expect(state.queue, hasLength(1));
        expect(state.queue.single.appId, 'com.tencent.wechat');
        expect(state.queue.single.kind, InstallTaskKind.update);
        expect(state.queue.single.version, isNull);
      },
    );
  });
}

InstallTask _task({
  required String id,
  String appId = 'com.example.test',
  String appName = 'Test App',
  InstallTaskKind kind = InstallTaskKind.install,
  InstallStatus status = InstallStatus.pending,
  String? version,
}) {
  return InstallTask(
    id: id,
    appId: appId,
    appName: appName,
    kind: kind,
    status: status,
    version: version,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
}

class TestInstallQueue extends InstallQueue {
  TestInstallQueue({required InstallQueueState initialState})
    : _initialState = initialState;

  final InstallQueueState _initialState;

  @override
  InstallQueueState build() => _initialState;

  @override
  Future<void> startProcessing() async {}
}
