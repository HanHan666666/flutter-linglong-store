import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/presentation/widgets/install_to_download_flyout.dart';

void main() {
  testWidgets('launches a transient flyout from source to download target', (
    tester,
  ) async {
    final sourceKey = GlobalKey(debugLabel: 'test-install-source');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InstallToDownloadFlyoutLayer(
          child: Scaffold(
            body: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    key: sourceKey,
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(top: 24, right: 24),
                    color: Colors.blue,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: DownloadCenterFlyoutTarget(
                      child: Container(
                        width: 48,
                        height: 48,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    return Center(
                      child: FilledButton(
                        onPressed: () {
                          InstallToDownloadFlyoutLayer.maybeOf(context)?.launch(
                            appId: 'org.example.app',
                            appName: '示例应用',
                            sourceKey: sourceKey,
                          );
                        },
                        child: const Text('install'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('install-download-flyout')), findsNothing);

    await tester.tap(find.text('install'));
    await tester.pump();

    expect(find.byKey(const Key('install-download-flyout')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('install-download-flyout')), findsNothing);
  });

  testWidgets('treats a missing source as a handled fallback pulse', (
    tester,
  ) async {
    final missingSourceKey = GlobalKey(debugLabel: 'missing-install-source');
    var handledFallback = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InstallToDownloadFlyoutLayer(
          child: Scaffold(
            body: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: DownloadCenterFlyoutTarget(
                      child: Container(
                        width: 48,
                        height: 48,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    return Center(
                      child: FilledButton(
                        onPressed: () {
                          handledFallback =
                              InstallToDownloadFlyoutLayer.maybeOf(
                                context,
                              )?.launch(
                                appId: 'org.example.offscreen',
                                appName: '离屏应用',
                                sourceKey: missingSourceKey,
                              ) ??
                              false;
                        },
                        child: const Text('fallback'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('fallback'));
    await tester.pump();

    expect(handledFallback, isTrue);
    expect(find.byKey(const Key('install-download-flyout')), findsNothing);
    expect(
      find.byKey(const Key('install-download-target-pulse')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('install-download-target-pulse')),
      findsNothing,
    );
  });
}
