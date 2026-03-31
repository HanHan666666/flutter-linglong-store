import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linglong_store/application/providers/app_operation_queue_provider.dart';
import 'package:linglong_store/core/di/providers.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';
import 'package:linglong_store/domain/repositories/linglong_cli_repository.dart';

class _FakeLinglongCliRepository implements LinglongCliRepository {
  int installCallCount = 0;
  int updateCallCount = 0;

  @override
  Future<bool> cancelInstall(String appId) async => true;

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
    yield InstallProgress(
      appId: appId,
      status: InstallStatus.success,
      progress: 1.0,
      message: '安装完成',
    );
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
  Stream<InstallProgress> updateApp(String appId, {String? version}) async* {
    updateCallCount += 1;
    yield InstallProgress(
      appId: appId,
      status: InstallStatus.success,
      progress: 1.0,
      message: '更新完成',
    );
  }
}

class _FakeAnalyticsRepository implements AnalyticsRepository {
  const _FakeAnalyticsRepository();

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
    String? osVersion,
    String? repoName,
    String? appVersion,
  }) async {}
}

Future<ProviderContainer> _createTestContainer(
  _FakeLinglongCliRepository fakeRepo,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  // 入队链路会读取 locale 与匿名统计相关 Provider，测试需显式注入最小依赖。
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

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('AppOperationQueueController', () {
    test('routes update operations to updateApp and records update task kind', () async {
      final fakeRepo = _FakeLinglongCliRepository();
      final container = await _createTestContainer(fakeRepo);
      addTearDown(container.dispose);

      container.read(appOperationQueueControllerProvider).enqueueBatchOperations([
        const EnqueueAppOperationParams(
          kind: InstallTaskKind.update,
          appId: 'com.example.update',
          appName: 'Update App',
          version: '2.0.0',
        ),
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(installQueueProvider);
      expect(fakeRepo.updateCallCount, 1);
      expect(fakeRepo.installCallCount, 0);
      expect(state.history.first.kind, InstallTaskKind.update);
      expect(state.history.first.message, '更新完成');
    });

    test('routes install operations to installApp and records install task kind', () async {
      final fakeRepo = _FakeLinglongCliRepository();
      final container = await _createTestContainer(fakeRepo);
      addTearDown(container.dispose);

      container.read(appOperationQueueControllerProvider).enqueueAppOperation(
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
    });
  });
}
