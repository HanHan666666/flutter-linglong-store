import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_operation_failure.dart';

part 'install_progress.freezed.dart';
part 'install_progress.g.dart';

/// 安装进度事件类型。
///
/// 与 Rust 版本保持同一语义分层：进度、消息、错误和取消分别独立建模，
/// 避免 UI 再把传输层负载误当成展示文案。
enum InstallProgressEventType { progress, message, error, cancelled }

/// 安装进度状态枚举
enum InstallStatus {
  pending,
  downloading,
  installing,
  success,
  failed,
  cancelled,
  interrupted,
}

/// 安装进度事件
@freezed
sealed class InstallProgress with _$InstallProgress {
  const factory InstallProgress({
    required String appId,
    @Default(InstallProgressEventType.message)
    InstallProgressEventType eventType,
    required InstallStatus status,
    @Default(0.0) double progress,

    /// 旧调用方使用的展示文案；新 Data 事件保持为空。
    String? message,

    /// 可在当前语言下重新格式化的稳定阶段代码。
    AppOperationMessageCode? messageCode,

    /// ll-cli 返回的原始 message 文本。
    String? rawMessage,

    /// ll-cli 输出流中的原始单行内容，用于下载中心按任务保存诊断日志。
    String? outputLine,

    /// 旧调用方使用的错误摘要；新 Data 事件保持为空。
    String? error,
    int? errorCode,

    /// 后端返回的原始错误详情。
    String? errorDetail,

    /// 与 locale 无关的结构化失败事实。
    AppOperationFailure? failure,
  }) = _InstallProgress;

  factory InstallProgress.fromJson(Map<String, dynamic> json) =>
      _$InstallProgressFromJson(json);
}
