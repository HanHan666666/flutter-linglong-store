import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/network_speed_provider.dart';
import 'package:linglong_store/application/providers/sidebar_config_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/presentation/pages/update_app/update_app_page.dart';
import 'package:linglong_store/presentation/widgets/download_manager_dialog.dart';
import 'package:linglong_store/presentation/widgets/sidebar.dart';

void main() {
  group('DownloadManagerDialog', () {
    testWidgets(
      'shows active task progress as readable percent and keeps a stable shell height',
      (tester) async {
        final installQueue = TestInstallQueue(
          initialState: InstallQueueState(
            currentTask: InstallTask(
              id: 'task-1',
              appId: 'org.example.demo',
              appName: 'Demo',
              kind: InstallTaskKind.update,
              status: InstallStatus.downloading,
              progress: 0.74,
              message: 'Downloading files',
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
            isProcessing: true,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              installQueueProvider.overrideWith(() => installQueue),
              networkSpeedProvider.overrideWithValue(
                const NetworkSpeed(downloadBytesPerSec: 2.3 * 1024 * 1024),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: FilledButton(
                        onPressed: () => showDownloadManagerDialog(context),
                        child: const Text('open'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.textContaining('74%'), findsOneWidget);
        expect(find.textContaining('2.3'), findsAtLeastNWidgets(1));

        final dialogSize = tester.getSize(find.byType(Dialog));
        expect(dialogSize.height, greaterThanOrEqualTo(420));

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, closeTo(0.74, 0.0001));
      },
    );

    testWidgets('closing dialog detaches install queue updates', (
      tester,
    ) async {
      final installQueue = TestInstallQueue();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installQueueProvider.overrideWith(() => installQueue),
            networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () => showDownloadManagerDialog(context),
                      child: const Text('open'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('下载管理'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('下载管理'), findsNothing);

      for (var i = 0; i < 12; i++) {
        installQueue.emit(
          InstallQueueState(
            currentTask: InstallTask(
              id: 'task-1',
              appId: 'org.example.demo',
              appName: 'Demo',
              kind: InstallTaskKind.update,
              status: InstallStatus.installing,
              progress: 10.0 + i,
              message: 'Downloading files',
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
            isProcessing: true,
          ),
        );

        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
      'closing dialog from sidebar does not throw during update page progress refreshes',
      (tester) async {
        final installQueue = TestInstallQueue();
        final updateApps = TestUpdateApps();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              installQueueProvider.overrideWith(() => installQueue),
              updateAppsProvider.overrideWith(() => updateApps),
              sidebarConfigProvider.overrideWith((ref) async => []),
              networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
            ],
            child: MaterialApp(
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: Row(
                  children: [
                    Sidebar(currentPath: '/update_apps'),
                    Expanded(child: UpdateAppPage()),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('下载管理'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(of: find.byType(Dialog), matching: find.text('下载管理')),
          findsOneWidget,
        );

        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pump();

        for (var i = 0; i < 12; i++) {
          installQueue.emit(
            InstallQueueState(
              currentTask: InstallTask(
                id: 'task-1',
                appId: 'org.example.demo',
                appName: 'Demo',
                kind: InstallTaskKind.update,
                status: InstallStatus.installing,
                progress: 10.0 + i,
                message: 'Downloading files',
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ),
              isProcessing: true,
            ),
          );

          await tester.pump();
          expect(tester.takeException(), isNull);
        }

        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Dialog), findsNothing);
      },
    );
  });
}

class TestInstallQueue extends InstallQueue {
  TestInstallQueue({InstallQueueState? initialState})
    : _initialState = initialState ?? const InstallQueueState();

  final InstallQueueState _initialState;

  @override
  InstallQueueState build() => _initialState;

  void emit(InstallQueueState nextState) {
    state = nextState;
  }
}

class TestUpdateApps extends UpdateApps {
  @override
  UpdateAppsState build() {
    return const UpdateAppsState(
      apps: [
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
  }

  @override
  Future<void> checkUpdates() async {}

  @override
  Future<void> refresh() async {}
}
