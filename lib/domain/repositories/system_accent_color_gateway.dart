/// 定义 Application 层订阅系统强调色的唯一平台边界。
///
/// 该接口隔离 Linux runner 的 XDG Portal 实现与未来其它宿主，业务层不得
/// 直接监听 EventChannel、读取桌面私有配置或感知桌面环境名称（docs/48 §7.1）。
library;

import '../models/system_accent_color.dart';

/// 系统强调色网关。
abstract interface class SystemAccentColorGateway {
  /// 订阅系统强调色；null 表示标准能力当前不可用或未设置（docs/48 §7.1）。
  Stream<SystemAccentColor?> watchAccentColor();
}
