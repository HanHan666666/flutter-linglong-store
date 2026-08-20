import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_collection_sync_provider.dart';
import 'package:linglong_store/application/providers/installed_app_diff_report_provider.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/application/services/installed_app_diff_report_service.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
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

        final container = ProviderContainer(
          overrides: [
            installedAppsProvider.overrideWith(() => installedApps),
            updateAppsProvider.overrideWith(() => updateApps),
            installedAppDiffReportServiceProvider.overrideWithValue(
              diffService,
            ),
          ],
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
  });
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
  Future<void> refresh() async {
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
  }
}

class RecordingUpdateApps extends UpdateApps {
  RecordingUpdateApps(this.events);

  final List<String> events;

  @override
  UpdateAppsState build() => const UpdateAppsState();

  @override
  Future<void> checkUpdates() async {
    final version = ref.read(installedAppsProvider).apps.single.version;
    events.add('updates:$version');
  }
}
