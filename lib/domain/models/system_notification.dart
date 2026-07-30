/// 定义与桌面实现无关的系统通知消息和投递结果。
///
/// Application 层只使用这些稳定类型表达通知意图；Linux MethodChannel、
/// GIO 错误码和桌面环境差异由 Platform 层统一吸收。
library;

/// 系统通知优先级。
enum SystemNotificationPriority {
  /// 普通信息通知，尊重桌面环境的免打扰和展示策略。
  normal,
}

/// 系统通知投递结果。
enum SystemNotificationSubmissionStatus {
  /// 平台已经接受投递请求，但不代表用户一定看到通知。
  submitted,

  /// 当前平台没有实现系统通知能力。
  unsupported,

  /// 当前会话暂时没有可用的系统通知服务。
  unavailable,

  /// 消息不符合平台通道约束，投递请求被拒绝。
  rejected,

  /// 平台调用发生了无法进一步分类的失败。
  failed,
}

/// 一条准备提交给操作系统的纯文本通知。
class SystemNotificationMessage {
  /// 创建稳定、与平台无关的通知消息。
  const SystemNotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    this.priority = SystemNotificationPriority.normal,
    this.category,
    this.iconName,
  });

  /// 稳定通知 ID；重试同一业务事件时允许系统替换旧通知。
  final String id;

  /// 通知标题。
  final String title;

  /// 通知正文，只允许纯文本。
  final String body;

  /// 通知优先级。
  final SystemNotificationPriority priority;

  /// Freedesktop 通知分类；旧平台不支持时允许忽略。
  final String? category;

  /// 主题图标名称，不携带任意文件路径。
  final String? iconName;
}

/// 系统通知投递的类型化结果。
class SystemNotificationSubmission {
  /// 创建一条不面向用户展示的投递结果。
  const SystemNotificationSubmission({
    required this.status,
    this.diagnosticCode,
  });

  /// 投递状态。
  final SystemNotificationSubmissionStatus status;

  /// 仅供日志诊断的稳定错误码，禁止作为用户文案直接展示。
  final String? diagnosticCode;
}
