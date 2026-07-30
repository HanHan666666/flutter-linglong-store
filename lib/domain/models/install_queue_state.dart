import '../../domain/models/app_operation_batch.dart';
import '../../domain/models/app_operation_journal_snapshot.dart';
import '../../domain/models/install_task.dart';

/// 安装队列状态
///
/// 封装安装队列的不可变状态，包含待处理队列、当前任务和历史记录。
class InstallQueueState {
  const InstallQueueState({
    this.queue = const [],
    this.currentTask,
    this.history = const [],
    this.batches = const [],
    this.outbox = const [],
    this.isProcessing = false,
  });

  /// 从版本化 Journal 快照恢复运行时状态。
  factory InstallQueueState.fromJournalSnapshot(
    AppOperationJournalSnapshot snapshot,
  ) {
    return InstallQueueState(
      queue: snapshot.pendingTasks,
      currentTask: snapshot.currentTask,
      history: snapshot.history,
      batches: snapshot.batches,
      outbox: snapshot.outbox,
    );
  }

  /// 待处理队列
  final List<InstallTask> queue;

  /// 当前正在处理的任务
  final InstallTask? currentTask;

  /// 历史记录（成功/失败）
  final List<InstallTask> history;

  /// 一键更新批次。
  final List<AppOperationBatch> batches;

  /// 等待生命周期协调器消费的持久化副作用。
  final List<AppOperationEffect> outbox;

  /// 是否正在处理中
  final bool isProcessing;

  /// 检查应用是否在队列中
  bool isAppInQueue(String appId) {
    if (currentTask?.appId == appId) return true;
    return queue.any((t) => t.appId == appId);
  }

  /// 获取应用的安装状态
  InstallTask? getAppInstallStatus(String appId) {
    if (currentTask?.appId == appId) return currentTask;
    for (final task in queue) {
      if (task.appId == appId) return task;
    }
    for (final task in history) {
      if (task.appId == appId) return task;
    }
    return null;
  }

  /// 获取应用当前仍处于活跃状态的任务列表。
  ///
  /// 只返回正在处理中的当前任务和等待队列中的任务，
  /// 不包含历史记录，便于 UI 精确映射“正在安装/等待安装”状态。
  List<InstallTask> getActiveTasksForApp(String appId) {
    final tasks = <InstallTask>[];
    if (currentTask?.appId == appId) {
      tasks.add(currentTask!);
    }
    tasks.addAll(queue.where((task) => task.appId == appId));
    return tasks;
  }

  /// 是否有活跃任务
  bool hasActiveTasks() => currentTask != null || queue.isNotEmpty;

  /// 转换为需要原子持久化的完整 Journal 快照。
  AppOperationJournalSnapshot toJournalSnapshot() {
    return AppOperationJournalSnapshot(
      pendingTasks: queue,
      currentTask: currentTask,
      history: history,
      batches: batches,
      outbox: outbox,
    );
  }

  /// 返回当前状态中的全部任务记录。
  ///
  /// 任务 ID 在三个集合中互斥；该顺序仅用于按 ID 建索引，不参与 UI 排序。
  List<InstallTask> get allTasks => [
    if (currentTask case final task?) task,
    ...queue,
    ...history,
  ];

  /// 根据批次 ID 生成稳定摘要。
  AppOperationBatchSummary summarizeBatch(String batchId) {
    final batch = batches.where((item) => item.id == batchId).firstOrNull;
    if (batch == null) {
      throw StateError('找不到应用操作批次: $batchId');
    }
    return AppOperationBatchSummary.fromBatch(batch: batch, tasks: allTasks);
  }

  /// 复制并更新
  InstallQueueState copyWith({
    List<InstallTask>? queue,
    InstallTask? currentTask,
    List<InstallTask>? history,
    List<AppOperationBatch>? batches,
    List<AppOperationEffect>? outbox,
    bool? isProcessing,
    bool clearCurrentTask = false,
  }) {
    return InstallQueueState(
      queue: queue ?? this.queue,
      currentTask: clearCurrentTask ? null : (currentTask ?? this.currentTask),
      history: history ?? this.history,
      batches: batches ?? this.batches,
      outbox: outbox ?? this.outbox,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
