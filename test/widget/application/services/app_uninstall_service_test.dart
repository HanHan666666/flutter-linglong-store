import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/app_uninstall_service.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/presentation/widgets/uninstall_blocked_dialog.dart';

import '../../../test_utils.dart';

/// 创建一个没有活跃安装任务的卸载服务
AppUninstallService _makeService({
  required List<String> events,
  required Completer<void> uninstallCompleter,
  UninstallConfirmDialog? confirmUninstall,
  UninstallInterceptDialog? interceptDialog,
  OpenDownloadManagerCallback? openDownloadManager,
}) {
  return AppUninstallService(
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
    confirmUninstall:
        confirmUninstall ??
        (_, {appName}) async {
          events.add('confirm:$appName');
          return true;
        },
    interceptDialog: interceptDialog,
    openDownloadManager: openDownloadManager,
  );
}

void main() {
  group('AppUninstallService', () {
    testWidgets('keeps uninstall flow working across async gaps', (
      tester,
    ) async {
      late BuildContext context;
      final events = <String>[];
      final uninstallCompleter = Completer<void>();

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final service = _makeService(
        events: events,
        uninstallCompleter: uninstallCompleter,
      );

      final future = service.uninstall(
        context,
        const InstalledApp(
          appId: 'org.example.demo',
          name: 'Demo',
          version: '1.0.0',
        ),
      );

      await tester.pump();
      uninstallCompleter.complete();

      await expectLater(future, completion(isTrue));
      await tester.pump();

      expect(events, [
        'confirm:Demo',
        'uninstall:org.example.demo@1.0.0:start',
        'uninstall:org.example.demo@1.0.0:end',
        'remove:org.example.demo@1.0.0',
        'sync',
        'report:org.example.demo@1.0.0:Demo',
      ]);
      expect(find.text('Demo 已卸载'), findsOneWidget);
    });

    testWidgets('blocks uninstall when an active install task exists', (
      tester,
    ) async {
      late BuildContext context;
      final events = <String>[];
      bool interceptDialogShown = false;

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final service = AppUninstallService(
        // 注入活跃安装任务读取器（返回非 null 表示有活跃任务）
        readActiveInstallTask: () => ('正在安装中的应用', 'org.active.app'),
        readRunningApps: () => const [],
        killRunningApp: (_) async => true,
        uninstallApp: (appId, version) async {
          events.add('uninstall:$appId');
          return 'ok';
        },
        removeInstalledApp: (appId, version) {
          events.add('remove:$appId');
        },
        syncAfterUninstall: () async {
          events.add('sync');
        },
        reportUninstall: (appId, version, {appName}) async {
          events.add('report:$appId');
        },
        confirmUninstall: (_, {appName}) async {
          events.add('confirm:$appName');
          return true;
        },
        interceptDialog:
            (context, {required activeTaskName, fallbackAppId = ''}) async {
              interceptDialogShown = true;
              events.add('intercept:$activeTaskName');
              return UninstallBlockedAction.acknowledge;
            },
      );

      final result = await service.uninstall(
        context,
        const InstalledApp(
          appId: 'org.example.demo',
          name: 'Demo',
          version: '1.0.0',
        ),
      );

      // 卸载被阻止
      expect(result, isFalse);
      expect(interceptDialogShown, isTrue);
      // 卸载执行器、移除和同步均未被调用
      expect(events, contains('intercept:正在安装中的应用'));
      expect(events, isNot(contains('uninstall:org.example.demo')));
      expect(events, isNot(contains('remove:org.example.demo')));
      expect(events, isNot(contains('sync')));
      expect(events, isNot(contains('confirm:Demo')));
    });

    testWidgets('opens download manager when user chooses 查看下载管理', (
      tester,
    ) async {
      late BuildContext context;
      bool downloadManagerOpened = false;

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final service = AppUninstallService(
        readActiveInstallTask: () => ('活跃应用', 'org.active.app'),
        readRunningApps: () => const [],
        killRunningApp: (_) async => true,
        uninstallApp: (appId, version) async => 'ok',
        removeInstalledApp: (appId, version) {},
        syncAfterUninstall: () async {},
        reportUninstall: (appId, version, {appName}) async {},
        confirmUninstall: (_, {appName}) async => false,
        interceptDialog:
            (context, {required activeTaskName, fallbackAppId = ''}) async {
              return UninstallBlockedAction.openDownloadManager;
            },
        openDownloadManager: (context) {
          downloadManagerOpened = true;
        },
      );

      final result = await service.uninstall(
        context,
        const InstalledApp(
          appId: 'org.example.demo',
          name: 'Demo',
          version: '1.0.0',
        ),
      );

      expect(result, isFalse);
      expect(downloadManagerOpened, isTrue);
    });

    testWidgets(
      'continues normal uninstall flow when there is no active task',
      (tester) async {
        late BuildContext context;
        bool interceptCalled = false;
        final events = <String>[];
        final completer = Completer<void>();

        await tester.pumpWidget(
          createTestApp(
            Builder(
              builder: (buildContext) {
                context = buildContext;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final service = AppUninstallService(
          // 无活跃任务
          readActiveInstallTask: () => null,
          readRunningApps: () => const [],
          killRunningApp: (_) async => true,
          uninstallApp: (appId, version) async {
            events.add('uninstall:$appId');
            completer.complete();
            return 'ok';
          },
          removeInstalledApp: (appId, version) {
            events.add('remove:$appId');
          },
          syncAfterUninstall: () async {
            events.add('sync');
          },
          reportUninstall: (appId, version, {appName}) async {},
          confirmUninstall: (_, {appName}) async {
            events.add('confirm');
            return true;
          },
          interceptDialog:
              (context, {required activeTaskName, fallbackAppId = ''}) async {
                interceptCalled = true;
                return UninstallBlockedAction.acknowledge;
              },
        );

        final future = service.uninstall(
          context,
          const InstalledApp(
            appId: 'org.example.demo',
            name: 'Demo',
            version: '1.0.0',
          ),
        );

        await tester.pump();
        await future;

        // 拦截弹窗未被调用
        expect(interceptCalled, isFalse);
        // 正常卸载流程已执行
        expect(
          events,
          containsAll([
            'confirm',
            'uninstall:org.example.demo',
            'remove:org.example.demo',
            'sync',
          ]),
        );
      },
    );
  });
}
