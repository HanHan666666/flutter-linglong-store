/// 卸载流程的返回结果
sealed class UninstallResult {}

/// 用户确认并成功完成卸载
class UninstallResultSuccess extends UninstallResult {}

/// 用户主动取消（关闭确认弹窗，或拦截弹窗点「我知道了」）
class UninstallResultCancelled extends UninstallResult {}

/// 卸载被活跃任务拦截，且用户选择查看下载管理
class UninstallResultBlockedByInstall extends UninstallResult {
  UninstallResultBlockedByInstall(this.activeTaskName, this.appId);
  final String activeTaskName;
  final String appId;
}

/// kill 运行中实例失败
class UninstallResultKillFailed extends UninstallResult {
  UninstallResultKillFailed(this.appId);
  final String appId;
}

/// 卸载执行失败
class UninstallResultError extends UninstallResult {
  UninstallResultError(this.message);
  final String message;
}
