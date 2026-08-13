import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/i18n/install_messages.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/models/app_operation_batch.dart';
import '../../domain/models/app_operation_failure.dart';
import '../../domain/models/app_operation_target_snapshot.dart';
import '../../domain/models/linux_distribution.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_queue_state.dart';
import '../../domain/models/install_task.dart';
import '../../domain/models/installed_app.dart';
import '../../domain/repositories/legacy_app_operation_state_repository.dart';
import '../services/app_operation_batch_reducer.dart';
import '../services/app_operation_persistence_barrier.dart';
import '../services/app_operation_queue_reducer.dart';
import '../services/app_operation_recovery_service.dart';
import '../services/app_operation_state_store.dart';
import '../services/app_operation_task_executor.dart';
import 'application_dependency_providers.dart';
import 'global_provider.dart' show currentLocaleProvider;

part 'install_queue_provider.g.dart';

/// 历史记录最大保留条数
const int _maxHistorySize = 50;

// ---------------------------------------------------------------------------
// 基础 Provider
// ---------------------------------------------------------------------------

/// InstallMessages Provider - 根据当前 locale 获取国际化消息
@riverpod
InstallMessages installMessages(Ref ref) {
  final locale = ref.watch(currentLocaleProvider);
  return InstallMessages.fromLocale(locale);
}

// ---------------------------------------------------------------------------
// 安装队列 Provider
// ---------------------------------------------------------------------------

/// 安装队列状态机 Provider
///
/// 核心功能：
/// 1. 严格串行安装：一次只处理一个安装任务
/// 2. XDG Journal：应用崩溃后可恢复完整操作状态
/// 3. 持久化屏障：外部动作不得领先于可恢复事实
/// 4. 错误恢复：重试机制
/// 5. 取消状态管理：区分"用户取消"和"真正失败"
@Riverpod(keepAlive: true)
class InstallQueue extends _$InstallQueue {
  @override
  InstallQueueState build() {
    ref.onDispose(_disposeResources);
    final restoreResult = _resolveStateStore().restore();
    final initialPersistence = restoreResult.migrationPersistence;
    if (initialPersistence != null) {
      _persistenceBarrier.track(initialPersistence);
      unawaited(
        initialPersistence.catchError((Object error, StackTrace stackTrace) {
          AppLogger.error('旧安装队列迁移到 XDG State Journal 失败', error, stackTrace);
        }),
      );
    }
    return restoreResult.state;
  }

  /// 生成不可复用的任务和批次身份。
  final _uuid = const Uuid();

  /// 队列、当前任务和历史记录的纯状态规则。
  final AppOperationQueueReducer _queueReducer =
      const AppOperationQueueReducer();

  /// 批次和 Outbox 的纯状态规则。
  final AppOperationBatchReducer _batchReducer =
      const AppOperationBatchReducer();

  /// 崩溃恢复后的本机事实核验规则。
  final AppOperationRecoveryService _recoveryService =
      const AppOperationRecoveryService();

  /// 延迟构造的完整状态存储，避免测试替身必须执行正式 build。
  AppOperationStateStore? _stateStore;

  /// 当前唯一活动的 CLI 单任务执行器。
  AppOperationTaskExecutor? _activeExecutor;

  /// 终态提交后的下一任务延迟调度器。
  Timer? _nextTaskTimer;

  /// 用户取消标志（区分"用户取消"和"真正失败"）
  /// 参考 Rust 版本 InstallSlot.is_cancelled
  bool _isUserCancelled = false;

  /// 把高响应的内存发布与必须先落盘的外部动作连接起来。
  final AppOperationPersistenceBarrier _persistenceBarrier =
      AppOperationPersistenceBarrier();

  /// 延迟解析持久化依赖，兼容只覆盖 build 的轻量 Widget 测试 Notifier。
  AppOperationStateStore _resolveStateStore() {
    final existing = _stateStore;
    if (existing != null) {
      return existing;
    }
    final journal = ref.read(appOperationJournalRepositoryProvider);
    LegacyAppOperationStateRepository? legacyRepository;
    try {
      legacyRepository = ref.read(legacyAppOperationStateRepositoryProvider);
    } catch (_) {
      // 旧存储端口只用于迁移，缺失时仍可正常读取 Journal。
    }
    final store = AppOperationStateStore(
      journal: journal,
      legacyRepository: legacyRepository,
    );
    _stateStore = store;
    return store;
  }

