import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/app_uninstall_service.dart';
import 'package:linglong_store/domain/models/installed_app.dart';

import '../../../test_utils.dart';

void main() {
  group('AppUninstallService', () {
    testWidgets('returns a typed success result without showing a snackbar', (
      tester,
    ) async {
      final events = <String>[];
      final uninstallCompleter = Completer<void>();

      await tester.pumpWidget(createTestApp(const SizedBox.shrink()));

      final service = AppUninstallService(
        readRunningApps: () => const [],
        killRunningApp: (_) async => true,
        uninstallApp: (appId, version) async {
          events.add('uninstall:$appId@$version:start');
          await uninstallCompleter.future;
          events.add('uninstall:$appId@$version:end');
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

      final future = service.uninstall(
        const InstalledApp(
          appId: 'org.example.demo',
          name: 'Demo',
          version: '1.0.0',
        ),
        ({required isRunning, appName}) async {
          events.add('confirm:$appName:$isRunning');
          return true;
        },
      );

      await tester.pump();
      uninstallCompleter.complete();

      await expectLater(
        future,
        completion(
          predicate<AppUninstallResult>(
            (result) => result.type == AppUninstallResultType.success,
          ),
        ),
      );
      await tester.pump();

      expect(events, [
        'confirm:Demo:false',
        'uninstall:org.example.demo@1.0.0:start',
        'uninstall:org.example.demo@1.0.0:end',
        'remove:org.example.demo@1.0.0',
        'sync',
        'report:org.example.demo@1.0.0:Demo',
      ]);
      expect(find.text('Demo 已卸载'), findsNothing);
    });
  });
}
