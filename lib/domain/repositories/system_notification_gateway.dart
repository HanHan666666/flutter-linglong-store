/// 定义 Application 层提交系统通知的唯一平台边界。
///
/// 该接口隔离 Linux runner 和未来其它宿主实现，业务层不得直接调用
/// MethodChannel、Shell 命令或桌面环境私有 API。
library;

import '../models/system_notification.dart';

/// 系统通知网关。
abstract interface class SystemNotificationGateway {
  /// 向当前桌面会话提交一条通知。
  Future<SystemNotificationSubmission> submit(
    SystemNotificationMessage message,
  );
}
