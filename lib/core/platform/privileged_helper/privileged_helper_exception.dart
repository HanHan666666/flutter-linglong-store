/// 特权 helper 传输层的稳定失败类型（docs/47 §10.2/§10.3/§12）。
///
/// 这些异常只描述“授权与传输层发生了什么”，不判断安装业务成败；Repository
/// 负责把它们映射为稳定的领域失败事实（authorizationCancelled /
/// helperUnavailable / execution），Presentation 再按当前语言格式化。
library;

/// 所有 helper 传输失败的公共基类。
sealed class PrivilegedHelperException implements Exception {
  /// 面向日志与诊断的英文描述；不用于 UI 展示。
  const PrivilegedHelperException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 用户关闭了 pkexec 认证对话框（退出码 126）。
///
/// 该失败必须触发队列授权门闩：当前任务以稳定事实结束，pending 任务停止
/// 自动消费，直到用户明确重试（§10.2）。
class PrivilegedHelperAuthorizationCancelledException
    extends PrivilegedHelperException {
  const PrivilegedHelperAuthorizationCancelledException()
    : super('pkexec authorization dismissed by user');
}

/// 授权组件不可用（§10.3）。
///
/// 触发条件：bundle 内 helper 二进制缺失、pkexec 不存在（退出码 127）、
/// FUSE 暂存创建失败，或 noexec 挂载等罕见文件系统限制导致执行失败。
/// 所有运行形态显示相同错误并停止自动消费队列，不回退旧路径。
class PrivilegedHelperUnavailableException extends PrivilegedHelperException {
  const PrivilegedHelperUnavailableException(super.message);
}

/// helper 启动失败。
///
/// 触发条件：ready 超时、通道提前 EOF、协议版本不匹配或 helper 启动后异常
/// 退出（退出码非 0/126/127）。同样需要队列门闩（§10.2 末段）。
class PrivilegedHelperStartupException extends PrivilegedHelperException {
  const PrivilegedHelperStartupException(super.message);
}

/// 会话中途传输断开。
///
/// helper 在任务执行期间退出或 stdout 关闭，ll-cli 结果无法确认；Repository
/// 必须按“结果不确定”处理并触发已安装状态复验，不得伪装成取消成功。
class PrivilegedHelperTransportException extends PrivilegedHelperException {
  const PrivilegedHelperTransportException(super.message);
}

/// 协议错误。
///
/// helper 报告 fatal error（invalidRequest/protocolMismatch/outputTooLarge/
/// internal）或客户端收到无法解码的事件；会话不可继续，需重新授权启动。
class PrivilegedHelperProtocolException extends PrivilegedHelperException {
  /// helper error 事件中的稳定 code（如 `internal`），用于诊断日志。
  final String? code;

  const PrivilegedHelperProtocolException(super.message, {this.code});
}

/// helper 拒绝并发 start（busy）。
///
/// 串行约束的最后防线（§8.1）；正常情况下 Application 队列不会触发。
class PrivilegedHelperBusyException extends PrivilegedHelperException {
  const PrivilegedHelperBusyException(super.message);
}
