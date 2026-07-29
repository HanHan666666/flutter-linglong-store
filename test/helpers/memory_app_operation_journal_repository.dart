/// 为 Provider 单元测试提供无文件副作用的应用操作 Journal。
///
/// 测试必须显式覆盖生产 XDG 文件仓库，避免测试进程读写开发者真实队列。
library;

import 'package:linglong_store/domain/models/app_operation_journal_snapshot.dart';
import 'package:linglong_store/domain/repositories/app_operation_journal_repository.dart';

/// 只在内存中保存最后一次完整快照的 Journal 仓库。
class MemoryAppOperationJournalRepository
    implements AppOperationJournalRepository {
  /// 使用可选初始快照创建仓库。
  MemoryAppOperationJournalRepository([this.snapshot]);

  /// 当前持久化快照。
  AppOperationJournalSnapshot? snapshot;

  @override
  AppOperationJournalSnapshot? load() => snapshot;

  @override
  Future<void> save(AppOperationJournalSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
