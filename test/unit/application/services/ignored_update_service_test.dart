import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/ignored_updates_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/installed_app_diff_report_provider.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/application/services/ignored_update_service.dart';
import 'package:linglong_store/application/services/installed_app_diff_report_service.dart';
import 'package:linglong_store/core/storage/ignored_update_storage.dart';
import 'package:linglong_store/domain/models/ignored_update.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';
import 'package:linglong_store/domain/repositories/linglong_cli_repository.dart';

void main() {
  group('IgnoredUpdateService', () {
    test(
      'persists ignore and immediately removes the visible update',
      () async {
        final storage = _MemoryIgnoredUpdateStorage();
        final updateApps = _TrackingUpdateApps(
          initialState: const UpdateAppsState(apps: [_updatableApp]),
        );
        final container = _createContainer(
          storage: storage,
          updateApps: updateApps,
        );
        addTearDown(container.dispose);

        final result = await container
            .read(ignoredUpdateServiceProvider)
            .ignore(_updatableApp);

        expect(result, IgnoreUpdateResult.success);
        expect(container.read(updateAppsProvider).apps, isEmpty);
        expect(
          container.read(ignoredUpdatesProvider).contains(_updatableApp.appId),
          isTrue,
        );
      },
    );

    test('rejects ignore while the same app has an active task', () async {
      final storage = _MemoryIgnoredUpdateStorage();
      final container = _createContainer(
        storage: storage,
        updateApps: _TrackingUpdateApps(
          initialState: const UpdateAppsState(apps: [_updatableApp]),
        ),
        installState: InstallQueueState(
          currentTask: InstallTask(
            id: 'task-1',
            appId: _updatableApp.appId,
            appName: _updatableApp.name,
            kind: InstallTaskKind.update,
            status: InstallStatus.installing,
            createdAt: 1,
          ),
          isProcessing: true,
        ),
      );
      addTearDown(container.dispose);

      final result = await container
          .read(ignoredUpdateServiceProvider)
          .ignore(_updatableApp);

      expect(result, IgnoreUpdateResult.activeTask);
      expect(container.read(ignoredUpdatesProvider).records, isEmpty);
      expect(container.read(updateAppsProvider).apps, hasLength(1));
    });

    test('rejects an app without a valid appId', () async {
      final storage = _MemoryIgnoredUpdateStorage();
      final container = _createContainer(
        storage: storage,
        updateApps: _TrackingUpdateApps(),
      );
      addTearDown(container.dispose);

      final result = await container
          .read(ignoredUpdateServiceProvider)
          .ignore(_updatableAppWithoutId);

      expect(result, IgnoreUpdateResult.invalidApp);
      expect(container.read(ignoredUpdatesProvider).records, isEmpty);
    });

    test(
      'restores locally before refreshing installed apps and updates',
      () async {
        final events = <String>[];
        final storage = _MemoryIgnoredUpdateStorage(
          initialRecords: const [_ignoredRecord],
        );
        final container = _createContainer(
          storage: storage,
          updateApps: _TrackingUpdateApps(events: events),
          installedApps: _TrackingInstalledApps(events: events),
        );
        addTearDown(container.dispose);

        final result = await container
            .read(ignoredUpdateServiceProvider)
            .restore(_ignoredRecord.appId);

        expect(result, RestoreIgnoredUpdateResult.success);
        expect(container.read(ignoredUpdatesProvider).records, isEmpty);
        expect(events, ['installed:refresh', 'updates:check']);
      },
    );

    test(
      'keeps restore choice when the following update check fails',
      () async {
        final storage = _MemoryIgnoredUpdateStorage(
          initialRecords: const [_ignoredRecord],
        );
        final container = _createContainer(
          storage: storage,
          updateApps: _TrackingUpdateApps(updateError: 'network failed'),
        );
        addTearDown(container.dispose);

        final result = await container
            .read(ignoredUpdateServiceProvider)
            .restore(_ignoredRecord.appId);

        expect(result, RestoreIgnoredUpdateResult.refreshFailed);
        expect(container.read(ignoredUpdatesProvider).records, isEmpty);
      },
    );
  });
}

const UpdatableApp _updatableApp = UpdatableApp(
  installedApp: InstalledApp(
    appId: 'org.example.demo',
    name: 'Demo',
    version: '1.0.0',
  ),
  latestVersion: '2.0.0',
);

