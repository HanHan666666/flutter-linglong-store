/// 安装队列取消与传输终态的编排回归测试。
///
/// 使用可控 Repository 保留任务流，验证 SIGTERM 受理后队列仍严格串行，
/// 且传输异常不会被上层取消意图掩盖为已取消。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/app_operation_queue_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/app_operation_failure.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/linglong_cli_failure.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';
import 'package:linglong_store/domain/repositories/linglong_cli_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/memory_app_operation_journal_repository.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('InstallQueue cancel handling', () {
    test(
      'keeps current task active when system kill cancellation fails',
      () async {
        final fakeRepo = _ControllableLinglongCliRepository()
          ..cancelOperationResult = false;
        final container = await _createTestContainer(fakeRepo);
        addTearDown(() async {
          await fakeRepo.dispose();
          container.dispose();
        });

        container
            .read(appOperationQueueControllerProvider)
            .enqueueAppOperation(
              const EnqueueAppOperationParams(
                kind: InstallTaskKind.install,
                appId: 'org.example.demo',
                appName: 'Demo',
              ),
            );

        final activeTask = await _waitForCurrentTask(container);
        expect(activeTask.status, InstallStatus.installing);
        await _waitForCondition(() => fakeRepo.startedApps.isNotEmpty);

        final cancelled = await container
            .read(installQueueProvider.notifier)
            .cancelTask('org.example.demo');

        final state = container.read(installQueueProvider);
        expect(cancelled, isFalse);
        expect(fakeRepo.cancelOperationCallCount, 1);
        expect(state.currentTask, isNotNull);
        expect(state.currentTask!.appId, 'org.example.demo');
        expect(state.currentTask!.status, InstallStatus.installing);
        expect(state.isProcessing, isTrue);
        expect(state.history, isEmpty);

        fakeRepo.emitInstallProgress(
          'org.example.demo',
          const InstallProgress(
            appId: 'org.example.demo',
            status: InstallStatus.success,
            progress: 100,
            message: '安装完成',
          ),
        );
        await _waitForFirstHistoryTask(container);
      },
    );

    test(
      'accepted cancellation keeps task occupied until stream terminal',
      () async {
        final fakeRepo = _ControllableLinglongCliRepository()
          ..cancelOperationResult = true;
        final container = await _createTestContainer(fakeRepo);
        addTearDown(() async {
          await fakeRepo.dispose();
          container.dispose();
        });

        container
            .read(appOperationQueueControllerProvider)
            .enqueueAppOperation(
              const EnqueueAppOperationParams(
                kind: InstallTaskKind.install,
                appId: 'org.example.demo',
                appName: 'Demo',
              ),
            );
        container
            .read(appOperationQueueControllerProvider)
            .enqueueAppOperation(
              const EnqueueAppOperationParams(
                kind: InstallTaskKind.install,
                appId: 'org.second.demo',
                appName: 'Second',
              ),
            );

        await _waitForCurrentTask(container);
        await _waitForCondition(() => fakeRepo.startedApps.isNotEmpty);

        final cancelled = await container
            .read(installQueueProvider.notifier)
            .cancelTask('org.example.demo');

        expect(cancelled, isTrue);
        expect(fakeRepo.cancelOperationCallCount, 1);
        // docs/54：取消已受理只是 SIGTERM 已发送；helper 未 exited 时仍需占位。
        await Future<void>.delayed(const Duration(milliseconds: 150));
        final state = container.read(installQueueProvider);
        expect(state.currentTask?.appId, 'org.example.demo');
        expect(state.isProcessing, isTrue);
        expect(state.history, isEmpty);
        expect(fakeRepo.startedApps, ['org.example.demo']);

        fakeRepo.emitInstallProgress(
          'org.example.demo',
          const InstallProgress(
            appId: 'org.example.demo',
            status: InstallStatus.cancelled,
          ),
        );
        await _waitForFirstHistoryTask(container);
        expect(
          container.read(installQueueProvider).history.first.status,
          InstallStatus.cancelled,
        );
        await _waitForCondition(() => fakeRepo.startedApps.length == 2);
        expect(fakeRepo.startedApps, ['org.example.demo', 'org.second.demo']);
      },
    );

    test(
      'stream failure after accepted cancellation stays a failure',
      () async {
        // 取消已受理不能证明进程已取消；传输失败仍须保留真实失败诊断。
        final fakeRepo = _ControllableLinglongCliRepository()
          ..cancelOperationResult = true;
        final container = await _createTestContainer(fakeRepo);
        addTearDown(() async {
          await fakeRepo.dispose();
          container.dispose();
        });

        container
            .read(appOperationQueueControllerProvider)
            .enqueueAppOperation(
              const EnqueueAppOperationParams(
                kind: InstallTaskKind.install,
                appId: 'org.example.demo',
                appName: 'Demo',
              ),
            );
        await _waitForCurrentTask(container);
        await _waitForCondition(() => fakeRepo.startedApps.isNotEmpty);
        expect(
          await container
              .read(installQueueProvider.notifier)
              .cancelTask('org.example.demo'),
          isTrue,
        );

        fakeRepo.emitInstallProgress(
          'org.example.demo',
          const InstallProgress(
            appId: 'org.example.demo',
            status: InstallStatus.failed,
            rawMessage: 'helper transport disconnected',
          ),
        );
        final completed = await _waitForFirstHistoryTask(container);
        expect(completed.status, InstallStatus.failed);
        expect(completed.failure?.diagnostic, 'helper transport disconnected');
      },
    );

    test(
      'helper busy execution error does not pause authorization gate',
      () async {
        // docs/54：内部 busy 不能按授权组件不可用处理，否则后续任务会被误暂停。
        final fakeRepo = _ControllableLinglongCliRepository();
        final container = await _createTestContainer(fakeRepo);
        addTearDown(() async {
          await fakeRepo.dispose();
          container.dispose();
        });

        final queue = container.read(installQueueProvider.notifier);
        for (final appId in ['org.example.demo', 'org.second.demo']) {
          container
              .read(appOperationQueueControllerProvider)
              .enqueueAppOperation(
                EnqueueAppOperationParams(
                  kind: InstallTaskKind.install,
                  appId: appId,
                  appName: appId,
                ),
              );
        }
        await _waitForCondition(() => fakeRepo.startedApps.isNotEmpty);
        fakeRepo.emitInstallProgress(
          'org.example.demo',
          const InstallProgress(
            appId: 'org.example.demo',
            status: InstallStatus.failed,
            failure: AppOperationFailure(
              kind: AppOperationFailureKind.execution,
              diagnostic: '客户端已有活动任务',
            ),
          ),
        );

        await _waitForCondition(() => fakeRepo.startedApps.length == 2);
        expect(queue.isAuthorizationGatePaused, isFalse);
      },
    );
  });
}

