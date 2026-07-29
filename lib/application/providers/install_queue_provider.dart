import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/app_xdg_paths.dart';
import '../../data/repositories/file_app_operation_journal_repository.dart';
import '../../core/i18n/install_messages.dart';
import '../../core/logging/app_logger.dart';
import '../../core/di/providers.dart'
    show analyticsRepositoryProvider, currentLocaleProvider;
import 'linglong_env_provider.dart';
import '../../domain/models/app_operation_batch.dart';
import '../../domain/models/app_operation_target_snapshot.dart';
import '../../domain/models/linux_distribution.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_queue_state.dart';
import '../../domain/models/install_state_machine.dart';
import '../../domain/models/install_task.dart';
import '../../domain/models/installed_app.dart';
import '../../domain/repositories/app_operation_journal_repository.dart';
import '../../domain/repositories/linglong_cli_repository.dart';
import '../../data/repositories/linglong_cli_repository_impl.dart';

part 'install_queue_provider.g.dart';

// ---------------------------------------------------------------------------
// 本地存储 key
// ---------------------------------------------------------------------------

/// 本地存储 key：当前正在处理的任务
const String _kCurrentTaskKey = 'linglong-store-current-install-task';

/// 本地存储 key：待处理队列
const String _kQueueKey = 'linglong-store-install-queue';

/// 历史记录最大保留条数
const int _maxHistorySize = 50;

// ---------------------------------------------------------------------------
// 基础 Provider
// ---------------------------------------------------------------------------

/// SharedPreferences Provider
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('SharedPreferences not initialized');
}

/// InstallMessages Provider - 根据当前 locale 获取国际化消息
@riverpod
InstallMessages installMessages(Ref ref) {
  final locale = ref.watch(currentLocaleProvider);
  return InstallMessages.fromLocale(locale);
}

/// Linglong CLI Repository Provider
@riverpod
LinglongCliRepository linglongCliRepository(Ref ref) {
  final messages = ref.watch(installMessagesProvider);
  return LinglongCliRepositoryImpl(messages);
}

/// 应用操作 Journal Provider。
///
/// 生产环境固定使用 XDG State 目录；测试可覆盖为内存实现，避免触碰用户状态。
@Riverpod(keepAlive: true)
AppOperationJournalRepository appOperationJournalRepository(Ref ref) {
  final journalPath = AppXdgPaths.resolveOperationJournalFilePath();
  if (journalPath == null) {
    throw StateError('无法解析 XDG 应用操作 Journal 路径');
  }
  return FileAppOperationJournalRepository(File(journalPath));
}

// ---------------------------------------------------------------------------
// 持久化 Mixin
// ---------------------------------------------------------------------------

/// 安装队列持久化能力 mixin。
///
/// 提供队列和当前任务的读写能力，供 [InstallQueue] 混入使用。
mixin _InstallQueuePersistence {
  /// Riverpod ref，由混入类提供。
  Ref get ref;

  AppOperationJournalRepository? _journal;

  /// 读取 SharedPreferences（安全兜底，失败返回 null）
  SharedPreferences? _readSharedPreferences() {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  /// 从 XDG State Journal 恢复队列状态（同步）。
  ///
  /// Journal 尚不存在时只执行一次旧 SharedPreferences 迁移；新快照成功
  /// 落盘后才删除旧 key，避免迁移中断造成活跃任务丢失。
  InstallQueueState restorePersistedState() {
    try {
      _journal = ref.read(appOperationJournalRepositoryProvider);
      final snapshot = _journal!.load();
      if (snapshot != null) {
        return InstallQueueState.fromJournalSnapshot(snapshot);
      }
    } catch (error, stackTrace) {
      AppLogger.error('应用操作 Journal 恢复失败', error, stackTrace);
    }

    final prefs = _readSharedPreferences();
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
          'Migrating legacy install queue: current=${currentTask?.appId}, pending=${queue.length}',
        );
      }

      final restoredState = InstallQueueState(
        currentTask: currentTask,
        queue: queue,
      );
      final journal = _journal;
      if (journal != null && (currentTask != null || queue.isNotEmpty)) {
        unawaited(
          journal
              .save(restoredState.toJournalSnapshot())
              .then((_) async {
                await prefs.remove(_kCurrentTaskKey);
                await prefs.remove(_kQueueKey);
              })
              .catchError((Object error, StackTrace stackTrace) {
                AppLogger.error(
                  '旧安装队列迁移到 XDG State Journal 失败',
                  error,
                  stackTrace,
                );
              }),
        );
      }
      return restoredState;
    } catch (e, s) {
      AppLogger.error('Failed to restore persisted install queue state', e, s);
      return const InstallQueueState();
    }
  }

  /// 异步保存完整状态；写入失败只记录诊断，不回滚正在执行的内存状态。
  Future<void> persistState(InstallQueueState nextState) async {
    final journal = _journal;
    if (journal == null) {
      return;
    }
    try {
      await journal.save(nextState.toJournalSnapshot());
    } catch (error, stackTrace) {
      AppLogger.error('应用操作状态持久化失败', error, stackTrace);
    }
  }
}

