import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_operation_queue_provider.dart';
import 'package:linglong_store/application/providers/linglong_env_provider.dart';
import 'package:linglong_store/core/di/providers.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/linux_distribution.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';
import 'package:linglong_store/domain/repositories/linglong_cli_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
              error: '安装失败',
              errorCode: 2001,
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
        expect(failedTask.errorMessage, contains('开发者模式'));
        expect(failedTask.message, contains('开发者模式'));
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
              error: '更新失败',
              errorCode: 2001,
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
        expect(failedTask.errorMessage, isNot(contains('开发者模式')));
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
              error: '安装失败',
              errorCode: 2001,
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
        expect(failedTask.errorMessage, equals('安装失败'));
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
  Future<String> uninstallApp(String appId, String version) async => '';

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
      analyticsRepositoryProvider.overrideWithValue(
        const _FakeAnalyticsRepository(),
      ),
      linglongCliRepositoryProvider.overrideWith((ref) => fakeRepo),
      linglongEnvProvider.overrideWithValue(envState),
    ],
  );
}
