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
  ///
  /// Future 完成表示该快照或一个更新快照已经持久化；实现可以合并尚未开始的
  /// 中间快照，但不得让调用方在等价或更新状态落盘前越过持久化屏障。
  Future<void> save(AppOperationJournalSnapshot snapshot);
}
