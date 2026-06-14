import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:linglong_store/core/migrations/file_migration_lock.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_migration_lock_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('首次进入会创建锁文件并执行 action', () async {
    final lockFile = File(p.join(tempDir.path, '.lock'));
    final lock = FileMigrationLock(lockFile);

    var executed = false;
    final result = await lock.synchronized(() async {
      executed = true;
      return 42;
    });

    expect(executed, isTrue);
    expect(result, 42);
    expect(await lockFile.exists(), isTrue);
  });

  test('action 抛异常时锁被正确释放', () async {
    final lockFile = File(p.join(tempDir.path, '.lock'));
    final lock = FileMigrationLock(lockFile);

    await expectLater(
      lock.synchronized(() async {
        throw StateError('boom');
      }),
      throwsA(isA<StateError>()),
    );

    // 锁应已释放，可再次进入
    var executed = false;
    await lock.synchronized(() async {
      executed = true;
    });
    expect(executed, isTrue);
  });

  test('返回值正确传递', () async {
    final lockFile = File(p.join(tempDir.path, '.lock'));
    final lock = FileMigrationLock(lockFile);
    final result = await lock.synchronized(() async => 'hello');
    expect(result, 'hello');
  });
}
