/// 系统强调色的根级订阅 Provider。
///
/// 业务定位：维护 Gateway 流的订阅生命周期，把有效 RGB 或 null 发布给
/// 根应用；不把颜色写进 GlobalAppState（docs/48 §7.3）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/system_accent_color.dart';
import 'application_dependency_providers.dart';

/// 系统强调色状态。
///
/// 设计约束（docs/48 §7.3）：
/// - 不持久化：强调色是可丢弃的运行时系统状态，不是用户偏好，写本地存储
///   会让下次启动先显示过期的旧系统颜色；
/// - 初始 loading、null（标准能力不可用/未设置）与流错误均由主题层解析为
///   品牌蓝，本 Provider 不携带用户文案，也不是错误页面状态；
/// - 非 autoDispose：根应用是唯一长期订阅者，进程级订阅随 ProviderScope
///   存活，页面与卡片禁止各自订阅造成重复 D-Bus 事件。
final systemAccentColorProvider = StreamProvider<SystemAccentColor?>((ref) {
  return ref.watch(systemAccentColorGatewayProvider).watchAccentColor();
});
