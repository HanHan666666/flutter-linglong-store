import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// 测试配置文件
///
/// 这个文件会在所有测试运行之前执行
/// 用于设置全局测试配置

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 配置 Golden 测试
  // 在 CI 环境中可能需要设置 golden 文件的基准目录

  // 运行测试
  await testMain();
}