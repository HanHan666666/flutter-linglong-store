import 'package:freezed_annotation/freezed_annotation.dart';

import 'install_progress.dart';

part 'install_task.freezed.dart';
part 'install_task.g.dart';

/// 安装任务状态机
///
/// 状态流转：
/// pending → installing → success/failed/cancelled
///
/// 严格串行安装：同一时间只允许一个安装任务执行
/// 失败隔离：单个任务失败不影响队列中其他任务
@freezed
sealed class InstallTask with _$InstallTask {
  const factory InstallTask({
    /// 唯一任务ID
    required String id,

    /// 应用ID
    required String appId,

    /// 应用名称
    required String appName,

    /// 应用图标URL
    String? icon,

    /// 目标版本
    String? version,

    /// 是否强制安装
    @Default(false) bool force,

    /// 当前状态
    @Default(InstallStatus.pending) InstallStatus status,

    /// 安装进度 (0-100)
    @Default(0.0) double progress,

    /// 状态消息
    String? message,

    /// 错误消息
    String? errorMessage,

    /// 错误代码
    int? errorCode,

    /// 错误详情
    String? errorDetail,

    /// 任务创建时间戳
    required int createdAt,

    /// 任务开始时间戳
    int? startedAt,

    /// 任务完成时间戳
    int? finishedAt,
  }) = _InstallTask;

  factory InstallTask.fromJson(Map<String, dynamic> json) =>
      _$InstallTaskFromJson(json);
}

/// InstallTask 扩展方法
extension InstallTaskX on InstallTask {
  /// 是否正在处理中
  bool get isProcessing => status == InstallStatus.installing;

  /// 是否已完成（成功或失败）
  bool get isCompleted =>
      status == InstallStatus.success ||
      status == InstallStatus.failed ||
      status == InstallStatus.cancelled;

  /// 是否失败
  bool get isFailed => status == InstallStatus.failed;

  /// 是否成功
  bool get isSuccess => status == InstallStatus.success;

  /// 转换为 JSON 字符串（用于持久化）
  String toJsonString() => toJson().toString();
}