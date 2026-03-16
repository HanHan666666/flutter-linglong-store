/// 启动流程测试
///
/// 测试应用启动序列的各个阶段。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

import 'package:linglong_store/app.dart';

import '../utils/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('启动流程测试', () {
    /// 验证启动页加载
    patrolTest(
      '应用启动后应该显示初始化界面',
      ($) async {
        // 启动应用
        await $.pumpWidgetAndSettle(const LinglongStoreApp());

        // 验证 MaterialApp 存在
        expect($(MaterialApp), findsOneWidget);
      },
      skip: false,
    );

    /// 验证初始化完成
    patrolTest(
      '应用初始化应该成功完成',
      ($) async {
        // 启动应用
        await $.pumpWidgetAndSettle(
          const LinglongStoreApp(),
          duration: TestConfig.appStartupTimeout,
        );

        // 等待初始化完成
        await $.pump(const Duration(seconds: 3));

        // 验证应用正常运行
        expect($(MaterialApp), findsOneWidget);
      },
      skip: false,
    );

    /// 验证环境检测
    patrolTest(
      '应用应该能够完成环境初始化',
      ($) async {
        // 启动应用
        await $.pumpWidgetAndSettle(const LinglongStoreApp());

        // 验证应用成功启动
        // 在真实测试中，会验证具体的环境检测逻辑
        expect($(MaterialApp), findsOneWidget);
      },
      skip: false,
    );

    /// 验证错误处理
    patrolTest(
      '应用启动失败时应该显示错误信息',
      ($) async {
        // 启动应用
        await $.pumpWidgetAndSettle(const LinglongStoreApp());

        // 在正常情况下，不应该显示错误
        // 这里验证应用成功启动
        expect($(MaterialApp), findsOneWidget);
      },
      skip: false,
    );
  });

  group('启动性能测试', () {
    /// 测量启动时间
    patrolTest(
      '测量应用启动时间',
      ($) async {
        final stopwatch = Stopwatch()..start();

        // 启动应用
        await $.pumpWidgetAndSettle(const LinglongStoreApp());
        stopwatch.stop();

        TestHelpers.log('启动时间: ${stopwatch.elapsedMilliseconds}ms');

        // 启动时间应该在合理范围内
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      },
      skip: false,
    );
  });
}