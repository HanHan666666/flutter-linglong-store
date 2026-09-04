/// 通过 Linux runner 的 XDG Portal EventChannel 订阅系统强调色。
///
/// 该实现不识别桌面环境名称、不启动外部进程，只消费
/// `org.freedesktop.portal.Settings` 的标准 `accent-color` 结果（docs/48 §5.3）。
/// 通道消息契约固定为：
///   有效：   `{ available: true, red: 0..255, green: 0..255, blue: 0..255 }`
///   不可用： `{ available: false }`
library;

import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/config/generated/application_identity.g.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/models/system_accent_color.dart';
import '../../domain/repositories/system_accent_color_gateway.dart';

/// Linux 系统强调色网关。
class LinuxSystemAccentColorGateway implements SystemAccentColorGateway {
  /// 使用固定平台事件通道创建网关。
  ///
  /// [channel] 与 [isLinux] 只为单测注入边界；生产路径共享同一个由应用
  /// 身份脚本生成的 EventChannel 名称，禁止手写完整 ID（docs/48 §7.4）。
  const LinuxSystemAccentColorGateway({
    EventChannel channel = const EventChannel(
      ApplicationIdentity.systemAccentColorChannel,
    ),
    bool Function() isLinux = _isLinuxHost,
  }) : _channel = channel,
       _isLinux = isLinux;

  /// 通道消息中的能力可用性字段名。
  static const String _availableField = 'available';

  /// 通道消息中的红色分量字段名。
  static const String _redField = 'red';

  /// 通道消息中的绿色分量字段名。
  static const String _greenField = 'green';

  /// 通道消息中的蓝色分量字段名。
  static const String _blueField = 'blue';

  final EventChannel _channel;
  final bool Function() _isLinux;

  @override
  Stream<SystemAccentColor?> watchAccentColor() {
    if (!_isLinux()) {
      // 非 Linux 宿主没有原生通道，立即发出一次 null 明确表达
      // 「标准能力不可用」，让订阅者直接落到品牌蓝回退，而不是停留在
      // 永久的 loading 状态（docs/48 §7.1 null 语义）。
      return Stream<SystemAccentColor?>.value(null);
    }

    // 降级策略（docs/48 §9）：
    // - 损坏的事件（非 Map / 缺字段 / 类型错误 / 分量越界）记录 warning 后
    //   跳过，不抛错，也不能把损坏数据当成颜色喂给主题系统；
    // - 流级错误（如通道未注册的 MissingPluginException、send_error）由
    //   handleError 统一记录并保持流存活，禁止产生未处理异步错误。
    return _channel
        .receiveBroadcastStream()
        .map<Object?>(_parseEvent)
        .where((Object? value) => !identical(value, _rejectedEvent))
        .cast<SystemAccentColor?>()
        .distinct()
        .handleError((Object error, StackTrace stackTrace) {
          AppLogger.warning('系统强调色通道流错误', error, stackTrace);
        });
  }

  /// 被拒绝事件的哨兵。
  ///
  /// 流中的 null 是合法值（表示不可用），因此不能复用 null 表达「跳过」，
  /// 用私有单例在 where 中做 identical 判断，零额外分配。
  static const Object _rejectedEvent = _RejectedEvent();

  /// 校验并转换单个通道事件。
  ///
  /// 返回 [SystemAccentColor]（有效）、null（标准能力不可用）或
  /// [_rejectedEvent]（事件损坏，应跳过）。所有校验失败路径都只记日志，
  /// 不抛异常，保证根主题订阅不会因为单条坏消息永久崩溃。
  Object? _parseEvent(Object? event) {
    if (event is! Map<Object?, Object?>) {
      AppLogger.warning('系统强调色事件不是 Map，已拒绝: $event');
      return _rejectedEvent;
    }

    final Object? available = event[_availableField];
    if (available is! bool) {
      AppLogger.warning('系统强调色事件缺少布尔 available 字段，已拒绝: $event');
      return _rejectedEvent;
    }
    if (!available) {
      // native 侧确认当前环境未提供标准强调色，交由主题层回退品牌蓝。
      return null;
    }

    final int? red = _readComponent(event, _redField);
    final int? green = _readComponent(event, _greenField);
    final int? blue = _readComponent(event, _blueField);
    if (red == null || green == null || blue == null) {
      // _readComponent 内部已按字段记录拒绝原因，这里只短路返回。
      return _rejectedEvent;
    }

    return SystemAccentColor(red: red, green: green, blue: blue);
  }

  /// 读取并校验 0..255 的整数颜色分量；非法时记录 warning 并返回 null。
  ///
  /// 严格拒绝宽松类型转换（如 double、字符串数字）与越界值，防止
  /// 坏数据以「恰好能看」的形态进入主题系统。
  int? _readComponent(Map<Object?, Object?> event, String field) {
    final Object? value = event[field];
    if (value is! int || value < 0 || value > 255) {
      AppLogger.warning('系统强调色分量 $field 非法（要求 0..255 int），已拒绝: $value');
      return null;
    }
    return value;
  }

  /// 隔离静态平台判断，便于平台边界验证时注入确定结果。
  static bool _isLinuxHost() => Platform.isLinux;
}

/// [_rejectedEvent] 的私有实现类型，禁止外部构造。
class _RejectedEvent {
  const _RejectedEvent();
}
