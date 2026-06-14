import 'dart:io';

import 'package:path/path.dart' as path;

/// 应用数据目录路径解析 helper。
///
/// 仅负责路径解析（纯函数，不涉及任何 IO 操作），不承担目录迁移职责。
/// 目录迁移逻辑由 [V001MigrateLegacyDataDirectory] 通过 app_data_migrations
/// 框架统一管理，在应用启动早期执行。
///
/// 被 AppLogger、LinuxRendererService、main.dart 等多处依赖，用于定位
/// 日志文件、配置文件、迁移状态文件、迁移锁文件等。
class AppDataDirectoryPaths {
  AppDataDirectoryPaths._();

  /// 历史 Flutter Linux application-id，只允许作为迁移来源出现。
  static const String legacyApplicationId = 'org.linglong-store.LinyapsManager';

  /// 当前统一的 application-id，同时也是数据目录名。
  static const String applicationId = 'com.dongpl.linglong-store.v2';

  /// 日志目录名，位于当前数据目录下。
  static const String logsDirectoryName = 'logs';

  /// 默认日志文件名。
  static const String logFileName = 'linglong-store.log';

  /// 迁移状态文件名（app_data_migrations 框架的 Repository 用）。
  static const String migrationStateFileName = '.migration_state.json';

  /// 迁移锁文件名（app_data_migrations 框架的 FileLock 用）。
  static const String migrationLockFileName = '.migration.lock';

  /// 解析 Linux 数据根目录：优先 XDG_DATA_HOME，其次回退到 HOME/.local/share。
  static String? resolveDataHomeDirectoryPath({
    Map<String, String>? environment,
  }) {
    final resolvedEnvironment = environment ?? Platform.environment;
    final xdgDataHome = resolvedEnvironment['XDG_DATA_HOME'];
    if (xdgDataHome != null && xdgDataHome.isNotEmpty) {
      return xdgDataHome;
    }

    final homeDirectoryPath = resolvedEnvironment['HOME'];
    if (homeDirectoryPath == null || homeDirectoryPath.isEmpty) {
      return null;
    }

    return path.join(homeDirectoryPath, '.local', 'share');
  }

  /// 解析历史数据目录路径。
  static String? resolveLegacyDataDirectoryPath({
    Map<String, String>? environment,
  }) {
    final dataHomeDirectoryPath = resolveDataHomeDirectoryPath(
      environment: environment,
    );
    if (dataHomeDirectoryPath == null || dataHomeDirectoryPath.isEmpty) {
      return null;
    }

    return path.join(dataHomeDirectoryPath, legacyApplicationId);
  }

  /// 解析当前数据目录路径（$XDG_DATA_HOME/<当前AppID>）。
  static String? resolveCurrentDataDirectoryPath({
    Map<String, String>? environment,
  }) {
    final dataHomeDirectoryPath = resolveDataHomeDirectoryPath(
      environment: environment,
    );
    if (dataHomeDirectoryPath == null || dataHomeDirectoryPath.isEmpty) {
      return null;
    }

    return path.join(dataHomeDirectoryPath, applicationId);
  }

  /// 解析当前日志文件路径，让日志与 SharedPreferences/Hive 共享同一数据根目录。
  static String? resolveCurrentLogFilePath({Map<String, String>? environment}) {
    final currentDataDirectoryPath = resolveCurrentDataDirectoryPath(
      environment: environment,
    );
    if (currentDataDirectoryPath == null || currentDataDirectoryPath.isEmpty) {
      return null;
    }

    return path.join(currentDataDirectoryPath, logsDirectoryName, logFileName);
  }

  /// 解析迁移状态文件路径。
  ///
  /// 文件位于当前应用数据目录下，符合 XDG 标准。app_data_migrations 框架的
  /// [FileMigrationStateRepository] 使用此路径。
  static String? resolveMigrationStateFilePath({
    Map<String, String>? environment,
  }) {
    final currentDataDirectoryPath = resolveCurrentDataDirectoryPath(
      environment: environment,
    );
    if (currentDataDirectoryPath == null || currentDataDirectoryPath.isEmpty) {
      return null;
    }

    return path.join(currentDataDirectoryPath, migrationStateFileName);
  }

  /// 解析迁移锁文件路径。
  ///
  /// 文件位于当前应用数据目录下。[FileMigrationLock] 使用此路径。
  static String? resolveMigrationLockFilePath({
    Map<String, String>? environment,
  }) {
    final currentDataDirectoryPath = resolveCurrentDataDirectoryPath(
      environment: environment,
    );
    if (currentDataDirectoryPath == null || currentDataDirectoryPath.isEmpty) {
      return null;
    }

    return path.join(currentDataDirectoryPath, migrationLockFileName);
  }
}
