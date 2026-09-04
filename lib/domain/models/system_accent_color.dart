/// XDG Portal 系统强调色的领域模型。
///
/// 业务定位：承载 `org.freedesktop.portal.Settings` 命名空间
/// `org.freedesktop.appearance/accent-color` 归一化后的 8-bit RGB 值，
/// 作为 Platform 层与 Application 层之间唯一的颜色契约（docs/48 §6/§7.1）。
///
/// 设计原因：刻意不依赖 `dart:ui Color` 或 Flutter 主题类型，保证 D-Bus 与
/// GVariant 细节不越过 Platform 边界；也不使用 freezed，三字段小值对象的
/// 代码生成只会增加构建产物与维护成本（docs/48 §7.1）。
library;

/// 系统强调色的纯 RGB 值对象。
///
/// 三个分量均要求落在 0..255；范围断言只用于在构造边界拦截损坏的平台
/// 数据，生产路径中 Platform 层会在转换前完成严格校验，正常情况不会触发。
class SystemAccentColor {
  /// 创建一个不可变的强调色值。
  const SystemAccentColor({
    required this.red,
    required this.green,
    required this.blue,
  }) : assert(red >= 0 && red <= 255, 'red 必须位于 0..255'),
       assert(green >= 0 && green <= 255, 'green 必须位于 0..255'),
       assert(blue >= 0 && blue <= 255, 'blue 必须位于 0..255');

  /// 红色分量（0..255，sRGB）。
  final int red;

  /// 绿色分量（0..255，sRGB）。
  final int green;

  /// 蓝色分量（0..255，sRGB）。
  final int blue;

  @override
  bool operator ==(Object other) {
    return other is SystemAccentColor &&
        other.red == red &&
        other.green == green &&
        other.blue == blue;
  }

  @override
  int get hashCode => Object.hash(red, green, blue);

  @override
  String toString() => 'SystemAccentColor($red, $green, $blue)';
}
