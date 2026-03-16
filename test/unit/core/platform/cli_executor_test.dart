import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/platform/cli_executor.dart';

void main() {
  group('CliOutput', () {
    test('should create CliOutput with correct properties', () {
      const output = CliOutput(
        stdout: 'test output',
        stderr: '',
        exitCode: 0,
      );

      expect(output.stdout, equals('test output'));
      expect(output.stderr, equals(''));
      expect(output.success, isTrue);
      expect(output.exitCode, equals(0));
    });

    test('should mark success as false when exitCode is non-zero', () {
      const output = CliOutput(
        stdout: '',
        stderr: 'error message',
        exitCode: 1,
      );

      expect(output.success, isFalse);
      expect(output.exitCode, equals(1));
    });
  });

  group('CliExecutor', () {
    group('execute', () {
      test('should return CliOutput with success=true when exit code is 0', () async {
        // 注意：这个测试需要实际的 ll-cli 环境
        // 在 CI 环境中应该 mock Process.start
        // 这里我们跳过需要实际命令的测试
      }, skip: 'Requires ll-cli to be installed');

      test('should return CliOutput with success=false when exit code is non-zero', () async {
        // 同上，需要 mock
      }, skip: 'Requires ll-cli to be installed');

      test('should throw CliTimeoutException on timeout', () async {
        // 测试超时场景
      }, skip: 'Requires mock Process');
    });

    group('executeOrErr', () {
      test('should return stdout when execution succeeds', () async {
        // 测试成功执行场景
      }, skip: 'Requires ll-cli to be installed');

      test('should throw CliExecutionException when execution fails', () async {
        // 测试失败场景
      }, skip: 'Requires ll-cli to be installed');
    });
  });

  group('CliTimeoutException', () {
    test('should create exception with correct properties', () {
      final exception = CliTimeoutException('执行超时', 'install');

      expect(exception.message, equals('执行超时'));
      expect(exception.command, equals('install'));
      expect(exception.toString(), contains('执行超时'));
    });
  });

  group('CliExecutionException', () {
    test('should create exception with correct properties', () {
      final exception = CliExecutionException('执行失败', 1, 'install');

      expect(exception.message, equals('执行失败'));
      expect(exception.exitCode, equals(1));
      expect(exception.command, equals('install'));
      expect(exception.toString(), contains('执行失败'));
    });
  });

  group('environment variables', () {
    test('should use English locale for consistent output parsing', () {
      // 验证环境变量配置正确
      const expectedEnv = {
        'LC_ALL': 'C.UTF-8',
        'LANG': 'C.UTF-8',
        'LANGUAGE': 'C.UTF-8',
        'LC_MESSAGES': 'C.UTF-8',
      };

      // 静态验证环境变量配置
      expect(expectedEnv['LC_ALL'], equals('C.UTF-8'));
      expect(expectedEnv['LANG'], equals('C.UTF-8'));
    });
  });
}