import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/version_check_service.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/presentation/widgets/update_available_dialog.dart';

void main() {
  const update = VersionCheckResultUpdateAvailable(
    currentVersion: '3.5.0',
    latestVersion: 'v3.5.1',
    releasePageUrl: 'https://example.com/releases/v3.5.1',
  );

  /// 通过真实 showDialog 打开弹窗，保证 Navigator.pop 语义与生产一致。
  Future<void> openDialog(
    WidgetTester tester, {
    required void Function(String url) onOpenUrl,
    required VoidCallback onUpdateNow,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
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
                    builder: (_) => UpdateAvailableDialog(
                      update: update,
                      onOpenUrl: onOpenUrl,
                      onUpdateNow: onUpdateNow,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows new version info and all four actions', (tester) async {
    await openDialog(tester, onOpenUrl: (_) {}, onUpdateNow: () {});

    expect(find.text('检查更新'), findsOneWidget);
    expect(find.text('发现新版本 v3.5.1，当前版本 3.5.0'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Gitee'), findsOneWidget);
    expect(find.text('立即更新'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
  });

  testWidgets('opens GitHub and Gitee links via callback', (tester) async {
    final opened = <String>[];
    await openDialog(tester, onOpenUrl: opened.add, onUpdateNow: () {});

    await tester.tap(find.text('GitHub'));
    await tester.tap(find.text('Gitee'));

    expect(opened, <String>[
      UpdateAvailableDialog.githubReleaseUrl,
      UpdateAvailableDialog.giteeReleaseUrl,
    ]);
  });

  testWidgets('triggers update flow on Update Now', (tester) async {
    var updateNowCalled = false;
    await openDialog(
      tester,
      onOpenUrl: (_) {},
      onUpdateNow: () => updateNowCalled = true,
    );

    await tester.tap(find.text('立即更新'));
    expect(updateNowCalled, isTrue);
  });

  testWidgets('dismisses dialog on Cancel', (tester) async {
    await openDialog(tester, onOpenUrl: (_) {}, onUpdateNow: () {});
    expect(find.byType(UpdateAvailableDialog), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateAvailableDialog), findsNothing);
  });
}
