import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/app_operation_queue_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/app_operation_batch.dart';
import 'package:linglong_store/domain/models/app_operation_journal_snapshot.dart';
import 'package:linglong_store/domain/models/app_operation_target_snapshot.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';
import 'package:linglong_store/domain/repositories/app_operation_journal_repository.dart';
import 'package:linglong_store/domain/repositories/linglong_cli_repository.dart';

import '../../../helpers/memory_app_operation_journal_repository.dart';

class _FakeLinglongCliRepository implements LinglongCliRepository {
  int installCallCount = 0;
  int updateCallCount = 0;
  List<InstallProgress> installEvents = const [
    InstallProgress(
      appId: 'ignored',
      status: InstallStatus.success,
      progress: 1.0,
      message: '安装完成',
    ),
  ];
  List<InstallProgress> updateEvents = const [
    InstallProgress(
      appId: 'ignored',
      status: InstallStatus.success,
      progress: 1.0,
      message: '更新完成',
    ),
  ];

  @override
  Future<bool> cancelOperation(
    String appId, {
    required InstallTaskKind kind,
  }) async {
    return true;
  }

  @override
  Future<String> createDesktopShortcut(String appId) async => '';

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
    installCallCount += 1;
    for (final event in installEvents) {
      yield event.copyWith(appId: appId);
    }
  }

  @override
  Future<String> killApp(String appName) async => '';

  @override
  Future<String> pruneApps() async => '';

  @override
  Future<void> runApp(String appId) async {}

  @override
  Future<List<InstalledApp>> searchVersions(String appId) async => const [];

  @override
  Future<String> uninstallApp(String appId, String? version) async => '';

  @override
  Stream<InstallProgress> updateApp(String appId) async* {
    updateCallCount += 1;
    for (final event in updateEvents) {
      yield event.copyWith(appId: appId);
    }
  }
}

class _FakeAnalyticsRepository implements AnalyticsRepository {
  const _FakeAnalyticsRepository();

  @override
  Future<void> initializeSession() async {}

  @override
  Future<void> reportInstall(
    String appId,
    String version, {
    String? appName,
  }) async {}

