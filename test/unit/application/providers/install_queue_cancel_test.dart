import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_operation_queue_provider.dart';
import 'package:linglong_store/core/di/providers.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';
import 'package:linglong_store/domain/repositories/linglong_cli_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    test('marks current task cancelled when system kill succeeds', () async {
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

      final cancelled = await container
          .read(installQueueProvider.notifier)
          .cancelTask('org.example.demo');

      final state = container.read(installQueueProvider);
      expect(cancelled, isTrue);
      expect(fakeRepo.cancelOperationCallCount, 1);
      expect(state.currentTask, isNull);
      expect(state.isProcessing, isFalse);
      expect(state.history, isNotEmpty);
      expect(state.history.first.appId, 'org.example.demo');
      expect(state.history.first.status, InstallStatus.cancelled);
    });
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

class _ControllableLinglongCliRepository implements LinglongCliRepository {
  final StreamController<InstallProgress> _installController =
      StreamController<InstallProgress>();

  bool cancelOperationResult = true;
  int cancelOperationCallCount = 0;

  Future<void> dispose() async {
    if (!_installController.isClosed) {
      await _installController.close();
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  void emitInstallProgress(InstallProgress progress) {
    _installController.add(progress);
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
    yield* _installController.stream;
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
  Future<String> uninstallApp(String appId, String version) async => '';

  @override
  Stream<InstallProgress> updateApp(String appId) async* {}
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
