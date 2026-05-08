import 'dart:io';

import 'package:path/path.dart' as path;

/// 启动期目录迁移的 warning 回调。
typedef AppDataDirectoryMigrationWarning = void Function(String message);

/// 旧目录清理回调；默认递归删除整个旧目录。
typedef DeleteLegacyDirectory =
    Future<void> Function(Directory legacyDirectory);

/// 将历史 Flutter 数据目录迁移到当前统一的应用数据目录。
class AppDataDirectoryMigration {
  AppDataDirectoryMigration({
    required this.legacyDataDirectoryPath,
    required this.currentDataDirectoryPath,
    AppDataDirectoryMigrationWarning? onWarning,
    DeleteLegacyDirectory? deleteLegacyDirectory,
  }) : _onWarning = onWarning ?? _defaultWarningLogger,
       _deleteLegacyDirectory =
           deleteLegacyDirectory ?? _defaultDeleteLegacyDirectory;

  /// 历史 Flutter Linux application-id，只允许作为迁移来源出现。
  static const String legacyApplicationId = 'org.linglong-store.LinyapsManager';

  /// 当前统一的 application-id，同时也是数据目录名。
  static const String applicationId = 'com.dongpl.linglong-store.v2';

  /// 日志目录名，位于当前数据目录下。
  static const String logsDirectoryName = 'logs';

  /// 默认日志文件名。
  static const String logFileName = 'linglong-store.log';

  final String legacyDataDirectoryPath;
  final String currentDataDirectoryPath;
  final AppDataDirectoryMigrationWarning _onWarning;
  final DeleteLegacyDirectory _deleteLegacyDirectory;

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

  /// 解析当前数据目录路径。
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

  /// 使用当前用户的数据根目录执行默认迁移。
  static Future<void> migrateForCurrentUser({
    AppDataDirectoryMigrationWarning? onWarning,
  }) async {
    final warningLogger = onWarning ?? _defaultWarningLogger;
    final legacyDataDirectoryPath = resolveLegacyDataDirectoryPath();
    final currentDataDirectoryPath = resolveCurrentDataDirectoryPath();

    if (legacyDataDirectoryPath == null || currentDataDirectoryPath == null) {
      warningLogger(
        'Skipping app data directory migration because the data home path '
        'cannot be resolved from XDG_DATA_HOME or HOME.',
      );
      return;
    }

    final migration = AppDataDirectoryMigration(
      legacyDataDirectoryPath: legacyDataDirectoryPath,
      currentDataDirectoryPath: currentDataDirectoryPath,
      onWarning: warningLogger,
    );

    await migration.migrate();
  }

  /// 执行迁移：递归合并旧目录内容，冲突时保留新目录已有文件。
  Future<void> migrate() async {
    final legacyDirectory = Directory(legacyDataDirectoryPath);
    if (!await legacyDirectory.exists()) {
      return;
    }

    final currentDirectory = Directory(currentDataDirectoryPath);
    if (!await currentDirectory.exists()) {
      await currentDirectory.create(recursive: true);
    }

    await _migrateDirectoryContents(
      sourceDirectory: legacyDirectory,
      targetDirectory: currentDirectory,
    );
    await _deleteLegacyDirectorySafely(legacyDirectory);
  }

  Future<void> _migrateDirectoryContents({
    required Directory sourceDirectory,
    required Directory targetDirectory,
  }) async {
    await for (final entity in sourceDirectory.list(followLinks: false)) {
      final entityName = path.basename(entity.path);
      final targetPath = path.join(targetDirectory.path, entityName);

      if (entity is Directory) {
        await _migrateDirectory(entity, Directory(targetPath));
        continue;
      }

      if (entity is File) {
        await _migrateFile(entity, File(targetPath));
        continue;
      }

      // 只迁移常规文件与目录，其他条目保守跳过并记录 warning。
      _onWarning('Skipping unsupported legacy data entry: ${entity.path}');
    }
  }

  Future<void> _migrateDirectory(
    Directory sourceDirectory,
    Directory targetDirectory,
  ) async {
    final targetExists = await _pathExists(targetDirectory.path);
    if (!targetExists) {
      await targetDirectory.create(recursive: true);
    } else if (!await targetDirectory.exists()) {
      _onWarning(
        'Skipping legacy directory ${sourceDirectory.path} because '
        'a non-directory entry already exists at ${targetDirectory.path}.',
      );
      return;
    }

    await _migrateDirectoryContents(
      sourceDirectory: sourceDirectory,
      targetDirectory: targetDirectory,
    );
  }

  Future<void> _migrateFile(File sourceFile, File targetFile) async {
    // 目标文件已存在时必须保留现有内容，避免覆盖用户当前目录数据。
    if (await _pathExists(targetFile.path)) {
      return;
    }

    final parentDirectory = targetFile.parent;
    if (!await parentDirectory.exists()) {
      await parentDirectory.create(recursive: true);
    }

    try {
      await sourceFile.rename(targetFile.path);
    } on FileSystemException {
      // 跨文件系统 rename 可能失败，回退到 copy + delete 保证迁移可完成。
      await sourceFile.copy(targetFile.path);
      await sourceFile.delete();
    }
  }

  Future<void> _deleteLegacyDirectorySafely(Directory legacyDirectory) async {
    try {
      await _deleteLegacyDirectory(legacyDirectory);
    } on FileSystemException catch (error) {
      _onWarning(
        'Failed to delete legacy data directory ${legacyDirectory.path}: '
        '${error.message}',
      );
    } catch (error) {
      _onWarning(
        'Failed to delete legacy data directory ${legacyDirectory.path}: '
        '$error',
      );
    }
  }

  Future<bool> _pathExists(String targetPath) async {
    final entityType = await FileSystemEntity.type(
      targetPath,
      followLinks: false,
    );
    return entityType != FileSystemEntityType.notFound;
  }

  static Future<void> _defaultDeleteLegacyDirectory(Directory legacyDirectory) {
    return legacyDirectory.delete(recursive: true);
  }

  static void _defaultWarningLogger(String message) {
    stderr.writeln(message);
  }
}
