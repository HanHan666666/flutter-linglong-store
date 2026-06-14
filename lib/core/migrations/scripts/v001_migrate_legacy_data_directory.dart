import 'dart:io';

import 'package:app_data_migrations/app_data_migrations.dart';
import 'package:path/path.dart' as path;

import '../../storage/app_xdg_paths.dart';

/// V001：把历史 application-id 数据目录迁移到当前 application-id 目录。
///
/// 背景：项目从 `org.linglong-store.LinyapsManager` 改名为
/// `com.dongpl.linglong-store.v2`，需要把旧目录里的 SharedPreferences /
/// Hive / 日志等用户数据搬到新目录，避免用户升级后数据丢失。
///
/// 幂等性保证（参考 [doc/03-迁移脚本编写指南.md] 的硬性要求）：
/// - 旧目录不存在 → 直接返回（已迁移过 / 全新安装 / 旧版本从未启动过）
/// - 新目录不存在 → 自动创建
/// - 同名文件冲突 → 保留新目录已有文件，跳过旧目录的同名文件
/// - 跨文件系统 rename 失败 → 回退到 copy + delete
///
/// 此 V 必须在所有依赖应用数据目录的服务初始化之前执行（AppLogger
/// 除外，因为日志是写入流、新目录会被 AppLogger 自动创建；新目录里
/// 本来就没有旧日志文件可丢）。
class V001MigrateLegacyDataDirectory implements Migration {
  V001MigrateLegacyDataDirectory({void Function(String)? onWarning})
      : _onWarning = onWarning ?? _defaultWarningLogger;

  /// 迁移过程中遇到无法处理的条目时调用（默认打印到 stderr）。
  final void Function(String) _onWarning;

  @override
  String get id => 'v001';

  @override
  String get description => '把旧 application-id 数据目录迁移到当前目录';

  @override
  Future<void> up() async {
    final legacyDataDirectoryPath =
        AppXdgPaths.resolveLegacyAppDataDirectory();
    final currentDataDirectoryPath =
        AppXdgPaths.resolveAppDataDirectory();

    if (legacyDataDirectoryPath == null || currentDataDirectoryPath == null) {
      _onWarning(
        '无法解析数据目录路径（XDG_DATA_HOME 或 HOME 缺失），跳过目录迁移。',
      );
      return;
    }

    final legacyDirectory = Directory(legacyDataDirectoryPath);
    if (!await legacyDirectory.exists()) {
      // 旧目录不存在 = 全新安装或已迁移过，幂等返回。
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
    // 例如：AppLogger 已经在新目录创建了 linglong-store.log，不能被旧日志覆盖。
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
      await legacyDirectory.delete(recursive: true);
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

  static void _defaultWarningLogger(String message) {
    stderr.writeln(message);
  }
}
