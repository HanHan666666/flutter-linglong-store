/// 定义安装与更新任务可持久化的结构化失败事实。
///
/// 该模型只保存稳定类别和原始诊断，不包含任何本地化展示文案。Data 负责解析，
/// Application 负责补充运行时失败，Presentation 再按当前语言格式化。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'linux_distribution.dart';

part 'app_operation_failure.freezed.dart';
part 'app_operation_failure.g.dart';

/// 应用操作失败类别。
enum AppOperationFailureKind {
  /// ll-cli 返回了结构化错误事件。
  cli,

  /// 长时间没有收到 CLI 活性事件。
  timeout,

  /// CLI 流结束后无法从本机状态证明目标已经完成。
  resultUnconfirmed,

  /// Repository 流在没有终态事件时结束。
  streamEndedWithoutTerminal,

  /// 进程启动、流消费或其他非预期执行异常。
  execution,

  /// 应用退出后恢复时无法证明原任务成功。
  interrupted,

  /// 用户关闭了特权 helper 的首次 pkexec 授权对话框（docs/47 §10.2）。
  authorizationCancelled,

  /// 授权组件不可用：helper 缺失、pkexec 失败或 helper 会话中断
  /// （docs/47 §10.3）。
  helperUnavailable,
}

/// 可本地化的操作阶段代码。
///
/// 未识别的 CLI 消息不强行归类，由 Presentation 回退展示任务的原始消息。
enum AppOperationMessageCode {
  preparing,
  starting,
  installingApplication,
  installingRuntime,
  installingBase,
  downloadingMetadata,
  downloadingFiles,
  postProcessing,
  processing,
  completed,
}

/// 安装或更新失败的稳定事实。
@freezed
sealed class AppOperationFailure with _$AppOperationFailure {
  const factory AppOperationFailure({
    required AppOperationFailureKind kind,

    /// ll-cli JSON 错误码；非 CLI 错误保持为空。
    int? cliCode,

    /// 未经本地化和改写的底层诊断，用于日志与错误解决方案查询。
    String? diagnostic,

    /// 需要追加发行版提示的稳定业务场景。
    LinuxDistributionGuidanceScenario? guidanceScenario,
  }) = _AppOperationFailure;

  factory AppOperationFailure.fromJson(Map<String, dynamic> json) =>
      _$AppOperationFailureFromJson(json);
}
