import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_state_machine.dart';
import '../../domain/models/install_task.dart';
import '../../domain/repositories/linglong_cli_repository.dart';
import '../../data/repositories/linglong_cli_repository_impl.dart';

part 'install_queue_provider.g.dart';

/// 本地存储 key
const String _kCurrentTaskKey = 'linglong-store-current-install-task';
const String _kQueueKey = 'linglong-store-install-queue';

/// 历史记录最大保留条数
const int _maxHistorySize = 50;

/// SharedPreferences Provider
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('SharedPreferences not initialized');
}

/// Linglong CLI Repository Provider
@riverpod
LinglongCliRepository linglongCliRepository(Ref ref) {
  return LinglongCliRepositoryImpl();
}

/// 安装队列状态
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

/// 安装队列状态机 Provider
///
/// 核心功能：
/// 1. 严格串行安装：一次只处理一个安装任务
/// 2. 持久化存储：应用崩溃后可恢复队列
/// 3. 状态持久：保存到 SharedPreferences
/// 4. 错误恢复：重试机制
/// 5. 取消状态管理：区分"用户取消"和"真正失败"
@Riverpod(keepAlive: true)
class InstallQueue extends _$InstallQueue {
  @override
  InstallQueueState build() {
    _prefs ??= _readSharedPreferences();

    // 在 build 阶段直接同步恢复本地状态，避免未初始化 _prefs 时触发异步读取，
    // 同时规避 Provider 在首帧构建期间被再次写入导致的生命周期告警。
    return _restorePersistedState();
  }

  SharedPreferences? _prefs;
  final _uuid = const Uuid();

  /// 安装状态机（用于超时检测）
  InstallStateMachine? _stateMachine;

  /// 超时检查定时器
  Timer? _timeoutCheckTimer;

  /// 用户取消标志（区分"用户取消"和"真正失败"）
  /// 参考 Rust 版本 InstallSlot.is_cancelled
  bool _isUserCancelled = false;

  /// 启动超时检查定时器
  void _startTimeoutCheck(String appId) {
    _stopTimeoutCheck();
    // 每隔超时时间的一半检查一次
    final checkInterval = Duration(
      seconds: (_stateMachine?.progressTimeoutSecs ?? 360) ~/ 2,
    );
    _timeoutCheckTimer = Timer.periodic(checkInterval, (_) {
      if (_stateMachine?.checkTimeout() == true) {
        AppLogger.warning('Install timeout for $appId');
        _stateMachine?.onFailure();
        markFailed(
          appId,
          '安装超时：长时间未收到进度更新',
          errorCode: -2, // 超时错误码
        );
      }
    });
  }

  /// 停止超时检查定时器
  void _stopTimeoutCheck() {
    _timeoutCheckTimer?.cancel();
    _timeoutCheckTimer = null;
  }

  /// 标记当前安装为用户取消
  ///
  /// 参考 Rust 版本 InstallSlot.mark_cancelled()
  /// 在用户主动取消安装时调用
  void markUserCancelled() {
    _isUserCancelled = true;
    AppLogger.info('[InstallQueue] 已标记用户取消');
  }

  /// 检查当前安装是否被用户取消
  ///
  /// 参考 Rust 版本 InstallSlot.is_cancelled()
  /// 读取后会重置标志
  bool isUserCancelled() {
    final result = _isUserCancelled;
    _isUserCancelled = false;
    return result;
  }

  /// 重置取消标志
  void _resetCancelFlag() {
    _isUserCancelled = false;
  }

