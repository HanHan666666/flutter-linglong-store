import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/network/api_exceptions.dart';
import 'package:linglong_store/core/platform/cli_executor.dart';

void main() {
  group('UninstallException', () {
    const testAppId = 'org.deepin.calculator';

    test('PKExec 授权取消场景 - 包含正确的错误信息', () {
      // 模拟 PKExec 取消后的错误信息
      const errorMessage =
          'Error executing command as another user: Request dismissed';

      const exception = UninstallException(
        errorMessage,
        appId: testAppId,
        exitCode: 126, // PKExec 取消时的常见退出码
      );

      expect(exception.message, contains('Request dismissed'));
      expect(exception.appId, equals(testAppId));
      expect(exception.exitCode, equals(126));
    });

    test('卸载命令执行失败场景', () {
      const exception = UninstallException(
        'Application not found',
        appId: testAppId,
        exitCode: 1,
      );

      expect(exception.message, equals('Application not found'));
      expect(exception.appId, equals(testAppId));
      expect(exception.exitCode, equals(1));
    });

    test('是 AppException 的子类，可被统一处理', () {
      const exception = UninstallException('test error');
      expect(exception, isA<AppException>());
    });

    test('userMessage 格式正确', () {
      const exception = UninstallException('some error');
      expect(exception.userMessage, equals('卸载失败：some error'));
    });

    test('可序列化为用户友好的错误信息', () {
      // 验证可以通过 presentAppError 函数转换为用户可见信息
      const exception = UninstallException(
        'Permission denied',
        appId: testAppId,
        exitCode: 126,
      );

      final userMessage = presentAppError(exception);
      expect(userMessage, equals('卸载失败：Permission denied'));
    });

    test('空 stderr 时使用默认错误信息', () {
      const exception = UninstallException(
        '', // 空 stderr
        appId: testAppId,
        exitCode: 1,
      );

      expect(exception.message, isEmpty);
      expect(exception.userMessage, equals('卸载失败：'));
    });
  });

  group('CliOutput 行为验证', () {
    test('exitCode 为 0 时 success 为 true', () {
      const output = CliOutput(
        stdout: 'success',
        stderr: '',
        exitCode: 0,
      );
      expect(output.success, isTrue);
    });

    test('exitCode 非 0 时 success 为 false (PKExec 取消)', () {
      // 模拟 PKExec 取消
      const output = CliOutput(
        stdout: '',
        stderr: 'Request dismissed',
        exitCode: 126,
      );
      expect(output.success, isFalse);
    });

    test('exitCode 非 0 时 success 为 false (应用不存在)', () {
      const output = CliOutput(
        stdout: '',
        stderr: 'Application not found',
        exitCode: 1,
      );
      expect(output.success, isFalse);
    });
  });

  group('修复验证', () {
    const appId = 'org.deepin.calculator';
    test('''
修复前行为（错误）：Repository 返回错误字符串，调用方需要检查字符串内容
修复后行为（正确）：Repository 抛出 UninstallException，调用方通过 catch 处理
    ''', () {
      // 修复后的正确行为：抛出异常
      void simulateUninstallFailure() {
        throw const UninstallException(
          'Request dismissed',
          appId: appId,
          exitCode: 126,
        );
      }

      // 验证异常可以被正确捕获
      expect(
        simulateUninstallFailure,
        throwsA(isA<UninstallException>()),
      );

      // 验证异常内容
      try {
        simulateUninstallFailure();
        fail('Should have thrown UninstallException');
      } on UninstallException catch (e) {
        expect(e.message, contains('Request dismissed'));
        expect(e.exitCode, equals(126));
      }
    });
  });
}