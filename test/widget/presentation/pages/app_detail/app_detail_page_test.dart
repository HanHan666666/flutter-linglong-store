import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/app_detail_provider.dart';
import 'package:linglong_store/application/providers/app_uninstall_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
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
            matching: find.byType(ElevatedButton),
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

    testWidgets('downgrade confirmation enqueues historical install with force', (
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

      await tester.tap(find.byKey(const Key('app-detail-version-install-1.0.0')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(ElevatedButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(installQueue.lastAppId, 'org.example.demo');
      expect(installQueue.lastVersion, '1.0.0');
      expect(installQueue.lastForce, isTrue);
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
}) {
  final effectiveInstallQueue =
      installQueue ?? _StaticInstallQueue(installQueueState);

  return ProviderScope(
    overrides: [
      appDetailProvider(
        appId,
      ).overrideWith(() => _StaticAppDetail(detailState)),
      installedAppsProvider.overrideWith(
        () => _StaticInstalledApps(apps: installedApps),
      ),
      installQueueProvider.overrideWith(
        () => effectiveInstallQueue,
      ),
      appUninstallServiceProvider.overrideWithValue(uninstallService),
    ],
    child: MaterialApp(
      locale: const Locale('zh'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AppDetailPage(appId: appId)),
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

class _StaticInstallQueue extends InstallQueue {
  _StaticInstallQueue([this.initialState = const InstallQueueState()]);

  final InstallQueueState initialState;

  @override
  InstallQueueState build() => initialState;
}

class _RecordingInstallQueue extends InstallQueue {
  String? lastAppId;
  String? lastAppName;
  String? lastIcon;
  String? lastVersion;
  bool? lastForce;

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
    lastAppId = appId;
    lastAppName = appName;
    lastIcon = icon;
    lastVersion = version;
    lastForce = force;
    return 'recorded-task';
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
