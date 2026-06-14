import 'dart:io';

import 'package:app_data_migrations/app_data_migrations.dart';

import '../../storage/app_xdg_paths.dart';

/// V002：把渲染器首选项从 data 目录搬到 config 目录。
///
/// 背景：早期版本 `renderer_preferences.ini` 误放在
/// `$XDG_DATA_HOME/<app-id>/startup/`，但渲染器首选项属于**用户配置**，
/// 按 XDG 规范应位于 `$XDG_CONFIG_HOME/<app-id>/startup/`。
/// 本 V 把老用户已存在的配置文件搬到正确位置。
///
/// 幂等性保证：
/// - 旧文件不存在 → 直接返回（全新安装 / 已迁移过 / 用户从未设置过）
/// - 新目录/文件已存在 → 保留新文件，删除旧文件（避免冲突）
/// - 跨文件系统 rename 失败 → 回退到 copy + delete
class V002MigrateRendererPrefsToConfigDir implements Migration {
  V002MigrateRendererPrefsToConfigDir();

  @override
  String get id => 'v002';

  @override
  String get description => '把 renderer_preferences.ini 从 data 搬到 config 目录';

  @override
  Future<void> up() async {
    final oldPath = AppXdgPaths.resolveLegacyRendererConfigFilePath();
    final newPath = AppXdgPaths.resolveRendererConfigFilePath();
    if (oldPath == null || newPath == null) {
      // XDG_DATA_HOME 或 XDG_CONFIG_HOME 解析失败，无法迁移，跳过。
      return;
    }

    final oldFile = File(oldPath);
    if (!await oldFile.exists()) {
      // 旧文件不存在 = 全新安装或已迁移过，幂等返回。
      return;
    }

    final newFile = File(newPath);
    if (await newFile.exists()) {
      // 新文件已存在（用户在新位置已经设置过），保留新文件，删除旧文件。
      await oldFile.delete();
      return;
    }

    final parentDir = newFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    try {
      await oldFile.rename(newPath);
    } on FileSystemException {
      // 跨文件系统 rename 可能失败，回退到 copy + delete。
      await oldFile.copy(newPath);
      await oldFile.delete();
    }
  }
}
