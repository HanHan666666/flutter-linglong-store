import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/services/version_check_service.dart';
import 'package:linglong_store/application/providers/linux_renderer_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/linux_renderer_service.dart';
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

  testWidgets('setting page does not render container auto-update option', (
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

    expect(find.text('容器内自动更新商店本体'), findsNothing);
  });

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

  testWidgets('setting page restores renderer entry and developer links', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final rendererService = LinuxRendererService(
      configFilePathOverride: '/tmp/unused/renderer_preferences.ini',
      dataDirectoryPathOverride: '/tmp/unused',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          linuxRendererServiceProvider.overrideWithValue(rendererService),
          linuxRendererRuntimeProvider.overrideWith(
            (ref) async => const LinuxRendererRuntimeState(
              currentMode: LinuxRendererMode.software,
              decisionSource: LinuxRendererDecisionSource.cpuFallback,
              isCpuWhitelisted: false,
              cpuVendor: 'Loongson',
              cpuModel: '3A6000',
              environmentValue: null,
            ),
          ),
        ],
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

    expect(find.text('软件渲染'), findsOneWidget);
    expect(find.text('Gitee'), findsOneWidget);
    expect(find.text('关于开发者'), findsOneWidget);
  });

  testWidgets('setting page renders typography controls', (tester) async {
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

    expect(find.text('字体设置'), findsOneWidget);
    expect(find.text('字体大小'), findsOneWidget);
    expect(find.text('字体粗细'), findsOneWidget);
    expect(find.text('更细'), findsOneWidget);
    expect(find.text('标准'), findsOneWidget);
    expect(find.text('更粗'), findsOneWidget);
  });

  testWidgets('setting page uses unified filled button for clear cache', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.binding.setSurfaceSize(const Size(1280, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '清除缓存'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '清除缓存'), findsNothing);
  });

  test('setting page uses release result url for update downloads', () {
    const result = VersionCheckResultUpdateAvailable(
      currentVersion: '3.3.1',
      latestVersion: 'v3.3.2',
      releasePageUrl:
          'https://github.com/HanHan666666/flutter-linglong-store/releases/tag/v3.3.2',
    );

    expect(
      resolveSettingPageUpdateDownloadUrl(result),
      'https://github.com/HanHan666666/flutter-linglong-store/releases/tag/v3.3.2',
    );
  });
}
