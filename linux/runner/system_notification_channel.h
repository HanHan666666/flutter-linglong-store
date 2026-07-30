#ifndef FLUTTER_SYSTEM_NOTIFICATION_CHANNEL_H_
#define FLUTTER_SYSTEM_NOTIFICATION_CHANNEL_H_

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>

/**
 * system_notification_channel_new:
 * @view: 承载平台通道的 Flutter 视图。
 * @application: 提交通知所使用的 GApplication，生命周期长于返回的通道。
 *
 * 创建遵循 GNotification 规范的系统通知通道。调用方拥有返回对象，
 * 并应在应用销毁时释放。
 *
 * Returns: (transfer full): 新建的 #FlMethodChannel。
 */
FlMethodChannel* system_notification_channel_new(FlView* view,
                                                 GApplication* application);

#endif  // FLUTTER_SYSTEM_NOTIFICATION_CHANNEL_H_
