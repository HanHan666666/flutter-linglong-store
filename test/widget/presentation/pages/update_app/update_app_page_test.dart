import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_operation_queue_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/network_speed_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/presentation/pages/update_app/update_app_page.dart';
import 'package:linglong_store/presentation/widgets/install_button.dart';

void main() {
  group('UpdateAppPage', () {
    testWidgets(
      'renders installing update row in Row layout without infinite width exception',
      (tester) async {
        final installQueue = TestInstallQueue(
          initialState: InstallQueueState(
            currentTask: InstallTask(
              id: 'task-installing',
              appId: 'org.example.demo',
              appName: 'Demo',
              kind: InstallTaskKind.update,
              status: InstallStatus.installing,
              progress: 0.4,
              message: 'Updating demo app',
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
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

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              installQueueProvider.overrideWith(() => installQueue),
              updateAppsProvider.overrideWith(() => updateApps),
              networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
              appOperationQueueControllerProvider.overrideWith(
                (ref) => RecordingAppOperationQueueController(ref),
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

        expect(find.byType(UpdateAppPage), findsOneWidget);
        expect(find.byType(InstallButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

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

    testWidgets(
      'keeps layout density while using surface-style update cards with hover shadow',
      (tester) async {
        final installQueue = TestInstallQueue(
          initialState: const InstallQueueState(),
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

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              installQueueProvider.overrideWith(() => installQueue),
              updateAppsProvider.overrideWith(() => updateApps),
              networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
              appOperationQueueControllerProvider.overrideWith(
                (ref) => RecordingAppOperationQueueController(ref),
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

        expect(find.text('1.0.0 → 1.1.0'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(AnimatedContainer), findsOneWidget);

        final card = tester.widget<Card>(find.byType(Card).first);
        expect(card.margin, const EdgeInsets.all(4.0));
        expect(card.clipBehavior, Clip.none);
        expect(card.color, Colors.transparent);

        final animatedContainerFinder = find.byType(AnimatedContainer).first;
        final animatedContainer = tester.widget<AnimatedContainer>(
          animatedContainerFinder,
        );
        final decoration = animatedContainer.decoration! as BoxDecoration;
        final BuildContext containerContext = tester.element(
          animatedContainerFinder,
        );
        expect(decoration.color, containerContext.appColors.surface);
        expect(decoration.border, isNotNull);
        expect(decoration.boxShadow, isNull);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer();
        await mouse.moveTo(tester.getCenter(find.byType(Card)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final hoveredContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        final hoveredDecoration = hoveredContainer.decoration! as BoxDecoration;
        expect(hoveredDecoration.boxShadow, isNotNull);
        expect(hoveredDecoration.boxShadow, isNotEmpty);
      },
    );

    testWidgets('keeps header and list visible during background refresh', (
      tester,
    ) async {
      final installQueue = TestInstallQueue(
        initialState: const InstallQueueState(),
      );
      final updateApps = TestUpdateApps(
        initialState: const UpdateAppsState(
          apps: [
            UpdatableApp(
              installedApp: InstalledApp(
                appId: 'org.example.demo',
                name: 'Demo',
                version: '1.0.0',
              ),
              latestVersion: '1.1.0',
            ),
          ],
          isLoading: true,
          hasLoadedOnce: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installQueueProvider.overrideWith(() => installQueue),
            updateAppsProvider.overrideWith(() => updateApps),
            networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
            appOperationQueueControllerProvider.overrideWith(
              (ref) => RecordingAppOperationQueueController(ref),
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

      expect(find.text('共 1 个应用可更新'), findsOneWidget);
      expect(find.text('1.0.0 → 1.1.0'), findsOneWidget);
    });

    testWidgets('shows check update action next to update all in header', (
      tester,
    ) async {
      final installQueue = TestInstallQueue(
        initialState: const InstallQueueState(),
      );
      final updateApps = TestUpdateApps(
        initialState: const UpdateAppsState(
          apps: [
            UpdatableApp(
              installedApp: InstalledApp(
                appId: 'org.example.demo',
                name: 'Demo',
                version: '1.0.0',
              ),
              latestVersion: '1.1.0',
            ),
          ],
          hasLoadedOnce: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installQueueProvider.overrideWith(() => installQueue),
            updateAppsProvider.overrideWith(() => updateApps),
            networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
            appOperationQueueControllerProvider.overrideWith(
              (ref) => RecordingAppOperationQueueController(ref),
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

      expect(find.widgetWithText(OutlinedButton, '检查更新'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '全部更新'), findsOneWidget);
    });

    testWidgets('keeps empty state visible during background refresh', (
      tester,
    ) async {
      final installQueue = TestInstallQueue(
        initialState: const InstallQueueState(),
      );
      final updateApps = TestUpdateApps(
        initialState: const UpdateAppsState(
          isLoading: true,
          hasLoadedOnce: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installQueueProvider.overrideWith(() => installQueue),
            updateAppsProvider.overrideWith(() => updateApps),
            networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
            appOperationQueueControllerProvider.overrideWith(
              (ref) => RecordingAppOperationQueueController(ref),
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

      expect(find.text('暂无更新'), findsNWidgets(2));
      expect(find.widgetWithText(OutlinedButton, '检查更新中...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('keeps check update action available in empty state', (
      tester,
    ) async {
      final installQueue = TestInstallQueue(
        initialState: const InstallQueueState(),
      );
      final updateApps = TestUpdateApps(
        initialState: const UpdateAppsState(hasLoadedOnce: true),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installQueueProvider.overrideWith(() => installQueue),
            updateAppsProvider.overrideWith(() => updateApps),
            networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
            appOperationQueueControllerProvider.overrideWith(
              (ref) => RecordingAppOperationQueueController(ref),
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

      final beforeTapCalls = updateApps.checkUpdatesCalls;
      expect(find.widgetWithText(OutlinedButton, '检查更新'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, '检查更新'));
      await tester.pump();

      expect(updateApps.checkUpdatesCalls, beforeTapCalls + 1);
    });

    testWidgets('shows "等待安装" for pending apps in queue, not progress bar', (
      tester,
    ) async {
      final installQueue = TestInstallQueue(
        initialState: InstallQueueState(
          currentTask: InstallTask(
            id: 'task-running',
            appId: 'org.example.app1',
            appName: 'App 1',
            kind: InstallTaskKind.update,
            status: InstallStatus.installing,
            progress: 0.5,
            message: 'Installing app 1',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
          queue: [
            InstallTask(
              id: 'task-pending',
              appId: 'org.example.app2',
              appName: 'App 2',
              kind: InstallTaskKind.update,
              status: InstallStatus.pending,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          ],
          isProcessing: true,
        ),
      );
      final updateApps = TestUpdateApps(
        apps: const [
          UpdatableApp(
            installedApp: InstalledApp(
              appId: 'org.example.app1',
              name: 'App 1',
              version: '1.0.0',
            ),
            latestVersion: '1.1.0',
          ),
          UpdatableApp(
            installedApp: InstalledApp(
              appId: 'org.example.app2',
              name: 'App 2',
              version: '2.0.0',
            ),
            latestVersion: '2.1.0',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installQueueProvider.overrideWith(() => installQueue),
            updateAppsProvider.overrideWith(() => updateApps),
            networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
            appOperationQueueControllerProvider.overrideWith(
              (ref) => RecordingAppOperationQueueController(ref),
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

      // App 2 是 pending 状态，应该显示"等待安装"，而不是进度条
      expect(find.text('等待安装'), findsOneWidget);
      // 网速不应该显示（因为 App 2 不是当前任务）
      expect(find.textContaining('KB/s'), findsNothing);
      expect(find.textContaining('MB/s'), findsNothing);
    });
  });
}

class TestInstallQueue extends InstallQueue {
  TestInstallQueue({required this.initialState});

  final InstallQueueState initialState;

  @override
  InstallQueueState build() => initialState;
}

class TestUpdateApps extends UpdateApps {
  TestUpdateApps({UpdateAppsState? initialState, List<UpdatableApp>? apps})
    : initialState =
          initialState ?? UpdateAppsState(apps: apps ?? const <UpdatableApp>[]);

  final UpdateAppsState initialState;
  int checkUpdatesCalls = 0;
  int refreshCalls = 0;

  @override
  UpdateAppsState build() => initialState;

  @override
  Future<void> checkUpdates() async {
    checkUpdatesCalls += 1;
  }

  @override
  Future<void> refresh() async {
    refreshCalls += 1;
  }
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