// ---------------------------------------------------------------------------
// 安装队列 Provider
// ---------------------------------------------------------------------------

/// 安装队列状态机 Provider
///
/// 核心功能：
/// 1. 严格串行安装：一次只处理一个安装任务
/// 2. 持久化存储：应用崩溃后可恢复队列
/// 3. 状态持久：保存到 SharedPreferences
/// 4. 错误恢复：重试机制
/// 5. 取消状态管理：区分"用户取消"和"真正失败"
@Riverpod(keepAlive: true)
class InstallQueue extends _$InstallQueue with _InstallQueuePersistence {
  @override
  InstallQueueState build() {
    // 在 build 阶段直接同步恢复本地状态，避免未初始化 _prefs 时触发异步读取，
    // 同时规避 Provider 在首帧构建期间被再次写入导致的生命周期告警。
    return restorePersistedState();
  }

  final _uuid = const Uuid();

  /// 安装状态机（用于超时检测）
  InstallStateMachine? _stateMachine;

  /// 超时检查定时器
  Timer? _timeoutCheckTimer;

  /// 用户取消标志（区分"用户取消"和"真正失败"）
  /// 参考 Rust 版本 InstallSlot.is_cancelled
  bool _isUserCancelled = false;

  /// 原子更新内存状态并排队保存同一个完整 Journal 快照。
  void _commitState(InstallQueueState nextState) {
    state = nextState;
    unawaited(persistState(nextState));
  }

  String _appendOutputLine(String currentOutput, String? outputLine) {
    final line = outputLine?.trimRight();
    if (line == null || line.isEmpty) {
      return currentOutput;
    }
    if (currentOutput.isEmpty) {
      return line;
    }
    return '$currentOutput\n$line';
  }

  InstallTask _appendCommandOutput(InstallTask task, String? outputLine) {
    final nextOutput = _appendOutputLine(task.commandOutput, outputLine);
    if (nextOutput == task.commandOutput) {
      return task;
    }
    return task.copyWith(commandOutput: nextOutput);
  }

  // -----------------------------------------------------------------------
  // 超时检查
  // -----------------------------------------------------------------------

