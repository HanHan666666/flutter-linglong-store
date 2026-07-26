import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

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

    test('writes command output into the provided log file', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'shell-command-executor-test-',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final logFile = File('${tempDir.path}/install.log');
      final executor = ShellCommandExecutor();

      final result = await executor.run(
        [
          'bash',
          '-lc',
          'printf "hello from stdout\\n"; printf "oops from stderr\\n" >&2',
        ],
        logOptions: ShellCommandLogOptions(
          filePath: logFile.path,
          overwrite: true,
        ),
      );

      final content = await logFile.readAsString();

      expect(result.success, isTrue);
      expect(content, contains('bash -lc'));
      expect(content, contains('hello from stdout'));
      expect(content, contains('oops from stderr'));
    });

    test('streams stdout and stderr while keeping the final result', () async {
      final executor = ShellCommandExecutor();
      final outputs = <ShellOutputLine>[];

      final result = await executor.runStreaming([
        'bash',
        '-lc',
        'printf "live stdout\\n"; printf "live stderr\\n" >&2',
      ], onOutput: outputs.add);

      expect(result.success, isTrue);
      expect(
        outputs,
        contains(
          isA<ShellOutputLine>()
              .having(
                (item) => item.channel,
                'channel',
                ShellOutputChannel.stdout,
              )
              .having((item) => item.line, 'line', 'live stdout'),
        ),
      );
      expect(
        outputs,
        contains(
          isA<ShellOutputLine>()
              .having(
                (item) => item.channel,
                'channel',
                ShellOutputChannel.stderr,
              )
              .having((item) => item.line, 'line', 'live stderr'),
        ),
      );
    });

    test(
      'streaming result keeps a bounded tail while callbacks receive all lines',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'shell-command-bounded-output-test-',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });
        final executor = ShellCommandExecutor();
        var receivedLines = 0;

        final result = await executor.runStreaming(
          [
            'bash',
            '-lc',
            r'for i in $(seq 1 2000); do '
                r'printf "%04d-abcdefghijklmnopqrstuvwxyz0123456789\n" "$i"; '
                'done',
          ],
          logOptions: ShellCommandLogOptions(
            filePath: '${tempDir.path}/full-output.log',
            overwrite: true,
          ),
          onOutput: (_) => receivedLines += 1,
        );

        expect(result.success, isTrue);
        expect(receivedLines, 2000);
        expect(utf8.encode(result.stdout).length, lessThanOrEqualTo(64 * 1024));
        expect(result.stdout, isNot(contains('0001-')));
        expect(result.stdout, contains('2000-'));
        expect(
          await File('${tempDir.path}/full-output.log').readAsString(),
          contains('0001-'),
        );
      },
    );
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
    ShellCommandLogOptions? logOptions,
  }) async {
    return _result;
  }
}
