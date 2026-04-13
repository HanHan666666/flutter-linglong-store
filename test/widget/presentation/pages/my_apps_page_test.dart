import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:linglong_store/application/providers/app_uninstall_provider.dart';
import 'package:linglong_store/application/providers/application_card_state_provider.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
import 'package:linglong_store/application/providers/running_process_provider.dart';
import 'package:linglong_store/application/services/app_uninstall_service.dart';
import 'package:linglong_store/core/config/shell_branch_visibility.dart';
import 'package:linglong_store/core/config/shell_primary_route.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/models/uninstall_result.dart';
import 'package:linglong_store/presentation/pages/my_apps/my_apps_page.dart';
import 'package:linglong_store/presentation/widgets/app_card.dart';

void main() {
  group('MyAppsPage app list layout', () {
    testWidgets('keeps vertical spacing between installed app cards', (
      tester,
    ) async {
      final installedApps = _StaticInstalledApps(
        apps: const [
          InstalledApp(
            appId: 'app.one',
            name: 'App One',
            version: '1.0.0',
            description: 'First app',
          ),
          InstalledApp(
            appId: 'app.two',
            name: 'App Two',
            version: '2.0.0',
            description: 'Second app',
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            installedAppsProvider.overrideWith(() => installedApps),
            runningProcessProvider.overrideWith(() => _StaticRunningProcess()),
            applicationCardStateIndexProvider.overrideWithValue(
              const ApplicationCardStateIndex(
                installedVersionByAppId: {
                  'app.one': '1.0.0',
                  'app.two': '2.0.0',
                },
                updateAppIds: {},
                activeTasksByAppId: {},
              ),
            ),
            appUninstallServiceProvider.overrideWithValue(
              _NoopAppUninstallService(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('暂无已安装应用'), findsNothing);

      final cardFinder = find.byType(AppCard);
      expect(cardFinder, findsNWidgets(2));

      final firstRect = tester.getRect(cardFinder.at(0));
      final secondRect = tester.getRect(cardFinder.at(1));
      expect(secondRect.top - firstRect.bottom, AppSpacing.sm);
    });
  });
}

Widget _buildTestApp({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: ShellBranchVisibilityScope(
      activeRoute: ShellPrimaryRoute.myApps,
      currentRoute: ShellPrimaryRoute.myApps,
      child: MaterialApp(
        locale: const Locale('zh'),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: MyAppsPage()),
      ),
    ),
  );
}

class _StaticInstalledApps extends InstalledApps {
  _StaticInstalledApps({required this.apps});

  final List<InstalledApp> apps;

  @override
  InstalledAppsState build() {
    return InstalledAppsState(apps: apps);
  }

  @override
  Future<void> refresh() async {}
}

class _StaticRunningProcess extends RunningProcess {
  @override
  RunningProcessState build() {
    return const RunningProcessState(apps: <RunningApp>[]);
  }
}

class _NoopAppUninstallService extends AppUninstallService {
  _NoopAppUninstallService()
    : super(
        readRunningApps: () => const <RunningApp>[],
        killRunningApp: (_) async => true,
        uninstallApp: (_, __) async => '',
        removeInstalledApp: (_, __) {},
        syncAfterUninstall: () async {},
        reportUninstall: (_, __, {String? appName}) async {},
      );

  @override
  Future<UninstallResult> executeUninstall(InstalledApp app) async {
    return UninstallResultSuccess();
  }
}
