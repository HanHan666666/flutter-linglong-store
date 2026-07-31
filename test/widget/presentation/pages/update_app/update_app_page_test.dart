import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_operation_queue_provider.dart';
import 'package:linglong_store/application/providers/ignored_updates_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
import 'package:linglong_store/application/providers/network_speed_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/storage/ignored_update_storage.dart';
import 'package:linglong_store/domain/models/ignored_update.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/presentation/pages/update_app/update_app_page.dart';
import 'package:linglong_store/presentation/widgets/install_to_download_flyout.dart';
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
              installedAppsProvider.overrideWith(() => TestInstalledApps()),
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
              installedAppsProvider.overrideWith(() => TestInstalledApps()),
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

        await tester.tap(find.widgetWithText(FilledButton, '更 新'));
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
              installedAppsProvider.overrideWith(() => TestInstalledApps()),
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

        final semanticsHandle = tester.ensureSemantics();
        try {
          expect(find.bySemanticsLabel('Demo 的更多更新操作'), findsOneWidget);
        } finally {
          semanticsHandle.dispose();
        }

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
            installedAppsProvider.overrideWith(() => TestInstalledApps()),
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
            installedAppsProvider.overrideWith(() => TestInstalledApps()),
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
            installedAppsProvider.overrideWith(() => TestInstalledApps()),
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
            installedAppsProvider.overrideWith(() => TestInstalledApps()),
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

    testWidgets(
      'manual check refreshes installed apps before recomputing updates',
      (tester) async {
        final events = <String>[];
        final installQueue = TestInstallQueue(
          initialState: const InstallQueueState(),
        );
        final installedApps = TestInstalledApps(events: events);
        final updateApps = TestUpdateApps(events: events);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              installQueueProvider.overrideWith(() => installQueue),
              installedAppsProvider.overrideWith(() => installedApps),
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
        events.clear();

        await tester.tap(find.widgetWithText(OutlinedButton, '检查更新'));
        await tester.pump();

        expect(events, ['installed:refresh', 'updates:check']);
      },
    );

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
            installedAppsProvider.overrideWith(() => TestInstalledApps()),
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

    testWidgets(
      'shows subtle ignored entry and opens the empty manager dialog',
      (tester) async {
        final storage = _MemoryIgnoredUpdateStorage();
        await tester.pumpWidget(
          _buildIgnoredUpdateFeatureHost(
            storage: storage,
            installQueue: TestInstallQueue(
              initialState: const InstallQueueState(),
            ),
            updateApps: TestUpdateApps(),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final entryFinder = find.byKey(const ValueKey('ignored-updates-entry'));
        expect(entryFinder, findsOneWidget);
        expect(find.text('已忽略（0）'), findsOneWidget);
        expect(tester.getSize(entryFinder).height, greaterThanOrEqualTo(48));
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == '管理已忽略的更新，共 0 个应用' &&
                widget.properties.button == true,
          ),
          findsOneWidget,
        );

        final entry = tester.widget<TextButton>(entryFinder);
        expect(entry.child, isA<Text>());
        expect(
          find.descendant(of: entryFinder, matching: find.byType(Icon)),
          findsNothing,
        );

        await tester.tap(entryFinder);
        await tester.pumpAndSettle();

        expect(find.text('已忽略的更新'), findsOneWidget);
        expect(find.text('暂无已忽略的应用'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('已忽略的更新'), findsNothing);
      },
    );

    testWidgets(
      'ignores from the row menu and restores from the manager dialog',
      (tester) async {
        final storage = _MemoryIgnoredUpdateStorage();
        final updateApps = TestUpdateApps(
          apps: const [
            UpdatableApp(
              installedApp: InstalledApp(
                appId: 'org.example.demo',
                name: 'Demo',
                version: '1.0.0',
              ),
              latestVersion: '2.0.0',
            ),
          ],
        );
        await tester.pumpWidget(
          _buildIgnoredUpdateFeatureHost(
            storage: storage,
            installQueue: TestInstallQueue(
              initialState: const InstallQueueState(),
            ),
            updateApps: updateApps,
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(
          find.byKey(const ValueKey('update-app-more-org.example.demo')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('忽略此应用更新'));
        await tester.pumpAndSettle();

        expect(find.text('1.0.0 → 2.0.0'), findsNothing);
        expect(find.text('已忽略（1）'), findsOneWidget);
        expect(find.text('全部更新'), findsNothing);
        expect(find.text('已忽略 Demo 的后续更新，可在“已忽略”中恢复'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('ignored-updates-entry')));
        await tester.pumpAndSettle();

        expect(find.text('Demo'), findsOneWidget);
        expect(find.text('org.example.demo'), findsOneWidget);
        expect(find.text('忽略时版本：1.0.0'), findsOneWidget);
        final restoreButton = find.widgetWithText(TextButton, '恢复更新提醒');
        expect(tester.getSize(restoreButton).height, greaterThanOrEqualTo(48));
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == '恢复 Demo 的更新提醒' &&
                widget.properties.button == true,
          ),
          findsOneWidget,
        );

        await tester.tap(restoreButton);
        await tester.pumpAndSettle();

        expect(find.text('暂无已忽略的应用'), findsOneWidget);
        expect(storage.load(), isEmpty);
      },
    );

    testWidgets('disables ignore menu item while the app update is active', (
      tester,
    ) async {
      final storage = _MemoryIgnoredUpdateStorage();
      await tester.pumpWidget(
        _buildIgnoredUpdateFeatureHost(
          storage: storage,
          installQueue: TestInstallQueue(
            initialState: const InstallQueueState(
              currentTask: InstallTask(
                id: 'task-active',
                appId: 'org.example.demo',
                appName: 'Demo',
                kind: InstallTaskKind.update,
                status: InstallStatus.installing,
                createdAt: 1,
              ),
              isProcessing: true,
            ),
          ),
          updateApps: TestUpdateApps(
            apps: const [
              UpdatableApp(
                installedApp: InstalledApp(
                  appId: 'org.example.demo',
                  name: 'Demo',
                  version: '1.0.0',
                ),
                latestVersion: '2.0.0',
              ),
            ],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(
        find.byKey(const ValueKey('update-app-more-org.example.demo')),
      );
      // 锚点菜单同步显示，不再为旧 PopupMenuRoute 推进 300ms 动画。
      await tester.pump();

      final disabledItem = tester.widget<MenuItemButton>(
        find.byKey(const ValueKey('ignore-updates-org.example.demo')),
      );
      expect(disabledItem.enabled, isFalse);
      expect(storage.load(), isEmpty);
    });

    testWidgets('launches flyout after single update is enqueued', (
      tester,
    ) async {
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
      final singleCalls = <EnqueueAppOperationParams>[];
      final batchCalls = <List<EnqueueAppOperationParams>>[];

      await tester.pumpWidget(
        _buildFlyoutHost(
          installQueue: installQueue,
          updateApps: updateApps,
          singleCalls: singleCalls,
          batchCalls: batchCalls,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.widgetWithText(FilledButton, '更 新'));
      await tester.pump();

      expect(singleCalls, hasLength(1));
      expect(find.byKey(const Key('install-download-flyout')), findsOneWidget);
    });

    testWidgets('does not trigger single update flyout when enqueue fails', (
      tester,
    ) async {
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
      final singleCalls = <EnqueueAppOperationParams>[];
      final batchCalls = <List<EnqueueAppOperationParams>>[];

      await tester.pumpWidget(
        _buildFlyoutHost(
          installQueue: installQueue,
          updateApps: updateApps,
          singleCalls: singleCalls,
          batchCalls: batchCalls,
          singleReturnValue: '',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.widgetWithText(FilledButton, '更 新'));
      await tester.pump();

      expect(singleCalls, hasLength(1));
      expect(find.byKey(const Key('install-download-flyout')), findsNothing);
      expect(
        find.byKey(const Key('install-download-target-pulse')),
        findsNothing,
      );
    });

    testWidgets('pulses download center after batch update is enqueued', (
      tester,
    ) async {
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
      final singleCalls = <EnqueueAppOperationParams>[];
      final batchCalls = <List<EnqueueAppOperationParams>>[];

      await tester.pumpWidget(
        _buildFlyoutHost(
          installQueue: installQueue,
          updateApps: updateApps,
          singleCalls: singleCalls,
          batchCalls: batchCalls,
          batchReturnValue: const ['task-1'],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.widgetWithText(FilledButton, '全部更新'));
      await tester.pump();

      expect(batchCalls, hasLength(1));
      expect(
        find.byKey(const Key('install-download-target-pulse')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('install-download-flyout')), findsNothing);
    });

    testWidgets('does not pulse download center when batch enqueue fails', (
      tester,
    ) async {
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
      final singleCalls = <EnqueueAppOperationParams>[];
      final batchCalls = <List<EnqueueAppOperationParams>>[];

      await tester.pumpWidget(
        _buildFlyoutHost(
          installQueue: installQueue,
          updateApps: updateApps,
          singleCalls: singleCalls,
          batchCalls: batchCalls,
          batchReturnValue: const <String>[],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.widgetWithText(FilledButton, '全部更新'));
      await tester.pump();

      expect(batchCalls, hasLength(1));
      expect(
        find.byKey(const Key('install-download-target-pulse')),
        findsNothing,
      );
    });
  });
}

Widget _buildIgnoredUpdateFeatureHost({
  required IgnoredUpdateStorage storage,
  required InstallQueue installQueue,
  required UpdateApps updateApps,
}) {
  return ProviderScope(
    overrides: [
      ignoredUpdateStorageProvider.overrideWithValue(storage),
      installQueueProvider.overrideWith(() => installQueue),
      installedAppsProvider.overrideWith(() => TestInstalledApps()),
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
  );
}

Widget _buildFlyoutHost({
  required InstallQueue installQueue,
  required UpdateApps updateApps,
  List<EnqueueAppOperationParams>? singleCalls,
  List<List<EnqueueAppOperationParams>>? batchCalls,
  String singleReturnValue = 'task-1',
  List<String> batchReturnValue = const <String>['task-1'],
}) {
  return ProviderScope(
    overrides: [
      installQueueProvider.overrideWith(() => installQueue),
      installedAppsProvider.overrideWith(() => TestInstalledApps()),
      updateAppsProvider.overrideWith(() => updateApps),
      networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
      appOperationQueueControllerProvider.overrideWith(
        (ref) => RecordingAppOperationQueueController(
          ref,
          singleCalls: singleCalls,
          batchCalls: batchCalls,
          singleReturnValue: singleReturnValue,
          batchReturnValue: batchReturnValue,
        ),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: InstallToDownloadFlyoutLayer(
          child: Stack(
            children: [
              Positioned.fill(child: UpdateAppPage()),
              Positioned(
                top: 16,
                right: 16,
                child: DownloadCenterFlyoutTarget(
                  child: SizedBox(width: 40, height: 40),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class TestInstallQueue extends InstallQueue {
  TestInstallQueue({required this.initialState});

  final InstallQueueState initialState;

  @override
  InstallQueueState build() => initialState;
}

class TestInstalledApps extends InstalledApps {
  TestInstalledApps({this.events});

  final List<String>? events;

  @override
  InstalledAppsState build() {
    return const InstalledAppsState(
      apps: [
        InstalledApp(appId: 'org.example.demo', name: 'Demo', version: '1.0.0'),
      ],
    );
  }

  @override
  Future<void> refresh() async {
    events?.add('installed:refresh');
    state = build();
  }
}

class TestUpdateApps extends UpdateApps {
  TestUpdateApps({
    UpdateAppsState? initialState,
    List<UpdatableApp>? apps,
    this.events,
  }) : initialState =
           initialState ??
           UpdateAppsState(apps: apps ?? const <UpdatableApp>[]);

  final UpdateAppsState initialState;
  final List<String>? events;
  int checkUpdatesCalls = 0;
  int refreshCalls = 0;

  @override
  UpdateAppsState build() => initialState;

  @override
  Future<void> checkUpdates() async {
    checkUpdatesCalls += 1;
    events?.add('updates:check');
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
    List<List<EnqueueAppOperationParams>>? batchCalls,
    this.singleReturnValue = 'task-1',
    List<String>? batchReturnValue,
  }) : singleCalls = singleCalls ?? <EnqueueAppOperationParams>[],
       batchCalls = batchCalls ?? <List<EnqueueAppOperationParams>>[],
       batchReturnValue = batchReturnValue ?? const <String>['task-1'];

  final List<EnqueueAppOperationParams> singleCalls;
  final List<List<EnqueueAppOperationParams>> batchCalls;
  final String singleReturnValue;
  final List<String> batchReturnValue;

  @override
  String enqueueAppOperation(EnqueueAppOperationParams params) {
    singleCalls.add(params);
    return singleReturnValue;
  }

  @override
  List<String> enqueueBatchOperations(
    List<EnqueueAppOperationParams> paramsList,
  ) {
    batchCalls.add(List<EnqueueAppOperationParams>.from(paramsList));
    return List<String>.from(batchReturnValue);
  }
}

/// 为 Widget 测试提供可观察、无外部依赖的忽略更新存储。
class _MemoryIgnoredUpdateStorage implements IgnoredUpdateStorage {
  /// 使用给定快照初始化内存存储。
  _MemoryIgnoredUpdateStorage({
    List<IgnoredUpdate> initialRecords = const <IgnoredUpdate>[],
  }) : _records = List<IgnoredUpdate>.from(initialRecords);

  /// 当前持久化快照，刻意复制以模拟真实存储的值语义。
  List<IgnoredUpdate> _records;

  @override
  List<IgnoredUpdate> load() => List<IgnoredUpdate>.from(_records);

  @override
  Future<bool> save(List<IgnoredUpdate> records) async {
    _records = List<IgnoredUpdate>.from(records);
    return true;
  }
}
