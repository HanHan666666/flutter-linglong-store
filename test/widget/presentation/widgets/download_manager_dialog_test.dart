import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/network_speed_provider.dart';
import 'package:linglong_store/application/providers/sidebar_config_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/presentation/pages/update_app/update_app_page.dart';
import 'package:linglong_store/presentation/widgets/app_icon.dart';
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
              icon: 'https://example.com/icon.png',
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
        expect(find.byType(AppIcon), findsOneWidget);

        final dialogSize = tester.getSize(find.byType(Dialog));
        expect(dialogSize.height, greaterThanOrEqualTo(420));

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, closeTo(0.74, 0.0001));
      },
    );

    testWidgets('shows active task progress message only once', (tester) async {
      const progressMessage =
          'Updating main:com.tencent.wechat/4.1.1.7/x86_64/binary';
      final installQueue = TestInstallQueue(
        initialState: InstallQueueState(
          currentTask: InstallTask(
            id: 'task-duplicate-message',
            appId: 'com.tencent.wechat',
            appName: '微信',
            kind: InstallTaskKind.update,
            status: InstallStatus.installing,
            progress: 0.99,
            message: progressMessage,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
          isProcessing: true,
        ),
      );

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

      expect(find.text(progressMessage), findsOneWidget);
      expect(find.byTooltip(progressMessage), findsOneWidget);
    });

    testWidgets('renders refined work panel structure for active tasks', (
      tester,
    ) async {
      final installQueue = TestInstallQueue(
        initialState: InstallQueueState(
          currentTask: InstallTask(
            id: 'task-1',
            appId: 'org.example.demo',
            appName: 'Demo',
            kind: InstallTaskKind.install,
            status: InstallStatus.downloading,
            progress: 0.42,
            message: 'Downloading files',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
          queue: [
            InstallTask(
              id: 'task-2',
              appId: 'org.example.next',
              appName: 'Next',
              kind: InstallTaskKind.install,
              status: InstallStatus.pending,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          ],
          isProcessing: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installQueueProvider.overrideWith(() => installQueue),
            networkSpeedProvider.overrideWithValue(
              const NetworkSpeed(downloadBytesPerSec: 1024 * 1024),
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

      expect(find.byKey(const Key('downloadManagerTitleBar')), findsOneWidget);
      expect(
        find.byKey(const Key('downloadManagerOverviewBar')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('downloadManagerTaskList')), findsOneWidget);
      expect(find.byKey(const Key('downloadManagerStatusBar')), findsOneWidget);
      expect(find.text('当前任务'), findsOneWidget);

      final dialogSize = tester.getSize(find.byType(Dialog));
      expect(dialogSize.width, greaterThanOrEqualTo(560));
      expect(dialogSize.height, greaterThanOrEqualTo(460));
    });

    testWidgets('shows plain message text instead of raw json payload', (
      tester,
    ) async {
      final installQueue = TestInstallQueue(
        initialState: InstallQueueState(
          currentTask: InstallTask(
            id: 'task-1',
            appId: 'org.example.demo',
            appName: 'Demo',
            kind: InstallTaskKind.install,
            status: InstallStatus.downloading,
            progress: 0.05,
            message: '{"message":"Beginning to pull data","percentage":5}',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
          isProcessing: true,
        ),
      );

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

      expect(find.text('Beginning to pull data'), findsAtLeastNWidgets(1));
      expect(
        find.textContaining('{"message":"Beginning to pull data"'),
        findsNothing,
      );
    });

    testWidgets('active task progress tooltip keeps full raw message text', (
      tester,
    ) async {
      const fullStatus =
          'Resolving dependency org.deepin.runtime.webengine version 25.2.1 '
          'from repo stable with additional package metadata';
      final ellipsizedStatus = '${fullStatus.substring(0, 50)}...';
      final installQueue = TestInstallQueue(
        initialState: InstallQueueState(
          currentTask: InstallTask(
            id: 'task-1',
            appId: 'org.example.demo',
            appName: 'Demo',
            kind: InstallTaskKind.install,
            status: InstallStatus.installing,
            progress: 0.42,
            message: ellipsizedStatus,
            rawMessage: fullStatus,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
          isProcessing: true,
        ),
      );

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

      expect(find.byTooltip(fullStatus), findsOneWidget);
      expect(find.byTooltip(ellipsizedStatus), findsNothing);
    });

    testWidgets(
      'shows slow install hint when progress stalls near completion',
      (tester) async {
        final startedAt = DateTime.now()
            .subtract(const Duration(seconds: 45))
            .millisecondsSinceEpoch;

        final installQueue = TestInstallQueue(
          initialState: InstallQueueState(
            currentTask: InstallTask(
              id: 'task-slow',
              appId: 'org.example.demo',
              appName: 'Demo',
              kind: InstallTaskKind.install,
              status: InstallStatus.installing,
              progress: 0.95,
              message: 'Installing runtime dependencies',
              createdAt: startedAt,
              startedAt: startedAt,
            ),
            isProcessing: true,
          ),
        );

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

        expect(find.text('如果进度看起来较慢，可能正在安装软件必备依赖，请再等等……'), findsOneWidget);
        final hintRow = find.ancestor(
          of: find.text('如果进度看起来较慢，可能正在安装软件必备依赖，请再等等……'),
          matching: find.byType(Row),
        );
        expect(hintRow, findsOneWidget);
        expect(
          find.descendant(
            of: hintRow,
            matching: find.byIcon(Icons.info_outline),
          ),
          findsOneWidget,
        );
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
            child: const MaterialApp(
              locale: Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
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

    testWidgets('renders full failed error text without line clamping', (
      tester,
    ) async {
      const errorMessage =
          'Error executing command as another user: Request denied because authentication dialog was dismissed before the command could continue. pkexec exited with code 126.';

      final installQueue = TestInstallQueue(
        initialState: InstallQueueState(
          history: [
            InstallTask(
              id: 'task-failed',
              appId: 'org.example.demo',
              appName: 'Demo',
              kind: InstallTaskKind.install,
              status: InstallStatus.failed,
              message: '安装失败',
              errorMessage: errorMessage,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              finishedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          ],
        ),
      );

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

      final errorTexts = tester
          .widgetList<Text>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.data == errorMessage &&
                  widget.style?.color == AppColors.error,
            ),
          )
          .toList();

      expect(errorTexts, isNotEmpty);
      expect(errorTexts.first.maxLines, isNull);
      expect(errorTexts.first.overflow, isNull);
    });

    testWidgets(
      'copy button copies command output and shows local success text',
      (tester) async {
        const commandOutput =
            'll-cli install --json com.tencent.wechat\n'
            '{"message":"Downloading files","percentage":50}\n'
            '{"message":"Install complete","percentage":100}';
        const clipboardChannel = SystemChannels.platform;
        MethodCall? clipboardCall;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          clipboardChannel,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboardCall = call;
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            clipboardChannel,
            null,
          );
        });

        final installQueue = TestInstallQueue(
          initialState: InstallQueueState(
            history: [
              InstallTask(
                id: 'wechat-history-1',
                appId: 'com.tencent.wechat',
                appName: '微信',
                kind: InstallTaskKind.install,
                status: InstallStatus.success,
                commandOutput: commandOutput,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                finishedAt: DateTime.now().millisecondsSinceEpoch,
              ),
            ],
          ),
        );

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

        expect(clipboardCall, isNull);

        await tester.tap(find.text('微信'));
        await tester.pump();

        expect(clipboardCall, isNull);

        await tester.tap(find.text('复制日志'));
        await tester.pump();
        expect(clipboardCall?.method, equals('Clipboard.setData'));
        expect(clipboardCall?.arguments, {'text': commandOutput});
        expect(find.text('复制成功'), findsOneWidget);
        expect(find.text('命令已复制到剪贴板'), findsNothing);

        await tester.pump(const Duration(milliseconds: 1200));

        expect(find.text('复制日志'), findsOneWidget);
        expect(find.text('复制成功'), findsNothing);
      },
    );

    testWidgets('aligns failed status with action buttons', (tester) async {
      const commandOutput =
          'll-cli install --json com.qq.wemeet\n'
          '{"code":-1,"message":"Could not resolve hostname"}';
      final installQueue = TestInstallQueue(
        initialState: InstallQueueState(
          history: [
            InstallTask(
              id: 'wemeet-history-1',
              appId: 'com.qq.wemeet',
              appName: '腾讯会议',
              kind: InstallTaskKind.install,
              status: InstallStatus.failed,
              message: '安装失败',
              errorMessage: '安装失败：Could not resolve hostname',
              commandOutput: commandOutput,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              finishedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          ],
        ),
      );

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

      final statusCenter = tester.getCenter(find.text('失败'));
      final copyCenter = tester.getCenter(find.text('复制日志'));
      final retryCenter = tester.getCenter(find.byIcon(Icons.refresh));

      expect((statusCenter.dy - copyCenter.dy).abs(), lessThanOrEqualTo(2.0));
      expect((statusCenter.dy - retryCenter.dy).abs(), lessThanOrEqualTo(2.0));
    });
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
