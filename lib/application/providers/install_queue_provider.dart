import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/i18n/install_messages.dart';
import '../../core/logging/app_logger.dart';
import '../../core/di/providers.dart'
    show analyticsRepositoryProvider, currentLocaleProvider;
import 'linglong_env_provider.dart';
import '../../domain/models/linux_distribution.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_queue_state.dart';
import '../../domain/models/install_state_machine.dart';
import '../../domain/models/install_task.dart';
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

// ---------------------------------------------------------------------------
// 持久化 Mixin
// ---------------------------------------------------------------------------

/// 安装队列持久化能力 mixin。
///
/// 提供队列和当前任务的读写能力，供 [InstallQueue] 混入使用。
mixin _InstallQueuePersistence {
  /// Riverpod ref，由混入类提供。
  Ref get ref;

  SharedPreferences? _prefs;

  SharedPreferences? get prefs => _prefs;
  set prefs(SharedPreferences? value) => _prefs = value;

  /// 读取 SharedPreferences（安全兜底，失败返回 null）
  SharedPreferences? _readSharedPreferences() {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  /// 从 SharedPreferences 恢复队列状态（同步）。
  ///
  /// 在 Provider build 阶段直接调用，避免异步读取导致首帧状态不一致。
  InstallQueueState restorePersistedState() {
    final prefs = _prefs ?? _readSharedPreferences();
    if (prefs == null) {
      return const InstallQueueState();
    }

    _prefs = prefs;

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

  /// 持久化待处理队列到 SharedPreferences。
  Future<void> persistQueue(List<InstallTask> queue) async {
    final prefs = _prefs ?? _readSharedPreferences();
    if (prefs == null) return;

    _prefs = prefs;

    try {
      await prefs.setString(
        _kQueueKey,
        jsonEncode(queue.map((t) => t.toJson()).toList()),
      );
      AppLogger.debug('Queue persisted: ${queue.length} tasks');
    } catch (e, s) {
      AppLogger.error('Failed to persist queue', e, s);
    }
  }

  /// 持久化当前任务到 SharedPreferences。
  void persistCurrentTask(InstallTask? task) {
    final prefs = _prefs ?? _readSharedPreferences();
    if (prefs == null) return;

    _prefs = prefs;

    if (task != null) {
      try {
        prefs.setString(_kCurrentTaskKey, jsonEncode(task.toJson()));
      } catch (e, s) {
        AppLogger.error('Failed to persist current task', e, s);
      }
    }
  }

  /// 清除持久化的当前任务。
  void clearPersistedCurrentTask() {
    final prefs = _prefs ?? _readSharedPreferences();
    if (prefs == null) return;

    _prefs = prefs;
    prefs.remove(_kCurrentTaskKey);
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
    bool force = false,
  }) {
    // 检查是否已在队列中
    if (state.isAppInQueue(appId)) {
      AppLogger.warning('App $appId is already in queue, skipping');
      return '';
    }

    // 升级任务必须不带版本号，否则后续命令构造会出错。
    final effectiveVersion = kind == InstallTaskKind.update ? null : version;

    final kindTask = InstallTask(
      id: _generateTaskId(),
      appId: appId,
      appName: appName,
      icon: icon,
      kind: kind,
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
      version: kindTask.version,
      force: kindTask.force,
      status: kindTask.status,
      createdAt: kindTask.createdAt,
      message: messages.waitingFor(operation),
    );

    state = state.copyWith(queue: [...state.queue, task]);
    unawaited(persistQueue(state.queue));

    AppLogger.info('Enqueued task: ${task.id} for app: $appId');

    // 如果当前没有正在处理的任务，开始处理队列
    if (!state.isProcessing && state.currentTask == null) {
      Future.microtask(() => startProcessing());
    }

    return task.id;
  }

  /// 批量入队安装/更新任务。
  List<String> enqueueBatchOperations(List<EnqueueTaskParams> tasksParams) {
    final taskIds = <String>[];
    final newTasks = <InstallTask>[];
    final messages = ref.read(installMessagesProvider);

    for (final params in tasksParams) {
      if (state.isAppInQueue(params.appId)) {
        continue;
      }

      // 批量更新同样禁止携带版本号。
      final batchVersion = params.kind == InstallTaskKind.update
          ? null
          : params.version;

      final task = InstallTask(
        id: _generateTaskId(),
        appId: params.appId,
        appName: params.appName,
        icon: params.icon,
        kind: params.kind,
        version: batchVersion,
        force: params.force,
        status: InstallStatus.pending,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      taskIds.add(task.id);
      final operation = params.kind == InstallTaskKind.update
          ? messages.updateLabel
          : messages.installLabel;
      newTasks.add(task.copyWith(message: messages.waitingFor(operation)));
    }

    if (newTasks.isNotEmpty) {
      state = state.copyWith(queue: [...state.queue, ...newTasks]);
      unawaited(persistQueue(state.queue));
      AppLogger.info('Enqueued ${newTasks.length} tasks in batch');

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

    state = state.copyWith(
      isProcessing: true,
      queue: remainingQueue,
      currentTask: installingTask,
    );

    persistCurrentTask(installingTask);
    unawaited(persistQueue(remainingQueue));

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

    state = state.copyWith(currentTask: updatedTask);
    persistCurrentTask(updatedTask);

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

    state = state.copyWith(
      clearCurrentTask: true,
      isProcessing: false,
      history: [cancelledTask, ...state.history].take(_maxHistorySize).toList(),
    );

    clearPersistedCurrentTask();
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

    state = state.copyWith(
      clearCurrentTask: true,
      isProcessing: false,
      history: [completedTask, ...state.history].take(_maxHistorySize).toList(),
    );

    clearPersistedCurrentTask();
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

    state = state.copyWith(
      clearCurrentTask: true,
      isProcessing: false,
      history: [failedTask, ...state.history].take(_maxHistorySize).toList(),
    );

    clearPersistedCurrentTask();

    if (wasCancelled) {
      AppLogger.info('Task cancelled by user: $appId');
    } else {
      AppLogger.error('Task failed: $appId, error: $error, code: $errorCode');
    }

    // 继续处理下一个任务（失败不阻塞队列）
    Future.delayed(const Duration(milliseconds: 100), () => startProcessing());
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

      state = state.copyWith(
        clearCurrentTask: true,
        isProcessing: false,
        history: [
          cancelledTask,
          ...state.history,
        ].take(_maxHistorySize).toList(),
      );

      clearPersistedCurrentTask();
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
    state = state.copyWith(
      queue: state.queue.where((task) => task.id != taskId).toList(),
    );
    unawaited(persistQueue(state.queue));
  }

  /// 从历史记录中移除指定任务，不影响同应用的其他历史 item。
  void removeHistoryTask(String taskId) {
    state = state.copyWith(
      history: state.history.where((task) => task.id != taskId).toList(),
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
    state = state.copyWith(history: []);
  }

  /// 清空队列
  void clearQueue() {
    state = state.copyWith(queue: []);
    unawaited(persistQueue(state.queue));
    AppLogger.info('Queue cleared');
  }

  // -----------------------------------------------------------------------
  // 崩溃恢复 / 重试
  // -----------------------------------------------------------------------

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

      state = state.copyWith(
        clearCurrentTask: true,
        history: [successTask, ...state.history].take(_maxHistorySize).toList(),
      );
    } else {
      // 应用未安装，标记为失败
      AppLogger.info(
        'App ${persistedTask.appId} is not installed, marking as failed',
      );

      final messages = ref.read(installMessagesProvider);

      final failedTask = persistedTask.copyWith(
        status: InstallStatus.failed,
        message: messages.taskCrashInterrupted,
        errorMessage: messages.taskCrashRetryHint,
        finishedAt: DateTime.now().millisecondsSinceEpoch,
      );

      state = state.copyWith(
        clearCurrentTask: true,
        history: [failedTask, ...state.history].take(_maxHistorySize).toList(),
      );
    }

    clearPersistedCurrentTask();
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

    state = state.copyWith(
      history: state.history.where((task) => task.id != taskId).toList(),
    );

    enqueueOperation(
      kind: failedTask.kind,
      appId: failedTask.appId,
      appName: failedTask.appName,
      icon: failedTask.icon,
      version: failedTask.version,
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
    this.force = false,
  });

  final InstallTaskKind kind;
  final String appId;
  final String appName;
  final String? icon;
  final String? version;
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
