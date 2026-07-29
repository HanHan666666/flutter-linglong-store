/// 定义应用操作 Journal 的版本化完整快照。
///
/// 队列、当前任务、历史、批次和 Outbox 必须在同一次原子替换中落盘，
/// 防止崩溃后出现“任务完成但完成事件丢失”的跨文件不一致。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_operation_batch.dart';
import 'install_task.dart';

part 'app_operation_journal_snapshot.freezed.dart';
part 'app_operation_journal_snapshot.g.dart';

/// 当前操作 Journal 的结构版本。
const int currentAppOperationJournalSchemaVersion = 2;

/// 应用操作 Journal 完整快照。
@freezed
sealed class AppOperationJournalSnapshot with _$AppOperationJournalSnapshot {
  /// 创建一个版本化完整快照。
  const factory AppOperationJournalSnapshot({
    /// 持久化结构版本。
    @Default(currentAppOperationJournalSchemaVersion) int schemaVersion,

    /// 等待执行的任务。
    @Default(<InstallTask>[]) List<InstallTask> pendingTasks,

    /// 当前执行中的任务。
    InstallTask? currentTask,

    /// 有界任务历史。
    @Default(<InstallTask>[]) List<InstallTask> history,

    /// 活跃和近期完成的批次。
    @Default(<AppOperationBatch>[]) List<AppOperationBatch> batches,

    /// 等待生命周期协调器消费的副作用。
    @Default(<AppOperationEffect>[]) List<AppOperationEffect> outbox,
  }) = _AppOperationJournalSnapshot;

  /// 从 JSON 恢复快照。
  factory AppOperationJournalSnapshot.fromJson(Map<String, dynamic> json) =>
      _$AppOperationJournalSnapshotFromJson(json);

  /// 校验结构版本后从 JSON 恢复快照。
  static AppOperationJournalSnapshot fromVersionedJson(
    Map<String, dynamic> json,
  ) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != currentAppOperationJournalSchemaVersion) {
      throw FormatException('不支持的应用操作 Journal 版本: $schemaVersion');
    }
    return AppOperationJournalSnapshot.fromJson(json);
  }
}