  /// 异步保存完整状态；失败只记录诊断，关键动作由持久化屏障决定是否继续。
  Future<void> _persistState(InstallQueueState nextState) async {
    try {
      await _resolveStateStore().save(nextState);
    } catch (error, stackTrace) {
      AppLogger.error('应用操作状态持久化失败', error, stackTrace);
      rethrow;
    }
  }

  /// 原子更新内存状态并排队保存同一个完整 Journal 快照。
  Future<void> _commitState(InstallQueueState nextState) {
    state = nextState;
    final persistence = _persistState(nextState);
    _persistenceBarrier.track(persistence);
    // 普通进度更新不阻塞 UI；错误由 persistState 记录，关键动作还会通过屏障感知。
    unawaited(persistence.catchError((Object _, StackTrace _) {}));
    return persistence;
  }

  /// 等待调用期间出现的所有最新快照完成持久化。
  ///
  /// 生命周期协调器通过该入口保证 Outbox 先落盘再消费；队列执行器也用它保证
  /// 待执行任务和 currentTask 状态先落盘再启动 ll-cli。
  Future<void> waitForPendingPersistence() {
    return _persistenceBarrier.waitForLatest();
  }

  /// 延迟调度下一任务，并确保 Provider 释放后不再访问 Ref。
  void _scheduleNextTask() {
    _nextTaskTimer?.cancel();
    _nextTaskTimer = Timer(const Duration(milliseconds: 100), () {
      if (ref.mounted) {
        unawaited(startProcessing());
      }
    });
  }

  /// 只释放与指定任务匹配的活动执行器，避免旧回调终止新任务。
  void _disposeActiveExecutor({String? taskId}) {
    final executor = _activeExecutor;
    if (executor == null || (taskId != null && executor.taskId != taskId)) {
      return;
    }
    executor.dispose();
    _activeExecutor = null;
  }

  /// 释放单任务执行器和延迟调度资源。
  void _disposeResources() {
    _nextTaskTimer?.cancel();
    _nextTaskTimer = null;
    _disposeActiveExecutor();
  }

  // -----------------------------------------------------------------------
  // 取消标志管理
  // -----------------------------------------------------------------------

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

