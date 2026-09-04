#include "system_accent_color_channel.h"

#include "system_accent_color_portal.h"

// 系统强调色 EventChannel 胶水层（docs/48 §7.4）。
//
// 职责边界：本文件只负责 EventChannel 的 listen/cancel 生命周期与
// FlValue 消息组装；全部 D-Bus 逻辑都在 system_accent_color_portal
// 纯逻辑模块中，禁止把门户细节堆进入口文件或通道胶水。

namespace {

// 通道名必须与 Dart 生成常量使用同一 application ID（docs/48 §7.4），
// 后缀只表达通道职责。
constexpr char kChannelName[] = APPLICATION_ID "/system_accent_color";

// 消息契约（docs/48 §7.4）：
//   有效：   { available: true, red, green, blue }（int 0..255）
//   不可用： { available: false }
constexpr char kAvailableField[] = "available";
constexpr char kRedField[] = "red";
constexpr char kGreenField[] = "green";
constexpr char kBlueField[] = "blue";

// 流上下文：由 set_stream_handlers 的 user_data/destroy_notify 持有，
// 生命周期与通道当前 handler 绑定；channel 指针仅在回调期间借用。
struct AccentColorStreamContext {
  FlEventChannel* channel = nullptr;
  // 当前订阅期的 portal 客户端；listen 创建、cancel/销毁时停止并释放。
  SystemAccentColorPortalClient* client = nullptr;
};

// portal 结果上报回调：组装通道消息并发送。
//
// fl_event_channel_send 只允许在 listen 之后调用；portal 客户端仅在
// listen 期间运行，天然满足该约束。
void portal_notify_cb(gboolean available,
                      SystemAccentColorRgb color,
                      gpointer user_data) {
  auto* context = static_cast<AccentColorStreamContext*>(user_data);

  g_autoptr(FlValue) event = fl_value_new_map();
  fl_value_set_string_take(event, kAvailableField,
                           fl_value_new_bool(available));
  if (available) {
    fl_value_set_string_take(event, kRedField, fl_value_new_int(color.r));
    fl_value_set_string_take(event, kGreenField, fl_value_new_int(color.g));
    fl_value_set_string_take(event, kBlueField, fl_value_new_int(color.b));
  }

  // 发送失败（如 Dart 尚未完成 listen 注册）只记录一次诊断、不重试：
  // 下一次合法变化仍会照常发送，重试反而可能把过期事件推给新订阅。
  g_autoptr(GError) error = nullptr;
  if (!fl_event_channel_send(context->channel, event, nullptr, &error)) {
    g_debug("系统强调色：发送事件失败: %s",
            error == nullptr ? "unknown error" : error->message);
  }
}

// 停止并释放当前 portal 客户端；幂等，供 cancel 与销毁路径共用。
void stop_stream_client(AccentColorStreamContext* context) {
  if (context->client == nullptr) {
    return;
  }
  system_accent_color_portal_client_stop(context->client);
  system_accent_color_portal_client_unref(context->client);
  context->client = nullptr;
}

// Dart 端开始监听：创建并启动 portal 客户端。
FlMethodErrorResponse* listen_cb(FlEventChannel* channel,
                                 FlValue* args,
                                 gpointer user_data) {
  (void)args;
  auto* context = static_cast<AccentColorStreamContext*>(user_data);
  // 防御：同一通道上出现未取消的重复 listen 时先复位旧客户端，
  // 避免遗留的 D-Bus 订阅在新订阅期继续发事件。
  stop_stream_client(context);
  context->channel = channel;
  context->client = system_accent_color_portal_client_new(
      portal_notify_cb, context, nullptr);
  system_accent_color_portal_client_start(context->client);
  return nullptr;
}

// Dart 端取消监听：停止订阅并释放全部 D-Bus 资源。
FlMethodErrorResponse* cancel_cb(FlEventChannel* channel,
                                 FlValue* args,
                                 gpointer user_data) {
  (void)channel;
  (void)args;
  auto* context = static_cast<AccentColorStreamContext*>(user_data);
  stop_stream_client(context);
  return nullptr;
}

// 通道 handler 被替换或通道销毁时的清理入口。
void stream_context_destroy(gpointer user_data) {
  auto* context = static_cast<AccentColorStreamContext*>(user_data);
  stop_stream_client(context);
  delete context;
}

}  // namespace

FlEventChannel* system_accent_color_channel_new(FlView* view) {
  g_return_val_if_fail(FL_IS_VIEW(view), nullptr);

  FlBinaryMessenger* messenger =
      fl_engine_get_binary_messenger(fl_view_get_engine(view));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlEventChannel* channel =
      fl_event_channel_new(messenger, kChannelName, FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(channel, listen_cb, cancel_cb,
                                       new AccentColorStreamContext(),
                                       stream_context_destroy);
  return channel;
}
