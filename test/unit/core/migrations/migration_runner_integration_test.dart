import 'dart:io';

import 'package:app_data_migrations/app_data_migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:linglong_store/core/migrations/file_migration_lock.dart';

/// 假迁移脚本，用于集成测试。
class _FakeMigration implements Migration {
  _FakeMigration(this.id, {this.behavior});

  @override
  final String id;

  @override
  String get description => 'fake-$id';

  final Future<void> Function()? behavior;
  bool invoked = false;

  @override
  Future<void> up() async {
    invoked = true;
    if (behavior != null) await behavior!();
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('integration_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Runner + 框架内置 FileRepository + 业务层 Lock 端到端跑通', () async {
    final repo = FileMigrationStateRepository(
      File(p.join(tempDir.path, 'state.json')),
    );
    final lock = FileMigrationLock(File(p.join(tempDir.path, '.lock')));

    final migrations = [_FakeMigration('v001'), _FakeMigration('v002')];
    final runner = MigrationRunner(
      repository: repo,
      migrations: migrations,
      lock: lock,
    );

    final result = await runner.run();

    expect(result.applied.map((r) => r.id), ['v001', 'v002']);
    expect(migrations.every((m) => m.invoked), isTrue);
    expect(await repo.loadApplied(), containsAll(['v001', 'v002']));
  });

  test('注册表为空时正确返回空结果', () async {
    final repo = FileMigrationStateRepository(
      File(p.join(tempDir.path, 'state.json')),
    );
    final lock = FileMigrationLock(File(p.join(tempDir.path, '.lock')));

    final runner = MigrationRunner(
      repository: repo,
      migrations: const [],
      lock: lock,
    );

    final result = await runner.run();
    expect(result.applied, isEmpty);
    expect(result.skipped, isEmpty);
  });

  test('单点失败抛 MigrationFailedException 并停止后续', () async {
    final repo = FileMigrationStateRepository(
      File(p.join(tempDir.path, 'state.json')),
    );
    final lock = FileMigrationLock(File(p.join(tempDir.path, '.lock')));

    final migrations = [
      _FakeMigration('v001'),
      _FakeMigration(
        'v002',
        behavior: () async {
          throw StateError('boom');
        },
      ),
      _FakeMigration('v003'),
    ];
    final runner = MigrationRunner(
      repository: repo,
      migrations: migrations,
      lock: lock,
    );

    await expectLater(
      runner.run(),
      throwsA(
        isA<MigrationFailedException>()
            .having((e) => e.failedMigrationId, 'failedMigrationId', 'v002'),
      ),
    );

    expect(await repo.loadApplied(), ['v001']);
    expect(migrations[2].invoked, isFalse);
  });

  test('已应用的迁移在第二次 run 时被跳过', () async {
    final stateFile = File(p.join(tempDir.path, 'state.json'));
    final repo = FileMigrationStateRepository(stateFile);
    final lock = FileMigrationLock(File(p.join(tempDir.path, '.lock')));

    final migrations = [_FakeMigration('v001'), _FakeMigration('v002')];
    final runner = MigrationRunner(
      repository: repo,
      migrations: migrations,
      lock: lock,
    );

    // 第一次：应用全部
    await runner.run();
    expect(migrations.every((m) => m.invoked), isTrue);

    // 第二次：所有都已被应用，全部跳过
    migrations[0].invoked = false;
    migrations[1].invoked = false;
    final result2 = await runner.run();
    expect(result2.applied, isEmpty);
    expect(result2.skipped, ['v001', 'v002']);
    expect(migrations.every((m) => !m.invoked), isTrue);
  });
}
