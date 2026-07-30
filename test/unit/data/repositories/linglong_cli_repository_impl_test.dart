import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/platform/cli_executor.dart';
import 'package:linglong_store/domain/models/linglong_cli_failure.dart';

void main() {
  group('LinglongCliException', () {
    test('keeps stable category and raw command diagnostics', () {
      const exception = LinglongCliException(
        LinglongCliFailure(
          kind: LinglongCliFailureKind.permissionDenied,
          command: 'uninstall',
          diagnostic: 'Request dismissed',
          exitCode: 126,
        ),
      );

      expect(exception.failure.kind, LinglongCliFailureKind.permissionDenied);
      expect(exception.failure.command, 'uninstall');
      expect(exception.failure.diagnostic, 'Request dismissed');
      expect(exception.failure.exitCode, 126);
      expect(exception.toString(), 'Request dismissed');
    });
  });

  group('CliOutput', () {
    test('uses stderr first and falls back to stdout for diagnostics', () {
      const stderrOutput = CliOutput(
        stdout: 'secondary output',
        stderr: 'primary error',
        exitCode: 1,
      );
      const stdoutOutput = CliOutput(
        stdout: 'fallback error',
        stderr: '',
        exitCode: 1,
      );

      expect(stderrOutput.primaryMessage, 'primary error');
      expect(stdoutOutput.primaryMessage, 'fallback error');
    });
  });
}
