import 'package:freezed_annotation/freezed_annotation.dart';

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

    /// 规范化后的展示文案。
    String? message,

    /// ll-cli 返回的原始 message 文本。
    String? rawMessage,

    /// 规范化后的错误摘要。
    String? error,
    int? errorCode,

    /// 后端返回的原始错误详情。
    String? errorDetail,
  }) = _InstallProgress;

  factory InstallProgress.fromJson(Map<String, dynamic> json) =>
      _$InstallProgressFromJson(json);
}