  /// 启动超时检查定时器
  void _startTimeoutCheck(String taskId, String appId) {
    _stopTimeoutCheck();
    // 每隔超时时间的一半检查一次
    final checkInterval = Duration(
      seconds: (_stateMachine?.progressTimeoutSecs ?? 360) ~/ 2,
    );
    _timeoutCheckTimer = Timer.periodic(checkInterval, (_) {
      if (_stateMachine?.checkTimeout() == true) {
        AppLogger.warning('Install timeout for $appId');
        _stateMachine?.onFailure();
        _markFailed(
          taskId,
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

    final kindTask = InstallTask(
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
    // 使用国际化消息
    final messages = ref.read(installMessagesProvider);
    final operation = kind == InstallTaskKind.update
        ? messages.updateLabel
        : messages.installLabel;
    final task = InstallTask(
      id: kindTask.id,
      appId: kindTask.appId,
      appName: kindTask.appName,
      icon: kindTask.icon,
      kind: kindTask.kind,
      target: kindTask.target,
      version: kindTask.version,
      force: kindTask.force,
      status: kindTask.status,
      createdAt: kindTask.createdAt,
      message: messages.waitingFor(operation),
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
    final messages = ref.read(installMessagesProvider);
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
      final operation = params.kind == InstallTaskKind.update
          ? messages.updateLabel
          : messages.installLabel;
      newTasks.add(task.copyWith(message: messages.waitingFor(operation)));
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

    // 使用国际化消息
    final messages = ref.read(installMessagesProvider);
    final operation = task.isUpdateTask
        ? messages.updateLabel
        : messages.installLabel;

    // 更新状态为安装中
    final installingTask = task.copyWith(
      status: InstallStatus.installing,
      message: messages.preparing(operation, task.appId),
      startedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _commitState(
      state.copyWith(
        isProcessing: true,
        queue: remainingQueue,
        currentTask: installingTask,
      ),
    );

    // 启动状态机和超时检查
    _stateMachine = InstallStateMachine();
    _stateMachine!.start();
    _startTimeoutCheck(task.id, task.appId);

    AppLogger.info('Processing task: ${task.id} for app: ${task.appId}');

    try {
      // 获取 CLI Repository
      final cliRepo = ref.read(linglongCliRepositoryProvider);

      // 监听安装进度流
      final progressStream = task.kind == InstallTaskKind.update
          ? cliRepo.updateApp(task.appId)
          : cliRepo.installApp(
              task.appId,
              version: task.version,
              force: task.force,
            );
      await for (final progress in progressStream) {
        _handleProgress(task.id, progress);
      }

      // 注意：安装成功的标记可能由进度流中的 success 状态触发
      // 如果流正常结束但没有标记成功/取消/失败，这里手动检查
      if (state.currentTask?.id == task.id &&
          state.currentTask?.status != InstallStatus.success &&
          state.currentTask?.status != InstallStatus.cancelled &&
          state.currentTask?.status != InstallStatus.failed) {
        // 检查状态机状态
        if (_stateMachine?.state == InstallStateMachineState.succeeded) {
          _markSuccess(task.id);
        } else if (_stateMachine?.state != InstallStateMachineState.failed) {
          // 若底层流结束时仍未给出 success/failed/cancelled 终态，
          // 不能乐观推断成功；否则历史版本安装会出现“假完成”。
          _stateMachine?.onFailure();
          _markFailed(task.id, messages.confirmFailed(operation));
        }
      }
    } catch (e, s) {
      AppLogger.error('Install request failed for ${task.appId}', e, s);
      _stateMachine?.onFailure();
      _markFailed(task.id, e.toString());
    }
  }

  // -----------------------------------------------------------------------
  // 进度处理
  // -----------------------------------------------------------------------

  /// 处理安装进度
  void _handleProgress(String taskId, InstallProgress progress) {
    final currentTask = state.currentTask;
    if (currentTask == null || currentTask.id != taskId) return;

    final appId = currentTask.appId;

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

    final updatedTask = _appendCommandOutput(currentTask, progress.outputLine)
        .copyWith(
          status: progress.status,
          progress: progress.progress,
          message: progress.message,
          rawMessage: progress.rawMessage,
          errorMessage: progress.error,
          errorCode: progress.errorCode,
          errorDetail: progress.errorDetail ?? progress.rawMessage,
        );

    _commitState(state.copyWith(currentTask: updatedTask));

    // 检查是否完成
    if (progress.status == InstallStatus.success) {
      _markSuccess(taskId);
    } else if (progress.status == InstallStatus.failed) {
      _markFailed(
        taskId,
        progress.error ?? '安装失败',
        errorCode: progress.errorCode,
        errorDetail: progress.errorDetail ?? progress.rawMessage,
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

    // 停止超时检查和清理状态机
    _stopTimeoutCheck();
    _stateMachine?.dispose();
    _stateMachine = null;

    // 使用国际化消息
    final messages = ref.read(installMessagesProvider);
    final operation = currentTask.isUpdateTask
        ? messages.updateLabel
        : messages.installLabel;

    final cancelledTask = currentTask.copyWith(
      status: InstallStatus.cancelled,
      message: messages.cancelled(operation),
      finishedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _commitTerminalTask(cancelledTask);
    AppLogger.info('[InstallQueue] 任务已从流中标记取消: ${currentTask.appId}');

    // 处理下一个任务
    Future.delayed(const Duration(milliseconds: 100), () => startProcessing());
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

    // 停止超时检查和清理状态机
    _stopTimeoutCheck();
    _stateMachine?.dispose();
    _stateMachine = null;

    // 使用国际化消息
    final messages = ref.read(installMessagesProvider);
    final operation = currentTask.isUpdateTask
        ? messages.updateLabel
        : messages.installLabel;

    final completedTask = currentTask.copyWith(
      status: InstallStatus.success,
      progress: 100,
      message: messages.completed(operation),
      finishedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _commitTerminalTask(completedTask);
    AppLogger.info('Task completed successfully: $appId');

    // 上报安装/更新统计记录（fire-and-forget）
    ref
        .read(analyticsRepositoryProvider)
        .reportInstall(
          completedTask.appId,
          completedTask.version ?? 'unknown',
          appName: completedTask.appName,
        );

    // 处理下一个任务
    Future.delayed(const Duration(milliseconds: 100), () => startProcessing());
  }

  /// 标记失败
  ///
  /// 将当前任务标记为失败，记录错误信息，继续处理下一个任务
  /// 会自动检测是否为用户取消，并设置正确的状态
  void _markFailed(
    String taskId,
    String error, {
    int? errorCode,
    String? errorDetail,
  }) {
    final currentTask = state.currentTask;
    if (currentTask == null || currentTask.id != taskId) {
      AppLogger.warning(
        'markFailed called for task $taskId but current task is ${currentTask?.id}',
      );
      return;
    }

    final appId = currentTask.appId;

    // 停止超时检查和清理状态机
    _stopTimeoutCheck();
    _stateMachine?.dispose();
    _stateMachine = null;

    // 检查是否为用户取消（参考 Rust 版本 InstallSlot.is_cancelled）
    final wasCancelled = isUserCancelled();

    // 使用国际化消息
    final messages = ref.read(installMessagesProvider);
    final operation = currentTask.isUpdateTask
        ? messages.updateLabel
        : messages.installLabel;
    final cancelledMsg = messages.cancelled(operation);
    final resolvedError = wasCancelled
        ? cancelledMsg
        : _decorateFailureMessageForCurrentPlatform(
            task: currentTask,
            message: error,
            messages: messages,
          );

    // 根据取消状态决定任务状态
    final failedTask = currentTask.copyWith(
      status: wasCancelled ? InstallStatus.cancelled : InstallStatus.failed,
      errorMessage: resolvedError,
      errorCode: wasCancelled ? null : errorCode,
      errorDetail: wasCancelled ? null : errorDetail,
      message: resolvedError,
      finishedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _commitTerminalTask(failedTask);

    if (wasCancelled) {
      AppLogger.info('Task cancelled by user: $appId');
    } else {
      AppLogger.error('Task failed: $appId, error: $error, code: $errorCode');
    }

    // 继续处理下一个任务（失败不阻塞队列）
    Future.delayed(const Duration(milliseconds: 100), () => startProcessing());
  }

  /// 提交任务终态，并在同一个状态快照中派生任务和批次 Outbox 事件。
  ///
  /// 该入口保证重复终态消息不会重复创建 effect；批次完成判断只检查自己的
  /// taskIds，不受之后入队的其他操作影响。
  void _commitTerminalTask(
    InstallTask terminalTask, {
    bool clearCurrentTask = true,
  }) {
    final nextHistory = <InstallTask>[
      terminalTask,
      ...state.history.where((task) => task.id != terminalTask.id),
    ];
    var nextState = state.copyWith(
      clearCurrentTask: clearCurrentTask,
      isProcessing: clearCurrentTask ? false : state.isProcessing,
      history: _retainBoundedHistory(nextHistory),
    );

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
              createdAt: terminalTask.finishedAt ?? _nowTimestamp(),
            ),
          ],
        );
      }
    }

    final batchId = terminalTask.batchId;
    if (batchId != null) {
      nextState = _completeBatchIfReady(nextState, batchId);
    }

    _commitState(nextState);
  }

  /// 当指定批次全部进入终态时，仅创建一次完成事件。
  InstallQueueState _completeBatchIfReady(
    InstallQueueState candidate,
    String batchId,
  ) {
    final batchIndex = candidate.batches.indexWhere(
      (batch) => batch.id == batchId,
    );
    if (batchIndex < 0) {
      AppLogger.warning('Task references missing update batch: $batchId');
      return candidate;
    }

    final batch = candidate.batches[batchIndex];
    if (batch.status == AppOperationBatchStatus.completed) {
      return candidate;
    }

    final tasksById = <String, InstallTask>{
      for (final task in candidate.allTasks) task.id: task,
    };
    final isCompleted = batch.taskIds.every(
      (taskId) => tasksById[taskId]?.isCompleted == true,
    );
    if (!isCompleted) {
      return candidate;
    }

    final completedBatch = batch.copyWith(
      status: AppOperationBatchStatus.completed,
      finishedAt: _nowTimestamp(),
      notificationState: AppOperationNotificationState.pending,
    );
    final batches = [...candidate.batches];
    batches[batchIndex] = completedBatch;

    final effectId = 'update-batch-completed-$batchId';
    final outbox = candidate.outbox.any((effect) => effect.id == effectId)
        ? candidate.outbox
        : [
            ...candidate.outbox,
            AppOperationEffect(
              id: effectId,
              type: AppOperationEffectType.updateBatchCompleted,
              aggregateId: batchId,
              createdAt: completedBatch.finishedAt!,
            ),
          ];

    return candidate.copyWith(batches: batches, outbox: outbox);
  }

  /// 限制普通历史规模，同时保留仍被批次摘要引用的任务。
  List<InstallTask> _retainBoundedHistory(List<InstallTask> history) {
    final batchTaskIds = state.batches.expand((batch) => batch.taskIds).toSet();
    final retained = <InstallTask>[];
    var ordinaryCount = 0;
    for (final task in history) {
      if (batchTaskIds.contains(task.id)) {
        retained.add(task);
      } else if (ordinaryCount < _maxHistorySize) {
        retained.add(task);
        ordinaryCount += 1;
      }
    }
    return retained;
  }

  String _decorateFailureMessageForCurrentPlatform({
    required InstallTask task,
    required String message,
    required InstallMessages messages,
  }) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return trimmedMessage;
    }

    // 失败文案的发行版增强统一收口在队列层，原因是多个页面都消费同一份失败状态：
    // - 下载管理
    // - 详情页
    // - 其他依赖安装历史/当前任务的展示面
    // 这样可以避免页面层各自再拼一遍提示，导致规则漂移或重复追加。
    final distribution =
        ref.read(linglongEnvProvider).result?.distribution ??
        LinuxDistribution.unknown;
    final scenario = task.isUpdateTask
        ? LinuxDistributionGuidanceScenario.appUpdateFailure
        : LinuxDistributionGuidanceScenario.appInstallFailure;

    return messages.appendDistributionGuidance(
      distribution: distribution,
      scenario: scenario,
      message: trimmedMessage,
    );
  }

  // -----------------------------------------------------------------------
  // 取消 / 移除 / 清空
  // -----------------------------------------------------------------------

  /// 取消任务
  ///
  /// 取消当前正在执行的任务或从队列中移除
  ///
  /// 参考 Rust 版本 `cancel_linglong_install` 的流程：
  /// 1. 调用 CLI 取消方法（`pkexec killall`）
  /// 2. 系统级 kill 成功后标记取消状态（`markUserCancelled`）
  /// 3. 更新任务状态为 `cancelled`
  Future<bool> cancelTask(String appId) async {
    final currentTask = state.currentTask;
    if (currentTask != null && currentTask.appId == appId) {
      // 取消当前任务。只有 pkexec/killall 成功时，才能把 UI 状态落为已取消。
      bool cancelSuccess = false;
      try {
        cancelSuccess = await ref
            .read(linglongCliRepositoryProvider)
            .cancelOperation(appId, kind: currentTask.kind);
      } catch (e) {
        AppLogger.error('[InstallQueue] 取消安装失败: $appId', e);
      }

      if (!cancelSuccess) {
        // 授权取消或 kill 失败时，安装可能仍在后台继续，必须保持当前任务。
        _resetCancelFlag();
        AppLogger.warning('[InstallQueue] 取消安装未完成，保持任务继续运行: $appId');
        return false;
      }

      // 标记为用户取消（参考 Rust 版本 InstallSlot.mark_cancelled）
      markUserCancelled();

      // 停止超时检查和清理状态机
      _stopTimeoutCheck();
      _stateMachine?.dispose();
      _stateMachine = null;

      final activeTask = state.currentTask;
      if (activeTask?.id != currentTask.id) {
        AppLogger.info('[InstallQueue] 任务已由进度流完成取消: $appId');
        return true;
      }

      final messages = ref.read(installMessagesProvider);
      final operation = activeTask!.isUpdateTask
          ? messages.updateLabel
          : messages.installLabel;
      final cancelledMessage = messages.cancelled(operation);

      final cancelledTask = _appendCommandOutput(activeTask, cancelledMessage)
          .copyWith(
            status: InstallStatus.cancelled,
            message: cancelledMessage,
            finishedAt: DateTime.now().millisecondsSinceEpoch,
          );

      _commitTerminalTask(cancelledTask);
      AppLogger.info('[InstallQueue] 任务已取消: $appId');

      // 处理下一个任务
      Future.delayed(
        const Duration(milliseconds: 100),
        () => startProcessing(),
      );

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
    _commitState(
      state.copyWith(
        queue: state.queue.where((task) => task.id != taskId).toList(),
      ),
    );
    if (queuedTask.batchId != null) {
      final messages = ref.read(installMessagesProvider);
      _commitTerminalTask(
        queuedTask.copyWith(
          status: InstallStatus.cancelled,
          message: messages.cancelled(messages.updateLabel),
          finishedAt: _nowTimestamp(),
        ),
        clearCurrentTask: false,
      );
    }
  }

  /// 从历史记录中移除指定任务，不影响同应用的其他历史 item。
  void removeHistoryTask(String taskId) {
    _commitState(
      state.copyWith(
        history: state.history.where((task) => task.id != taskId).toList(),
      ),
    );
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
    _commitState(state.copyWith(queue: []));
    final messages = ref.read(installMessagesProvider);
    for (final task in batchTasks) {
      _commitTerminalTask(
        task.copyWith(
          status: InstallStatus.cancelled,
          message: messages.cancelled(messages.updateLabel),
          finishedAt: _nowTimestamp(),
        ),
        clearCurrentTask: false,
      );
    }
    AppLogger.info('Queue cleared');
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

    final installedTarget = _resolveInstalledTarget(
      persistedTask,
      installedApps,
    );
    final canProveSuccess = _canProveRecoveredSuccess(
      persistedTask,
      installedTarget,
    );

    if (canProveSuccess) {
      AppLogger.info(
        'Recovered ${persistedTask.appId} at verified target version '
        '${installedTarget?.version}',
      );

      final messages = ref.read(installMessagesProvider);
      final operation = persistedTask.isUpdateTask
          ? messages.updateLabel
          : messages.installLabel;

      final successTask = persistedTask.copyWith(
        status: InstallStatus.success,
        progress: 100,
        message: messages.completed(operation),
        finishedAt: DateTime.now().millisecondsSinceEpoch,
      );

      _commitTerminalTask(successTask);
    } else {
      AppLogger.warning(
        'Unable to prove recovered task success: app=${persistedTask.appId}, '
        'old=${persistedTask.target?.installedVersion}, '
        'expected=${persistedTask.target?.expectedVersion}, '
        'actual=${installedTarget?.version}',
      );

      final messages = ref.read(installMessagesProvider);

      final interruptedTask = persistedTask.copyWith(
        status: InstallStatus.interrupted,
        message: messages.taskCrashInterrupted,
        errorMessage: messages.taskCrashRetryHint,
        finishedAt: DateTime.now().millisecondsSinceEpoch,
      );

      _commitTerminalTask(interruptedTask);
    }
  }

  /// 按任务快照精确定位本机实例；无法唯一确定时返回 null。
  InstalledApp? _resolveInstalledTarget(
    InstallTask task,
    List<InstalledApp> installedApps,
  ) {
    final target = task.target;
    final candidates = installedApps.where((app) {
      if (app.appId != task.appId) {
        return false;
      }
      if (target == null) {
        return true;
      }
      return _matchesOptionalIdentity(target.arch, app.arch) &&
          _matchesOptionalIdentity(target.channel, app.channel) &&
          _matchesOptionalIdentity(target.module, app.module) &&
          _matchesOptionalIdentity(target.repoName, app.repoName);
    }).toList();
    return candidates.length == 1 ? candidates.single : null;
  }

  /// 判断恢复后的本机事实是否足以证明原任务成功。
  bool _canProveRecoveredSuccess(
    InstallTask task,
    InstalledApp? installedTarget,
  ) {
    if (installedTarget == null) {
      return false;
    }

    final target = task.target;
    if (task.isUpdateTask) {
      final expectedVersion = target?.expectedVersion;
      return expectedVersion != null &&
          expectedVersion.isNotEmpty &&
          installedTarget.version == expectedVersion;
    }

    final requestedVersion = target?.requestedInstallVersion ?? task.version;
    return requestedVersion == null ||
        requestedVersion.isEmpty ||
        installedTarget.version == requestedVersion;
  }

  /// 目标快照未指定某个身份字段时允许匹配，指定后必须完全一致。
  bool _matchesOptionalIdentity(String? expected, String? actual) {
    return expected == null || expected.isEmpty || expected == actual;
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