Future<ProviderContainer> _createTestContainer(
  _ControllableLinglongCliRepository fakeRepo,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appOperationJournalRepositoryProvider.overrideWithValue(
        MemoryAppOperationJournalRepository(),
      ),
      analyticsRepositoryProvider.overrideWithValue(
        const _FakeAnalyticsRepository(),
      ),
      linglongCliRepositoryProvider.overrideWith((ref) => fakeRepo),
    ],
  );
}

Future<InstallTask> _waitForCurrentTask(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    final task = container.read(installQueueProvider).currentTask;
    if (task != null) {
      return task;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  throw TestFailure('Timed out waiting for current install task');
}

Future<InstallTask> _waitForFirstHistoryTask(
  ProviderContainer container,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    final history = container.read(installQueueProvider).history;
    if (history.isNotEmpty) {
      return history.first;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  throw TestFailure('Timed out waiting for install queue history to update');
}

/// 等待 fake CLI 收到下一任务，避免定时调度差异让测试依赖固定延迟。
Future<void> _waitForCondition(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw TestFailure('Timed out waiting for queue condition');
}

/// 分应用保留进度流的测试替身，用于观察下一项真正开始的时刻。
class _ControllableLinglongCliRepository implements LinglongCliRepository {
  /// 按应用隔离流，保证两个排队任务的启动顺序可独立观察。
  final Map<String, StreamController<InstallProgress>> _installControllers = {};

  /// 实际开始监听的安装任务序列。
  final List<String> startedApps = [];

  /// 让测试精确控制底层是否接受取消请求。
  bool cancelOperationResult = true;

  /// 记录取消调用次数，防止测试误把队列移除当作活动任务取消。
  int cancelOperationCallCount = 0;

  /// 收尾仍在监听的测试流，避免测试间保留活动订阅。
  Future<void> dispose() async {
    for (final controller in _installControllers.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  /// 向指定任务发送一个进度事件，其他排队任务不会收到。
  void emitInstallProgress(String appId, InstallProgress progress) {
    _installControllers[appId]!.add(progress);
  }

  @override
  Future<bool> cancelOperation(
    String appId, {
    required InstallTaskKind kind,
  }) async {
    cancelOperationCallCount += 1;
    return cancelOperationResult;
  }

  @override
  Future<DesktopShortcutResult> createDesktopShortcut(String appId) async {
    return const DesktopShortcutResult(
      path: '/tmp/example.desktop',
      disposition: DesktopShortcutDisposition.created,
    );
  }

  @override
  Future<List<InstalledApp>> getInstalledApps({
    bool includeBaseService = false,
  }) async {
    return const [];
  }

  @override
  Future<String> getLlCliVersion() async => '';

  @override
  Future<List<RunningApp>> getRunningApps() async => const [];

  @override
  Stream<InstallProgress> installApp(
    String appId, {
    String? version,
    bool force = false,
  }) async* {
    startedApps.add(appId);
    final controller = StreamController<InstallProgress>();
    _installControllers[appId] = controller;
    yield* controller.stream;
  }

  @override
  Future<void> killApp(String appName) async {}

  @override
  Future<void> pruneApps() async {}

  @override
  Future<void> runApp(String appId) async {}

  @override
  Future<List<InstalledApp>> searchVersions(String appId) async => const [];

  @override
  Future<void> uninstallApp(String appId, String? version) async {}

  @override
  Stream<InstallProgress> updateApp(String appId) async* {}
}

class _FakeAnalyticsRepository implements AnalyticsRepository {
  const _FakeAnalyticsRepository();

  @override
  Future<void> initializeSession() async {}

  @override
  Future<void> reportInstalledAppsDiff({
    required List<InstalledApp> addedItems,
    required List<InstalledApp> removedItems,
  }) async {}

  @override
  Future<void> reportVisit({
    String? arch,
    String? llVersion,
    String? llBinVersion,
    String? detailMsg,
    String? osVersion,
    String? repoName,
    String? appVersion,
  }) async {}
}
