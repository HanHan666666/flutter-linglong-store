import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_operation_queue_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/network_speed_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/presentation/pages/update_app/update_app_page.dart';

void main() {
  group('UpdateAppPage', () {
    testWidgets(
      'does not trigger another update for a stale successful row while queue is active',
      (tester) async {
        final installQueue = TestInstallQueue(
          initialState: InstallQueueState(
            currentTask: InstallTask(
              id: 'task-running',
              appId: 'org.example.other',
              appName: 'Other',
              kind: InstallTaskKind.update,
              status: InstallStatus.installing,
              progress: 0.4,
              message: 'Updating other app',
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
            history: [
              InstallTask(
                id: 'task-success',
                appId: 'org.example.demo',
                appName: 'Demo',
                kind: InstallTaskKind.update,
                status: InstallStatus.success,
                progress: 1.0,
                message: '更新完成',
                createdAt: DateTime.now().millisecondsSinceEpoch,
                finishedAt: DateTime.now().millisecondsSinceEpoch,
              ),
            ],
            isProcessing: true,
          ),
        );
        final updateApps = TestUpdateApps(
          apps: const [
            UpdatableApp(
              installedApp: InstalledApp(
                appId: 'org.example.demo',
                name: 'Demo',
                version: '1.0.0',
              ),
              latestVersion: '1.1.0',
              latestVersionDescription: 'Bug fixes',
            ),
          ],
        );
        final recordedSingles = <EnqueueAppOperationParams>[];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              installQueueProvider.overrideWith(() => installQueue),
              updateAppsProvider.overrideWith(() => updateApps),
              networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
              appOperationQueueControllerProvider.overrideWith(
                (ref) => RecordingAppOperationQueueController(
                  ref,
                  singleCalls: recordedSingles,
                ),
              ),
            ],
            child: const MaterialApp(
              locale: Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: UpdateAppPage()),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.widgetWithText(ElevatedButton, '更 新'));
        await tester.pump();

        expect(recordedSingles, isEmpty);
      },
    );
  });
}

class TestInstallQueue extends InstallQueue {
  TestInstallQueue({required this.initialState});

  final InstallQueueState initialState;

  @override
  InstallQueueState build() => initialState;
}

class TestUpdateApps extends UpdateApps {
  TestUpdateApps({required this.apps});

  final List<UpdatableApp> apps;

  @override
  UpdateAppsState build() => UpdateAppsState(apps: apps);

  @override
  Future<void> checkUpdates() async {}

  @override
  Future<void> refresh() async {}
}

class RecordingAppOperationQueueController extends AppOperationQueueController {
  RecordingAppOperationQueueController(
    super.ref, {
    List<EnqueueAppOperationParams>? singleCalls,
  }) : singleCalls = singleCalls ?? <EnqueueAppOperationParams>[];

  final List<EnqueueAppOperationParams> singleCalls;

  @override
  String enqueueAppOperation(EnqueueAppOperationParams params) {
    singleCalls.add(params);
    return 'task-${singleCalls.length}';
  }
}
