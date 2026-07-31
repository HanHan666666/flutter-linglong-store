import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/app_operation_queue_provider.dart';
import 'package:linglong_store/application/providers/global_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/linglong_env_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/app_operation_failure.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/linglong_cli_failure.dart';
import 'package:linglong_store/domain/models/linux_distribution.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';
import 'package:linglong_store/domain/repositories/linglong_cli_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/memory_app_operation_journal_repository.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('InstallQueue distribution guidance', () {
    test(
      'appends distribution guidance for failed install tasks on adapted distros',
      () async {
        final fakeRepo = _FakeLinglongCliRepository()
          ..installEvents = const [
            InstallProgress(
              appId: 'ignored',
              status: InstallStatus.failed,
              failure: AppOperationFailure(
                kind: AppOperationFailureKind.cli,
                cliCode: 2001,
                diagnostic: 'install failed',
              ),
            ),
          ];

        final container = await _createTestContainer(
          fakeRepo,
          envState: const LinglongEnvState(
            checkState: LinglongEnvCheckState.success,
            result: LinglongEnvCheckResult(
              isOk: true,
              distribution: LinuxDistribution.uos,
              checkedAt: 1,
            ),
          ),
        );
        addTearDown(container.dispose);

        container
            .read(appOperationQueueControllerProvider)
            .enqueueAppOperation(
              const EnqueueAppOperationParams(
                kind: InstallTaskKind.install,
                appId: 'org.example.demo',
                appName: 'Demo',
              ),
            );

        final failedTask = await _waitForFirstHistoryTask(container);
        expect(failedTask.status, InstallStatus.failed);
        final message = container
            .read(installMessagesProvider)
            .errorMessageForTask(
              failedTask,
              distribution: LinuxDistribution.uos,
            );
        expect(message, contains('开发者模式'));
        expect(failedTask.errorMessage, isNull);
        expect(failedTask.message, isNull);
      },
    );

    test(
      'does not append install guidance for unsupported failure scenarios',
      () async {
        final fakeRepo = _FakeLinglongCliRepository()
          ..updateEvents = const [
            InstallProgress(
              appId: 'ignored',
              status: InstallStatus.failed,
              failure: AppOperationFailure(
                kind: AppOperationFailureKind.cli,
                cliCode: 2001,
                diagnostic: 'update failed',
              ),
            ),
          ];

        final container = await _createTestContainer(
          fakeRepo,
          envState: const LinglongEnvState(
            checkState: LinglongEnvCheckState.success,
            result: LinglongEnvCheckResult(
              isOk: true,
              distribution: LinuxDistribution.uos,
              checkedAt: 1,
            ),
          ),
        );
        addTearDown(container.dispose);

        container
            .read(appOperationQueueControllerProvider)
            .enqueueAppOperation(
              const EnqueueAppOperationParams(
                kind: InstallTaskKind.update,
                appId: 'org.example.demo',
                appName: 'Demo',
              ),
            );

        final failedTask = await _waitForFirstHistoryTask(container);
        expect(failedTask.status, InstallStatus.failed);
        final message = container
            .read(installMessagesProvider)
            .errorMessageForTask(
              failedTask,
              distribution: LinuxDistribution.uos,
            );
        expect(message, isNot(contains('开发者模式')));
      },
    );

    test(
      'does not append guidance for distributions without special adaptation',
      () async {
        final fakeRepo = _FakeLinglongCliRepository()
          ..installEvents = const [
            InstallProgress(
              appId: 'ignored',
              status: InstallStatus.failed,
              failure: AppOperationFailure(
                kind: AppOperationFailureKind.cli,
                cliCode: 2001,
                diagnostic: 'install failed',
              ),
            ),
          ];

        final container = await _createTestContainer(
          fakeRepo,
          envState: const LinglongEnvState(
            checkState: LinglongEnvCheckState.success,
            result: LinglongEnvCheckResult(
              isOk: true,
              distribution: LinuxDistribution(displayName: 'Deepin 23'),
              checkedAt: 1,
            ),
          ),
        );
        addTearDown(container.dispose);

        container
            .read(appOperationQueueControllerProvider)
            .enqueueAppOperation(
              const EnqueueAppOperationParams(
                kind: InstallTaskKind.install,
                appId: 'org.example.demo',
                appName: 'Demo',
              ),
            );

        final failedTask = await _waitForFirstHistoryTask(container);
        expect(failedTask.status, InstallStatus.failed);
        final message = container
            .read(installMessagesProvider)
            .errorMessageForTask(
              failedTask,
              distribution: const LinuxDistribution(displayName: 'Deepin 23'),
            );
        expect(message, isNot(contains('开发者模式')));
      },
    );
  });
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

class _FakeLinglongCliRepository implements LinglongCliRepository {
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
    for (final event in installEvents) {
      yield event.copyWith(appId: appId);
    }
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
  Stream<InstallProgress> updateApp(String appId) async* {
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
  required LinglongEnvState envState,
}) async {
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
      linglongEnvProvider.overrideWithValue(envState),
      globalAppProvider.overrideWith(_ChineseGlobalApp.new),
    ],
  );
}

/// 为错误提示测试固定中文，避免并行测试修改平台或持久化 Locale。
class _ChineseGlobalApp extends GlobalApp {
  @override
  GlobalAppState build() {
    return const GlobalAppState(locale: Locale('zh'), isInitialized: true);
  }
}