  // -----------------------------------------------------------------------
  // 入队操作
  // -----------------------------------------------------------------------

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
  /// 更新任务不允许携带 version，升级命令不接受版本号。
  String enqueueOperation({
    required InstallTaskKind kind,
    required String appId,
    required String appName,
    String? icon,
    String? version,
    AppOperationTargetSnapshot? target,
    bool force = false,
  }) {
    // 检查是否已在队列中
    if (state.isAppInQueue(appId)) {
      AppLogger.warning('App $appId is already in queue, skipping');
      return '';
    }

    // 升级任务必须不带版本号，否则后续命令构造会出错。
    final effectiveVersion = kind == InstallTaskKind.update ? null : version;
    final effectiveTarget =
        target ??
        AppOperationTargetSnapshot(
          appId: appId,
          displayName: appName,
          icon: icon,
          requestedInstallVersion: effectiveVersion,
        );

    final task = InstallTask(
      id: _generateTaskId(),
      appId: appId,
      appName: appName,
      icon: icon,
      kind: kind,
      target: effectiveTarget,
      version: effectiveVersion,
      force: force,
      status: InstallStatus.pending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    _commitState(state.copyWith(queue: [...state.queue, task]));

    AppLogger.info('Enqueued task: ${task.id} for app: $appId');

    // 如果当前没有正在处理的任务，开始处理队列
    if (!state.isProcessing && state.currentTask == null) {
      Future.microtask(() => startProcessing());
    }

    return task.id;
  }

  /// 批量入队安装/更新任务。
  List<String> enqueueBatchOperations(List<EnqueueTaskParams> tasksParams) {
    if (tasksParams.any((params) => params.kind != InstallTaskKind.update)) {
      AppLogger.warning('Rejected non-update task in update-all batch');
      return const <String>[];
    }

    final batchId = _generateBatchId();
    final taskIds = <String>[];
    final newTasks = <InstallTask>[];
    final targets = <AppOperationTargetSnapshot>[];
    final reservedAppIds = <String>{
      if (state.currentTask case final task?) task.appId,
      ...state.queue.map((task) => task.appId),
    };

    for (final params in tasksParams) {
      if (!reservedAppIds.add(params.appId)) {
        continue;
      }

      // 批量更新同样禁止携带版本号。
      final batchVersion = params.kind == InstallTaskKind.update
          ? null
          : params.version;
      final target =
          params.target ??
          AppOperationTargetSnapshot(
            appId: params.appId,
            displayName: params.appName,
            icon: params.icon,
            requestedInstallVersion: batchVersion,
          );

      final task = InstallTask(
        id: _generateTaskId(),
        batchId: batchId,
        appId: params.appId,
        appName: params.appName,
        icon: params.icon,
        kind: params.kind,
        target: target,
        version: batchVersion,
        force: params.force,
        status: InstallStatus.pending,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      taskIds.add(task.id);
      targets.add(target);
      newTasks.add(task);
    }

    if (newTasks.isNotEmpty) {
      final batch = AppOperationBatch(
        id: batchId,
        taskIds: taskIds,
        targets: targets,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      _commitState(
        state.copyWith(
          queue: [...state.queue, ...newTasks],
          batches: [...state.batches, batch],
        ),
      );
      AppLogger.info(
        'Enqueued ${newTasks.length} tasks in update batch $batchId',
      );

      if (!state.isProcessing && state.currentTask == null) {
        Future.microtask(() => startProcessing());
      }
    }

    return taskIds;
  }

  // -----------------------------------------------------------------------
  // 队列处理
  // -----------------------------------------------------------------------

  /// 开始处理队列中的下一个任务
  ///
  /// 严格串行安装：同一时间只处理一个任务
  Future<void> startProcessing() async {
    // 队列完成后会延迟调度下一轮处理；页面/测试容器释放后不能再访问 ref。
    if (!ref.mounted) return;
    await processQueue();
  }

  /// 处理队列
  Future<void> processQueue() async {
    try {
      // 入队和终态更新通常由微任务触发下一轮处理；先等待最新快照，确保即将
      // 执行的任务或上一任务的终态已经成为可恢复事实。
      await waitForPendingPersistence();
    } catch (error, stackTrace) {
      AppLogger.error('队列状态尚未持久化，暂停启动下一任务', error, stackTrace);
      return;
    }

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
    final previousState = state;

    // 重置取消标志（确保每次安装都是干净的状态）
    _resetCancelFlag();

    // 更新状态为安装中
    final installingTask = task.copyWith(
      status: InstallStatus.installing,
      messageCode: AppOperationMessageCode.preparing,
      startedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _commitState(_queueReducer.promoteTask(state: state, task: installingTask));

    try {
      await waitForPendingPersistence();
    } catch (error, stackTrace) {
      AppLogger.error(
        '当前任务状态无法持久化，未启动 ll-cli: ${task.appId}',
        error,
        stackTrace,
      );
      // processQueue 已确认 previousState 是最近一次 durable 状态；只有当前任务
      // 未被其他操作替换时才回滚内存，避免覆盖等待期间发生的更新。
      if (state.currentTask?.id == task.id) {
        state = previousState;
      }
      return;
    }
    if (!ref.mounted || state.currentTask?.id != task.id) {
      return;
    }

    AppLogger.info('Processing task: ${task.id} for app: ${task.appId}');
    final executor = AppOperationTaskExecutor(
      repository: ref.read(linglongCliRepositoryProvider),
      task: task,
    );
    _activeExecutor?.dispose();
    _activeExecutor = executor;
    try {
      await executor.execute(_handleExecutionEvent);
    } finally {
      if (identical(_activeExecutor, executor)) {
        _activeExecutor = null;
      }
      executor.dispose();
    }
  }

  // -----------------------------------------------------------------------
  // 进度处理
  // -----------------------------------------------------------------------

  /// 把执行器事件编排为队列状态变更。
  void _handleExecutionEvent(AppOperationExecutionEvent event) {
    if (!ref.mounted || state.currentTask?.id != event.taskId) {
      return;
    }
    switch (event) {
      case AppOperationProgressEvent():
        _handleProgress(event.taskId, event.progress);
      case AppOperationTimeoutEvent():
        AppLogger.warning('Install timeout for ${state.currentTask?.appId}');
        _markFailed(
          event.taskId,
          _buildFailure(
            taskId: event.taskId,
            kind: AppOperationFailureKind.timeout,
            diagnostic: 'No install progress received before timeout',
          ),
        );
      case AppOperationStreamFailedEvent():
        AppLogger.error(
          'Install request failed for ${state.currentTask?.appId}',
          event.error,
          event.stackTrace,
        );
        _markFailed(
          event.taskId,
          _buildFailure(
            taskId: event.taskId,
            kind: AppOperationFailureKind.execution,
            diagnostic: event.error.toString(),
          ),
        );
      case AppOperationStreamEndedEvent():
        final currentTask = state.currentTask;
        if (currentTask == null || currentTask.id != event.taskId) {
          return;
        }
        // 无终态结束无法证明成功，历史版本安装尤其不能乐观完成。
        _markFailed(
          event.taskId,
          _buildFailure(
            taskId: event.taskId,
            kind: AppOperationFailureKind.streamEndedWithoutTerminal,
            diagnostic: 'Operation stream ended without terminal event',
          ),
        );
    }
  }

  /// 处理安装进度
  void _handleProgress(String taskId, InstallProgress progress) {
    final currentTask = state.currentTask;
    if (currentTask == null || currentTask.id != taskId) return;

    final appId = currentTask.appId;
    if (progress.status == InstallStatus.cancelled) {
      AppLogger.info('[InstallQueue] 收到取消状态: $appId');
    }

    _commitState(
      _queueReducer.applyProgress(
        state: state,
        taskId: taskId,
        progress: progress,
      ),
    );

    // 检查是否完成
    if (progress.status == InstallStatus.success) {
      _markSuccess(taskId);
    } else if (progress.status == InstallStatus.failed) {
      final failure =
          progress.failure ??
          _buildFailure(
            taskId: taskId,
            kind: progress.errorCode == null
                ? AppOperationFailureKind.execution
                : AppOperationFailureKind.cli,
            cliCode: progress.errorCode,
            diagnostic:
                progress.errorDetail ?? progress.rawMessage ?? progress.error,
          );
      _markFailed(
        taskId,
        _withFailureGuidance(taskId: taskId, failure: failure),
      );
    } else if (progress.status == InstallStatus.cancelled) {
      // 取消状态：停止超时检查，更新历史记录
      _handleCancelledProgress(taskId);
    }
  }

  /// 处理取消状态（从安装流中收到 cancelled 状态）
  void _handleCancelledProgress(String taskId) {
    final currentTask = state.currentTask;
    if (currentTask == null || currentTask.id != taskId) return;

    _disposeActiveExecutor(taskId: taskId);

    final cancelledTask = currentTask.copyWith(
      status: InstallStatus.cancelled,
      finishedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _commitTerminalTask(cancelledTask);
    AppLogger.info('[InstallQueue] 任务已从流中标记取消: ${currentTask.appId}');

    _scheduleNextTask();
  }

  // -----------------------------------------------------------------------
  // 任务完成 / 失败
  // -----------------------------------------------------------------------

  /// 标记成功
  ///
  /// 将当前任务标记为成功，添加到历史记录，并处理下一个任务
  void _markSuccess(String taskId) {
    final currentTask = state.currentTask;
    if (currentTask == null || currentTask.id != taskId) {
      AppLogger.warning(
        'markSuccess called for task $taskId but current task is ${currentTask?.id}',
      );
      return;
    }

    final appId = currentTask.appId;

    _disposeActiveExecutor(taskId: taskId);

    final completedTask = currentTask.copyWith(
      status: InstallStatus.success,
      progress: 100,
      messageCode: AppOperationMessageCode.completed,
      finishedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _commitTerminalTask(completedTask);
    AppLogger.info('Task completed successfully: $appId');

    _scheduleNextTask();
  }

  /// 标记失败
  ///
  /// 将当前任务标记为失败，记录错误信息，继续处理下一个任务
  /// 会自动检测是否为用户取消，并设置正确的状态
  void _markFailed(String taskId, AppOperationFailure failure) {
    final currentTask = state.currentTask;
    if (currentTask == null || currentTask.id != taskId) {
      AppLogger.warning(
        'markFailed called for task $taskId but current task is ${currentTask?.id}',
      );
      return;
    }

    final appId = currentTask.appId;

    _disposeActiveExecutor(taskId: taskId);

    // 检查是否为用户取消（参考 Rust 版本 InstallSlot.is_cancelled）
    final wasCancelled = isUserCancelled();

    // 根据取消状态决定任务状态
    final failedTask = currentTask.copyWith(
      status: wasCancelled ? InstallStatus.cancelled : InstallStatus.failed,
      failure: wasCancelled ? null : failure,
      finishedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _commitTerminalTask(failedTask);

    if (wasCancelled) {
      AppLogger.info('Task cancelled by user: $appId');
    } else {
      AppLogger.error(
        'Task failed: $appId, kind=${failure.kind.name}, '
        'code=${failure.cliCode}, diagnostic=${failure.diagnostic}',
      );
    }

    _scheduleNextTask();
  }

  /// 提交任务终态，并在同一个状态快照中派生任务和批次 Outbox 事件。
  ///
  /// 该入口保证重复终态消息不会重复创建 effect；批次完成判断只检查自己的
  /// taskIds，不受之后入队的其他操作影响。
  void _commitTerminalTask(
    InstallTask terminalTask, {
    bool clearCurrentTask = true,
  }) {
    final batchId = terminalTask.batchId;
    if (batchId != null && !state.batches.any((batch) => batch.id == batchId)) {
      AppLogger.warning('Task references missing update batch: $batchId');
    }
    _commitState(
      _queueReducer.commitTerminalTask(
        state: state,
        terminalTask: terminalTask,
        nowTimestamp: _nowTimestamp(),
        maxHistorySize: _maxHistorySize,
        clearCurrentTask: clearCurrentTask,
      ),
    );
  }

  AppOperationFailure _buildFailure({
    required String taskId,
    required AppOperationFailureKind kind,
    int? cliCode,
    String? diagnostic,
  }) {
    final task = state.currentTask;
    final scenario = task != null && task.id == taskId && task.isUpdateTask
        ? LinuxDistributionGuidanceScenario.appUpdateFailure
        : LinuxDistributionGuidanceScenario.appInstallFailure;
    return AppOperationFailure(
      kind: kind,
      cliCode: cliCode,
      diagnostic: diagnostic,
      guidanceScenario: scenario,
    );
  }

  /// 为旧测试替身或过渡期调用方补齐失败提示场景。
  AppOperationFailure _withFailureGuidance({
    required String taskId,
    required AppOperationFailure failure,
  }) {
    if (failure.guidanceScenario != null) {
      return failure;
    }
    return failure.copyWith(
      guidanceScenario: _buildFailure(
        taskId: taskId,
        kind: failure.kind,
      ).guidanceScenario,
    );
  }

  // -----------------------------------------------------------------------
  // 取消 / 移除 / 清空
  // -----------------------------------------------------------------------

  /// 取消任务
  ///
  /// 取消当前正在执行的任务或从队列中移除
  ///
  /// 参考精确 PID 协作取消流程：
  /// 1. 通过当前执行器调用 CLI Repository 的精确取消入口
  /// 2. 系统级 SIGTERM 成功后标记取消状态（`markUserCancelled`）
  /// 3. 更新任务状态为 `cancelled`
  Future<bool> cancelTask(String appId) async {
    final currentTask = state.currentTask;
    if (currentTask != null && currentTask.appId == appId) {
      // 只有精确 PID 协作取消成功时，才能把 UI 状态落为已取消。
      bool cancelSuccess = false;
      try {
        final executor = _activeExecutor;
        cancelSuccess = executor != null && executor.taskId == currentTask.id
            ? await executor.cancel()
            : await ref
                  .read(linglongCliRepositoryProvider)
                  .cancelOperation(appId, kind: currentTask.kind);
      } catch (e) {
        AppLogger.error('[InstallQueue] 取消安装失败: $appId', e);
      }

      if (!cancelSuccess) {
        // 授权取消或 SIGTERM 失败时，安装可能仍在后台继续，必须保持当前任务。
        _resetCancelFlag();
        AppLogger.warning('[InstallQueue] 取消安装未完成，保持任务继续运行: $appId');
        return false;
      }

      // 标记为用户取消（参考 Rust 版本 InstallSlot.mark_cancelled）
      markUserCancelled();

      _disposeActiveExecutor(taskId: currentTask.id);

      final activeTask = state.currentTask;
      if (activeTask?.id != currentTask.id) {
        // 取消等待期间任务可能已由 CLI 流终结，标志不得泄漏到下一任务。
        _resetCancelFlag();
        AppLogger.info('[InstallQueue] 任务已由进度流完成取消: $appId');
        return true;
      }

      const cancellationLog = 'Operation cancelled by user';

      final cancelledTask = _queueReducer
          .appendCommandOutput(activeTask!, cancellationLog)
          .copyWith(
            status: InstallStatus.cancelled,
            finishedAt: DateTime.now().millisecondsSinceEpoch,
          );

      _commitTerminalTask(cancelledTask);
      AppLogger.info('[InstallQueue] 任务已取消: $appId');

      _scheduleNextTask();

      return true;
    }

    return _removeFirstQueuedTaskForApp(appId);
  }

  /// 从等待队列中移除指定任务，不影响同应用的其他 item 或历史记录。
  void removeQueuedTask(String taskId) {
    final queuedTask = state.queue
        .where((task) => task.id == taskId)
        .firstOrNull;
    if (queuedTask == null) {
      return;
    }
    _commitState(_queueReducer.removeQueuedTask(state, taskId));
    if (queuedTask.batchId != null) {
      _commitTerminalTask(
        queuedTask.copyWith(
          status: InstallStatus.cancelled,
          finishedAt: _nowTimestamp(),
        ),
        clearCurrentTask: false,
      );
    }
  }

  /// 从历史记录中移除指定任务，不影响同应用的其他历史 item。
  void removeHistoryTask(String taskId) {
    _commitState(_queueReducer.removeHistoryTask(state, taskId));
  }

  /// 兼容旧调用：按 appId 只移除第一个等待任务，不再触碰历史记录。
  void removeFromQueue(String appId) {
    _removeFirstQueuedTaskForApp(appId);
  }

  bool _removeFirstQueuedTaskForApp(String appId) {
    final index = state.queue.indexWhere((task) => task.appId == appId);
    if (index < 0) {
      return false;
    }
    removeQueuedTask(state.queue[index].id);
    return true;
  }

  /// 清空历史记录
  void clearHistory() {
    _commitState(state.copyWith(history: []));
  }

  /// 清空队列
  void clearQueue() {
    final batchTasks = state.queue
        .where((task) => task.batchId != null)
        .toList();
    _commitState(_queueReducer.clearQueue(state));
    for (final task in batchTasks) {
      _commitTerminalTask(
        task.copyWith(
          status: InstallStatus.cancelled,
          finishedAt: _nowTimestamp(),
        ),
        clearCurrentTask: false,
      );
    }
    AppLogger.info('Queue cleared');
  }

  /// 记录生命周期协调器对某条 Outbox 事件的消费尝试。
  ///
  /// 尝试次数和领域状态写入同一 Journal，应用在副作用执行期间退出后可以
  /// 继续消费；通知使用稳定 ID，重复提交时由系统尽量替换旧通知。
  void markEffectAttempt(String effectId) {
    final nextState = _batchReducer.markEffectAttempt(
      state: state,
      effectId: effectId,
      nowTimestamp: _nowTimestamp(),
    );
    if (!identical(nextState, state)) {
      _commitState(nextState);
    }
  }

  /// 原子确认 Outbox 事件，并可同时写入批次通知结果。
  ///
  /// 通知状态只允许随对应批次完成事件确认，避免事件已删除但状态仍为 pending
  /// 的不一致快照。未知事件按幂等确认处理，不修改当前状态。
  void acknowledgeEffect(
    String effectId, {
    AppOperationNotificationState? notificationState,
  }) {
    final nextState = _batchReducer.acknowledgeEffect(
      state: state,
      effectId: effectId,
      notificationState: notificationState,
    );
    if (!identical(nextState, state)) {
      _commitState(nextState);
    }
  }

  // -----------------------------------------------------------------------
  // 崩溃恢复 / 重试
  // -----------------------------------------------------------------------

  /// 崩溃恢复检查
  ///
  /// 在应用启动时调用，检查是否有未完成的任务
  Future<void> checkRecovery(List<InstalledApp> installedApps) async {
    final persistedTask = state.currentTask;
    if (persistedTask == null) {
      AppLogger.info('No persisted task to recover');
      return;
    }

    AppLogger.info('Recovering task for app: ${persistedTask.appId}');

    final recovery = _recoveryService.evaluate(persistedTask, installedApps);

    if (recovery.status == AppOperationRecoveryStatus.verifiedSuccess) {
      AppLogger.info(
        'Recovered ${persistedTask.appId} at verified target version '
        '${recovery.installedTarget?.version}',
      );

      final successTask = persistedTask.copyWith(
        status: InstallStatus.success,
        progress: 100,
        messageCode: AppOperationMessageCode.completed,
        finishedAt: DateTime.now().millisecondsSinceEpoch,
      );

      _commitTerminalTask(successTask);
    } else {
      AppLogger.warning(
        'Unable to prove recovered task success: app=${persistedTask.appId}, '
        'old=${persistedTask.target?.installedVersion}, '
        'expected=${persistedTask.target?.expectedVersion}, '
        'actual=${recovery.installedTarget?.version}',
      );

      final interruptedTask = persistedTask.copyWith(
        status: InstallStatus.interrupted,
        failure: AppOperationFailure(
          kind: AppOperationFailureKind.interrupted,
          diagnostic: 'Operation interrupted before recovery verification',
          guidanceScenario: persistedTask.isUpdateTask
              ? LinuxDistributionGuidanceScenario.appUpdateFailure
              : LinuxDistributionGuidanceScenario.appInstallFailure,
        ),
        finishedAt: DateTime.now().millisecondsSinceEpoch,
      );

      _commitTerminalTask(interruptedTask);
    }
  }

  /// 重试失败的任务。
  ///
  /// 旧入口按 appId 找到第一条失败记录后委托给精确的 taskId 入口，
  /// 保持外部兼容但避免一次删除同应用的多条历史。
  void retryFailed(String appId) {
    final failedTask = state.history
        .where(
          (task) => task.appId == appId && task.status == InstallStatus.failed,
        )
        .firstOrNull;
    if (failedTask == null) {
      return;
    }
    retryFailedTask(failedTask.id);
  }

  /// 按任务 ID 重试失败记录，并保留原始 install/update 类型与版本参数。
  void retryFailedTask(String taskId) {
    final failedTask = state.history
        .where((task) => task.id == taskId)
        .firstOrNull;
    if (failedTask == null || failedTask.status != InstallStatus.failed) {
      return;
    }
    if (state.isAppInQueue(failedTask.appId)) {
      AppLogger.warning(
        'App ${failedTask.appId} is already in queue, skipping retry',
      );
      return;
    }

    _commitState(
      state.copyWith(
        history: state.history.where((task) => task.id != taskId).toList(),
      ),
    );

    enqueueOperation(
      kind: failedTask.kind,
      appId: failedTask.appId,
      appName: failedTask.appName,
      icon: failedTask.icon,
      version: failedTask.version,
      target: failedTask.target,
      force: failedTask.force,
    );
  }

  // -----------------------------------------------------------------------
  // 内部工具方法
  // -----------------------------------------------------------------------

  /// 生成唯一任务ID
  String _generateTaskId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4().substring(0, 8)}';
  }

  /// 生成稳定批次 ID。
  String _generateBatchId() {
    return '${_nowTimestamp()}-${_uuid.v4()}';
  }

  /// 获取当前毫秒时间戳，统一批次与事件落盘口径。
  int _nowTimestamp() => DateTime.now().millisecondsSinceEpoch;
}

// ---------------------------------------------------------------------------
// 入队任务参数 DTO
// ---------------------------------------------------------------------------

/// 入队任务参数
class EnqueueTaskParams {
  const EnqueueTaskParams({
    required this.kind,
    required this.appId,
    required this.appName,
    this.icon,
    this.version,
    this.target,
    this.force = false,
  });

  final InstallTaskKind kind;
  final String appId;
  final String appName;
  final String? icon;
  final String? version;
  final AppOperationTargetSnapshot? target;
  final bool force;
}

// ---------------------------------------------------------------------------
// 便捷访问 Provider
// ---------------------------------------------------------------------------

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
