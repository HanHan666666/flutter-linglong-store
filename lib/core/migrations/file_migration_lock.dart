import 'dart:io';

import 'package:app_data_migrations/app_data_migrations.dart';

/// 基于 [File.lock] 的跨进程并发锁实现。
///
/// 在多窗口（多进程）同时启动场景下，保证同一时间只有一个进程能执行迁移。
/// 内部使用 `dart:io` 的 `RandomAccessFile.lock(FileLock.blockingExclusive)`，
/// 等价于 POSIX flock 排他锁。
///
/// 默认超时 5 分钟。超时会抛 [Timeout]。
class FileMigrationLock implements MigrationLock {
  FileMigrationLock(
    this.lockFile, {
    this.timeout = const Duration(minutes: 5),
  });

  /// 锁文件路径。建议放在应用数据目录下，
  /// 例如 `~/.local/share/com.dongpl.linglong-store.v2/.migration.lock`。
  final File lockFile;

  /// 等锁超时时间。
  final Duration timeout;

  @override
  Future<T> synchronized<T>(Future<T> Function() action) async {
    // 确保锁文件存在
    if (!await lockFile.exists()) {
      await lockFile.parent.create(recursive: true);
      await lockFile.create(recursive: true);
    }

    final raf = await lockFile.open(mode: FileMode.write);
    try {
      // 阻塞等待独占锁
      await raf.lock(FileLock.blockingExclusive).timeout(timeout);
      return await action();
    } finally {
      // 进程退出时 OS 自动释放锁，unlock 失败可忽略
      try {
        await raf.unlock();
      } catch (_) {
        // 忽略
      }
      await raf.close();
    }
  }
}
