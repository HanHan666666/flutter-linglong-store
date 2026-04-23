import '../../domain/models/install_task.dart';

/// 安装队列状态
///
/// 封装安装队列的不可变状态，包含待处理队列、当前任务和历史记录。
class InstallQueueState {
  const InstallQueueState({
    this.queue = const [],
    this.currentTask,
    this.history = const [],
    this.isProcessing = false,
  });

  /// 待处理队列
  final List<InstallTask> queue;

  /// 当前正在处理的任务
  final InstallTask? currentTask;

  /// 历史记录（成功/失败）
  final List<InstallTask> history;

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

  /// 复制并更新
  InstallQueueState copyWith({
    List<InstallTask>? queue,
    InstallTask? currentTask,
    List<InstallTask>? history,
    bool? isProcessing,
    bool clearCurrentTask = false,
  }) {
    return InstallQueueState(
      queue: queue ?? this.queue,
      currentTask: clearCurrentTask ? null : (currentTask ?? this.currentTask),
      history: history ?? this.history,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
