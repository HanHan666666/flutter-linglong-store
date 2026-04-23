import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/app_uninstall_service.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/models/uninstall_result.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('AppUninstallService', () {
    test('getActiveBlockingTask returns null when no active task', () {
      final service = AppUninstallService(
        readRunningApps: () => const [],
        killRunningApp: (_) async => true,
        uninstallApp: (appId, version) async => 'ok',
        removeInstalledApp: (appId, version) {},
        syncAfterUninstall: () async {},
        reportUninstall: (appId, version, {appName}) async {},
        readActiveInstallTask: () => null,
      );

      expect(service.getActiveBlockingTask(), isNull);
    });

    test('getActiveBlockingTask returns task info when active', () {
      final service = AppUninstallService(
        readRunningApps: () => const [],
        killRunningApp: (_) async => true,
        uninstallApp: (appId, version) async => 'ok',
        removeInstalledApp: (appId, version) {},
        syncAfterUninstall: () async {},
        reportUninstall: (appId, version, {appName}) async {},
        readActiveInstallTask: () => ('My App', 'org.active.app'),
      );

      final result = service.getActiveBlockingTask();
      expect(result, isNotNull);
      expect(result!.$1, 'My App');
      expect(result.$2, 'org.active.app');
    });

    test('getRunningInstances returns matching apps', () {
      final runningApps = [
        const RunningApp(
          id: '1',
          appId: 'org.foo',
          name: 'Foo',
          version: '1.0.0',
          arch: 'x86_64',
          channel: 'main',
          source: 'linglong',
          pid: 1234,
          containerId: 'c1',
        ),
        const RunningApp(
          id: '2',
          appId: 'org.bar',
          name: 'Bar',
          version: '1.0.0',
          arch: 'x86_64',
          channel: 'main',
          source: 'linglong',
          pid: 5678,
          containerId: 'c2',
        ),
        const RunningApp(
          id: '3',
          appId: 'org.foo',
          name: 'Foo',
          version: '1.0.0',
          arch: 'x86_64',
          channel: 'main',
          source: 'linglong',
          pid: 9999,
          containerId: 'c3',
        ),
      ];

      final service = AppUninstallService(
        readRunningApps: () => runningApps,
        killRunningApp: (_) async => true,
        uninstallApp: (appId, version) async => 'ok',
        removeInstalledApp: (appId, version) {},
        syncAfterUninstall: () async {},
        reportUninstall: (appId, version, {appName}) async {},
      );

      final instances = service.getRunningInstances('org.foo');
      expect(instances.length, 2);
      expect(instances.every((a) => a.appId == 'org.foo'), isTrue);
    });

    test('executeUninstall returns success on normal flow', () async {
      final events = <String>[];

      final service = AppUninstallService(
        readRunningApps: () => const [],
        killRunningApp: (_) async => true,
        uninstallApp: (appId, version) async {
          events.add('uninstall:$appId@$version');
          return 'ok';
        },
        removeInstalledApp: (appId, version) {
          events.add('remove:$appId@$version');
        },
        syncAfterUninstall: () async {
          events.add('sync');
        },
        reportUninstall: (appId, version, {appName}) async {
          events.add('report:$appId@$version:$appName');
        },
      );

      final app = const InstalledApp(
        appId: 'org.example.demo',
        name: 'Demo',
        version: '1.0.0',
      );

      final result = await service.executeUninstall(app);

      expect(result, isA<UninstallResultSuccess>());
      expect(events, [
        'uninstall:org.example.demo@1.0.0',
        'remove:org.example.demo@1.0.0',
        'sync',
        'report:org.example.demo@1.0.0:Demo',
      ]);
    });

    test('executeUninstall kills running instances first', () async {
      final events = <String>[];

      final service = AppUninstallService(
        readRunningApps: () => [
          const RunningApp(
            id: '1',
            appId: 'org.example.demo',
            name: 'Demo',
            version: '1.0.0',
            arch: 'x86_64',
            channel: 'main',
            source: 'linglong',
            pid: 1234,
            containerId: 'c1',
          ),
        ],
        killRunningApp: (app) async {
          events.add('kill:${app.appId}');
          return true;
        },
        uninstallApp: (appId, version) async {
          events.add('uninstall:$appId@$version');
          return 'ok';
        },
        removeInstalledApp: (appId, version) {
          events.add('remove:$appId@$version');
        },
        syncAfterUninstall: () async {
          events.add('sync');
        },
        reportUninstall: (appId, version, {appName}) async {},
      );

      final app = const InstalledApp(
        appId: 'org.example.demo',
        name: 'Demo',
        version: '1.0.0',
      );

      final result = await service.executeUninstall(app);

      expect(result, isA<UninstallResultSuccess>());
      expect(events, [
        'kill:org.example.demo',
        'uninstall:org.example.demo@1.0.0',
        'remove:org.example.demo@1.0.0',
        'sync',
      ]);
    });

    test('executeUninstall returns kill failure result', () async {
      final service = AppUninstallService(
        readRunningApps: () => [
          const RunningApp(
            id: '1',
            appId: 'org.example.demo',
            name: 'Demo',
            version: '1.0.0',
            arch: 'x86_64',
            channel: 'main',
            source: 'linglong',
            pid: 1234,
            containerId: 'c1',
          ),
        ],
        killRunningApp: (_) async => false,
        uninstallApp: (appId, version) async => 'ok',
        removeInstalledApp: (appId, version) {},
        syncAfterUninstall: () async {},
        reportUninstall: (appId, version, {appName}) async {},
      );

      final app = const InstalledApp(
        appId: 'org.example.demo',
        name: 'Demo',
        version: '1.0.0',
      );

      final result = await service.executeUninstall(app);

      expect(result, isA<UninstallResultKillFailed>());
      expect((result as UninstallResultKillFailed).appId, 'org.example.demo');
    });

    test(
      'executeUninstall returns error result on uninstall failure',
      () async {
        final service = AppUninstallService(
          readRunningApps: () => const [],
          killRunningApp: (_) async => true,
          uninstallApp: (appId, version) async {
            throw Exception('uninstall failed');
          },
          removeInstalledApp: (appId, version) {},
          syncAfterUninstall: () async {},
          reportUninstall: (appId, version, {appName}) async {},
        );

        final app = const InstalledApp(
          appId: 'org.example.demo',
          name: 'Demo',
          version: '1.0.0',
        );

        final result = await service.executeUninstall(app);

        expect(result, isA<UninstallResultError>());
        expect(
          (result as UninstallResultError).message,
          contains('uninstall failed'),
        );
      },
    );
  });
}