  @override
  Future<void> reportUninstall(
    String appId,
    String version, {
    String? appName,
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

Future<ProviderContainer> _createTestContainer(
  _FakeLinglongCliRepository fakeRepo, {
  AppOperationJournalRepository? journal,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  // 入队链路会读取 locale 与匿名统计相关 Provider，测试需显式注入最小依赖。
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appOperationJournalRepositoryProvider.overrideWithValue(
        journal ?? MemoryAppOperationJournalRepository(),
      ),
      analyticsRepositoryProvider.overrideWithValue(
        const _FakeAnalyticsRepository(),
      ),
      linglongCliRepositoryProvider.overrideWith((ref) => fakeRepo),
    ],
  );
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('AppOperationQueueController', () {
    test('does not start ll-cli before the queued task is durable', () async {
      final fakeRepo = _FakeLinglongCliRepository();
      final journal = _BlockingJournalRepository();
      final container = await _createTestContainer(fakeRepo, journal: journal);
      addTearDown(container.dispose);

      container
          .read(appOperationQueueControllerProvider)
          .enqueueAppOperation(
            const EnqueueAppOperationParams(
              kind: InstallTaskKind.install,
              appId: 'com.example.durable',
              appName: 'Durable App',
            ),
          );

      await journal.firstSaveStarted.future;
      expect(fakeRepo.installCallCount, 0);

      journal.releaseFirstSave.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeRepo.installCallCount, 1);
    });

    test(
      'routes update operations to updateApp and records update task kind',
      () async {
        final fakeRepo = _FakeLinglongCliRepository();
        final container = await _createTestContainer(fakeRepo);
        addTearDown(container.dispose);

        container
            .read(appOperationQueueControllerProvider)
            .enqueueBatchOperations([
              const EnqueueAppOperationParams(
                kind: InstallTaskKind.update,
                appId: 'com.example.update',
                appName: 'Update App',
                target: AppOperationTargetSnapshot(
                  appId: 'com.example.update',
                  displayName: 'Update App',
                  arch: 'x86_64',
                  channel: 'main',
                  module: 'binary',
                  repoName: 'stable',
                  installedVersion: '1.0.0',
                  expectedVersion: '2.0.0',
                ),
              ),
            ]);

        await Future<void>.delayed(const Duration(milliseconds: 20));

        final state = container.read(installQueueProvider);
        expect(fakeRepo.updateCallCount, 1);
        expect(fakeRepo.installCallCount, 0);
        expect(state.history.first.kind, InstallTaskKind.update);
        expect(state.history.first.message, '更新完成');
        expect(state.history.first.target?.installedVersion, '1.0.0');
        expect(state.history.first.target?.expectedVersion, '2.0.0');
        expect(state.batches, hasLength(1));
        expect(state.batches.single.status, AppOperationBatchStatus.completed);
        expect(
          state.batches.single.notificationState,
          AppOperationNotificationState.pending,
        );
        expect(state.outbox.map((effect) => effect.type), [
          AppOperationEffectType.taskSucceeded,
          AppOperationEffectType.updateBatchCompleted,
        ]);
      },
    );

    test(
      'routes install operations to installApp and records install task kind',
      () async {
        final fakeRepo = _FakeLinglongCliRepository();
        final container = await _createTestContainer(fakeRepo);
        addTearDown(container.dispose);

        container
            .read(appOperationQueueControllerProvider)
            .enqueueAppOperation(
              const EnqueueAppOperationParams(
                kind: InstallTaskKind.install,
                appId: 'com.example.install',
                appName: 'Install App',
                version: '1.0.0',
              ),
            );

        await Future<void>.delayed(const Duration(milliseconds: 20));

        final state = container.read(installQueueProvider);
        expect(fakeRepo.installCallCount, 1);
        expect(fakeRepo.updateCallCount, 0);
        expect(state.history.first.kind, InstallTaskKind.install);
        expect(state.history.first.message, '安装完成');
      },
    );

    test(
      'marks install as failed when the progress stream ends without a terminal status',
      () async {
        final fakeRepo = _FakeLinglongCliRepository()
          ..installEvents = const [
            InstallProgress(
              appId: 'ignored',
              status: InstallStatus.pending,
              message: '准备安装',
            ),
          ];
        final container = await _createTestContainer(fakeRepo);
        addTearDown(container.dispose);

        container
            .read(appOperationQueueControllerProvider)
            .enqueueAppOperation(
              const EnqueueAppOperationParams(
                kind: InstallTaskKind.install,
                appId: 'com.example.install',
                appName: 'Install App',
                version: '1.0.0',
              ),
            );

        await Future<void>.delayed(const Duration(milliseconds: 20));

        final state = container.read(installQueueProvider);
        expect(fakeRepo.installCallCount, 1);
        expect(state.currentTask, isNull);
        expect(state.history.first.status, InstallStatus.failed);
        expect(state.history.first.errorMessage, contains('无法确认安装结果'));
      },
    );

    test('records command output lines on completed task history', () async {
      final fakeRepo = _FakeLinglongCliRepository()
        ..installEvents = const [
          InstallProgress(
            appId: 'ignored',
            status: InstallStatus.downloading,
            progress: 0.5,
            message: '正在下载',
            outputLine: '{"message":"Downloading files","percentage":50}',
          ),
          InstallProgress(
            appId: 'ignored',
            status: InstallStatus.success,
            progress: 100,
            message: '安装完成',
            outputLine: '{"message":"Install complete","percentage":100}',
          ),
        ];
      final container = await _createTestContainer(fakeRepo);
      addTearDown(container.dispose);

      container
          .read(appOperationQueueControllerProvider)
          .enqueueAppOperation(
            const EnqueueAppOperationParams(
              kind: InstallTaskKind.install,
              appId: 'com.example.install',
              appName: 'Install App',
            ),
          );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      final historyTask = container.read(installQueueProvider).history.first;
      expect(historyTask.commandOutput, contains('Downloading files'));
      expect(historyTask.commandOutput, contains('Install complete'));
    });
  });
}

/// 首次保存可控的 Journal，用于验证 ll-cli 不会领先于队列事实落盘。
class _BlockingJournalRepository implements AppOperationJournalRepository {
  /// 第一次队列快照已经进入实际保存。
  final Completer<void> firstSaveStarted = Completer<void>();

  /// 允许第一次保存完成。
  final Completer<void> releaseFirstSave = Completer<void>();

  /// 当前已持久化快照。
  AppOperationJournalSnapshot? snapshot;

  /// 只阻塞第一次保存，后续 currentTask 和终态写入正常完成。
  bool _hasBlockedFirstSave = false;

  @override
  AppOperationJournalSnapshot? load() => snapshot;

  @override
  Future<void> save(AppOperationJournalSnapshot snapshot) async {
    if (!_hasBlockedFirstSave) {
      _hasBlockedFirstSave = true;
      firstSaveStarted.complete();
      await releaseFirstSave.future;
    }
    this.snapshot = snapshot;
  }
}
