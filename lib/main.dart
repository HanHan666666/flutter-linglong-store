import 'dart:io';

import 'package:app_data_migrations/app_data_migrations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'application/providers/og_install_controller.dart';
import 'application/providers/install_queue_provider.dart';
import 'core/logging/app_logger.dart';
import 'core/migrations/file_migration_lock.dart';
import 'core/migrations/migrations.dart';
import 'core/network/api_client.dart';
import 'core/protocol/og_protocol_request.dart';
import 'core/platform/single_instance.dart';
import 'core/platform/window_service.dart';
import 'core/config/app_config.dart';
import 'core/storage/app_data_directory_paths.dart';
import 'core/storage/cache_service.dart';
import 'core/storage/preferences_service.dart';

void main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 应用图片缓存限额（Flutter 默认 100MB/1000张，压缩到 64MB/200张）
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      AppConfig.imageCacheSizeBytes;
  PaintingBinding.instance.imageCache.maximumSize = 200;

  // 初始化日志（同步执行）。
  // AppLogger 内部会自动创建当前应用数据目录的 logs/ 子目录，
  // 日志写入新 application_id 目录，不依赖目录迁移完成。
  await AppLogger.init();

  // 冷启动时 XDG 会通过 desktop Exec 的 %u 把 og 链接传进来。
  // 这里只筛选旧协议链接，普通启动参数不进入安装流程，避免误触发提示。
  final initialOgProtocolUrls = arguments
      .where((argument) => OgProtocolRequest.tryParse(argument) != null)
      .toList(growable: false);

  // 单实例检测：必须在窗口初始化之前执行
  // 如果已有实例运行，激活其窗口并退出当前实例
  final isFirstInstance = await SingleInstance.ensure(arguments);
  if (!isFirstInstance) {
    AppLogger.info('Another instance is running, exiting...');
    exit(0);
  }

  // 初始化窗口管理器
  await WindowService.init();

  // 执行数据迁移：必须在 SharedPreferences/ApiClient/CacheService 等任何依赖
  // 应用数据目录的服务初始化之前执行。app_data_migrations 框架自带
  // FileMigrationStateRepository，不依赖 SharedPreferences，可在这一步执行
  // V001（目录迁移）以及后续业务级 V。
  await _runMigrations();

  // 初始化 SharedPreferences（V001 已把旧目录的 shared_preferences.json
  // 搬到新目录，这里能读到用户历史数据）
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
        // 注入冷启动阶段收到的旧 og 协议链接，App 层会等启动流程完成后入队。
        initialOgProtocolUrlsProvider.overrideWithValue(initialOgProtocolUrls),
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

/// 执行数据迁移。
///
/// 时机：必须在 [PreferencesService.init] / [ApiClient.init] / [CacheService.init]
/// 等任何依赖应用数据目录的服务初始化之前执行。
///
/// 实现细节：
/// - Repository 用框架内置 [FileMigrationStateRepository]，状态文件位于
///   `$XDG_DATA_HOME/<当前AppID>/.migration_state.json`，符合 XDG 标准。
/// - 锁用业务侧 [FileMigrationLock]，锁文件位于
///   `$XDG_DATA_HOME/<当前AppID>/.migration.lock`，基于 POSIX flock。
/// - 任意一个 V 脚本失败都会抛 [MigrationFailedException]，此处记录详细
///   日志后退出进程，避免在不一致状态下继续启动。
/// - 启动阶段无 Flutter UI 上下文，无法弹窗兜底。如需 UI 提示，可改为在
///   runApp 后第一个画面里执行迁移，但本项目选择"启动失败即退出"的简单策略。
Future<void> _runMigrations() async {
  final stateFilePath =
      AppDataDirectoryPaths.resolveMigrationStateFilePath();
  final lockFilePath =
      AppDataDirectoryPaths.resolveMigrationLockFilePath();
  if (stateFilePath == null || lockFilePath == null) {
    AppLogger.warning(
      '无法解析应用数据目录，跳过数据迁移。这可能导致旧数据无法被迁移到新版本。',
    );
    return;
  }

  final repo = FileMigrationStateRepository(File(stateFilePath));
  final lock = FileMigrationLock(File(lockFilePath));

  final runner = MigrationRunner(
    repository: repo,
    migrations: appMigrations,
    lock: lock,
  );

  try {
    final result = await runner.run();
    AppLogger.info(
      '迁移完成: 应用 ${result.applied.length} 个 / 跳过 ${result.skipped.length} 个',
    );
    for (final record in result.applied) {
      AppLogger.info(
        '  - ${record.id} (${record.elapsed}): ${record.description}',
      );
    }
  } on MigrationFailedException catch (e, st) {
    AppLogger.error(
      '迁移失败: ${e.failedMigrationId}',
      e.cause,
      st,
    );
    exit(1);
  } on MigrationIdConflictException catch (e, st) {
    AppLogger.error(
      '迁移注册表 id 冲突: ${e.conflictingId}',
      e,
      st,
    );
    exit(1);
  }
}
