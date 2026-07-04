import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/presentation/widgets/app_detail_secondary_actions.dart';
import 'package:linglong_store/presentation/widgets/expandable_icon_button.dart';

void main() {
  group('AppDetailSecondaryActions', () {
    testWidgets('isVisible 为 false 时不渲染任何按钮', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppDetailSecondaryActions(
              isVisible: false,
              onCreateShortcut: _noop,
              onUninstall: _noop,
              onShare: _noop,
            ),
          ),
        ),
      );

      expect(find.byType(ExpandableIconButton), findsNothing);
    });

    testWidgets('isVisible 为 true 时渲染三个 ExpandableIconButton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppDetailSecondaryActions(
              isVisible: true,
              onCreateShortcut: _noop,
              onUninstall: _noop,
              onShare: _noop,
            ),
          ),
        ),
      );

      expect(find.byType(ExpandableIconButton), findsNWidgets(3));
      expect(find.byIcon(Icons.shortcut_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });

    testWidgets('点击创建桌面快捷方式按钮触发回调', (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppDetailSecondaryActions(
              isVisible: true,
              onCreateShortcut: () => called = true,
              onUninstall: _noop,
              onShare: _noop,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.shortcut_outlined));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('点击卸载按钮触发回调', (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppDetailSecondaryActions(
              isVisible: true,
              onCreateShortcut: _noop,
              onUninstall: () => called = true,
              onShare: _noop,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('点击分享按钮触发回调', (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppDetailSecondaryActions(
              isVisible: true,
              onCreateShortcut: _noop,
              onUninstall: _noop,
              onShare: () => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('卸载按钮使用错误色图标', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppDetailSecondaryActions(
              isVisible: true,
              onCreateShortcut: _noop,
              onUninstall: _noop,
              onShare: _noop,
            ),
          ),
        ),
      );

      final uninstallButton = find.widgetWithIcon(
        ExpandableIconButton,
        Icons.delete_outline_rounded,
      );
      final iconWidget = tester.widget<Icon>(
        find.descendant(
          of: uninstallButton,
          matching: find.byIcon(Icons.delete_outline_rounded),
        ),
      );

      expect(iconWidget.color, Theme.of(tester.element(uninstallButton)).colorScheme.error);
    });
  });
}

void _noop() {}
