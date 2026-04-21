import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/linglong_env_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/platform/local_path_opener.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';
import 'package:linglong_store/presentation/widgets/linglong_env_dialog.dart';

void main() {
  testWidgets(
    'shows the open log directory button during installation and opens the directory',
    (tester) async {
      final opener = _FakeLocalPathOpener();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            linglongEnvProvider.overrideWith(() => _InstallingLinglongEnv()),
            localPathOpenerProvider.overrideWithValue(opener),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Center(child: LinglongEnvDialog())),
          ),
        ),
      );

      expect(find.text('打开日志目录'), findsOneWidget);

      await tester.tap(find.text('打开日志目录'));
      await tester.pump();

      expect(opener.openedDirectories, ['/tmp/install-logs']);
    },
  );
}

class _InstallingLinglongEnv extends LinglongEnv {
  @override
  LinglongEnvState build() {
    return const LinglongEnvState(
      checkState: LinglongEnvCheckState.failed,
      result: LinglongEnvCheckResult(
        isOk: false,
        errorMessage: 'll-cli 未安装或不可用',
        checkedAt: 1,
      ),
      isInstalling: true,
      installProgress: 0.5,
      installMessage: '正在执行安装脚本（需要管理员权限）...',
      installLogFilePath: '/tmp/install-logs/linglong-env-install.log',
    );
  }
}

class _FakeLocalPathOpener implements LocalPathOpener {
  final List<String> openedDirectories = <String>[];

  @override
  Future<bool> openDirectory(String directoryPath) async {
    openedDirectories.add(directoryPath);
    return true;
  }
}
