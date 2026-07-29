/// 定义应用操作 Journal 的持久化边界。
///
/// Application 层只依赖该接口，不感知文件路径、临时文件和损坏备份策略。
library;

import '../models/app_operation_journal_snapshot.dart';

/// 应用操作 Journal 仓库。
abstract interface class AppOperationJournalRepository {
  /// 同步读取启动快照；文件不存在时返回 null。
  AppOperationJournalSnapshot? load();

  /// 串行、原子地保存完整快照。
  Future<void> save(AppOperationJournalSnapshot snapshot);
}
