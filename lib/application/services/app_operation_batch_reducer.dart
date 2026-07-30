/// 提供应用操作批次和持久化 Outbox 的纯状态推导。
///
/// 批次完成与副作用事件必须和任务终态写入同一快照，因此本文件只返回新的
/// `InstallQueueState`，不直接执行通知、统计或磁盘写入。
library;

import '../../domain/models/app_operation_batch.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_queue_state.dart';
import '../../domain/models/install_task.dart';

/// 批次与 Outbox 纯状态归并器。
class AppOperationBatchReducer {
  /// 创建无状态归并器。
  const AppOperationBatchReducer();

  /// 根据任务终态幂等派生任务成功事件和批次完成事件。
  InstallQueueState recordTerminalTask({
    required InstallQueueState state,
    required InstallTask terminalTask,
    required int nowTimestamp,
  }) {
    var nextState = state;
    if (terminalTask.status == InstallStatus.success) {
      final effectId = 'task-succeeded-${terminalTask.id}';
      if (!nextState.outbox.any((effect) => effect.id == effectId)) {
        nextState = nextState.copyWith(
          outbox: [
            ...nextState.outbox,
            AppOperationEffect(
              id: effectId,
              type: AppOperationEffectType.taskSucceeded,
              aggregateId: terminalTask.id,
              createdAt: terminalTask.finishedAt ?? nowTimestamp,
            ),
          ],
        );
      }
    }

    final batchId = terminalTask.batchId;
    if (batchId == null) {
      return nextState;
    }
    return _completeBatchIfReady(
      state: nextState,
      batchId: batchId,
      nowTimestamp: nowTimestamp,
    );
  }

  /// 记录某条 Outbox 事件的消费尝试。
  InstallQueueState markEffectAttempt({
    required InstallQueueState state,
    required String effectId,
    required int nowTimestamp,
  }) {
    final effectIndex = state.outbox.indexWhere(
      (effect) => effect.id == effectId,
    );
    if (effectIndex < 0) {
      return state;
    }

    final outbox = [...state.outbox];
    final effect = outbox[effectIndex];
    outbox[effectIndex] = effect.copyWith(
      attemptCount: effect.attemptCount + 1,
      lastAttemptAt: nowTimestamp,
    );
    return state.copyWith(outbox: outbox);
  }

  /// 确认 Outbox 事件，并可在同一状态中写入批次通知结果。
  InstallQueueState acknowledgeEffect({
    required InstallQueueState state,
    required String effectId,
    AppOperationNotificationState? notificationState,
  }) {
    final effect = state.outbox
        .where((item) => item.id == effectId)
        .firstOrNull;
    if (effect == null) {
      return state;
    }

    var batches = state.batches;
    if (notificationState != null) {
      if (effect.type != AppOperationEffectType.updateBatchCompleted) {
        throw StateError('只有批次完成事件可以写入通知状态');
      }
      final batchIndex = batches.indexWhere(
        (batch) => batch.id == effect.aggregateId,
      );
      if (batchIndex >= 0) {
        batches = [...batches];
        batches[batchIndex] = batches[batchIndex].copyWith(
          notificationState: notificationState,
        );
      }
    }

    return state.copyWith(
      batches: batches,
      outbox: state.outbox.where((item) => item.id != effectId).toList(),
    );
  }

  /// 在指定批次全部任务已终态时生成批次事实和唯一完成事件。
  InstallQueueState _completeBatchIfReady({
    required InstallQueueState state,
    required String batchId,
    required int nowTimestamp,
  }) {
    final batchIndex = state.batches.indexWhere((batch) => batch.id == batchId);
    if (batchIndex < 0) {
      return state;
    }

    final batch = state.batches[batchIndex];
    if (batch.status == AppOperationBatchStatus.completed) {
      return state;
    }

    final tasksById = <String, InstallTask>{
      for (final task in state.allTasks) task.id: task,
    };
    final isCompleted = batch.taskIds.every(
      (taskId) => tasksById[taskId]?.isCompleted == true,
    );
    if (!isCompleted) {
      return state;
    }

    final completedBatch = batch.copyWith(
      status: AppOperationBatchStatus.completed,
      finishedAt: nowTimestamp,
      notificationState: AppOperationNotificationState.pending,
    );
    final batches = [...state.batches];
    batches[batchIndex] = completedBatch;

    final effectId = 'update-batch-completed-$batchId';
    final outbox = state.outbox.any((effect) => effect.id == effectId)
        ? state.outbox
        : [
            ...state.outbox,
            AppOperationEffect(
              id: effectId,
              type: AppOperationEffectType.updateBatchCompleted,
              aggregateId: batchId,
              createdAt: nowTimestamp,
            ),
          ];
    return state.copyWith(batches: batches, outbox: outbox);
  }
}
