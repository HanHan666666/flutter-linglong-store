import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:linglong_store/core/config/theme.dart';

/// 创建测试用的 MaterialApp widget
///
/// 使用方法:
/// ```dart
/// await tester.pumpWidget(createTestApp(MyWidget()));
/// ```
Widget createTestApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
}

/// 创建带有 Navigator 的测试 widget
///
/// 用于测试需要导航的 widget
Widget createTestAppWithNavigator(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        '/': (context) => Scaffold(body: child),
        '/detail': (context) => const Scaffold(body: Text('Detail Page')),
      },
    ),
  );
}

/// 测试用的假数据工厂
class TestFixtures {
  TestFixtures._();

  /// 创建测试用的应用数据 Map
  static Map<String, dynamic> createTestAppMap({
    String appId = 'com.example.test',
    String name = 'Test App',
    String version = '1.0.0',
    String? icon,
    String? description,
    String? arch,
    String? channel,
    String? kind,
    String? module,
    String? runtime,
    String? size,
    String? repoName,
  }) {
    return {
      'app_id': appId,
      'name': name,
      'version': version,
      'icon': icon ?? 'https://example.com/icon.png',
      'description': description ?? 'Test app description',
      'arch': arch,
      'channel': channel,
      'kind': kind,
      'module': module,
      'runtime': runtime,
      'size': size ?? '10.5 MB',
      'repo_name': repoName ?? 'community',
    };
  }

  /// 创建测试用的安装任务数据
  static Map<String, dynamic> createTestInstallTaskMap({
    String appId = 'com.example.test',
    String name = 'Test App',
    String? version = '1.0.0',
    String? icon,
    double progress = 0.0,
    String? message,
    bool isProcessing = false,
    bool isCompleted = false,
    bool isFailed = false,
    String? error,
    int? errorCode,
  }) {
    return {
      'appId': appId,
      'name': name,
      'version': version,
      'icon': icon,
      'progress': progress,
      'message': message,
      'isProcessing': isProcessing,
      'isCompleted': isCompleted,
      'isFailed': isFailed,
      'error': error,
      'errorCode': errorCode,
    };
  }
}

/// 异步测试辅助方法
Future<void> pumpAndSettleWithTimeout(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await tester.pumpAndSettle(timeout);
}

/// 等待 widget 出现
Future<void> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TimeoutException('Widget not found: $finder', timeout);
}