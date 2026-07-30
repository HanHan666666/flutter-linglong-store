/// 使用 XDG State 目录中的单文件实现应用操作 Journal。
///
/// 该实现只在启动时同步读取；运行期间只保留正在写入和等待写入的最新快照，
/// 并通过同目录临时文件原子替换正式文件，避免高频进度形成无界 IO 队列。
library;

import 'dart:convert';
import 'dart:io';

import '../../core/logging/app_logger.dart';
import '../../domain/models/app_operation_journal_snapshot.dart';
import '../../domain/repositories/app_operation_journal_repository.dart';
import '../persistence/latest_value_write_queue.dart';

/// 基于本地 JSON 文件的应用操作 Journal 仓库。
class FileAppOperationJournalRepository
    implements AppOperationJournalRepository {
  /// 使用已经按 XDG 规则解析的目标文件创建仓库。
  FileAppOperationJournalRepository(this._journalFile) {
    _writeQueue = LatestValueWriteQueue<AppOperationJournalSnapshot>(
      _writeSnapshot,
    );
  }

  /// 正式 Journal 文件。
  final File _journalFile;

  /// 合并尚未开始的中间状态，确保写入积压始终有界。
  late final LatestValueWriteQueue<AppOperationJournalSnapshot> _writeQueue;

  @override
  AppOperationJournalSnapshot? load() {
    if (!_journalFile.existsSync()) {
      return null;
    }

    try {
      final decoded = jsonDecode(_journalFile.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('应用操作 Journal 根节点不是对象');
      }
      return AppOperationJournalSnapshot.fromVersionedJson(decoded);
    } catch (error, stackTrace) {
      _preserveCorruptedSnapshot(error, stackTrace);
      return const AppOperationJournalSnapshot();
    }
  }

  @override
  Future<void> save(AppOperationJournalSnapshot snapshot) {
    return _writeQueue.enqueue(snapshot);
  }

  /// 只在快照真正取得写入槽时编码，避免为随后被覆盖的进度状态消耗 CPU。
  Future<void> _writeSnapshot(AppOperationJournalSnapshot snapshot) {
    return _writeAtomically(jsonEncode(snapshot.toJson()));
  }

  /// 在同一目录写入临时文件并原子替换正式文件。
  Future<void> _writeAtomically(String contents) async {
    final parent = _journalFile.parent;
    await parent.create(recursive: true);

    final temporaryFile = File('${_journalFile.path}.$pid.tmp');
    try {
      await temporaryFile.writeAsString(contents, flush: true);
      await temporaryFile.rename(_journalFile.path);
    } catch (error, stackTrace) {
      AppLogger.error('应用操作 Journal 原子写入失败', error, stackTrace);
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
      rethrow;
    }
  }

  /// 把损坏文件改名保留，避免静默丢失诊断证据。
  void _preserveCorruptedSnapshot(Object error, StackTrace stackTrace) {
    final backupPath =
        '${_journalFile.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}';
    try {
      _journalFile.renameSync(backupPath);
      AppLogger.error(
        '应用操作 Journal 已损坏，原文件已保留到 $backupPath',
        error,
        stackTrace,
      );
    } catch (backupError, backupStackTrace) {
      AppLogger.error('应用操作 Journal 已损坏且无法保留副本', backupError, backupStackTrace);
    }
  }
}