  /// 初始化（需要在应用启动时调用）
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  SharedPreferences? _readSharedPreferences() {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  InstallQueueState _restorePersistedState() {
    final prefs = _prefs;
    if (prefs == null) {
      return const InstallQueueState();
    }

    try {
      InstallTask? currentTask;
      final currentTaskJson = prefs.getString(_kCurrentTaskKey);
      if (currentTaskJson != null) {
        currentTask = InstallTask.fromJson(
          jsonDecode(currentTaskJson) as Map<String, dynamic>,
        );
      }

      final queueJson = prefs.getString(_kQueueKey);
      final queue = queueJson == null
          ? const <InstallTask>[]
          : (jsonDecode(queueJson) as List<dynamic>)
                .map((e) => InstallTask.fromJson(e as Map<String, dynamic>))
                .toList();

      if (currentTask != null || queue.isNotEmpty) {
        AppLogger.info(
          'Restored install queue state: current=${currentTask?.appId}, pending=${queue.length}',
        );
      }

      return InstallQueueState(currentTask: currentTask, queue: queue);
    } catch (e, s) {
      AppLogger.error('Failed to restore persisted install queue state', e, s);
      unawaited(prefs.remove(_kCurrentTaskKey));
      unawaited(prefs.remove(_kQueueKey));
      return const InstallQueueState();
    }
  }

  /// 入队安装任务
  ///
  /// 返回任务ID，如果应用已在队列中则返回空字符串
  String enqueueInstall({
    required String appId,
    required String appName,
    String? icon,
    String? version,
    bool force = false,
  }) {
    return enqueueOperation(
      kind: InstallTaskKind.install,
      appId: appId,
      appName: appName,
      icon: icon,
      version: version,
      force: force,
    );
  }

  /// 入队安装/更新任务。
  ///
  /// 统一入口保证 Presentation 层不需要直接关心底层队列状态写入细节。
  String enqueueOperation({
    required InstallTaskKind kind,
    required String appId,
    required String appName,
    String? icon,
    String? version,
    bool force = false,
  }) {
    // 检查是否已在队列中
    if (state.isAppInQueue(appId)) {
      AppLogger.warning('App $appId is already in queue, skipping');
      return '';
    }

    final kindTask = InstallTask(
      id: _generateTaskId(),
      appId: appId,
      appName: appName,
      icon: icon,
      kind: kind,
      version: version,
      force: force,
      status: InstallStatus.pending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final task = InstallTask(
      id: kindTask.id,
      appId: kindTask.appId,
      appName: kindTask.appName,
      icon: kindTask.icon,
      kind: kindTask.kind,
      version: kindTask.version,
      force: kindTask.force,
      status: kindTask.status,
      createdAt: kindTask.createdAt,
      message: kindTask.waitingMessage,
    );

    state = state.copyWith(queue: [...state.queue, task]);
    persistQueue();

    AppLogger.info('Enqueued task: ${task.id} for app: $appId');

    // 如果当前没有正在处理的任务，开始处理队列
    if (!state.isProcessing && state.currentTask == null) {
      Future.microtask(() => startProcessing());
    }

    return task.id;
  }

  /// 批量入队
  List<String> enqueueBatch(List<EnqueueTaskParams> tasksParams) {
    return enqueueBatchOperations(tasksParams);
  }

  /// 批量入队安装/更新任务。
  List<String> enqueueBatchOperations(List<EnqueueTaskParams> tasksParams) {
    final taskIds = <String>[];
    final newTasks = <InstallTask>[];

    for (final params in tasksParams) {
      if (state.isAppInQueue(params.appId)) {
        continue;
      }

      final task = InstallTask(
        id: _generateTaskId(),
        appId: params.appId,
        appName: params.appName,
        icon: params.icon,
        kind: params.kind,
        version: params.version,
        force: params.force,
        status: InstallStatus.pending,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      taskIds.add(task.id);
      newTasks.add(task.copyWith(message: task.waitingMessage));
    }

    if (newTasks.isNotEmpty) {
      state = state.copyWith(queue: [...state.queue, ...newTasks]);
      persistQueue();
      AppLogger.info('Enqueued ${newTasks.length} tasks in batch');

      if (!state.isProcessing && state.currentTask == null) {
        Future.microtask(() => startProcessing());
      }
    }

    return taskIds;
  }

  /// 开始处理队列中的下一个任务
  ///
  /// 严格串行安装：同一时间只处理一个任务
  Future<void> startProcessing() async {
    await processQueue();
  }

  /// 处理队列
  Future<void> processQueue() async {
    // 如果已经在处理中，或者有当前任务，直接返回
    if (state.isProcessing || state.currentTask != null) {
      AppLogger.info('Already processing or has current task, skipping');
      return;
    }

    if (state.queue.isEmpty) {
      AppLogger.info('Queue is empty, nothing to process');
      return;
    }

    // 取出队列中第一个任务
    final nextTask = state.queue.first;
    await processInstallTask(nextTask);
  }

  /// 执行单个队列任务
  ///
  /// 从队列中取出任务并执行，更新进度状态
  Future<void> processInstallTask(InstallTask task) async {
    final remainingQueue = state.queue.where((t) => t.id != task.id).toList();

    // 重置取消标志（确保每次安装都是干净的状态）
    _resetCancelFlag();

    // 更新状态为安装中
    final installingTask = task.copyWith(
      status: InstallStatus.installing,
      message: task.preparingMessage,
      startedAt: DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(
      isProcessing: true,
      queue: remainingQueue,
      currentTask: installingTask,
    );

    _persistCurrentTask();
    persistQueue();

    // 启动状态机和超时检查
    _stateMachine = InstallStateMachine();
    _stateMachine!.start();
    _startTimeoutCheck(task.appId);

    AppLogger.info('Processing task: ${task.id} for app: ${task.appId}');

    try {
      // 获取 CLI Repository
      final cliRepo = ref.read(linglongCliRepositoryProvider);

      // 监听安装进度流
      final progressStream = task.kind == InstallTaskKind.update
          ? cliRepo.updateApp(task.appId, version: task.version)
          : cliRepo.installApp(
              task.appId,
              version: task.version,
              force: task.force,
            );
      await for (final progress in progressStream) {
        _handleProgress(task.appId, progress);
      }

      // 注意：安装成功的标记可能由进度流中的 success 状态触发
      // 如果流正常结束但没有标记成功/取消/失败，这里手动检查
      if (state.currentTask?.appId == task.appId &&
          state.currentTask?.status != InstallStatus.success &&
          state.currentTask?.status != InstallStatus.cancelled &&
          state.currentTask?.status != InstallStatus.failed) {
        // 检查状态机状态
        if (_stateMachine?.state == InstallStateMachineState.succeeded) {
          markSuccess(task.appId);
        } else if (_stateMachine?.state != InstallStateMachineState.failed) {
          // 进程正常退出，标记成功
          _stateMachine?.onSuccess();
          markSuccess(task.appId);
        }
      }
    } catch (e, s) {
      AppLogger.error('Install request failed for ${task.appId}', e, s);
      _stateMachine?.onFailure();
      markFailed(task.appId, e.toString());
    }
  }

  /// 处理安装进度
  void _handleProgress(String appId, InstallProgress progress) {
    if (state.currentTask?.appId != appId) return;

    // 更新状态机
    if (progress.status == InstallStatus.success) {
      _stateMachine?.onSuccess();
    } else if (progress.status == InstallStatus.failed) {
      _stateMachine?.onFailure();
    } else if (progress.status == InstallStatus.cancelled) {
      // 取消状态不需要更新状态机，由 cancelTask 方法处理
      AppLogger.info('[InstallQueue] 收到取消状态: $appId');
    } else if (progress.progress > 0) {
      // 有进度百分比，调用 onProgress
      _stateMachine?.onProgress(progress.progress);
    } else {
      // 收到消息事件，刷新时间戳
      _stateMachine?.onMessage();
    }

    final updatedTask = state.currentTask!.copyWith(
      status: progress.status,
      progress: progress.progress,
      message: progress.message,
      errorMessage: progress.error,
      errorCode: progress.errorCode,
    );

    state = state.copyWith(currentTask: updatedTask);
    _persistCurrentTask();

    // 检查是否完成
    if (progress.status == InstallStatus.success) {
      markSuccess(appId);
    } else if (progress.status == InstallStatus.failed) {
      markFailed(
        appId,
        progress.error ?? '安装失败',
        errorCode: progress.errorCode,
      );
    } else if (progress.status == InstallStatus.cancelled) {
      // 取消状态：停止超时检查，更新历史记录
      _handleCancelledProgress(appId);
    }
  }

  /// 处理取消状态（从安装流中收到 cancelled 状态）
  void _handleCancelledProgress(String appId) {
    if (state.currentTask?.appId != appId) return;

    // 停止超时检查和清理状态机
    _stopTimeoutCheck();
    _stateMachine?.dispose();
    _stateMachine = null;

    final cancelledTask = state.currentTask!.copyWith(
      status: InstallStatus.cancelled,
      message: state.currentTask!.cancelledMessage,
      finishedAt: DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(
      clearCurrentTask: true,
      isProcessing: false,
      history: [cancelledTask, ...state.history].take(_maxHistorySize).toList(),
    );

    _clearPersistedCurrentTask();
    AppLogger.info('[InstallQueue] 任务已从流中标记取消: $appId');

    // 处理下一个任务
    Future.delayed(const Duration(milliseconds: 100), () => startProcessing());
  }

  /// 更新进度
  ///
  /// 更新当前任务的进度和消息
  void updateProgress(String appId, double progress, String message) {
    if (state.currentTask?.appId != appId) return;

    state = state.copyWith(
      currentTask: state.currentTask!.copyWith(
        progress: progress,
        message: message,
      ),
    );
    _persistCurrentTask();
  }

  /// 标记成功
  ///
  /// 将当前任务标记为成功，添加到历史记录，并处理下一个任务
  void markSuccess(String appId) {
    if (state.currentTask?.appId != appId) {
      AppLogger.warning(
        'markSuccess called for $appId but current task is ${state.currentTask?.appId}',
      );
      return;
    }

    // 停止超时检查和清理状态机
    _stopTimeoutCheck();
    _stateMachine?.dispose();
    _stateMachine = null;

    final completedTask = state.currentTask!.copyWith(
      status: InstallStatus.success,
      progress: 100,
      message: state.currentTask!.successMessage,
      finishedAt: DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(
      clearCurrentTask: true,
      isProcessing: false,
      history: [completedTask, ...state.history].take(_maxHistorySize).toList(),
    );

    _clearPersistedCurrentTask();
    AppLogger.info('Task completed successfully: $appId');

    // 处理下一个任务
    Future.delayed(const Duration(milliseconds: 100), () => startProcessing());
  }

  /// 标记失败
  ///
  /// 将当前任务标记为失败，记录错误信息，继续处理下一个任务
  /// 会自动检测是否为用户取消，并设置正确的状态
  void markFailed(
    String appId,
    String error, {
    int? errorCode,
    String? errorDetail,
  }) {
    if (state.currentTask?.appId != appId) {
      AppLogger.warning(
        'markFailed called for $appId but current task is ${state.currentTask?.appId}',
      );
      return;
    }

    // 停止超时检查和清理状态机
    _stopTimeoutCheck();
    _stateMachine?.dispose();
    _stateMachine = null;

    // 检查是否为用户取消（参考 Rust 版本 InstallSlot.is_cancelled）
    final wasCancelled = isUserCancelled();

    // 根据取消状态决定任务状态
    final failedTask = state.currentTask!.copyWith(
      status: wasCancelled ? InstallStatus.cancelled : InstallStatus.failed,
      errorMessage: wasCancelled ? state.currentTask!.cancelledMessage : error,
      errorCode: wasCancelled ? null : errorCode,
      errorDetail: wasCancelled ? null : errorDetail,
      message: wasCancelled ? state.currentTask!.cancelledMessage : error,
      finishedAt: DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(
      clearCurrentTask: true,
      isProcessing: false,
      history: [failedTask, ...state.history].take(_maxHistorySize).toList(),
    );

    _clearPersistedCurrentTask();

    if (wasCancelled) {
      AppLogger.info('Task cancelled by user: $appId');
    } else {
      AppLogger.error('Task failed: $appId, error: $error, code: $errorCode');
    }

    // 继续处理下一个任务（失败不阻塞队列）
    Future.delayed(const Duration(milliseconds: 100), () => startProcessing());
  }

  /// 取消任务
  ///
  /// 取消当前正在执行的任务或从队列中移除
  ///
  /// 参考 Rust 版本 `cancel_linglong_install` 的流程：
  /// 1. 标记取消状态（`markUserCancelled`）
  /// 2. 调用 CLI 取消方法（`pkexec killall`）
  /// 3. 更新任务状态为 `cancelled`
  Future<bool> cancelTask(String appId) async {
    if (state.currentTask?.appId == appId) {
      // 标记为用户取消（参考 Rust 版本 InstallSlot.mark_cancelled）
      markUserCancelled();

      // 停止超时检查和清理状态机
      _stopTimeoutCheck();
      _stateMachine?.dispose();
      _stateMachine = null;

      // 取消当前任务
      bool cancelSuccess = false;
      try {
        cancelSuccess = await ref
            .read(linglongCliRepositoryProvider)
            .cancelOperation(
              appId,
              kind: state.currentTask!.kind,
            );
      } catch (e) {
        AppLogger.error('[InstallQueue] 取消安装失败: $appId', e);
      }

      // 无论取消是否成功，都更新任务状态
      // 因为用户已明确要求取消，即使进程终止失败也应标记为取消
      final cancelledTask = state.currentTask!.copyWith(
        status: InstallStatus.cancelled,
        message: state.currentTask!.cancelledMessage,
        finishedAt: DateTime.now().millisecondsSinceEpoch,
      );

      state = state.copyWith(
        clearCurrentTask: true,
        isProcessing: false,
        history: [
          cancelledTask,
          ...state.history,
        ].take(_maxHistorySize).toList(),
      );

      _clearPersistedCurrentTask();

      if (cancelSuccess) {
        AppLogger.info('[InstallQueue] 任务已取消: $appId');
      } else {
        AppLogger.warning('[InstallQueue] 任务已标记取消（但进程终止可能失败）: $appId');
      }

      // 处理下一个任务
      Future.delayed(
        const Duration(milliseconds: 100),
        () => startProcessing(),
      );

      return cancelSuccess;
    } else {
      // 从队列中移除
      removeFromQueue(appId);
      return true;
    }
  }

  /// 取消安装（兼容旧接口）
  @Deprecated('Use cancelTask instead')
  Future<bool> cancelInstall(String appId) async {
    return await cancelTask(appId);
  }

  /// 从队列中移除任务
  void removeFromQueue(String appId) {
    state = state.copyWith(
      queue: state.queue.where((t) => t.appId != appId).toList(),
      history: state.history.where((t) => t.appId != appId).toList(),
    );
    persistQueue();
  }

  /// 清空历史记录
  void clearHistory() {
    state = state.copyWith(history: []);
  }

  /// 清空队列
  void clearQueue() {
    state = state.copyWith(queue: []);
    persistQueue();
    AppLogger.info('Queue cleared');
  }

  /// 持久化队列到 SharedPreferences
  ///
  /// 将当前待处理队列保存到本地存储
  Future<void> persistQueue() async {
    final prefs = _prefs ?? _readSharedPreferences();
    if (prefs == null) return;

    _prefs = prefs;

    try {
      await prefs.setString(
        _kQueueKey,
        jsonEncode(state.queue.map((t) => t.toJson()).toList()),
      );
      AppLogger.debug('Queue persisted: ${state.queue.length} tasks');
    } catch (e, s) {
      AppLogger.error('Failed to persist queue', e, s);
    }
  }

  /// 从 SharedPreferences 恢复队列
  ///
  /// 队列已在 build() 阶段通过 _restorePersistedState() 同步恢复，
  /// 此方法保留为兼容接口，无需重复执行。
  Future<void> restoreQueue() async {}

  /// 崩溃恢复检查
  ///
  /// 在应用启动时调用，检查是否有未完成的任务
  Future<void> checkRecovery(List<String> installedAppIds) async {
    final persistedTask = state.currentTask;
    if (persistedTask == null) {
      AppLogger.info('No persisted task to recover');
      return;
    }

    AppLogger.info('Recovering task for app: ${persistedTask.appId}');

    // 当前恢复链路只拿到 appId 集合，因此仍按 appId 粗略判断。
    // 后续若启动阶段改为传入 appId + version，可继续向多版本精确恢复收敛。
    final isInstalled = installedAppIds.contains(persistedTask.appId);

    if (isInstalled) {
      // 应用已安装，标记为成功
      AppLogger.info(
        'App ${persistedTask.appId} is installed, marking as success',
      );

      final successTask = persistedTask.copyWith(
        status: InstallStatus.success,
        progress: 100,
        message: persistedTask.successMessage,
        finishedAt: DateTime.now().millisecondsSinceEpoch,
      );

      state = state.copyWith(
        clearCurrentTask: true,
        history: [successTask, ...state.history].take(_maxHistorySize).toList(),
      );
    } else {
      // 应用未安装，标记为失败
      AppLogger.info(
        'App ${persistedTask.appId} is not installed, marking as failed',
      );

      final failedTask = persistedTask.copyWith(
        status: InstallStatus.failed,
        message: '应用崩溃，任务中断',
        errorMessage: '应用在执行过程中崩溃，请重试',
        finishedAt: DateTime.now().millisecondsSinceEpoch,
      );

      state = state.copyWith(
        clearCurrentTask: true,
        history: [failedTask, ...state.history].take(_maxHistorySize).toList(),
      );
    }

    _clearPersistedCurrentTask();
  }

  /// 重试失败的任务
  void retryFailed(String appId) {
    InstallTask? failedTask;
    for (final task in state.history) {
      if (task.appId == appId) {
        failedTask = task;
        break;
      }
    }
    if (failedTask == null || failedTask.status != InstallStatus.failed) {
      return;
    }

    // 从历史中移除
    state = state.copyWith(
      history: state.history.where((t) => t.appId != appId).toList(),
    );

    // 重新入队
    enqueueInstall(
      appId: failedTask.appId,
      appName: failedTask.appName,
      icon: failedTask.icon,
      version: failedTask.version,
      force: failedTask.force,
    );
  }

  /// 生成唯一任务ID
  String _generateTaskId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4().substring(0, 8)}';
  }

  /// 持久化当前任务
  void _persistCurrentTask() {
    final prefs = _prefs ?? _readSharedPreferences();
    if (prefs == null) return;

    _prefs = prefs;

    if (state.currentTask != null) {
      try {
        prefs.setString(
          _kCurrentTaskKey,
          jsonEncode(state.currentTask!.toJson()),
        );
      } catch (e, s) {
        AppLogger.error('Failed to persist current task', e, s);
      }
    }
  }

  /// 清除持久化的当前任务
  void _clearPersistedCurrentTask() {
    final prefs = _prefs ?? _readSharedPreferences();
    if (prefs == null) return;

    _prefs = prefs;
    prefs.remove(_kCurrentTaskKey);
  }
}

/// 入队任务参数
class EnqueueTaskParams {
  const EnqueueTaskParams({
    required this.kind,
    required this.appId,
    required this.appName,
    this.icon,
    this.version,
    this.force = false,
  });

  final InstallTaskKind kind;
  final String appId;
  final String appName;
  final String? icon;
  final String? version;
  final bool force;
}

/// 便捷访问 Provider
@riverpod
InstallQueueState installQueueState(Ref ref) {
  return ref.watch(installQueueProvider);
}

@riverpod
InstallTask? currentInstallTask(Ref ref) {
  return ref.watch(installQueueProvider).currentTask;
}

@riverpod
List<InstallTask> pendingInstallQueue(Ref ref) {
  return ref.watch(installQueueProvider).queue;
}

@riverpod
List<InstallTask> installHistory(Ref ref) {
  return ref.watch(installQueueProvider).history;
}

@riverpod
bool hasActiveInstallTasks(Ref ref) {
  return ref.watch(installQueueProvider).hasActiveTasks();
}
