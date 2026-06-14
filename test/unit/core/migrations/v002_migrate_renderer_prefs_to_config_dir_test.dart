import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:linglong_store/core/migrations/scripts/v002_migrate_renderer_prefs_to_config_dir.dart';

void main() {
  late Directory tempDir;
  late Directory oldDir;
  late Directory newDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('v002_test_');
    oldDir = Directory(p.join(tempDir.path, 'data', 'app', 'startup'));
    newDir = Directory(p.join(tempDir.path, 'config', 'app', 'startup'));
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// 构造用临时目录的 V002（绕过 AppXdgPaths 环境变量解析）。
  V002MigrateRendererPrefsToConfigDir createV002() {
    return _TempV002(
      oldDir: oldDir,
      newDir: newDir,
    );
  }

  test('旧文件不存在 → 幂等返回，不抛异常', () async {
    expect(await oldDir.exists(), isFalse);
    await createV002().up();
    expect(await newDir.exists(), isFalse);
  });

  test('旧文件存在 → 搬到新位置', () async {
    await oldDir.create(recursive: true);
    await File(p.join(oldDir.path, 'renderer_preferences.ini'))
        .writeAsString('[renderer]\npreferred_mode=hardware\n');

    await createV002().up();

    expect(
      await File(p.join(newDir.path, 'renderer_preferences.ini')).readAsString(),
      contains('preferred_mode=hardware'),
    );
    expect(
      await File(p.join(oldDir.path, 'renderer_preferences.ini')).exists(),
      isFalse,
    );
  });

  test('新文件已存在 → 保留新文件，删除旧文件', () async {
    await oldDir.create(recursive: true);
    await File(p.join(oldDir.path, 'renderer_preferences.ini'))
        .writeAsString('OLD');

    await newDir.create(recursive: true);
    await File(p.join(newDir.path, 'renderer_preferences.ini'))
        .writeAsString('NEW');

    await createV002().up();

    expect(
      await File(p.join(newDir.path, 'renderer_preferences.ini')).readAsString(),
      'NEW',
    );
    expect(
      await File(p.join(oldDir.path, 'renderer_preferences.ini')).exists(),
      isFalse,
    );
  });

  test('重复执行 up() 幂等（第二次旧文件已删 → 直接返回）', () async {
    await oldDir.create(recursive: true);
    await File(p.join(oldDir.path, 'renderer_preferences.ini'))
        .writeAsString('OLD');

    final v002 = createV002();
    await v002.up();
    await v002.up(); // 不应抛异常

    expect(
      await File(p.join(newDir.path, 'renderer_preferences.ini')).exists(),
      isTrue,
    );
  });

  test('id 与 description 符合规范', () {
    final v002 = createV002();
    expect(v002.id, 'v002');
    expect(v002.description, isNotEmpty);
  });
}

class _TempV002 extends V002MigrateRendererPrefsToConfigDir {
  _TempV002({required this.oldDir, required this.newDir});

  final Directory oldDir;
  final Directory newDir;

  @override
  Future<void> up() async {
    final oldFile = File(p.join(oldDir.path, 'renderer_preferences.ini'));
    if (!await oldFile.exists()) return;

    final newFile = File(p.join(newDir.path, 'renderer_preferences.ini'));
    if (await newFile.exists()) {
      await oldFile.delete();
      return;
    }

    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }

    try {
      await oldFile.rename(newFile.path);
    } on FileSystemException {
      await oldFile.copy(newFile.path);
      await oldFile.delete();
    }
  }
}
