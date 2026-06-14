import 'dart:io';

import 'package:path/path.dart' as path;

/// 应用 XDG 标准路径解析 helper。
///
/// 严格遵循 [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/)：
/// - **数据**（持久化、用户数据）：`$XDG_DATA_HOME`（默认 `$HOME/.local/share`）
/// - **配置**（用户设置、首选项）：`$XDG_CONFIG_HOME`（默认 `$HOME/.config`）
/// - **缓存**（可重新生成、可删除）：`$XDG_CACHE_HOME`（默认 `$HOME/.cache`）
/// - **运行时**（sockets/locks、文件必须 0700）：`$XDG_RUNTIME_DIR`（systemd 设置）
///
/// 应用子目录统一以 application-id 命名，避免与其他应用冲突。
///
/// 仅负责路径解析（纯函数，不涉及任何 IO 操作）。
class AppXdgPaths {
  AppXdgPaths._();

  // === 应用身份 ===

  /// 历史 Flutter Linux application-id，只允许作为迁移来源出现。
  static const String legacyApplicationId = 'org.linglong-store.LinyapsManager';

  /// 当前统一的 application-id，同时也是数据目录名。
  static const String applicationId = 'com.dongpl.linglong-store.v2';

  // === 子目录与文件名 ===

  static const String logsDirectoryName = 'logs';
  static const String logFileName = 'linglong-store.log';
  static const String migrationStateFileName = '.migration_state.json';
  static const String migrationLockFileName = '.migration.lock';
  static const String singleInstanceLockFileName = 'linglong-store.lock';
  static const String singleInstanceSocketFileName = 'linglong-store.sock';

  // === XDG 根目录解析 ===

