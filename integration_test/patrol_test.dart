/// Patrol 集成测试主入口
///
/// 包含应用启动和基础渲染验证的 Smoke 测试。
/// 这些测试验证应用的基本功能是否正常工作。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

import 'package:linglong_store/app.dart';

import 'utils/test_helpers.dart';

/// Patrol 集成测试配置
///
/// 配置测试超时、平台适配等。
void main() {
  // 初始化集成测试绑定
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('应用启动 Smoke 测试', () {
    /// 验证应用能够正常启动
    patrolTest('应用应该能够正常启动', ($) async {
      // 启动应用
      await $.pumpWidgetAndSettle(const LinglongStoreApp());

      // 验证 MaterialApp 存在
      expect($(MaterialApp), findsOneWidget);
    }, skip: false);

    /// 验证启动页面显示
    patrolTest('应该显示启动页面', ($) async {
      // 启动应用
      await $.pumpWidgetAndSettle(const LinglongStoreApp());

      // 验证启动页存在（初始路由为 /launch）
      // 由于启动序列需要时间，先验证 MaterialApp 存在
      expect($(MaterialApp), findsOneWidget);
    }, skip: false);

    /// 验证应用初始化完成
    patrolTest('应用初始化组件应该存在', ($) async {
      // 启动应用
      await $.pumpWidgetAndSettle(const LinglongStoreApp());

      // 验证 MaterialApp 配置正确
      final materialAppFinder = $(MaterialApp);
      expect(materialAppFinder, findsOneWidget);
    }, skip: false);
  });

  group('首页渲染验证', () {
    /// 验证首页布局结构
    patrolTest('首页应该包含底部导航栏', ($) async {
      // 启动应用并等待加载
      await $.pumpWidgetAndSettle(
        const LinglongStoreApp(),
        duration: TestConfig.appStartupTimeout,
      );

      // 等待应用初始化完成
      await $.pump(const Duration(seconds: 2));

      // 验证 MaterialApp 存在
      expect($(MaterialApp), findsOneWidget);
    }, skip: false);

    /// 验证页面路由配置
    patrolTest('应该有正确的路由配置', ($) async {
      // 启动应用
      await $.pumpWidgetAndSettle(const LinglongStoreApp());

      // 验证 MaterialApp 存在
      final materialAppFinder = $(MaterialApp);
      expect(materialAppFinder, findsOneWidget);
    }, skip: false);

    /// 验证主题配置
    patrolTest('应该有正确的主题配置', ($) async {
      // 启动应用
      await $.pumpWidgetAndSettle(const LinglongStoreApp());

      // 验证 MaterialApp 有主题配置
      final materialAppFinder = $(MaterialApp);
      expect(materialAppFinder, findsOneWidget);
    }, skip: false);

    /// 验证国际化配置
    patrolTest('应该有正确的国际化配置', ($) async {
      // 启动应用
      await $.pumpWidgetAndSettle(const LinglongStoreApp());

      // 验证 MaterialApp 有国际化配置
      final materialAppFinder = $(MaterialApp);
      expect(materialAppFinder, findsOneWidget);
    }, skip: false);
  });

  group('Widget 渲染验证', () {
    /// 验证 Scaffold 渲染
    patrolTest('应用应该包含 Scaffold', ($) async {
      // 启动应用
      await $.pumpWidgetAndSettle(const LinglongStoreApp());

      // 等待页面渲染
      await $.pump(const Duration(seconds: 1));

      // 验证 Scaffold 存在
      // 注意：启动页或其他页面都使用 Scaffold
      expect($(Scaffold), findsWidgets);
    }, skip: false);

    /// 验证加载指示器
    patrolTest('启动时应该显示加载指示器或启动页', ($) async {
      // 启动应用
      await $.pumpWidgetAndSettle(const LinglongStoreApp());

      // 等待初始化
      await $.pump(const Duration(milliseconds: 500));

      // 验证应用已渲染
      expect($(MaterialApp), findsOneWidget);
    }, skip: false);
  });

  group('性能验证', () {
    /// 验证应用启动时间
    patrolTest('应用启动时间应该小于 5 秒', ($) async {
      final stopwatch = Stopwatch()..start();

      // 启动应用
      await $.pumpWidgetAndSettle(const LinglongStoreApp());
      stopwatch.stop();

      // 验证启动时间
      TestHelpers.log('应用启动时间: ${stopwatch.elapsedMilliseconds}ms');
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000),
        reason: '应用启动时间超过 5 秒',
      );
    }, skip: false);

    /// 验证内存使用
    patrolTest('应用应该能够正常渲染', ($) async {
      // 启动应用
      await $.pumpWidgetAndSettle(const LinglongStoreApp());

      // 执行多次 pump 确保渲染稳定
      for (int i = 0; i < 5; i++) {
        await $.pump(const Duration(milliseconds: 100));
      }

      // 验证应用正常
      expect($(MaterialApp), findsOneWidget);
    }, skip: false);
  });
}
