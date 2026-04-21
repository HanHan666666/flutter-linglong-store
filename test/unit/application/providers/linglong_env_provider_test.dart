import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglong_store/application/providers/linglong_env_provider.dart';
import 'package:linglong_store/application/services/linglong_environment_service.dart';
import 'package:linglong_store/application/services/linglong_install_log_service.dart';
import 'package:linglong_store/application/services/linglong_install_script_service.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('LinglongEnv provider', () {
    test('checkEnvironment keeps warning-only success non-blocking', () async {
      final container = ProviderContainer(
        overrides: [
          linglongEnvironmentServiceProvider.overrideWithValue(
            _FakeEnvironmentService(
              const LinglongEnvCheckResult(
                isOk: true,
                warningMessage: '当前玲珑基础环境版本(1.8.2)过低',
                llCliVersion: '1.8.2',
                repoStatus: RepoStatus.ok,
                checkedAt: 1,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(linglongEnvProvider.notifier)
          .checkEnvironment();
      final state = container.read(linglongEnvProvider);

      expect(result.isOk, isTrue);
      expect(state.result?.warningMessage, isNotNull);
      expect(state.shouldShowDialog, isFalse);
      expect(state.canContinue, isTrue);
    });

    test(
      'performAutoInstall returns false when pkexec bash exits non-zero',
      () async {
        final container = ProviderContainer(
          overrides: [
            linglongEnvironmentServiceProvider.overrideWithValue(
              _FakeEnvironmentService(
                const LinglongEnvCheckResult(
                  isOk: true,
                  llCliVersion: '1.9.1',
                  repoStatus: RepoStatus.ok,
                  checkedAt: 1,
                ),
              ),
            ),
            linglongInstallScriptServiceProvider.overrideWithValue(
              LinglongInstallScriptService(
                loadScript: () async => '#!/bin/bash\necho install',
              ),
            ),
            shellCommandExecutorProvider.overrideWithValue(
              ShellCommandExecutor(
                runner: const _FixedShellCommandRunner(
                  ShellCommandResult(
                    stdout: 'out',
                    stderr: 'pkexec denied',
                    exitCode: 1,
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final success = await container
            .read(linglongEnvProvider.notifier)
            .performAutoInstall();
        final state = container.read(linglongEnvProvider);

        expect(success, isFalse);
        expect(state.isInstalling, isFalse);
        expect(state.installMessage, contains('pkexec denied'));
      },
    );

    test(
      'performAutoInstall records a readable install log file path',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'linglong-install-log-provider-test-',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        final container = ProviderContainer(
          overrides: [
            linglongEnvironmentServiceProvider.overrideWithValue(
              _FakeEnvironmentService(
                const LinglongEnvCheckResult(
                  isOk: true,
                  llCliVersion: '1.9.1',
                  repoStatus: RepoStatus.ok,
                  checkedAt: 1,
                ),
              ),
            ),
            linglongInstallScriptServiceProvider.overrideWithValue(
              LinglongInstallScriptService(
                loadScript: () async => '#!/bin/bash\necho install',
              ),
            ),
            linglongInstallLogServiceProvider.overrideWithValue(
              LinglongInstallLogService(
                logDirectoryPath: tempDir.path,
                fileName: 'linglong-env-install.log',
              ),
            ),
            shellCommandExecutorProvider.overrideWithValue(
              ShellCommandExecutor(
                runner: _LoggingShellCommandRunner(
                  const ShellCommandResult(
                    stdout: 'ok',
                    stderr: '',
                    exitCode: 0,
                  ),
                  logContent: 'install step 1\ninstall step 2\n',
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final success = await container
            .read(linglongEnvProvider.notifier)
            .performAutoInstall();
        final state = container.read(linglongEnvProvider);

        expect(success, isTrue);
        expect(state.installLogFilePath, isNotNull);
        expect(
          state.installLogFilePath,
          '${tempDir.path}/linglong-env-install.log',
        );

        final content = await File(state.installLogFilePath!).readAsString();
        expect(content, contains('install step 1'));
        expect(content, contains('install step 2'));
      },
    );
  });
}

class _FakeEnvironmentService extends LinglongEnvironmentService {
  _FakeEnvironmentService(this._result)
    : super(
        executor: ShellCommandExecutor(
          runner: const _FixedShellCommandRunner(
            ShellCommandResult(stdout: '', stderr: '', exitCode: 0),
          ),
        ),
      );

  final LinglongEnvCheckResult _result;

  @override
  Future<LinglongEnvCheckResult> checkEnvironment() async => _result;
}

class _FixedShellCommandRunner implements ShellCommandRunner {
  const _FixedShellCommandRunner(this._result);

  final ShellCommandResult _result;

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) async {
    return _result;
  }
}

class _LoggingShellCommandRunner implements ShellCommandRunner {
  const _LoggingShellCommandRunner(this._result, {required this.logContent});

  final ShellCommandResult _result;
  final String logContent;

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) async {
    if (logOptions != null) {
      final file = File(logOptions.filePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        logContent,
        mode: logOptions.overwrite ? FileMode.write : FileMode.append,
        flush: true,
      );
    }
    return _result;
  }
}
