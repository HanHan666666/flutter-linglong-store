import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';

void main() {
  group('ShellCommandResult', () {
    test('prefers stderr as the primary message when both streams exist', () {
      const result = ShellCommandResult(
        stdout: 'stdout message',
        stderr: 'stderr message',
        exitCode: 1,
      );

      expect(result.primaryMessage, 'stderr message');
    });

    test(
      'falls back to stdout as the primary message when stderr is blank',
      () {
        const result = ShellCommandResult(
          stdout: 'stdout message',
          stderr: '   ',
          exitCode: 1,
        );

        expect(result.primaryMessage, 'stdout message');
      },
    );
  });

  group('ShellCommandExecutor', () {
    test('returns the runner output for a successful command', () async {
      final executor = ShellCommandExecutor(
        runner: const _FixedShellCommandRunner(
          ShellCommandResult(stdout: 'ok', stderr: '', exitCode: 0),
        ),
      );

      final result = await executor.run(['pkexec', 'bash', '/tmp/test.sh']);

      expect(result.exitCode, 0);
      expect(result.stdout, 'ok');
      expect(result.success, isTrue);
    });

    test('returns the runner output for a failed command', () async {
      final executor = ShellCommandExecutor(
        runner: const _FixedShellCommandRunner(
          ShellCommandResult(stdout: 'out', stderr: 'boom', exitCode: 1),
        ),
      );

      final result = await executor.run(['pkexec', 'bash', '/tmp/test.sh']);

      expect(result.exitCode, 1);
      expect(result.primaryMessage, 'boom');
      expect(result.success, isFalse);
    });
  });
}

class _FixedShellCommandRunner implements ShellCommandRunner {
  const _FixedShellCommandRunner(this._result);

  final ShellCommandResult _result;

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
  }) async {
    return _result;
  }
}
