#include "system_notification_channel.h"

namespace {

// 通知通道必须与 Dart 生成常量使用同一 application ID，后缀只表达通道职责。
constexpr char kChannelName[] = APPLICATION_ID "/system_notification";
constexpr char kSubmitMethod[] = "submit";
constexpr char kSubmittedResult[] = "submitted";

/**
 * 从参数映射读取必需字符串。
 *
 * 必需字段必须存在且非空；在 native 边界重复校验可防止其它 MethodChannel
 * 调用方传入错误类型导致 GLib 警告或进程崩溃。
 */
const gchar* read_required_string(FlValue* arguments, const gchar* key) {
  if (arguments == nullptr ||
      fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  FlValue* value = fl_value_lookup_string(arguments, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
    return nullptr;
  }
  const gchar* text = fl_value_get_string(value);
  return text != nullptr && *text != '\0' ? text : nullptr;
}

/**
 * 从参数映射读取可选字符串。
 *
 * Dart 的 null 和缺失字段都表示“不设置”；其它类型按非法参数处理，由调用
 * 入口统一返回错误，避免静默接受损坏的通道契约。
 */
bool read_optional_string(FlValue* arguments,
                          const gchar* key,
                          const gchar** output) {
  FlValue* value = fl_value_lookup_string(arguments, key);
  if (value == nullptr || fl_value_get_type(value) == FL_VALUE_TYPE_NULL) {
    *output = nullptr;
    return true;
  }
  if (fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
    return false;
  }
  *output = fl_value_get_string(value);
  return true;
}

/**
 * 处理通知提交。
 *
 * GApplication 只保证“接受提交”，无法证明桌面最终显示或用户已经看到，
 * 因此成功结果固定返回 submitted，不创造虚假的 delivered 状态。
 */
FlMethodResponse* submit_notification(GApplication* application,
                                      FlValue* arguments) {
  const gchar* id = read_required_string(arguments, "id");
  const gchar* title = read_required_string(arguments, "title");
  const gchar* priority = read_required_string(arguments, "priority");
  const gchar* body = nullptr;
  const gchar* category = nullptr;
  const gchar* icon_name = nullptr;

  if (id == nullptr || title == nullptr ||
      g_strcmp0(priority, "normal") != 0 ||
      !read_optional_string(arguments, "body", &body) ||
      !read_optional_string(arguments, "category", &category) ||
      !read_optional_string(arguments, "iconName", &icon_name)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "invalid_arguments", "通知参数缺失或类型错误", nullptr));
  }

  g_autoptr(GNotification) notification = g_notification_new(title);
  if (body != nullptr && *body != '\0') {
    g_notification_set_body(notification, body);
  }
  g_notification_set_priority(notification, G_NOTIFICATION_PRIORITY_NORMAL);

  if (icon_name != nullptr && *icon_name != '\0') {
    g_autoptr(GIcon) icon = g_themed_icon_new(icon_name);
    g_notification_set_icon(notification, icon);
  }

// g_notification_set_category 从 GLib 2.70 起提供。旧发行版继续投递通知，
// 仅省略分类元数据，避免为了非关键能力提高最低系统依赖。
#if GLIB_CHECK_VERSION(2, 70, 0)
  if (category != nullptr && *category != '\0') {
    g_notification_set_category(notification, category);
  }
#else
  // 旧 GLib 没有 category API，但其余通知能力仍可正常使用。
  (void)category;
#endif

  g_application_send_notification(application, id, notification);
  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_string(kSubmittedResult)));
}

/**
 * MethodChannel 调用入口。
 *
 * Flutter Linux 在 GTK 主线程分发通道调用，因此 GNotification 的创建和提交
 * 均保持在主线程，不额外引入线程切换或外部进程。
 */
void method_call_cb(FlMethodChannel* channel,
                    FlMethodCall* method_call,
                    gpointer user_data) {
  GApplication* application = G_APPLICATION(user_data);
  const gchar* method = fl_method_call_get_name(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (g_strcmp0(method, kSubmitMethod) == 0) {
    response = submit_notification(
        application, fl_method_call_get_args(method_call));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

}  // namespace

FlMethodChannel* system_notification_channel_new(FlView* view,
                                                 GApplication* application) {
  g_return_val_if_fail(FL_IS_VIEW(view), nullptr);
  g_return_val_if_fail(G_IS_APPLICATION(application), nullptr);

  FlBinaryMessenger* messenger =
      fl_engine_get_binary_messenger(fl_view_get_engine(view));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel =
      fl_method_channel_new(messenger, kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            application, nullptr);
  return channel;
}
