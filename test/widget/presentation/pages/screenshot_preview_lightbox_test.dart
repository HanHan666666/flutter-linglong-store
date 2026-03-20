import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/presentation/pages/app_detail/screenshot_preview_lightbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenshotPreviewLightbox', () {
    testWidgets('shows localized title and current index', (tester) async {
      await _pumpHost(tester, themeMode: ThemeMode.light, locale: const Locale('en'));

      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      expect(find.text('Screenshots'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('uses theme-adaptive surfaces in light mode', (tester) async {
      await _pumpHost(tester, themeMode: ThemeMode.light);

      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      final titleBar = tester.widget<Container>(
        find.byKey(const Key('screenshotPreviewTitleBar')),
      );
      final thumbnailBar = tester.widget<Container>(
        find.byKey(const Key('screenshotPreviewThumbnailBar')),
      );

      final titleBarDecoration = titleBar.decoration as BoxDecoration;
      final thumbnailBarDecoration = thumbnailBar.decoration as BoxDecoration;

      expect(titleBarDecoration.color, isNot(const Color(0xFF15151F)));
      expect(thumbnailBarDecoration.color, isNot(const Color(0xFF15151F)));
    });

    testWidgets('close button dismisses only the dialog', (tester) async {
      await _pumpHost(
        tester,
        themeMode: ThemeMode.dark,
        locale: const Locale('en'),
      );

      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();
      expect(find.byType(ScreenshotPreviewLightbox), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(ScreenshotPreviewLightbox), findsNothing);
      expect(find.text('Host Page'), findsOneWidget);
    });

    testWidgets('next arrow updates screenshot index', (tester) async {
      await _pumpHost(tester, themeMode: ThemeMode.dark, initialIndex: 0);

      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Next screenshot'));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('hides thumbnail rail for a single screenshot', (tester) async {
      await _pumpHost(
        tester,
        themeMode: ThemeMode.dark,
        screenshots: const ['https://example.com/only.png'],
      );

      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('screenshotPreviewThumbnailBar')), findsNothing);
    });
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required ThemeMode themeMode,
  Locale locale = const Locale('zh'),
  List<String> screenshots = const [
    'https://example.com/1.png',
    'https://example.com/2.png',
  ],
  int initialIndex = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Column(
              children: [
                const Text('Host Page'),
                TextButton(
                  onPressed: () {
                    showScreenshotPreviewLightbox(
                      context,
                      screenshots: screenshots,
                      initialIndex: initialIndex,
                    );
                  },
                  child: const Text('Open Preview'),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
