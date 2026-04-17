import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/config/app_config.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/presentation/pages/launch/launch_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  testWidgets(
    'launch page displays dynamic version from PackageInfo, not hardcoded v1.0.0',
    (tester) async {
      // Mock PackageInfo 返回测试版本号
      PackageInfo.setMockInitialValues(
        appName: 'linglong_store',
        packageName: 'linglong_store',
        version: '3.1.2',
        buildNumber: '1',
        buildSignature: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LaunchPage(),
          ),
        ),
      );

      // 等待异步操作完成（版本号获取）
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证不应该显示硬编码的 v1.0.0
      expect(find.text('v1.0.0'), findsNothing);

      // 验证应该显示真实版本号 3.1.2 或 fallback 版本号
      final expectedVersion = 'v${AppConfig.appVersion}';
      expect(find.text(expectedVersion), findsOneWidget);
    },
  );
}