/// 使用 XDG State 目录中的单文件实现应用操作 Journal。
///
/// 该实现只在启动时同步读取；运行期间写入全部串行异步执行，并通过同目录
/// 临时文件原子替换正式文件，避免 UI isolate 因频繁进度事件进行同步 IO。
library;

import 'dart:convert';
import 'dart:io';

import '../../core/logging/app_logger.dart';
import '../../domain/models/app_operation_journal_snapshot.dart';
import '../../domain/repositories/app_operation_journal_repository.dart';

/// 基于本地 JSON 文件的应用操作 Journal 仓库。
class FileAppOperationJournalRepository
    implements AppOperationJournalRepository {
  /// 使用已经按 XDG 规则解析的目标文件创建仓库。
  FileAppOperationJournalRepository(this._journalFile);

  /// 正式 Journal 文件。
  final File _journalFile;

  /// 串行写入链，确保高频状态更新不会乱序覆盖较新的快照。
  Future<void> _pendingWrite = Future<void>.value();

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
    final contents = jsonEncode(snapshot.toJson());
    _pendingWrite = _pendingWrite
        .then<void>(
          (_) {},
          onError: (Object _, StackTrace __) {
            // 前一次失败不能阻断后续较新快照继续尝试落盘。
          },
        )
        .then<void>((_) => _writeAtomically(contents));
    return _pendingWrite;
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