  /// `$XDG_DATA_HOME`，未设置时回退到 `$HOME/.local/share`。
  /// HOME 也缺失时返回 null。
  static String? resolveDataHome({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    final xdg = env['XDG_DATA_HOME'];
    if (xdg != null && xdg.isNotEmpty) return xdg;
    return _homeFallback(env, const ['.local', 'share']);
  }

  /// `$XDG_CONFIG_HOME`，未设置时回退到 `$HOME/.config`。
  static String? resolveConfigHome({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    final xdg = env['XDG_CONFIG_HOME'];
    if (xdg != null && xdg.isNotEmpty) return xdg;
    return _homeFallback(env, const ['.config']);
  }

  /// `$XDG_CACHE_HOME`，未设置时回退到 `$HOME/.cache`。
  static String? resolveCacheHome({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    final xdg = env['XDG_CACHE_HOME'];
    if (xdg != null && xdg.isNotEmpty) return xdg;
    return _homeFallback(env, const ['.cache']);
  }

  /// `$XDG_RUNTIME_DIR`（systemd 管理，权限 0700）。
  /// 未设置时返回 null，调用方自行决定回退策略。
  static String? resolveRuntimeDir({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    final xdg = env['XDG_RUNTIME_DIR'];
    if (xdg == null || xdg.isEmpty) return null;
    return xdg;
  }

  /// 解析 `$HOME` + 子路径回退。HOME 缺失时返回 null。
  static String? _homeFallback(Map<String, String> env, List<String> suffix) {
    final home = env['HOME'];
    if (home == null || home.isEmpty) return null;
    return path.joinAll(<String>[home, ...suffix]);
  }

  // === 应用级目录（拼接 application-id） ===

  /// 应用数据目录：`$XDG_DATA_HOME/<app-id>/`。
  static String? resolveAppDataDirectory({Map<String, String>? environment}) {
    final dataHome = resolveDataHome(environment: environment);
    if (dataHome == null || dataHome.isEmpty) return null;
    return path.join(dataHome, applicationId);
  }

  /// 应用配置目录：`$XDG_CONFIG_HOME/<app-id>/`。
  static String? resolveAppConfigDirectory({Map<String, String>? environment}) {
    final configHome = resolveConfigHome(environment: environment);
    if (configHome == null || configHome.isEmpty) return null;
    return path.join(configHome, applicationId);
  }

  /// 应用缓存目录：`$XDG_CACHE_HOME/<app-id>/`。
  static String? resolveAppCacheDirectory({Map<String, String>? environment}) {
    final cacheHome = resolveCacheHome(environment: environment);
    if (cacheHome == null || cacheHome.isEmpty) return null;
    return path.join(cacheHome, applicationId);
  }

  /// 应用运行时目录：`$XDG_RUNTIME_DIR/<app-id>/`。
  /// `$XDG_RUNTIME_DIR` 未设置时返回 null。
  static String? resolveAppRuntimeDirectory({
    Map<String, String>? environment,
  }) {
    final runtimeDir = resolveRuntimeDir(environment: environment);
    if (runtimeDir == null || runtimeDir.isEmpty) return null;
    return path.join(runtimeDir, applicationId);
  }

  // === 历史目录（仅用于 V001 迁移） ===

  /// 旧 application-id 数据目录：`$XDG_DATA_HOME/<legacy-app-id>/`。
  static String? resolveLegacyAppDataDirectory({
    Map<String, String>? environment,
  }) {
    final dataHome = resolveDataHome(environment: environment);
    if (dataHome == null || dataHome.isEmpty) return null;
    return path.join(dataHome, legacyApplicationId);
  }

  // === 具体文件路径 ===

  /// 当前日志文件：`$XDG_DATA_HOME/<app-id>/logs/linglong-store.log`。
  static String? resolveCurrentLogFilePath({
    Map<String, String>? environment,
  }) {
    final dir = resolveLogsDirectoryPath(environment: environment);
    if (dir == null || dir.isEmpty) return null;
    return path.join(dir, logFileName);
  }

  /// 日志目录：`$XDG_DATA_HOME/<app-id>/logs/`。
  static String? resolveLogsDirectoryPath({Map<String, String>? environment}) {
    final appData = resolveAppDataDirectory(environment: environment);
    if (appData == null || appData.isEmpty) return null;
    return path.join(appData, logsDirectoryName);
  }

  /// 迁移状态文件：`$XDG_DATA_HOME/<app-id>/.migration_state.json`。
  static String? resolveMigrationStateFilePath({
    Map<String, String>? environment,
  }) {
    final appData = resolveAppDataDirectory(environment: environment);
    if (appData == null || appData.isEmpty) return null;
    return path.join(appData, migrationStateFileName);
  }

  /// 迁移锁文件：`$XDG_DATA_HOME/<app-id>/.migration.lock`。
  static String? resolveMigrationLockFilePath({
    Map<String, String>? environment,
  }) {
    final appData = resolveAppDataDirectory(environment: environment);
    if (appData == null || appData.isEmpty) return null;
    return path.join(appData, migrationLockFileName);
  }

  /// 单实例锁文件：`$XDG_RUNTIME_DIR/<app-id>/linglong-store.lock`。
  /// `$XDG_RUNTIME_DIR` 未设置时返回 null（调用方需回退，如 `/tmp`）。
  static String? resolveSingleInstanceLockFilePath({
    Map<String, String>? environment,
  }) {
    final runtime = resolveAppRuntimeDirectory(environment: environment);
    if (runtime == null || runtime.isEmpty) return null;
    return path.join(runtime, singleInstanceLockFileName);
  }

  /// 单实例 socket 文件：`$XDG_RUNTIME_DIR/<app-id>/linglong-store.sock`。
  /// `$XDG_RUNTIME_DIR` 未设置时返回 null。
  static String? resolveSingleInstanceSocketFilePath({
    Map<String, String>? environment,
  }) {
    final runtime = resolveAppRuntimeDirectory(environment: environment);
    if (runtime == null || runtime.isEmpty) return null;
    return path.join(runtime, singleInstanceSocketFileName);
  }

  /// 渲染器首选项配置文件：`$XDG_CONFIG_HOME/<app-id>/startup/renderer_preferences.ini`。
  static String? resolveRendererConfigFilePath({
    Map<String, String>? environment,
  }) {
    final appConfig = resolveAppConfigDirectory(environment: environment);
    if (appConfig == null || appConfig.isEmpty) return null;
    return path.join(appConfig, 'startup', 'renderer_preferences.ini');
  }

  /// 渲染器首选项旧路径（V002 之前在 data 目录下）。
  /// 仅用于 V002 迁移来源识别，禁止新代码直接使用。
  static String? resolveLegacyRendererConfigFilePath({
    Map<String, String>? environment,
  }) {
    final appData = resolveAppDataDirectory(environment: environment);
    if (appData == null || appData.isEmpty) return null;
    return path.join(appData, 'startup', 'renderer_preferences.ini');
  }
}
