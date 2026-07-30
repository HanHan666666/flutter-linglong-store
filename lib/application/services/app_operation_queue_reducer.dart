/// 提供应用操作队列的纯状态转换。
///
/// Reducer 不读取 Riverpod、locale、时间或外部仓储；调用方显式传入已经构造好的
/// 任务和时间，使队列不变量可以脱离 UI 与平台环境审阅。
library;

import '../../domain/models/install_progress.dart';
import '../../domain/models/install_queue_state.dart';
import '../../domain/models/install_task.dart';
import 'app_operation_batch_reducer.dart';

/// 队列、当前任务和历史记录归并器。
class AppOperationQueueReducer {
  /// 创建队列归并器。
  const AppOperationQueueReducer({
    AppOperationBatchReducer batchReducer = const AppOperationBatchReducer(),
  }) : _batchReducer = batchReducer;

  /// 终态提交时使用的批次和 Outbox 归并规则。
  final AppOperationBatchReducer _batchReducer;

  /// 把等待任务提升为唯一当前任务。
  InstallQueueState promoteTask({
    required InstallQueueState state,
    required InstallTask task,
  }) {
    return state.copyWith(
      isProcessing: true,
      queue: state.queue.where((item) => item.id != task.id).toList(),
      currentTask: task,
    );
  }

  /// 把一条 CLI 进度归并到指定当前任务。
  InstallQueueState applyProgress({
    required InstallQueueState state,
    required String taskId,
    required InstallProgress progress,
  }) {
    final currentTask = state.currentTask;
    if (currentTask == null || currentTask.id != taskId) {
      return state;
    }
    final updatedTask = appendCommandOutput(currentTask, progress.outputLine)
        .copyWith(
          status: progress.status,
          progress: progress.progress,
          message: progress.message,
          rawMessage: progress.rawMessage,
          errorMessage: progress.error,
          errorCode: progress.errorCode,
          errorDetail: progress.errorDetail ?? progress.rawMessage,
        );
    return state.copyWith(currentTask: updatedTask);
  }

  /// 提交任务终态，并同步推导历史、批次和 Outbox。
  InstallQueueState commitTerminalTask({
    required InstallQueueState state,
    required InstallTask terminalTask,
    required int nowTimestamp,
    required int maxHistorySize,
    bool clearCurrentTask = true,
  }) {
    final nextHistory = <InstallTask>[
      terminalTask,
      ...state.history.where((task) => task.id != terminalTask.id),
    ];
    final boundedHistory = _retainBoundedHistory(
      history: nextHistory,
      batchesState: state,
      maxHistorySize: maxHistorySize,
    );
    final nextState = state.copyWith(
      clearCurrentTask: clearCurrentTask,
      isProcessing: clearCurrentTask ? false : state.isProcessing,
      history: boundedHistory,
    );
    return _batchReducer.recordTerminalTask(
      state: nextState,
      terminalTask: terminalTask,
      nowTimestamp: nowTimestamp,
    );
  }

  /// 从当前命令输出追加一条非空原始行。
  InstallTask appendCommandOutput(InstallTask task, String? outputLine) {
    final line = outputLine?.trimRight();
    if (line == null || line.isEmpty) {
      return task;
    }
    final nextOutput = task.commandOutput.isEmpty
        ? line
        : '${task.commandOutput}\n$line';
    return task.copyWith(commandOutput: nextOutput);
  }

  /// 从等待队列移除指定任务。
  InstallQueueState removeQueuedTask(InstallQueueState state, String taskId) {
    return state.copyWith(
      queue: state.queue.where((task) => task.id != taskId).toList(),
    );
  }

  /// 从历史记录移除指定任务。
  InstallQueueState removeHistoryTask(InstallQueueState state, String taskId) {
    return state.copyWith(
      history: state.history.where((task) => task.id != taskId).toList(),
    );
  }

  /// 删除全部等待任务；批次任务的取消终态由调用方继续逐项提交。
  InstallQueueState clearQueue(InstallQueueState state) {
    return state.copyWith(queue: const <InstallTask>[]);
  }

  /// 限制普通历史数量，同时保留仍被批次摘要引用的任务事实。
  List<InstallTask> _retainBoundedHistory({
    required List<InstallTask> history,
    required InstallQueueState batchesState,
    required int maxHistorySize,
  }) {
    final batchTaskIds = batchesState.batches
        .expand((batch) => batch.taskIds)
        .toSet();
    final retained = <InstallTask>[];
    var ordinaryCount = 0;
    for (final task in history) {
      if (batchTaskIds.contains(task.id)) {
        retained.add(task);
      } else if (ordinaryCount < maxHistorySize) {
        retained.add(task);
        ordinaryCount += 1;
      }
    }
    return retained;
  }
}
