import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'application/providers/install_queue_provider.dart';
import 'core/network/api_client.dart';
import 'core/logging/app_logger.dart';
import 'core/platform/single_instance.dart';
import 'core/platform/window_service.dart';
import 'core/storage/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志（同步执行）
  await AppLogger.init();

  // 单实例检测：必须在窗口初始化之前执行
  // 如果已有实例运行，激活其窗口并退出当前实例
  final isFirstInstance = await SingleInstance.ensure();
  if (!isFirstInstance) {
    AppLogger.info('Another instance is running, exiting...');
    exit(0);
  }

  // 初始化窗口管理器
  await WindowService.init();

  // 初始化 SharedPreferences
  await PreferencesService.init();
  final sharedPreferences = await SharedPreferences.getInstance();

  // 初始化网络客户端，避免 Provider 首次读取时访问未初始化的 Dio 单例
  ApiClient.init(
    localeGetter: () =>
        sharedPreferences.getString('linglong-store-language') ?? 'zh',
  );

  // 初始化 Hive（用于缓存）
  await Hive.initFlutter();

  // 显示窗口
  await WindowService.show();

  // 注册退出时的清理回调
  _registerExitHandler();

  runApp(
    ProviderScope(
      overrides: [
        // 注入 SharedPreferences 实例
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const LinglongStoreApp(),
    ),
  );
}

/// 注册退出时的清理回调
void _registerExitHandler() {
  // 监听进程信号，优雅退出
  ProcessSignal.sigterm.watch().listen((_) async {
    AppLogger.info('Received SIGTERM, cleaning up...');
    await SingleInstance.dispose();
    exit(0);
  });

  ProcessSignal.sigint.watch().listen((_) async {
    AppLogger.info('Received SIGINT, cleaning up...');
    await SingleInstance.dispose();
    exit(0);
  });
}
