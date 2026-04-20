import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/launch_provider.dart';
import 'package:linglong_store/application/providers/linglong_env_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';
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
          overrides: [
            launchSequenceProvider.overrideWith(() => _IdleLaunchSequence()),
          ],
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

      // 验证应该显示 PackageInfo 的真实版本号，而不是配置里的硬编码 fallback。
      const expectedVersion = 'v3.1.2';
      expect(find.text(expectedVersion), findsOneWidget);
    },
  );

  testWidgets(
    'launch page does not show the environment dialog for warning-only state',
    (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'linglong_store',
        packageName: 'linglong_store',
        version: '3.1.2',
        buildNumber: '1',
        buildSignature: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            launchSequenceProvider.overrideWith(() => _IdleLaunchSequence()),
            linglongEnvProvider.overrideWith(() => _WarningLinglongEnv()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LaunchPage(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}

class _IdleLaunchSequence extends LaunchSequence {
  @override
  LaunchState build() => const LaunchState();

  @override
  Future<void> runSequence() async {}
}

class _WarningLinglongEnv extends LinglongEnv {
  @override
  LinglongEnvState build() {
    return const LinglongEnvState(
      checkState: LinglongEnvCheckState.success,
      result: LinglongEnvCheckResult(
        isOk: true,
        warningMessage: '当前玲珑基础环境版本(1.8.2)过低',
        llCliVersion: '1.8.2',
        repoStatus: RepoStatus.ok,
        checkedAt: 1,
      ),
    );
  }
}
