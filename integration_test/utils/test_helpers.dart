/// Patrol 集成测试辅助工具
///
/// 提供测试初始化、配置和通用测试操作的工具函数。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linglong_store/app.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/storage/preferences_service.dart';

/// 测试配置常量
class TestConfig {
  TestConfig._();

  /// 默认测试超时时间
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// 长操作超时时间
  static const Duration longTimeout = Duration(minutes: 2);

  /// 短操作超时时间
  static const Duration shortTimeout = Duration(seconds: 5);

  /// 应用启动超时时间
  static const Duration appStartupTimeout = Duration(seconds: 15);

  /// 列表滚动等待时间
  static const Duration scrollDelay = Duration(milliseconds: 300);
}

/// 测试辅助工具类
///
/// 提供测试初始化、清理和通用操作的静态方法。
class TestHelpers {
  TestHelpers._();

  /// 初始化测试环境
  ///
  /// 在测试开始前调用，初始化必要的测试基础设施。
  /// 包括日志、存储等。
  static Future<void> initTestEnvironment() async {
    // 初始化日志（测试模式）
    await AppLogger.init();

    // 初始化 SharedPreferences（使用内存模拟）
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();

    // 初始化 Hive（内存模式）
    await Hive.initFlutter();
  }

  /// 清理测试环境
  ///
  /// 在测试结束后调用，清理测试产生的数据。
  static Future<void> cleanupTestEnvironment() async {
    // 清理 Hive 缓存
    await Hive.deleteFromDisk();
  }

  /// 创建测试用应用 Widget
  ///
  /// 用于集成测试，创建最小化的应用实例。
  static Widget createTestApp() {
    return const ProviderScope(child: LinglongStoreApp());
  }

  /// 等待 widget 渲染稳定
  ///
  /// [tester] - Widget tester
  /// [timeout] - 超时时间
  static Future<void> waitForStability(
    WidgetTester tester, {
    Duration timeout = TestConfig.defaultTimeout,
  }) async {
    await tester.pumpAndSettle(timeout);
  }

  /// 等待 Patrol widget 渲染稳定
  ///
  /// [$] - Patrol tester
  /// [timeout] - 超时时间
  static Future<void> waitForPatrolStability(
    PatrolTester $, {
    Duration timeout = TestConfig.defaultTimeout,
  }) async {
    await $.pumpAndSettle(timeout: timeout);
  }

  /// 等待指定条件成立
  ///
  /// [condition] - 条件函数
  /// [timeout] - 超时时间
  /// [interval] - 检查间隔
  static Future<void> waitUntil(
    bool Function() condition, {
    Duration timeout = TestConfig.defaultTimeout,
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      if (condition()) {
        return;
      }
      await Future.delayed(interval);
    }
    throw TimeoutException('条件未在指定时间内成立', timeout);
  }

  /// 生成随机字符串
  ///
  /// [length] - 字符串长度
  static String randomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(chars[DateTime.now().microsecondsSinceEpoch % chars.length]);
    }
    return buffer.toString();
  }

  /// 格式化测试名称
  ///
  /// [description] - 测试描述
  static String formatTestName(String description) {
    return description.replaceAll(' ', '_').toLowerCase();
  }

  /// 打印测试日志
  ///
  /// [message] - 日志消息
  static void log(String message) {
    debugPrint('[Patrol Test] $message');
  }
}

/// 超时异常
class TimeoutException implements Exception {
  TimeoutException(this.message, this.duration);

  final String message;
  final Duration duration;

  @override
  String toString() =>
      'TimeoutException: $message (${duration.inMilliseconds}ms)';
}

/// 测试数据生成器
class TestDataGenerator {
  TestDataGenerator._();

  /// 生成模拟应用数据
  static Map<String, dynamic> mockAppData({
    String? id,
    String? name,
    String? description,
  }) {
    return {
      'id': id ?? 'com.example.app',
      'name': name ?? '测试应用',
      'description': description ?? '这是一个测试应用',
      'icon': 'https://example.com/icon.png',
      'version': '1.0.0',
      'size': 1024000,
      'rating': 4.5,
      'downloads': 10000,
    };
  }

  /// 生成模拟应用列表数据
  static List<Map<String, dynamic>> mockAppList({int count = 10}) {
    return List.generate(
      count,
      (index) => mockAppData(id: 'com.example.app$index', name: '测试应用 $index'),
    );
  }

  /// 生成模拟分类数据
  static Map<String, dynamic> mockCategoryData({String? code, String? name}) {
    return {
      'code': code ?? 'test_category',
      'name': name ?? '测试分类',
      'icon': 'https://example.com/category.png',
      'appCount': 100,
    };
  }
}

/// 测试断言扩展
class TestAssertions {
  TestAssertions._();

  /// 断言 widget 可见
  static void assertVisible(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// 断言 widget 不可见
  static void assertNotVisible(Finder finder) {
    expect(finder, findsNothing);
  }

  /// 断言 widget 数量
  static void assertCount(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// 断言 widget 至少有 N 个
  static void assertAtLeast(Finder finder, int minCount) {
    final matchCount = finder.evaluate().length;
    expect(matchCount, greaterThanOrEqualTo(minCount));
  }

  /// 断言文本内容
  static void assertTextContent(Finder finder, String expectedText) {
    final widget = finder.evaluate().first.widget;
    if (widget is Text) {
      expect(widget.data, expectedText);
    } else {
      throw ArgumentError('Finder 找到的 widget 不是 Text 类型');
    }
  }
}
