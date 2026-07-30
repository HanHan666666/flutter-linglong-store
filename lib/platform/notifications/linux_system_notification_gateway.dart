/// 通过 Linux runner 的 GNotification 通道提交桌面系统通知。
///
/// 该实现不识别发行版或桌面环境，也不启动 `notify-send` 等外部进程；
/// GIO 会根据当前宿主会话选择 Freedesktop Notifications 或 Portal 后端。
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/config/generated/application_identity.g.dart';
import '../../domain/models/system_notification.dart';
import '../../domain/repositories/system_notification_gateway.dart';

/// Linux 系统通知网关。
class LinuxSystemNotificationGateway implements SystemNotificationGateway {
  /// 使用固定平台通道创建网关。
  const LinuxSystemNotificationGateway({
    MethodChannel channel = const MethodChannel(
      ApplicationIdentity.systemNotificationChannel,
    ),
    bool Function() isLinux = _isLinuxHost,
  }) : _channel = channel,
       _isLinux = isLinux;

  /// runner 支持的提交方法。
  static const String _submitMethod = 'submit';

  /// 防止 runner 或桌面通知服务异常时长期阻塞 Outbox。
  static const Duration _submissionTimeout = Duration(seconds: 3);

  /// 标题和正文上限用于保护平台通道，不负责通知策略的业务摘要裁剪。
  static const int _maximumTitleLength = 160;
  static const int _maximumBodyLength = 2048;

  final MethodChannel _channel;
  final bool Function() _isLinux;

  @override
  Future<SystemNotificationSubmission> submit(
    SystemNotificationMessage message,
  ) async {
    if (!_isLinux()) {
      return const SystemNotificationSubmission(
        status: SystemNotificationSubmissionStatus.unsupported,
        diagnosticCode: 'non_linux_host',
      );
    }

    final validationError = _validate(message);
    if (validationError != null) {
      return SystemNotificationSubmission(
        status: SystemNotificationSubmissionStatus.rejected,
        diagnosticCode: validationError,
      );
    }

    try {
      final result = await _channel
          .invokeMethod<String>(_submitMethod, <String, Object?>{
            'id': message.id,
            'title': message.title,
            'body': message.body,
            'priority': message.priority.name,
            'category': message.category,
            'iconName': message.iconName,
          })
          .timeout(_submissionTimeout);
      if (result == 'submitted') {
        return const SystemNotificationSubmission(
          status: SystemNotificationSubmissionStatus.submitted,
        );
      }
      return const SystemNotificationSubmission(
        status: SystemNotificationSubmissionStatus.failed,
        diagnosticCode: 'unexpected_native_result',
      );
    } on MissingPluginException {
      return const SystemNotificationSubmission(
        status: SystemNotificationSubmissionStatus.unsupported,
        diagnosticCode: 'missing_linux_channel',
      );
    } on TimeoutException {
      return const SystemNotificationSubmission(
        status: SystemNotificationSubmissionStatus.unavailable,
        diagnosticCode: 'submission_timeout',
      );
    } on PlatformException catch (error) {
      return SystemNotificationSubmission(
        status: error.code == 'invalid_arguments'
            ? SystemNotificationSubmissionStatus.rejected
            : SystemNotificationSubmissionStatus.unavailable,
        diagnosticCode: error.code,
      );
    } catch (_) {
      return const SystemNotificationSubmission(
        status: SystemNotificationSubmissionStatus.failed,
        diagnosticCode: 'unexpected_submission_error',
      );
    }
  }

  /// 在跨越平台通道前拒绝空身份、空标题和异常大的负载。
  String? _validate(SystemNotificationMessage message) {
    if (message.id.trim().isEmpty) {
      return 'empty_notification_id';
    }
    if (message.title.trim().isEmpty) {
      return 'empty_notification_title';
    }
    if (message.title.runes.length > _maximumTitleLength) {
      return 'notification_title_too_long';
    }
    if (message.body.runes.length > _maximumBodyLength) {
      return 'notification_body_too_long';
    }
    return null;
  }

  /// 隔离静态平台判断，便于平台边界验证时注入确定结果。
  static bool _isLinuxHost() => Platform.isLinux;
}
