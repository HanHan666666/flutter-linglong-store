#ifndef FLUTTER_SYSTEM_ACCENT_COLOR_CHANNEL_H_
#define FLUTTER_SYSTEM_ACCENT_COLOR_CHANNEL_H_

#include <flutter_linux/flutter_linux.h>

/**
 * system_accent_color_channel_new:
 * @view: 承载平台通道的 Flutter 视图。
 *
 * 创建遵循 XDG Portal Settings 规范的系统强调色 EventChannel
 * （docs/48 §7.4）。Dart 端开始监听后才会连接 D-Bus，取消监听即停止
 * 订阅；D-Bus 细节全部封装在 system_accent_color_portal 模块中。
 * 调用方拥有返回对象，并应在应用销毁时释放。
 *
 * Returns: (transfer full): 新建的 #FlEventChannel。
 */
FlEventChannel* system_accent_color_channel_new(FlView* view);

#endif  // FLUTTER_SYSTEM_ACCENT_COLOR_CHANNEL_H_
