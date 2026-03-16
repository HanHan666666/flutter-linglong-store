import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'application/providers/global_provider.dart';
import 'application/providers/install_queue_provider.dart';
import 'application/providers/launch_provider.dart';
import 'application/providers/setting_provider.dart';
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

/// 应用初始化 Widget
///
/// 负责在应用启动时初始化所有 Provider
class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // 将 Provider 初始化延后到首帧之后，避免在 widget tree 首次构建期间
    // 写入 Provider 状态，触发 Riverpod 的 lifecycle 保护异常。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initApp();
    });
  }

  Future<void> _initApp() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);

      // 初始化全局状态 Provider
      await ref.read(globalAppProvider.notifier).init(prefs);

      // 初始化安装队列 Provider
      await ref.read(installQueueProvider.notifier).init(prefs);

      // 初始化设置 Provider
      await ref.read(settingProvider.notifier).init(prefs);

      // 初始化启动序列 Provider
      await ref.read(launchSequenceProvider.notifier).init(prefs);

      setState(() {
        _initialized = true;
      });

      AppLogger.info('App initialized successfully');
    } catch (e, s) {
      AppLogger.error('Failed to initialize app', e, s);
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    '初始化失败',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _initialized = false;
                      });
                      _initApp();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('正在初始化...', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    }

    // 返回子组件（MaterialApp.router），由路由控制显示 LaunchPage 或主页
    return widget.child;
  }
}
