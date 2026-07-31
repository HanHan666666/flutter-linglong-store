import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_self_update_provider.dart';
import 'package:linglong_store/application/services/app_installation_probe.dart';
import 'package:linglong_store/application/services/app_self_update_service.dart';
import 'package:linglong_store/application/services/version_check_service.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/platform/file_downloader.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/presentation/widgets/app_update_flow.dart';

/// 可控自更新服务替身：按预设触发进度回调，不执行真实下载/安装。
class _FakeSelfUpdateService extends AppSelfUpdateService {
  _FakeSelfUpdateService({this.failWith})
    : super(
        probe: AppInstallationProbe(),
        downloader: FileDownloader(),
        shellExecutor: ShellCommandExecutor(),
        currentArch: () => 'x86_64',
        restartApp: (_) async {},
        closeApp: () async {},
      );

  final AppSelfUpdateUnsupportedException? failWith;
  int callCount = 0;

  @override
  Future<bool> performUpdate({
    required VersionCheckResultUpdateAvailable update,
    required void Function(AppSelfUpdateProgress progress) onProgress,
  }) async {
    callCount++;
    onProgress(
      const AppSelfUpdateProgress(
        AppSelfUpdatePhase.downloading,
        progress: 0.3,
      ),
    );
    onProgress(
      const AppSelfUpdateProgress(AppSelfUpdatePhase.verifying, progress: 0.8),
    );
    final error = failWith;
    if (error != null) {
      onProgress(
        AppSelfUpdateProgress(
          AppSelfUpdatePhase.failed,
          progress: 0,
          error: error,
        ),
      );
      throw error;
    }
    onProgress(const AppSelfUpdateProgress(AppSelfUpdatePhase.done, progress: 1));
    return true;
  }
}

void main() {
  const update = VersionCheckResultUpdateAvailable(
    currentVersion: '3.5.0',
    latestVersion: 'v3.5.1',
    releasePageUrl: 'https://example.com/releases/v3.5.1',
  );

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
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const AppUpdateFlowDialog(update: update),
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

  testWidgets('shows progress phases and completes', (tester) async {
    await openDialog(tester, _FakeSelfUpdateService());

    // 完成阶段文案。
    expect(find.text('更新完成'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // 成功后不提供重试/取消按钮。
    expect(find.text('重试'), findsNothing);
  });

  testWidgets('shows error and retry on failure', (tester) async {
    final service = _FakeSelfUpdateService(
      failWith: const AppSelfUpdateUnsupportedException(
        AppSelfUpdateUnsupportedReason.checksumMismatch,
      ),
    );
    await openDialog(tester, service);

    expect(find.text('更新包校验失败，已中止安装'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
  });

  testWidgets('retry re-runs the update flow', (tester) async {
    final service = _FakeSelfUpdateService(
      failWith: const AppSelfUpdateUnsupportedException(
        AppSelfUpdateUnsupportedReason.checksumMismatch,
      ),
    );
    await openDialog(tester, service);
    expect(service.callCount, 1);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(service.callCount, 2);
  });
}
