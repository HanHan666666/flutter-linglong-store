import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/app_detail_provider.dart';
import 'package:linglong_store/application/providers/app_uninstall_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/application/services/app_uninstall_service.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/app_detail.dart' as dm;
import 'package:linglong_store/domain/models/app_version.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/models/uninstall_result.dart';
import 'package:linglong_store/presentation/pages/app_detail/app_detail_page.dart';
import 'package:linglong_store/presentation/widgets/install_to_download_flyout.dart';

Finder _filledButtonWithText(String text) {
  return find.ancestor(
    of: find.text(text),
    matching: find.byWidgetPredicate((widget) => widget is FilledButton),
  );
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('AppDetailPage version actions', () {
    testWidgets('runtime info row exposes copy action', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const clipboardChannel = SystemChannels.platform;
      MethodCall? clipboardCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(clipboardChannel, (call) async {
            clipboardCall = call;
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(clipboardChannel, null);
      });

      await tester.pumpWidget(
        _buildTestApp(
          appId: 'org.example.demo',
          uninstallService: _RecordingUninstallService(),
          detailState: _detailState(versions: const []),
          installedApps: const [],
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      final runtimeCard = find.byKey(const ValueKey('app-detail-info-运行时'));
      final runtimeCopyButton = find.descendant(
        of: runtimeCard,
        matching: find.byIcon(Icons.copy_outlined),
      );

      expect(runtimeCopyButton, findsOneWidget);

      await tester.tap(runtimeCopyButton);
      await tester.pump();

      expect(clipboardCall?.method, equals('Clipboard.setData'));
      expect(
        clipboardCall?.arguments,
        equals(<String, dynamic>{
          'text': 'main:org.deepin.runtime.webengine/25.2.1/x86_64',
        }),
      );
    });

    testWidgets('failed install message wraps fully and copies full detail', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(760, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const displayedMessage =
          'Error executing command as another user: Request denied because authentication dialog was dismissed before the command could continue.';
      const fullErrorDetail =
          'Error executing command as another user: Request denied because authentication dialog was dismissed before the command could continue. pkexec exited with code 126.';

      const clipboardChannel = SystemChannels.platform;
      MethodCall? clipboardCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(clipboardChannel, (call) async {
            clipboardCall = call;
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(clipboardChannel, null);
      });

      await tester.pumpWidget(
        _buildTestApp(
          appId: 'org.example.demo',
          uninstallService: _RecordingUninstallService(),
          detailState: _detailState(versions: const []),
          installedApps: const [],
          installQueueState: InstallQueueState(
            history: [
              InstallTask(
                id: 'failed-task',
                appId: 'org.example.demo',
                appName: 'Demo',
                version: '2.0.0',
                status: InstallStatus.failed,
                message: displayedMessage,
                errorMessage: displayedMessage,
                errorDetail: fullErrorDetail,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                finishedAt: DateTime.now().millisecondsSinceEpoch,
              ),
            ],
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      final errorText = find.text(displayedMessage);
      final copyButton = find.byTooltip('复制错误信息');
      final errorTextWidget = tester.widget<Text>(errorText);

      expect(errorText, findsOneWidget);
      expect(copyButton, findsOneWidget);
      expect(errorTextWidget.maxLines, isNull);
      expect(
        tester.getTopLeft(copyButton).dy,
        greaterThan(tester.getBottomLeft(errorText).dy),
      );

      await tester.tap(copyButton);
      await tester.pump();

      expect(clipboardCall?.method, equals('Clipboard.setData'));
      expect(
        clipboardCall?.arguments,
        equals(<String, dynamic>{'text': fullErrorDetail}),
      );
    });

    testWidgets('non-failed install message keeps copying displayed message', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(760, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const displayedMessage = '准备安装...';
      const rawMessage = '{"message":"raw install message"}';

      const clipboardChannel = SystemChannels.platform;
      MethodCall? clipboardCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(clipboardChannel, (call) async {
            clipboardCall = call;
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(clipboardChannel, null);
      });

      await tester.pumpWidget(
        _buildTestApp(
          appId: 'org.example.demo',
          uninstallService: _RecordingUninstallService(),
          detailState: _detailState(versions: const []),
          installedApps: const [],
          installQueueState: InstallQueueState(
            currentTask: InstallTask(
              id: 'active-task',
              appId: 'org.example.demo',
              appName: 'Demo',
              version: '2.0.0',
              status: InstallStatus.installing,
              message: displayedMessage,
              rawMessage: rawMessage,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
            isProcessing: true,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      final statusRow = find.ancestor(
        of: find.text(displayedMessage),
        matching: find.byType(Row),
      );
      final copyButton = find.descendant(
        of: statusRow.first,
        matching: find.widgetWithText(TextButton, '复制'),
      );
      final neutralTooltip = find.descendant(
        of: statusRow.first,
        matching: find.byTooltip('复制'),
      );
      final errorTooltip = find.descendant(
        of: statusRow.first,
        matching: find.byTooltip('复制错误信息'),
      );

      expect(neutralTooltip, findsOneWidget);
      expect(errorTooltip, findsNothing);

      await tester.tap(copyButton);
      await tester.pump();

      expect(clipboardCall?.method, equals('Clipboard.setData'));
      expect(
        clipboardCall?.arguments,
        equals(<String, dynamic>{'text': displayedMessage}),
      );
    });

    testWidgets(
      'restored failed task copies error message when detail is absent',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(760, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const displayedMessage = '任务异常中断';
        const errorMessage = '请重试安装，若仍失败请检查认证授权。';

        const clipboardChannel = SystemChannels.platform;
        MethodCall? clipboardCall;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(clipboardChannel, (call) async {
              clipboardCall = call;
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(clipboardChannel, null);
        });

        await tester.pumpWidget(
          _buildTestApp(
            appId: 'org.example.demo',
            uninstallService: _RecordingUninstallService(),
            detailState: _detailState(versions: const []),
            installedApps: const [],
            installQueueState: InstallQueueState(
              history: [
                InstallTask(
                  id: 'restored-failed-task',
                  appId: 'org.example.demo',
                  appName: 'Demo',
                  version: '2.0.0',
                  status: InstallStatus.failed,
                  message: displayedMessage,
                  errorMessage: errorMessage,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  finishedAt: DateTime.now().millisecondsSinceEpoch,
                ),
              ],
            ),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('复制错误信息'));
        await tester.pump();

        expect(clipboardCall?.method, equals('Clipboard.setData'));
        expect(
          clipboardCall?.arguments,
          equals(<String, dynamic>{'text': errorMessage}),
        );
      },
    );

    testWidgets(
      'failed install message copies raw message when it is the only detail',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(760, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const displayedMessage = '安装失败';
        const rawMessage =
            '{"message":"polkit denied request","stdout":"","stderr":"Request dismissed by user"}';

        const clipboardChannel = SystemChannels.platform;
        MethodCall? clipboardCall;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(clipboardChannel, (call) async {
              clipboardCall = call;
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(clipboardChannel, null);
        });

        await tester.pumpWidget(
          _buildTestApp(
            appId: 'org.example.demo',
            uninstallService: _RecordingUninstallService(),
            detailState: _detailState(versions: const []),
            installedApps: const [],
            installQueueState: InstallQueueState(
              history: [
                InstallTask(
                  id: 'raw-failed-task',
                  appId: 'org.example.demo',
                  appName: 'Demo',
                  version: '2.0.0',
                  status: InstallStatus.failed,
                  message: displayedMessage,
                  rawMessage: rawMessage,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  finishedAt: DateTime.now().millisecondsSinceEpoch,
                ),
              ],
            ),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('复制错误信息'));
        await tester.pump();

        expect(clipboardCall?.method, equals('Clipboard.setData'));
        expect(
          clipboardCall?.arguments,
          equals(<String, dynamic>{'text': rawMessage}),
        );
      },
    );

    testWidgets(
      'renders installed badge and uninstall for installed versions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final uninstallService = _RecordingUninstallService();

        await tester.pumpWidget(
          _buildTestApp(
            appId: 'org.example.demo',
            uninstallService: uninstallService,
            detailState: _detailState(
              versions: const [
                AppVersion(
                  versionNo: '2.0.0',
                  releaseTime: '2026-04-19',
                  packageSize: '1048576',
                ),
                AppVersion(
                  versionNo: '1.0.0',
                  releaseTime: '2026-04-18',
                  packageSize: '524288',
                ),
              ],
            ),
            installedApps: const [
              InstalledApp(
                appId: 'org.example.demo',
                name: 'Demo',
                version: '1.0.0',
                arch: 'x86_64',
                channel: 'main',
                module: 'main',
              ),
            ],
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('app-detail-version-install-2.0.0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('app-detail-version-installed-badge-1.0.0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('app-detail-version-uninstall-1.0.0')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'version uninstall resolves the best matching installed instance',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final uninstallService = _RecordingUninstallService();

        await tester.pumpWidget(
          _buildTestApp(
            appId: 'org.example.demo',
            uninstallService: uninstallService,
            detailState: _detailState(
              versions: const [
                AppVersion(
                  versionNo: '1.0.0',
                  releaseTime: '2026-04-18',
                  packageSize: '524288',
                ),
              ],
            ),
            installedApps: const [
              InstalledApp(
                appId: 'org.example.demo',
                name: 'Demo',
                version: '1.0.0',
                arch: 'arm64',
                channel: 'beta',
                module: 'runtime',
              ),
              InstalledApp(
                appId: 'org.example.demo',
                name: 'Demo',
                version: '1.0.0',
                arch: 'x86_64',
                channel: 'main',
                module: 'main',
              ),
            ],
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('app-detail-version-uninstall-1.0.0')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(uninstallService.executedApps, hasLength(1));
        expect(uninstallService.executedApps.single.version, '1.0.0');
        expect(uninstallService.executedApps.single.arch, 'x86_64');
        expect(uninstallService.executedApps.single.channel, 'main');
        expect(uninstallService.executedApps.single.module, 'main');
      },
    );

    testWidgets('matching version row shows installing progress state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          appId: 'org.example.demo',
          uninstallService: _RecordingUninstallService(),
          detailState: _detailState(
            versions: const [
              AppVersion(
                versionNo: '2.0.0',
                releaseTime: '2026-04-19',
                packageSize: '1048576',
              ),
              AppVersion(
                versionNo: '1.0.0',
                releaseTime: '2026-04-18',
                packageSize: '524288',
              ),
            ],
          ),
          installedApps: const [],
          installQueueState: InstallQueueState(
            currentTask: InstallTask(
              id: 'task-1',
              appId: 'org.example.demo',
              appName: 'Demo',
              version: '1.0.0',
              status: InstallStatus.installing,
              progress: 0.42,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
            isProcessing: true,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      final versionRow = find.byKey(const Key('app-detail-version-row-1.0.0'));
      expect(versionRow, findsOneWidget);
      expect(
        find.descendant(of: versionRow, matching: find.text('42%')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: versionRow,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: versionRow,
          matching: find.byKey(const Key('app-detail-version-install-1.0.0')),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'downgrade confirmation enqueues historical install with force',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final installQueue = _RecordingInstallQueue();

        await tester.pumpWidget(
          _buildTestApp(
            appId: 'org.example.demo',
            uninstallService: _RecordingUninstallService(),
            detailState: _detailState(
              versions: const [
                AppVersion(
                  versionNo: '2.0.0',
                  releaseTime: '2026-04-19',
                  packageSize: '1048576',
                ),
                AppVersion(
                  versionNo: '1.0.0',
                  releaseTime: '2026-04-18',
                  packageSize: '524288',
                ),
              ],
            ),
            installedApps: const [
              InstalledApp(
                appId: 'org.example.demo',
                name: 'Demo',
                version: '2.0.0',
                arch: 'x86_64',
                channel: 'main',
                module: 'main',
              ),
            ],
            installQueue: installQueue,
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('app-detail-version-install-1.0.0')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(installQueue.lastAppId, 'org.example.demo');
        expect(installQueue.lastVersion, '1.0.0');
        expect(installQueue.lastForce, isTrue);
      },
    );

    testWidgets('main install action launches download flyout on success', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final installQueue = _RecordingInstallQueue();

      await tester.pumpWidget(
        _buildTestApp(
          appId: 'org.example.demo',
          uninstallService: _RecordingUninstallService(),
          detailState: _detailState(versions: const []),
          installedApps: const [],
          installQueue: installQueue,
          withFlyoutLayer: true,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(_filledButtonWithText('安 装'));
      await tester.pump();

      expect(installQueue.lastAppId, 'org.example.demo');
      expect(find.byKey(const Key('install-download-flyout')), findsOneWidget);
    });

    testWidgets('main install action skips flyout when enqueue fails', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final installQueue = _RecordingInstallQueue(nextTaskId: '');

      await tester.pumpWidget(
        _buildTestApp(
          appId: 'org.example.demo',
          uninstallService: _RecordingUninstallService(),
          detailState: _detailState(versions: const []),
          installedApps: const [],
          installQueue: installQueue,
          withFlyoutLayer: true,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(_filledButtonWithText('安 装'));
      await tester.pump();

      expect(installQueue.lastAppId, 'org.example.demo');
      expect(find.byKey(const Key('install-download-flyout')), findsNothing);
      expect(
        find.byKey(const Key('install-download-target-pulse')),
        findsNothing,
      );
    });

    testWidgets('main update action launches download flyout on success', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final installQueue = _RecordingInstallQueue();
      const installedApp = InstalledApp(
        appId: 'org.example.demo',
        name: 'Demo',
        version: '1.0.0',
        arch: 'x86_64',
        channel: 'main',
        module: 'main',
      );

      await tester.pumpWidget(
        _buildTestApp(
          appId: 'org.example.demo',
          uninstallService: _RecordingUninstallService(),
          detailState: _detailState(versions: const []),
          installedApps: const [installedApp],
          updateAppsState: const UpdateAppsState(
            apps: [
              UpdatableApp(installedApp: installedApp, latestVersion: '2.0.0'),
            ],
          ),
          installQueue: installQueue,
          withFlyoutLayer: true,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(_filledButtonWithText('更 新'), findsOneWidget);

      await tester.tap(_filledButtonWithText('更 新'));
      await tester.pump();

      expect(installQueue.lastKind, InstallTaskKind.update);
      expect(installQueue.lastAppId, 'org.example.demo');
      expect(installQueue.lastVersion, isNull);
      expect(find.byKey(const Key('install-download-flyout')), findsOneWidget);
    });

    testWidgets('version install action launches download flyout on success', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final installQueue = _RecordingInstallQueue();

      await tester.pumpWidget(
        _buildTestApp(
          appId: 'org.example.demo',
          uninstallService: _RecordingUninstallService(),
          detailState: _detailState(
            versions: const [
              AppVersion(
                versionNo: '1.0.0',
                releaseTime: '2026-04-18',
                packageSize: '524288',
              ),
            ],
          ),
          installedApps: const [],
          installQueue: installQueue,
          withFlyoutLayer: true,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('app-detail-version-install-1.0.0')),
      );
      await tester.pump();

      expect(installQueue.lastVersion, '1.0.0');
      expect(find.byKey(const Key('install-download-flyout')), findsOneWidget);
    });
  });
}

Widget _buildTestApp({
  required String appId,
  required AppDetailState detailState,
  required List<InstalledApp> installedApps,
  required _RecordingUninstallService uninstallService,
  InstallQueueState installQueueState = const InstallQueueState(),
  InstallQueue? installQueue,
  UpdateAppsState updateAppsState = const UpdateAppsState(),
  bool withFlyoutLayer = false,
}) {
  final effectiveInstallQueue =
      installQueue ?? _StaticInstallQueue(installQueueState);
  Widget home = AppDetailPage(appId: appId);

  if (withFlyoutLayer) {
    home = InstallToDownloadFlyoutLayer(
      child: Stack(
        children: [
          Positioned.fill(child: home),
          const Positioned(
            top: 16,
            right: 16,
            child: DownloadCenterFlyoutTarget(
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ],
      ),
    );
  }

  return ProviderScope(
    overrides: [
      appDetailProvider(
        appId,
      ).overrideWith(() => _StaticAppDetail(detailState)),
      installedAppsProvider.overrideWith(
        () => _StaticInstalledApps(apps: installedApps),
      ),
      updateAppsProvider.overrideWith(() => _StaticUpdateApps(updateAppsState)),
      installQueueProvider.overrideWith(() => effectiveInstallQueue),
      appUninstallServiceProvider.overrideWithValue(uninstallService),
    ],
    child: MaterialApp(
      locale: const Locale('zh'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

AppDetailState _detailState({required List<AppVersion> versions}) {
  return AppDetailState(
    app: const InstalledApp(
      appId: 'org.example.demo',
      name: 'Demo',
      version: '2.0.0',
      description: 'Demo description',
      arch: 'x86_64',
      channel: 'main',
      module: 'main',
      runtime: 'main:org.deepin.runtime.webengine/25.2.1/x86_64',
    ),
    appDetail: const dm.AppDetail(
      appId: 'org.example.demo',
      name: 'Demo',
      version: '2.0.0',
      description: 'Demo description',
      arch: 'x86_64',
      channel: 'main',
      module: 'main',
      runtime: 'main:org.deepin.runtime.webengine/25.2.1/x86_64',
    ),
    versions: versions,
    isVersionListExpanded: true,
  );
}

class _StaticAppDetail extends AppDetail {
  _StaticAppDetail(this.initialState);

  final AppDetailState initialState;

  @override
  AppDetailState build(String appId) => initialState;

  @override
  Future<void> loadDetail(InstalledApp? initialApp) async {}

  @override
  Future<void> retryVersions() async {}

  @override
  Future<void> retryComments() async {}

  @override
  Future<void> submitComment(String remark, {String? version}) async {}
}

class _StaticInstalledApps extends InstalledApps {
  _StaticInstalledApps({required this.apps});

  final List<InstalledApp> apps;

  @override
  InstalledAppsState build() => InstalledAppsState(apps: apps);
}

class _StaticUpdateApps extends UpdateApps {
  _StaticUpdateApps(this.initialState);

  final UpdateAppsState initialState;

  @override
  UpdateAppsState build() => initialState;

  @override
  Future<void> checkUpdates() async {}
}

class _StaticInstallQueue extends InstallQueue {
  _StaticInstallQueue([this.initialState = const InstallQueueState()]);

  final InstallQueueState initialState;

  @override
  InstallQueueState build() => initialState;
}

class _RecordingInstallQueue extends InstallQueue {
  _RecordingInstallQueue({this.nextTaskId = 'recorded-task'});

  String? lastAppId;
  String? lastAppName;
  String? lastIcon;
  InstallTaskKind? lastKind;
  String? lastVersion;
  bool? lastForce;
  final String nextTaskId;

  @override
  InstallQueueState build() => const InstallQueueState();

  @override
  String enqueueInstall({
    required String appId,
    required String appName,
    String? icon,
    String? version,
    bool force = false,
  }) {
    lastKind = InstallTaskKind.install;
    lastAppId = appId;
    lastAppName = appName;
    lastIcon = icon;
    lastVersion = version;
    lastForce = force;
    return nextTaskId;
  }

  @override
  String enqueueOperation({
    required InstallTaskKind kind,
    required String appId,
    required String appName,
    String? icon,
    String? version,
    bool force = false,
  }) {
    lastKind = kind;
    lastAppId = appId;
    lastAppName = appName;
    lastIcon = icon;
    lastVersion = version;
    lastForce = force;
    return nextTaskId;
  }
}

class _RecordingUninstallService extends AppUninstallService {
  _RecordingUninstallService()
    : super(
        readRunningApps: () => const <RunningApp>[],
        killRunningApp: (_) async => true,
        uninstallApp: (_, __) async => '',
        removeInstalledApp: (_, __) {},
        syncAfterUninstall: () async {},
        reportUninstall: (_, __, {String? appName}) async {},
      );

  final List<InstalledApp> executedApps = <InstalledApp>[];

  @override
  Future<UninstallResult> executeUninstall(InstalledApp app) async {
    executedApps.add(app);
    return UninstallResultSuccess();
  }
}
