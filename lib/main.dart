import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'application/providers/install_queue_provider.dart';
import 'core/network/api_client.dart';
import 'core/logging/app_logger.dart';
import 'core/platform/single_instance.dart';
import 'core/platform/window_service.dart';
import 'core/config/app_config.dart';
import 'core/storage/cache_service.dart';
import 'core/storage/preferences_service.dart';
import 'presentation/pages/app_detail/screenshot_preview_app.dart';
import 'presentation/pages/app_detail/screenshot_preview_window_payload.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 应用图片缓存限额（Flutter 默认 100MB/1000张，压缩到 64MB/200张）
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      AppConfig.imageCacheSizeBytes;
  PaintingBinding.instance.imageCache.maximumSize = 200;

  // 初始化日志（同步执行）
  await AppLogger.init();

  // window_manager 必须在所有窗口路径（主窗口和子窗口）分支之前初始化，
  // 否则子窗口 Flutter 引擎找不到 channel 实现会抛 MissingPluginException
  await windowManager.ensureInitialized();

  // 子窗口检测：在单实例检测和主窗口初始化之前执行
  // desktop_multi_window 通过 arguments 区分主窗口与子窗口
  final windowController = await WindowController.fromCurrentEngine();
  if (await _tryRunSubWindow(windowController)) {
    return;
  }

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

  // 初始化缓存系统；这里需要同步完成 cache box 打开，
  // 这样后续同步读取缓存时不会触发 “Box not found”。
  await CacheService.init();

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

Future<bool> _tryRunSubWindow(WindowController windowController) async {
  final arguments = windowController.arguments;
  if (arguments.isEmpty) {
    return false;
  }

  final payload = ScreenshotPreviewWindowPayload.tryParseArguments(arguments);
  if (payload != null) {
    await _runScreenshotPreviewWindow(
      windowController: windowController,
      payload: payload,
    );
    return true;
  }

  if (_extractWindowType(arguments) == kScreenshotPreviewWindowType) {
    await _runInvalidScreenshotPreviewWindow();
    return true;
  }

  return false;
}

String? _extractWindowType(String arguments) {
  try {
    final decoded = jsonDecode(arguments);
    if (decoded is Map && decoded['type'] is String) {
      return decoded['type'] as String;
    }
  } catch (_) {
    // 参数损坏时返回 null，由调用方决定是否展示错误窗。
  }
  return null;
}

/// 初始化并运行截图预览子窗口
Future<void> _runScreenshotPreviewWindow({
  required WindowController windowController,
  required ScreenshotPreviewWindowPayload payload,
}) async {
  // 注意：windowManager.ensureInitialized() 已在 main() 顶部统一调用，此处不重复
  // 子窗口：隐藏系统标题栏，使用自定义标题栏
  const windowOptions = WindowOptions(
    size: Size(1100, 700),
    minimumSize: Size(640, 400),
    center: true,
    title: '截图预览',
    backgroundColor: Color(0xFF1C1C28),
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ScreenshotPreviewApp(
      initialPayload: payload,
      windowBinding: DesktopScreenshotPreviewWindowBinding(
        controller: windowController,
      ),
    ),
  );
}

Future<void> _runInvalidScreenshotPreviewWindow() async {
  const windowOptions = WindowOptions(
    size: Size(480, 240),
    minimumSize: Size(420, 220),
    center: true,
    title: '截图预览',
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const ScreenshotPreviewLaunchErrorApp());
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
