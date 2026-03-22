import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'install_progress.dart';

part 'install_task.freezed.dart';
part 'install_task.g.dart';

/// 队列任务类型。
///
/// `install` 和 `update` 共用同一套串行状态机，但在执行命令、
/// 取消文案和成功文案上需要显式区分，避免继续依赖调用方猜测。
enum InstallTaskKind { install, update }

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

    /// 队列任务类型
    @Default(InstallTaskKind.install) InstallTaskKind kind,

    /// 目标版本
    String? version,

    /// 是否强制安装
    @Default(false) bool force,

    /// 当前状态
    @Default(InstallStatus.pending) InstallStatus status,

    /// 安装进度。
    ///
    /// 新链路统一使用 `0.0..1.0` 比例值；为兼容旧展示链路，这里仍容忍
    /// 历史上的 `0..100` 百分比值，并在 Presentation 层通过辅助方法归一化。
    @Default(0.0) double progress,

    /// 状态消息
    String? message,

    /// 安装链路中保留的原始 message 文本，用于诊断与兼容展示。
    String? rawMessage,

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
  /// 是否为更新任务。
  bool get isUpdateTask => kind == InstallTaskKind.update;

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

  /// 归一化后的进度值，统一转换为 `0.0..1.0` 供 UI 进度组件消费。
  double get progressValue {
    final raw = progress.isNaN ? 0.0 : progress;
    final normalized = raw > 1 ? raw / 100 : raw;
    return normalized.clamp(0.0, 1.0);
  }

  /// 统一百分比文案，兼容比例值和旧的百分比值。
  String get progressPercentLabel =>
      '${(progressValue * 100).round().clamp(0, 100)}%';

  /// 对旧任务或异常任务兜底，避免把整段 JSON 原文直接渲染到 UI。
  String? get displayMessage => _extractMessageText(message);

  /// 保留原始 message 里的纯文本内容，供诊断或次级展示使用。
  String? get displayRawMessage => _extractMessageText(rawMessage);

  /// 待处理文案。
  String get waitingMessage => isUpdateTask ? '等待更新...' : '等待安装...';

  /// 开始执行文案。
  String get preparingMessage => isUpdateTask ? '准备更新...' : '准备安装...';

  /// 成功完成文案。
  String get successMessage => isUpdateTask ? '更新完成' : '安装完成';

  /// 用户取消文案。
  String get cancelledMessage => isUpdateTask ? '更新已取消' : '安装已取消';

  /// 转换为 JSON 字符串（用于持久化）
  String toJsonString() => toJson().toString();

  static String? _extractMessageText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // 非 JSON 字符串按普通文案处理。
    }

    return trimmed;
  }
}
