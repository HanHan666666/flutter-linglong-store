import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/local_path_opener.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('LocalPathOpener', () {
    test('opens a directory with xdg-open', () async {
      final runner = _RecordingShellCommandRunner(
        const ShellCommandResult(stdout: '', stderr: '', exitCode: 0),
      );
      final opener = LocalPathOpener(
        executor: ShellCommandExecutor(runner: runner),
      );

      final opened = await opener.openDirectory('/tmp/install-logs');

      expect(opened, isTrue);
      expect(runner.commands, [
        ['xdg-open', '/tmp/install-logs'],
      ]);
    });

    test('returns false when xdg-open fails', () async {
      final opener = LocalPathOpener(
        executor: ShellCommandExecutor(
          runner: _RecordingShellCommandRunner(
            const ShellCommandResult(
              stdout: '',
              stderr: 'failed to open',
              exitCode: 1,
            ),
          ),
        ),
      );

      final opened = await opener.openDirectory('/tmp/install-logs');

      expect(opened, isFalse);
    });
  });
}

class _RecordingShellCommandRunner implements ShellCommandRunner {
  _RecordingShellCommandRunner(this._result);

  final List<List<String>> commands = <List<String>>[];
  final ShellCommandResult _result;

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) async {
    commands.add(List<String>.from(command));
    return _result;
  }
}