const IgnoredUpdate _ignoredRecord = IgnoredUpdate(
  appId: 'org.example.demo',
  appName: 'Demo',
  ignoredVersion: '1.0.0',
  ignoredAt: 100,
);

const UpdatableApp _updatableAppWithoutId = UpdatableApp(
  installedApp: InstalledApp(appId: ' ', name: 'Invalid', version: '1.0.0'),
  latestVersion: '2.0.0',
);

ProviderContainer _createContainer({
  required IgnoredUpdateStorage storage,
  required UpdateApps updateApps,
  InstalledApps? installedApps,
  InstallQueueState installState = const InstallQueueState(),
}) {
  return ProviderContainer(
    overrides: [
      ignoredUpdateStorageProvider.overrideWithValue(storage),
      installQueueProvider.overrideWith(
        () => _StaticInstallQueue(installState),
      ),
      installedAppsProvider.overrideWith(
        () => installedApps ?? _TrackingInstalledApps(),
      ),
      updateAppsProvider.overrideWith(() => updateApps),
      // 同步链路会触发差量检测，测试用空实现避免依赖 ll-cli 与真实轮询。
      installedAppDiffReportServiceProvider.overrideWithValue(
        _NoopDiffReportService(),
      ),
    ],
  );
}

/// 差量检测空实现：同步触发仅作占位，不启动任何 Timer。
class _NoopDiffReportService extends InstalledAppDiffReportService {
  _NoopDiffReportService()
    : super(
        cliRepository: _PlaceholderCliRepository(),
        analyticsRepository: _NoopAnalyticsRepository(),
      );

  @override
  void scheduleImmediateCheck() {}
}

/// 仅供构造占位的空统计仓储；差量逻辑被覆写，不会真正调用任何方法。
class _NoopAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<void> initializeSession() async {}

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

  @override
  Future<void> reportInstalledAppsDiff({
    required List<InstalledApp> addedItems,
    required List<InstalledApp> removedItems,
  }) async {}
}

/// 仅供构造占位的 CLI 仓储；差量逻辑被覆写，不会真正调用任何方法。
class _PlaceholderCliRepository implements LinglongCliRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StaticInstallQueue extends InstallQueue {
  /// 创建不会自行变化的安装队列。
  _StaticInstallQueue(this.initialState);

  /// 测试指定的安装队列初始状态。
  final InstallQueueState initialState;

  @override
  InstallQueueState build() => initialState;
}

/// 记录集合同步过程中已安装列表的刷新顺序。
class _TrackingInstalledApps extends InstalledApps {
  /// 创建可选的事件追踪器。
  _TrackingInstalledApps({this.events});

  /// 同步步骤事件列表。
  final List<String>? events;

  @override
  InstalledAppsState build() => const InstalledAppsState();

  @override
  Future<void> refresh() async {
    events?.add('installed:refresh');
    state = const InstalledAppsState();
  }
}

/// 记录更新检查并允许注入错误状态的测试控制器。
class _TrackingUpdateApps extends UpdateApps {
  /// 创建带初始状态、事件追踪和可选错误的控制器。
  _TrackingUpdateApps({
    this.initialState = const UpdateAppsState(),
    this.events,
    this.updateError,
  });

  /// 首次读取 Provider 时返回的状态。
  final UpdateAppsState initialState;

  /// 同步步骤事件列表。
  final List<String>? events;

  /// 更新检查结束后写入状态的模拟错误。
  final String? updateError;

  @override
  UpdateAppsState build() => initialState;

  @override
  Future<void> checkUpdates() async {
    events?.add('updates:check');
    state = UpdateAppsState(hasLoadedOnce: true, error: updateError);
  }
}

/// 为业务服务测试隔离 SharedPreferences 的内存存储。
class _MemoryIgnoredUpdateStorage implements IgnoredUpdateStorage {
  /// 使用给定记录初始化存储。
  _MemoryIgnoredUpdateStorage({
    List<IgnoredUpdate> initialRecords = const <IgnoredUpdate>[],
  }) : _records = List<IgnoredUpdate>.from(initialRecords);

  /// 当前已经持久化的记录快照。
  List<IgnoredUpdate> _records;

  @override
  List<IgnoredUpdate> load() => List<IgnoredUpdate>.from(_records);

  @override
  Future<bool> save(List<IgnoredUpdate> records) async {
    _records = List<IgnoredUpdate>.from(records);
    return true;
  }
}
