import 'dart:async';

/// 安装状态机状态
///
/// 对应 Rust 版本的状态流转：
/// Idle -> Waiting -> Installing -> Succeeded/Failed
enum InstallStateMachineState {
  /// 空闲
  idle,

  /// 已启动进程，尚未收到百分比
  waiting,

  /// 已收到进度百分比
  installing,

  /// 成功
  succeeded,

  /// 失败
  failed,
}

/// 安装状态机
///
/// 管理安装任务的状态流转，包含超时检测
/// 参考：rust-linglong-store/src-tauri/src/services/install/state_machine.rs
class InstallStateMachine {
  InstallStateMachine({
    this.progressTimeoutSecs = 360,
  });

  /// 进度超时时间（秒）
  final int progressTimeoutSecs;

  /// 当前状态
  InstallStateMachineState _state = InstallStateMachineState.idle;

  /// 最后一次进度更新时间
  DateTime? _lastProgressAt;

  /// 最后一次进度百分比
  double _lastPercentage = 0.0;

  /// 超时定时器
  Timer? _timeoutTimer;

  /// 获取当前状态
  InstallStateMachineState get state => _state;

  /// 获取最后进度百分比
  double get lastPercentage => _lastPercentage;

  /// 启动状态机
  void start() {
    _state = InstallStateMachineState.waiting;
    _lastProgressAt = DateTime.now();
    _lastPercentage = 0.0;
    _startTimeoutCheck();
  }

  /// 处理进度事件
  void onProgress(double percentage) {
    // Waiting -> Installing (第一次进度时)
    if (_state == InstallStateMachineState.waiting) {
      _state = InstallStateMachineState.installing;
    }

    // Installing 状态下更新进度
    if (_state == InstallStateMachineState.installing) {
      _lastProgressAt = DateTime.now();
      _lastPercentage = percentage;
    }
  }

  /// 处理消息事件（刷新时间戳，延长超时）
  void onMessage() {
    if (_state == InstallStateMachineState.waiting ||
        _state == InstallStateMachineState.installing) {
      _lastProgressAt = DateTime.now();
    }
  }

  /// 处理错误事件
  void onError() {
    _state = InstallStateMachineState.failed;
    _stopTimeoutCheck();
  }

  /// 处理成功事件
  void onSuccess() {
    _state = InstallStateMachineState.succeeded;
    _stopTimeoutCheck();
  }

  /// 处理失败事件
  void onFailure() {
    _state = InstallStateMachineState.failed;
    _stopTimeoutCheck();
  }

  /// 检查是否超时
  bool checkTimeout() {
    if (_state != InstallStateMachineState.waiting &&
        _state != InstallStateMachineState.installing) {
      return false;
    }

    if (_lastProgressAt == null) {
      return false;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_lastProgressAt!).inSeconds;

    return elapsed >= progressTimeoutSecs;
  }

  /// 刷新时间戳
  void touch() {
    _lastProgressAt = DateTime.now();
  }

  /// 重置状态机
  void reset() {
    _state = InstallStateMachineState.idle;
    _lastProgressAt = null;
    _lastPercentage = 0.0;
    _stopTimeoutCheck();
  }

  /// 启动超时检查定时器
  void _startTimeoutCheck() {
    _stopTimeoutCheck();
    _timeoutTimer = Timer.periodic(
      Duration(seconds: progressTimeoutSecs ~/ 2),
      (_) {
        if (checkTimeout()) {
          onFailure();
        }
      },
    );
  }

  /// 停止超时检查定时器
  void _stopTimeoutCheck() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// 释放资源
  void dispose() {
    _stopTimeoutCheck();
  }
}