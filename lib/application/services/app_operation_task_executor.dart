/// 执行单个安装或更新任务，并把 CLI 流转换为 Application 事件。
///
/// 执行器只拥有单任务生命周期、超时状态机和取消入口，不读取或修改全局队列；
/// 所有事件都携带 taskId，由队列编排器防止旧流覆盖新任务。
library;

import 'dart:async';

import '../../domain/models/install_progress.dart';
import '../../domain/models/install_state_machine.dart';
import '../../domain/models/install_task.dart';
import '../../domain/repositories/linglong_cli_repository.dart';

/// 单任务执行事件回调。
typedef AppOperationExecutionEventHandler =
    void Function(AppOperationExecutionEvent event);

/// 单任务执行器输出的事件基类。
sealed class AppOperationExecutionEvent {
  /// 创建携带稳定任务身份的事件。
  const AppOperationExecutionEvent(this.taskId);

  /// 事件所属任务。
  final String taskId;
}

/// CLI 返回的一条结构化进度。
final class AppOperationProgressEvent extends AppOperationExecutionEvent {
  /// 创建进度事件。
  const AppOperationProgressEvent(super.taskId, this.progress);

  /// 规范化后的 CLI 进度。
  final InstallProgress progress;
}

/// 长时间未收到任何进度或消息。
final class AppOperationTimeoutEvent extends AppOperationExecutionEvent {
  /// 创建超时事件。
  const AppOperationTimeoutEvent(super.taskId);
}

/// CLI 流抛出异常。
final class AppOperationStreamFailedEvent extends AppOperationExecutionEvent {
  /// 创建流异常事件。
  const AppOperationStreamFailedEvent(
    super.taskId, {
    required this.error,
    required this.stackTrace,
  });

  /// 原始异常。
  final Object error;

  /// 原始调用栈。
  final StackTrace stackTrace;
}

/// CLI 流正常结束，但没有 success/failed/cancelled 终态。
final class AppOperationStreamEndedEvent extends AppOperationExecutionEvent {
  /// 创建无终态结束事件。
  const AppOperationStreamEndedEvent(super.taskId);
}

/// 一个活动安装或更新任务的执行器。
class AppOperationTaskExecutor {
  /// 创建单任务执行器。
  AppOperationTaskExecutor({
    required LinglongCliRepository repository,
    required InstallTask task,
  }) : _repository = repository,
       _task = task;

  /// 当前任务使用的 CLI 能力端口。
  final LinglongCliRepository _repository;

  /// 执行开始前冻结的任务参数。
  final InstallTask _task;

  /// 只跟踪当前执行流活性的超时状态机。
  InstallStateMachine? _stateMachine;

  /// 把状态机超时转为 Application 事件的检查器。
  Timer? _timeoutCheckTimer;

  /// 防止释放后继续接受旧流事件。
  bool _disposed = false;

  /// 记录 CLI 是否已经给出明确终态。
  bool _terminalObserved = false;

  /// 当前执行器绑定的稳定任务 ID。
  String get taskId => _task.id;

  /// 启动并消费当前任务的 CLI 流。
  Future<void> execute(AppOperationExecutionEventHandler onEvent) async {
    if (_disposed) {
      return;
    }

    final stateMachine = InstallStateMachine();
    _stateMachine = stateMachine;
    stateMachine.start();
    _startTimeoutCheck(onEvent);

    try {
      final progressStream = _task.kind == InstallTaskKind.update
          ? _repository.updateApp(_task.appId)
          : _repository.installApp(
              _task.appId,
              version: _task.version,
              force: _task.force,
            );
      await for (final progress in progressStream) {
        if (_disposed) {
          break;
        }
        _updateStateMachine(progress);
        if (progress.status == InstallStatus.success ||
            progress.status == InstallStatus.failed ||
            progress.status == InstallStatus.cancelled) {
          _terminalObserved = true;
        }
        onEvent(AppOperationProgressEvent(_task.id, progress));
        if (_disposed) {
          break;
        }
      }

      if (!_disposed && !_terminalObserved) {
        onEvent(AppOperationStreamEndedEvent(_task.id));
      }
    } catch (error, stackTrace) {
      if (!_disposed) {
        _stateMachine?.onFailure();
        onEvent(
          AppOperationStreamFailedEvent(
            _task.id,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    } finally {
      dispose();
    }
  }

  /// 请求底层精确取消当前任务。
  Future<bool> cancel() {
    return _repository.cancelOperation(_task.appId, kind: _task.kind);
  }

  /// 停止计时器和状态机；重复调用安全。
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _timeoutCheckTimer?.cancel();
    _timeoutCheckTimer = null;
    _stateMachine?.dispose();
    _stateMachine = null;
  }

  /// 根据一条进度刷新执行活性和终态。
  void _updateStateMachine(InstallProgress progress) {
    if (progress.status == InstallStatus.success) {
      _stateMachine?.onSuccess();
    } else if (progress.status == InstallStatus.failed) {
      _stateMachine?.onFailure();
    } else if (progress.progress > 0) {
      _stateMachine?.onProgress(progress.progress);
    } else {
      // cancelled 和普通消息都代表 CLI 仍有响应，应刷新超时观察点。
      _stateMachine?.onMessage();
    }
  }

  /// 启动与既有超时口径一致的周期检查。
  void _startTimeoutCheck(AppOperationExecutionEventHandler onEvent) {
    final checkInterval = Duration(
      seconds: (_stateMachine?.progressTimeoutSecs ?? 360) ~/ 2,
    );
    _timeoutCheckTimer = Timer.periodic(checkInterval, (_) {
      if (_disposed || _terminalObserved) {
        return;
      }
      final stateMachine = _stateMachine;
      // InstallStateMachine 自身也会在同一时刻转入 failed；这里同时识别该状态，
      // 避免内部计时器先触发后让外层漏发超时事件。
      if (stateMachine?.state == InstallStateMachineState.failed ||
          stateMachine?.checkTimeout() == true) {
        _stateMachine?.onFailure();
        _terminalObserved = true;
        _timeoutCheckTimer?.cancel();
        _timeoutCheckTimer = null;
        onEvent(AppOperationTimeoutEvent(_task.id));
      }
    });
  }
}
