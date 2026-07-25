/// 应用持续忽略更新记录。
///
/// 该模型保存用户执行忽略时的轻量快照，使应用卸载后仍能在管理弹窗中
/// 被识别和恢复；真正的过滤身份始终只有 [appId]。
library;

class IgnoredUpdate {
  /// 创建一条已通过业务层校验的忽略记录。
  const IgnoredUpdate({
    required this.appId,
    required this.appName,
    required this.ignoredVersion,
    required this.ignoredAt,
    this.icon,
  });

  /// 应用唯一标识；跨版本、架构、仓库和 module 持续生效。
  final String appId;

  /// 忽略时的应用名称快照，仅用于管理界面展示。
  final String appName;

  /// 忽略时的图标地址快照；地址缺失或失效时由通用图标组件兜底。
  final String? icon;

  /// 用户执行忽略时的已安装版本，帮助用户识别记录。
  final String ignoredVersion;

  /// 忽略时间的毫秒时间戳，用于稳定排序。
  final int ignoredAt;

  /// 从本地 JSON 尝试恢复忽略记录。
  ///
  /// `appId` 或时间戳无效时返回 `null`；名称缺失时回退为 `appId`，
  /// 避免单个历史字段异常导致用户无法恢复有效的忽略身份。
  static IgnoredUpdate? tryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    final appId = _readNonEmptyString(value['appId']);
    final ignoredAtValue = value['ignoredAt'];
    if (appId == null || ignoredAtValue is! num) {
      return null;
    }

    return IgnoredUpdate(
      appId: appId,
      appName: _readNonEmptyString(value['appName']) ?? appId,
      icon: _readNonEmptyString(value['icon']),
      ignoredVersion: _readNonEmptyString(value['ignoredVersion']) ?? '',
      ignoredAt: ignoredAtValue.toInt(),
    );
  }

  /// 转换为 SharedPreferences 中保存的 JSON 结构。
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'appId': appId,
      'appName': appName,
      'icon': icon,
      'ignoredVersion': ignoredVersion,
      'ignoredAt': ignoredAt,
    };
  }

  /// 按忽略时间倒序、appId 正序比较记录，保证会话内外展示顺序一致。
  static int compareForDisplay(IgnoredUpdate left, IgnoredUpdate right) {
    final timeResult = right.ignoredAt.compareTo(left.ignoredAt);
    return timeResult != 0 ? timeResult : left.appId.compareTo(right.appId);
  }

  /// 读取并清洗本地字符串字段，空白字符串按缺失处理。
  static String? _readNonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
