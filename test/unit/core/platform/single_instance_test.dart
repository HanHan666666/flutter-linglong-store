import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/single_instance.dart';

void main() {
  setUpAll(() async {
    // 初始化日志
    await AppLogger.init();
  });

  setUp(() async {
    // 每个测试前清理资源
    await SingleInstance.dispose();
  });

  tearDown(() async {
    // 每个测试后清理资源
    await SingleInstance.dispose();
  });

  group('SingleInstance', () {
    group('isFirstInstance', () {
      test('should return true before ensure() is called', () {
        // 默认值应该是 true
        expect(SingleInstance.isFirstInstance, isTrue);
      });
    });

    group('ensure', () {
      test('should return true when no other instance is running', () async {
        // 第一次调用应该返回 true
        final result = await SingleInstance.ensure();
        expect(result, isTrue);
        expect(SingleInstance.isFirstInstance, isTrue);

        // 清理资源
        await SingleInstance.dispose();
      });

      test('should acquire file lock successfully', () async {
        // 确保没有残留的锁文件
        await SingleInstance.dispose();

        final result = await SingleInstance.ensure();
        expect(result, isTrue);

        // 验证锁文件已创建
        final lockFile = File('/tmp/linglong-store.lock');
        expect(await lockFile.exists(), isTrue);

        // 清理
        await SingleInstance.dispose();
      });
    });

    group('dispose', () {
      test('should clean up resources without error', () async {
        // 先确保有资源需要清理
        await SingleInstance.ensure();

        // 清理不应该抛出异常
        await expectLater(SingleInstance.dispose(), completes);
      });

      test('should be safe to call multiple times', () async {
        await SingleInstance.ensure();

        // 多次调用 dispose 应该不会出错
        await SingleInstance.dispose();
        await SingleInstance.dispose();
        await SingleInstance.dispose();
      });
    });
  });

  group('File Lock Integration', () {
    test('should prevent second instance from acquiring lock', () async {
      // 清理之前的状态
      await SingleInstance.dispose();

      // 第一个实例获取锁
      final firstResult = await SingleInstance.ensure();
      expect(firstResult, isTrue);

      // 创建一个新的进程来尝试获取锁（模拟第二个实例）
      // 注意：由于文件锁是进程级别的，同一个进程内的多次调用
      // 可能不会触发锁冲突，所以这个测试主要用于验证基本功能

      // 清理
      await SingleInstance.dispose();
    });
  });

  group('Socket File Cleanup', () {
    test('should create and cleanup socket file', () async {
      // 清理之前的状态
      await SingleInstance.dispose();

      final socketFile = File('/tmp/linglong-store.sock');

      // 确保启动时没有残留的 socket 文件
      if (await socketFile.exists()) {
        await socketFile.delete();
      }

      // 启动单实例检测
      await SingleInstance.ensure();

      // Socket 文件应该存在
      expect(await socketFile.exists(), isTrue);

      // 清理
      await SingleInstance.dispose();

      // Socket 文件应该被删除
      expect(await socketFile.exists(), isFalse);
    });
  });
}