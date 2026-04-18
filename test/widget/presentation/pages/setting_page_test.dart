import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/presentation/pages/setting/setting_page.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  testWidgets(
    'setting page no longer renders repository configuration section',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingPage()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('仓库配置'), findsNothing);
      expect(find.text('当前仓库源'), findsNothing);
      expect(find.text('可选仓库'), findsNothing);
    },
  );

  testWidgets('setting page about section renders community exchange link', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const Scaffold(body: SettingPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('社区交流'), findsOneWidget);
  });
}
