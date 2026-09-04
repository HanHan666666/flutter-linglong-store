/// 安装队列授权门闩测试（docs/47 §10.2/§13.2）。
///
/// 验证：授权取消（authorizationCancelled）或授权组件不可用
/// （helperUnavailable）导致任务失败后，pending 任务不再自动消费；
/// 用户明确重新入队时解除门闩并恢复执行。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/global_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/linglong_env_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/app_operation_failure.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/linglong_cli_failure.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';
import 'package:linglong_store/domain/models/linux_distribution.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/repositories/linglong_cli_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/memory_app_operation_journal_repository.dart';

/// 可切换输出事件的 CLI Repository 替身。
class _GateFakeCliRepository implements LinglongCliRepository {
  /// 每个应用 appId 对应的输出事件；未配置的应用按 success 处理。
  final Map<String, List<InstallProgress>> eventsByApp = {};

  /// installApp 被调用的应用序列（验证自动消费是否停止）。
  final List<String> installedApps = [];

  @override
  Stream<InstallProgress> installApp(
    String appId, {
    String? version,
    bool force = false,
  }) async* {
    installedApps.add(appId);
    final events = eventsByApp[appId] ??
        const [
          InstallProgress(
            appId: 'ignored',
            status: InstallStatus.success,
            progress: 1,
          ),
        ];
    for (final event in events) {
      yield event.copyWith(appId: appId);
    }
  }

  @override
  Future<bool> cancelOperation(
    String appId, {
    required InstallTaskKind kind,
  }) async {
    return true;
  }

  @override
  Future<DesktopShortcutResult> createDesktopShortcut(String appId) async {
    throw UnimplementedError();
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
    yield InstallProgress(
      appId: appId,
      status: InstallStatus.success,
      progress: 1,
    );
  }
}

class _ChineseGlobalApp extends GlobalApp {
  @override
  GlobalAppState build() {
    return const GlobalAppState(locale: Locale('zh'), isInitialized: true);
  }
}

Future<ProviderContainer> _createContainer(
  _GateFakeCliRepository fakeRepo,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appOperationJournalRepositoryProvider.overrideWithValue(
        MemoryAppOperationJournalRepository(),
      ),
      linglongCliRepositoryProvider.overrideWith((ref) => fakeRepo),
      linglongEnvProvider.overrideWithValue(
        const LinglongEnvState(
          checkState: LinglongEnvCheckState.success,
          result: LinglongEnvCheckResult(
            isOk: true,
            distribution: LinuxDistribution.uos,
            checkedAt: 1,
          ),
        ),
      ),
      globalAppProvider.overrideWith(_ChineseGlobalApp.new),
    ],
  );
}

/// 轮询等待条件成立（每 10ms 一次，最多 3s）。
Future<bool> _eventually(bool Function() condition) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    if (condition()) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return false;
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  test('authorization cancelled pauses queue and explicit enqueue resumes',
      () async {
    final fakeRepo = _GateFakeCliRepository()
      ..eventsByApp['org.first.app'] = const [
        InstallProgress(
          appId: 'ignored',
          status: InstallStatus.failed,
          failure: AppOperationFailure(
            kind: AppOperationFailureKind.authorizationCancelled,
            diagnostic: 'pkexec authorization dismissed by user',
          ),
        ),
      ];
    final container = await _createContainer(fakeRepo);
    addTearDown(container.dispose);

    final queue = container.read(installQueueProvider.notifier);
    queue.enqueueOperation(
      kind: InstallTaskKind.install,
      appId: 'org.first.app',
      appName: 'First',
    );
    queue.enqueueOperation(
      kind: InstallTaskKind.install,
      appId: 'org.second.app',
      appName: 'Second',
    );

    // 第一个任务以授权取消失败进入历史。
    final firstFailed = await _eventually(
      () => container.read(installQueueProvider).history.isNotEmpty,
    );
    expect(firstFailed, isTrue, reason: '首个任务应已进入历史');
    final historyTask = container.read(installQueueProvider).history.first;
    expect(historyTask.status, InstallStatus.failed);
    expect(
      historyTask.failure?.kind,
      AppOperationFailureKind.authorizationCancelled,
    );

    // 门闩生效：pending 任务保留且不被自动消费。
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final state = container.read(installQueueProvider);
    expect(queue.isAuthorizationGatePaused, isTrue);
    expect(fakeRepo.installedApps, ['org.first.app'],
        reason: '授权失败后不得自动启动下一任务（§10.2 第 3 条）');
    expect(
      state.queue.map((task) => task.appId),
      contains('org.second.app'),
      reason: 'pending 任务保留，不被清空',
    );

    // 用户明确再次点击安装：门闩解除，队列恢复消费。
    queue.enqueueOperation(
      kind: InstallTaskKind.install,
      appId: 'org.third.app',
      appName: 'Third',
    );
    final thirdProcessed = await _eventually(
      () => fakeRepo.installedApps.contains('org.third.app'),
    );
    expect(thirdProcessed, isTrue, reason: '明确入队后应恢复队列执行');
    expect(queue.isAuthorizationGatePaused, isFalse);
  });

  test('helper unavailable also pauses the queue', () async {
    final fakeRepo = _GateFakeCliRepository()
      ..eventsByApp['org.broken.app'] = const [
        InstallProgress(
          appId: 'ignored',
          status: InstallStatus.failed,
          failure: AppOperationFailure(
            kind: AppOperationFailureKind.helperUnavailable,
            diagnostic: 'helper binary not found',
          ),
        ),
      ];
    final container = await _createContainer(fakeRepo);
    addTearDown(container.dispose);

    final queue = container.read(installQueueProvider.notifier);
    queue.enqueueOperation(
      kind: InstallTaskKind.install,
      appId: 'org.broken.app',
      appName: 'Broken',
    );
    queue.enqueueOperation(
      kind: InstallTaskKind.install,
      appId: 'org.later.app',
      appName: 'Later',
    );

    final failed = await _eventually(
      () => container.read(installQueueProvider).history.isNotEmpty,
    );
    expect(failed, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(queue.isAuthorizationGatePaused, isTrue);
    expect(fakeRepo.installedApps, ['org.broken.app']);

    // 历史失败文案使用“授权组件不可用”。
    final historyTask = container.read(installQueueProvider).history.first;
    final message = container
        .read(installMessagesProvider)
        .errorMessageForTask(historyTask);
    expect(message, contains('授权组件不可用'));
  });
}
