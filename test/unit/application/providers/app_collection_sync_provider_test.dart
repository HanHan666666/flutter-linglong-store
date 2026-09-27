/// 验证应用集合同步入口在"更新成功但快照未收敛"时不会回流更新项。
///
/// 该入口是安装、更新、卸载与页面手动刷新的唯一收敛点，因此这里同时覆盖
/// 两条语义：无更新目标时保持既有"刷新后重算"行为；有更新目标时必须先确认
/// 目标版本已在快照中可见，否则跳过重算，但差量统计上报不能省。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_collection_sync_provider.dart';
import 'package:linglong_store/application/providers/installed_app_diff_report_provider.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/application/services/installed_app_diff_report_service.dart';
import 'package:linglong_store/application/services/update_convergence_service.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/app_operation_target_snapshot.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  setUpAll(() async {
    // 未收敛分支会写入诊断日志，测试进程同样需要初始化日志器。
    await AppLogger.init();
  });

  group('AppCollectionSyncService', () {
    test(
      'waits for installed apps refresh before recomputing updates',
      () async {
        final events = <String>[];
        final refreshCompleter = Completer<void>();
        final installedApps = DelayedInstalledApps(
          refreshCompleter: refreshCompleter,
          events: events,
        );
        final updateApps = RecordingUpdateApps(events);
        final diffService = RecordingDiffReportService(events);

        final container = _createContainer(
          installedApps: installedApps,
          updateApps: updateApps,
          diffService: diffService,
        );
        addTearDown(container.dispose);

        final syncFuture = Future.sync(
          () => container
              .read(appCollectionSyncServiceProvider)
              .syncAfterSuccessfulOperation(),
        );

        await Future<void>.delayed(Duration.zero);

        expect(events, ['installed:start']);

        refreshCompleter.complete();
        await syncFuture;

        // 同步完成后必须触发差量检测，安装/卸载统计由该链路统一上报。
        expect(
          events,
          ['installed:start', 'installed:end', 'updates:2.0.0', 'diff-check'],
        );
      },
    );

    test('无更新目标时不进入收敛确认并保持既有重算语义', () async {
      final events = <String>[];
      final verifier = RecordingConvergenceVerifier(
        const UpdateConvergenceResult(
          confirmed: false,
          attempts: 3,
          unconfirmedTargets: [],
          refreshFailed: false,
        ),
      );

      final container = _createContainer(
        installedApps: ImmediateInstalledApps(events, version: '2.0.0'),
        updateApps: RecordingUpdateApps(events),
        diffService: RecordingDiffReportService(events),
        verifier: verifier,
      );
      addTearDown(container.dispose);

      // 安装/卸载与页面手动刷新都走无目标分支，必须保持原有行为。
      await container
          .read(appCollectionSyncServiceProvider)
          .syncAfterSuccessfulOperation();

      expect(verifier.verifyCalls, 0);
      expect(
        events,
        ['installed:start', 'installed:end', 'updates:2.0.0', 'diff-check'],
      );
    });

    test('更新目标已收敛时重算更新列表', () async {
      final events = <String>[];
      final target = _target();
      final verifier = RecordingConvergenceVerifier(
        const UpdateConvergenceResult(
          confirmed: true,
          attempts: 1,
          unconfirmedTargets: [],
          refreshFailed: false,
        ),
      );

      final container = _createContainer(
        installedApps: ImmediateInstalledApps(events, version: '2.0.0'),
        updateApps: RecordingUpdateApps(events),
        diffService: RecordingDiffReportService(events),
        verifier: verifier,
      );
      addTearDown(container.dispose);

      await container
          .read(appCollectionSyncServiceProvider)
          .syncAfterSuccessfulOperation(updateTargets: [target]);

      expect(verifier.verifyCalls, 1);
      expect(verifier.lastTargets.single.appId, target.appId);
      expect(events, ['updates:2.0.0', 'diff-check']);
    });

    test('更新目标未收敛时跳过更新列表重算但仍上报差量统计', () async {
      final events = <String>[];
      final target = _target();
      final updateApps = RecordingUpdateApps(events);
      final verifier = RecordingConvergenceVerifier(
        UpdateConvergenceResult(
          confirmed: false,
          attempts: 3,
          unconfirmedTargets: [target],
          refreshFailed: false,
        ),
      );

      final container = _createContainer(
        // 快照仍是更新前的版本，模拟 `ll-cli list` 尚未收敛。
        installedApps: ImmediateInstalledApps(events, version: '1.0.0'),
        updateApps: updateApps,
        diffService: RecordingDiffReportService(events),
        verifier: verifier,
      );
      addTearDown(container.dispose);

      await container
          .read(appCollectionSyncServiceProvider)
          .syncAfterSuccessfulOperation(updateTargets: [target]);

      expect(verifier.verifyCalls, 1);
      // 关键回归点：禁止用更新前的版本把刚更新的应用重新判为可更新。
      expect(updateApps.checkUpdatesCalls, 0);
      expect(events, ['diff-check']);
    });
  });
}

