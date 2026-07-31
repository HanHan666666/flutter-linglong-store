import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_self_update_provider.dart';
import 'package:linglong_store/application/services/app_self_update_service.dart';
import 'package:linglong_store/application/services/version_check_service.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/app_self_update.dart';
import 'package:linglong_store/domain/repositories/app_self_update_gateways.dart';
import 'package:linglong_store/presentation/widgets/app_update_flow.dart';

/// 只为构造测试服务提供的未调用探测端口。
class _UnusedProbe implements AppInstallationProbe {
  @override
  Future<AppInstallation> detect() => throw UnimplementedError();
}

/// 只为构造测试服务提供的未调用工作区端口。
class _UnusedWorkspaceFactory implements AppUpdateWorkspaceFactory {
  @override
  Future<AppUpdateWorkspace> create() => throw UnimplementedError();
}

/// 可控自更新用例替身，不执行真实下载和安装。
class _FakeSelfUpdateService extends AppSelfUpdateService {
  _FakeSelfUpdateService({this.failWith})
    : super(
        probe: _UnusedProbe(),
        workspaceFactory: _UnusedWorkspaceFactory(),
        installers: const <AppUpdateInstaller>[],
        currentArch: () => 'amd64',
      );

  final Object? failWith;
  int callCount = 0;

  @override
  Future<void> performUpdate({
    required VersionCheckResultUpdateAvailable update,
    required AppSelfUpdateCancellation cancellation,
    required void Function(AppSelfUpdateProgress progress) onProgress,
  }) async {
    callCount++;
    onProgress(
      const AppSelfUpdateProgress(
        AppSelfUpdatePhase.downloading,
        progress: 0.3,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final error = failWith;
    if (error != null) {
      throw error;
    }
    onProgress(
      const AppSelfUpdateProgress(AppSelfUpdatePhase.done, progress: 1),
    );
  }
}

void main() {
  setUpAll(AppLogger.init);

  const update = VersionCheckResultUpdateAvailable(
    currentVersion: '3.5.0',
    latestVersion: 'v3.5.1',
    releasePageUrl: 'https://example.com/releases/v3.5.1',
  );

  /// 打开由应用级 Controller 驱动的流程弹窗。
  Future<void> openDialog(
    WidgetTester tester,
    _FakeSelfUpdateService service,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSelfUpdateServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    unawaited(
                      ref
                          .read(appSelfUpdateControllerProvider.notifier)
                          .start(update),
                    );
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const AppUpdateFlowDialog(),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('安装完成后提示用户手动关闭并重新打开', (tester) async {
    await openDialog(tester, _FakeSelfUpdateService());

    expect(find.text('更新已安装，请关闭应用后重新打开以使用新版本'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);
  });

  testWidgets('校验失败时展示稳定错误并允许重试', (tester) async {
    final service = _FakeSelfUpdateService(
      failWith: const AppSelfUpdateUnsupportedException(
        AppSelfUpdateUnsupportedReason.checksumMismatch,
      ),
    );
    await openDialog(tester, service);

    expect(find.text('更新包校验失败，已中止安装'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(service.callCount, 2);
  });
}
