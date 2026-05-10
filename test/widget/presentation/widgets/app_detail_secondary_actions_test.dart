import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/presentation/widgets/app_detail_secondary_actions.dart';

void main() {
  AppLocalizations l10nFor(WidgetTester tester) {
    return AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
  }

  Future<void> pumpSecondaryActions(
    WidgetTester tester, {
    required bool isVisible,
    VoidCallback? onCreateShortcut,
    VoidCallback? onUninstall,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AppDetailSecondaryActions(
            isVisible: isVisible,
            onCreateShortcut: onCreateShortcut ?? () {},
            onUninstall: onUninstall ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('未安装时隐藏次级操作', (tester) async {
    await pumpSecondaryActions(tester, isVisible: false);
    final l10n = l10nFor(tester);

    expect(find.text(l10n.createDesktopShortcut), findsNothing);
    expect(find.text(l10n.uninstall), findsNothing);
  });

  testWidgets('已安装时展示并响应次级操作', (tester) async {
    var shortcutTapped = false;
    var uninstallTapped = false;

    await pumpSecondaryActions(
      tester,
      isVisible: true,
      onCreateShortcut: () => shortcutTapped = true,
      onUninstall: () => uninstallTapped = true,
    );
    final l10n = l10nFor(tester);

    expect(find.text(l10n.createDesktopShortcut), findsOneWidget);
    expect(find.text(l10n.uninstall), findsOneWidget);

    await tester.tap(find.text(l10n.createDesktopShortcut));
    await tester.pump();
    await tester.tap(find.text(l10n.uninstall));
    await tester.pump();

    expect(shortcutTapped, isTrue);
    expect(uninstallTapped, isTrue);
  });

  testWidgets('卸载按钮沿用描边按钮并覆盖危险态交互反馈', (tester) async {
    await pumpSecondaryActions(tester, isVisible: true);
    final l10n = l10nFor(tester);

    expect(find.byType(OutlinedButton), findsNWidgets(2));

    final uninstallButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, l10n.uninstall),
    );

    expect(
      uninstallButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppTheme.lightTheme.colorScheme.error,
    );
    expect(
      uninstallButton.style?.side?.resolve(<WidgetState>{})?.color,
      AppTheme.lightTheme.colorScheme.error,
    );
    expect(
      uninstallButton.style?.backgroundColor?.resolve(<WidgetState>{
        WidgetState.hovered,
      }),
      AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.08),
    );
  });
}