/// 构造一个带目标版本期望的更新目标快照。
AppOperationTargetSnapshot _target() {
  return const AppOperationTargetSnapshot(
    appId: 'org.example.demo',
    displayName: 'Demo',
    installedVersion: '1.0.0',
    expectedVersion: '2.0.0',
  );
}

/// 创建注入了可控替身的隔离容器。
ProviderContainer _createContainer({
  required InstalledApps installedApps,
  required UpdateApps updateApps,
  required InstalledAppDiffReportService diffService,
  UpdateConvergenceVerifier? verifier,
}) {
  return ProviderContainer(
    overrides: [
      installedAppsProvider.overrideWith(() => installedApps),
      updateAppsProvider.overrideWith(() => updateApps),
      installedAppDiffReportServiceProvider.overrideWithValue(diffService),
      if (verifier != null)
        updateConvergenceVerifierProvider.overrideWithValue(verifier),
    ],
  );
}

/// 记录触发时机的差量检测替身，避免测试容器依赖真实 ll-cli。
class RecordingDiffReportService extends InstalledAppDiffReportService {
  RecordingDiffReportService(this.events)
    : super(
        cliRepository: MockLinglongCliRepository(),
        analyticsRepository: _NoopAnalyticsRepository(),
      );

  final List<String> events;

  @override
  void scheduleImmediateCheck() {
    events.add('diff-check');
  }
}

/// 记录收敛确认调用次数与入参的替身。
class RecordingConvergenceVerifier implements UpdateConvergenceVerifier {
  RecordingConvergenceVerifier(this.result);

  final UpdateConvergenceResult result;

  /// 被调用的次数。
  int verifyCalls = 0;

  /// 最近一次收到的目标集合。
  List<AppOperationTargetSnapshot> lastTargets = const [];

  @override
  Future<UpdateConvergenceResult> verify(
    List<AppOperationTargetSnapshot> targets,
  ) async {
    verifyCalls += 1;
    lastTargets = List<AppOperationTargetSnapshot>.from(targets);
    return result;
  }
}

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

/// 立即完成刷新的已安装快照替身，用于观察刷新与重算的先后关系。
class ImmediateInstalledApps extends InstalledApps {
  ImmediateInstalledApps(this.events, {required this.version});

  final List<String> events;
  final String version;

  @override
  InstalledAppsState build() {
    return InstalledAppsState(apps: [_app()]);
  }

  @override
  Future<bool> refresh() async {
    events.add('installed:start');
    state = InstalledAppsState(apps: [_app()]);
    events.add('installed:end');
    return true;
  }

  InstalledApp _app() {
    return InstalledApp(
      appId: 'org.example.demo',
      name: 'Demo',
      version: version,
    );
  }
}

/// 可控刷新时机的已安装快照替身，用于验证"先刷新再重算"的顺序约束。
class DelayedInstalledApps extends InstalledApps {
  DelayedInstalledApps({
    required this.refreshCompleter,
    required this.events,
  });

  final Completer<void> refreshCompleter;
  final List<String> events;

  @override
  InstalledAppsState build() {
    return const InstalledAppsState(
      apps: [
        InstalledApp(
          appId: 'org.example.demo',
          name: 'Demo',
          version: '1.0.0',
        ),
      ],
    );
  }

  @override
  Future<bool> refresh() async {
    events.add('installed:start');
    await refreshCompleter.future;
    state = const InstalledAppsState(
      apps: [
        InstalledApp(
          appId: 'org.example.demo',
          name: 'Demo',
          version: '2.0.0',
        ),
      ],
    );
    events.add('installed:end');
    return true;
  }
}

/// 记录更新检查调用次数与当时读取到的快照版本。
class RecordingUpdateApps extends UpdateApps {
  RecordingUpdateApps(this.events);

  final List<String> events;

  /// 更新检查被调用的次数。
  int checkUpdatesCalls = 0;

  @override
  UpdateAppsState build() => const UpdateAppsState();

  @override
  Future<void> checkUpdates() async {
    checkUpdatesCalls += 1;
    final version = ref.read(installedAppsProvider).apps.single.version;
    events.add('updates:$version');
  }
}
