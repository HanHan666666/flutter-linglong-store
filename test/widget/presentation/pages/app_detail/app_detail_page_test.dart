import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/models/uninstall_result.dart';
import 'package:linglong_store/presentation/pages/app_detail/app_detail_page.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('AppDetailPage version actions', () {
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
  });
}

Widget _buildTestApp({
  required String appId,
  required AppDetailState detailState,
  required List<InstalledApp> installedApps,
  required _RecordingUninstallService uninstallService,
}) {
  return ProviderScope(
    overrides: [
      appDetailProvider(
        appId,
      ).overrideWith(() => _StaticAppDetail(detailState)),
      installedAppsProvider.overrideWith(
        () => _StaticInstalledApps(apps: installedApps),
      ),
      installQueueProvider.overrideWith(() => _StaticInstallQueue()),
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
    ),
    appDetail: const dm.AppDetail(
      appId: 'org.example.demo',
      name: 'Demo',
      version: '2.0.0',
      description: 'Demo description',
      arch: 'x86_64',
      channel: 'main',
      module: 'main',
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
  @override
  InstallQueueState build() => const InstallQueueState();
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
