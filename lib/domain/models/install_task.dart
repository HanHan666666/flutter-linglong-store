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

    /// 安装进度（`0.0..1.0` 比例值，由 [progressValue] 归一化后供 UI 消费）。
    @Default(0.0) double progress,

    /// 状态消息
    String? message,

    /// 安装链路中保留的原始 message 文本，用于诊断。
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

/// 从 rawMessage 尾部提取 CLI 速度信息的正则。
///
/// 匹配格式：`[90.56MB/s]`、`[256.17KB/s]`、`[45.25B/s]` 等。
final _cliSpeedRegex = RegExp(r'\[(\d+\.?\d*\s*(?:B|KB|MB|GB)/s)\]$');

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

  /// 百分比文案（基于归一化后的 [progressValue] 计算）。
  String get progressPercentLabel =>
      '${(progressValue * 100).round().clamp(0, 100)}%';

  /// 推断任务真正开始执行的时间。
  DateTime? get executionStartedAt {
    final timestamp = startedAt ?? createdAt;
    if (timestamp <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 从 rawMessage 中提取 CLI 返回的下载速度（如 `"90.56MB/s"`）。
  ///
  /// 新版 ll-cli 在 message 尾部附加 `[90.56MB/s]` 格式的速度标记，
  /// 此方法提取纯速度文本。旧版 ll-cli 无此标记时返回 `null`。
  String? get cliSpeed {
    final raw = rawMessage;
    if (raw == null || raw.isEmpty) return null;
    return _cliSpeedRegex.firstMatch(raw)?.group(1);
  }

  /// 对旧任务或异常任务兜底，避免把整段 JSON 原文直接渲染到 UI。
  ///
  /// 同时去除 CLI 速度标记 `[XX/s]`，避免消息和速度区域重复展示。
  String? get displayMessage {
    final normalizedMessage = _extractMessageText(message);
    final normalizedRawMessage = _extractMessageText(rawMessage);
    final source = _isEllipsizedPrefixOf(normalizedMessage, normalizedRawMessage)
        // 兼容旧版本持久化的 50 字符省略文案，Tooltip 和复制必须回到完整原文。
        ? normalizedRawMessage
        : normalizedMessage;
    return _stripSpeedSuffix(source);
  }

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

  /// 是否需要提示“安装较慢，可能在处理依赖”。
  bool shouldShowSlowInstallHint(
    DateTime now, {
    Duration threshold = const Duration(seconds: 30),
  }) {
    if (status != InstallStatus.installing) {
      return false;
    }
    if (progressValue < 0.95) {
      return false;
    }
    final startedAtTime = executionStartedAt;
    if (startedAtTime == null) {
      return false;
    }
    return now.difference(startedAtTime) >= threshold;
  }

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

  static bool _isEllipsizedPrefixOf(String? value, String? fullValue) {
    if (value == null || fullValue == null || !value.endsWith('...')) {
      return false;
    }
    final prefix = value.substring(0, value.length - 3);
    return fullValue.length > value.length && fullValue.startsWith(prefix);
  }

  /// 去除消息尾部的 CLI 速度标记 `[XX MB/s]`。
  static String? _stripSpeedSuffix(String? text) {
    if (text == null || text.isEmpty) return text;
    return text.replaceAll(RegExp(r'\s*\[\d+\.?\d*\s*(?:B|KB|MB|GB)/s\]$'), '');
  }
}
