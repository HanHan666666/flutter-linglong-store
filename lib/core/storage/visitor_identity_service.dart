import 'dart:math';

import 'preferences_service.dart';

/// 管理客户端匿名访问标识。
///
/// 该标识不包含账号、设备信息或其他个人信息。首次生成后持久化并复用，让需要
/// 匿名去重的业务接口能够共享同一个稳定标识，避免各仓储重复实现生成逻辑。
class VisitorIdentityService {
  /// 创建匿名访问标识服务。
  const VisitorIdentityService();

  /// 与既有匿名统计保持一致的本地存储键。
  static const storageKey = 'analytics_visitor_id';

  /// 获取现有标识；尚未生成时创建并异步持久化。
  String getOrCreateVisitorId() {
    final existing = PreferencesService.getString(storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    // 时间戳与安全随机数组合只用于生成不含敏感信息的本地匿名标识。
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final visitorId = '${DateTime.now().millisecondsSinceEpoch}-$hex';

    // 写入失败不阻塞业务请求；下次调用会重新生成。
    PreferencesService.setString(storageKey, visitorId).ignore();
    return visitorId;
  }
}
