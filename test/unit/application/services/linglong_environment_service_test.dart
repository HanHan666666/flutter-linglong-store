import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/linglong_environment_service.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';

void main() {
  group('LinglongEnvironmentService', () {
    test('returns failure when ll-cli help cannot run', () async {
      final service = LinglongEnvironmentService(
        executor: ShellCommandExecutor(
          runner: _FakeShellCommandRunner.fromCommands({
            'll-cli --help': const ShellCommandResult(
              stdout: '',
              stderr: 'll-cli: command not found',
              exitCode: 127,
            ),
          }),
        ),
        clock: () => 123,
      );

      final result = await service.checkEnvironment();

      expect(result.isOk, isFalse);
      expect(result.llCliVersion, isNull);
      expect(result.repoStatus, RepoStatus.unavailable);
      expect(result.errorMessage, 'll-cli 未安装或不可用');
      expect(result.checkedAt, 123);
    });

    test(
      'returns warning-only success when version is lower than 1.9.0',
      () async {
        final service = LinglongEnvironmentService(
          executor: ShellCommandExecutor(
            runner: _FakeShellCommandRunner.fromCommands({
              'uname -m': const ShellCommandResult(
                stdout: 'x86_64\n',
                stderr: '',
                exitCode: 0,
              ),
              'ldd --version': const ShellCommandResult(
                stdout: 'ldd (GNU libc) 2.36\n',
                stderr: '',
                exitCode: 0,
              ),
              'uname -a': const ShellCommandResult(
                stdout: 'Linux test 6.8.0\n',
                stderr: '',
                exitCode: 0,
              ),
              'bash -c dpkg -l | grep linglong': const ShellCommandResult(
                stdout: 'ii linglong-bin 1.8.2\n',
                stderr: '',
                exitCode: 0,
              ),
              'll-cli --help': const ShellCommandResult(
                stdout: 'Usage: ll-cli\n',
                stderr: '',
                exitCode: 0,
              ),
              'll-cli --json repo show': const ShellCommandResult(
                stdout:
                    '{"defaultRepo":"stable","repos":[{"name":"stable","url":"https://repo.example"}]}',
                stderr: '',
                exitCode: 0,
              ),
              'll-cli --json --version': const ShellCommandResult(
                stdout: '{"version":"1.8.2"}',
                stderr: '',
                exitCode: 0,
              ),
              'apt-cache policy linglong-bin': const ShellCommandResult(
                stdout: 'Installed: 1.8.2\n',
                stderr: '',
                exitCode: 0,
              ),
            }),
          ),
          osReleaseReader: () async => 'PRETTY_NAME="Deepin 23"\n',
          environmentReader: (name) => null,
          clock: () => 456,
        );

        final result = await service.checkEnvironment();

        expect(result.isOk, isTrue);
        expect(result.warningMessage, isNotNull);
        expect(result.warningMessage, contains('1.8.2'));
        expect(result.repoStatus, RepoStatus.ok);
        expect(result.repoName, 'stable');
        expect(result.repos, hasLength(1));
        expect(result.llCliVersion, '1.8.2');
        expect(result.checkedAt, 456);
      },
    );

    test('returns failure when repo list is empty', () async {
      final service = LinglongEnvironmentService(
        executor: ShellCommandExecutor(
          runner: _FakeShellCommandRunner.fromCommands({
            'uname -m': const ShellCommandResult(
              stdout: 'x86_64\n',
              stderr: '',
              exitCode: 0,
            ),
            'ldd --version': const ShellCommandResult(
              stdout: 'ldd (GNU libc) 2.36\n',
              stderr: '',
              exitCode: 0,
            ),
            'uname -a': const ShellCommandResult(
              stdout: 'Linux test 6.8.0\n',
              stderr: '',
              exitCode: 0,
            ),
            'bash -c dpkg -l | grep linglong': const ShellCommandResult(
              stdout: '',
              stderr: '',
              exitCode: 1,
            ),
            'll-cli --help': const ShellCommandResult(
              stdout: 'Usage: ll-cli\n',
              stderr: '',
              exitCode: 0,
            ),
            'll-cli --json repo show': const ShellCommandResult(
              stdout: '{"defaultRepo":"stable","repos":[]}',
              stderr: '',
              exitCode: 0,
            ),
            'll-cli --json --version': const ShellCommandResult(
              stdout: '{"version":"1.9.1"}',
              stderr: '',
              exitCode: 0,
            ),
          }),
        ),
        osReleaseReader: () async => 'PRETTY_NAME="Deepin 23"\n',
        environmentReader: (name) => null,
      );

      final result = await service.checkEnvironment();

      expect(result.isOk, isFalse);
      expect(result.repoStatus, RepoStatus.notConfigured);
      expect(result.errorMessage, '未检测到玲珑仓库配置，请检查环境');
    });
  });
}

class _FakeShellCommandRunner implements ShellCommandRunner {
  _FakeShellCommandRunner.fromCommands(this._results);

  final Map<String, ShellCommandResult> _results;

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
  }) async {
    final key = command.join(' ');
    final result = _results[key];
    if (result == null) {
      throw StateError('Unexpected command: $key');
    }
    return result;
  }
}
