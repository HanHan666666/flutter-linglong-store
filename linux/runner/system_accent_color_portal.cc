#include "system_accent_color_portal.h"

#include <cmath>

// XDG Portal 系统强调色订阅实现（docs/48 §5.3/§7.4/§9）。
//
// 设计说明：
// - 只使用 GIO 自带的 GDBus，不引入第三方 D-Bus 库与外部进程；
// - 全部 D-Bus 操作异步发起，禁止在 GTK 主线程执行同步调用；
// - 能力缺失（无 portal、无 Settings 接口、键缺失、值非法）只记录诊断
//   日志并上报一次 unavailable，事件流保持存活等待恢复；
// - 所有回调都在 GLib 主上下文（Flutter platform 线程）分发，客户端
//   字段无需加锁；在飞异步回调通过引用计数保证不会访问已释放内存。

namespace {

// XDG Desktop Portal Settings 的标准标识（docs/48 §2.1）。
// 不读取 XDG_CURRENT_DESKTOP，能力判断只看运行时返回值。
constexpr char kPortalBusName[] = "org.freedesktop.portal.Desktop";
constexpr char kPortalObjectPath[] = "/org/freedesktop/portal/desktop";
constexpr char kSettingsInterface[] = "org.freedesktop.portal.Settings";
constexpr char kReadAllMethod[] = "ReadAll";
constexpr char kSettingChangedSignal[] = "SettingChanged";
constexpr char kAppearanceNamespace[] = "org.freedesktop.appearance";
constexpr char kAccentColorKey[] = "accent-color";

}  // namespace

// Portal 订阅客户端：普通 C 风格结构 + 手写引用计数。
//
// 为什么不用 GObject：状态机简单（连接 → 订阅 → 读取），裸结构的字段
// 与生命周期一目了然，可读性与可测性优于完整 GObject 类型样板。
struct SystemAccentColorPortalClient {
  // 引用计数：1 归持有者（channel 胶水层），每个在飞异步操作
  // （g_bus_get / g_dbus_connection_call）临时增持 1 个。
  // 只在 GLib 主上下文读写，无需原子操作。
  int ref_count = 1;

  // start 已调用 / stop 已请求，均保证幂等。
  gboolean started = FALSE;
  gboolean stopped = FALSE;

  // 取消在飞异步操作用的统一取消句柄。
  GCancellable* cancellable = nullptr;
  // 自有的会话总线连接引用。
  GDBusConnection* connection = nullptr;
  // org.freedesktop.portal.Desktop 的 name watcher 与 SettingChanged 订阅。
  guint name_watch_id = 0;
  guint signal_subscription_id = 0;

  // 最近一次上报给上层的值，用于去重（docs/48 §7.4 第 5 条）。
  gboolean has_published = FALSE;
  gboolean published_available = FALSE;
  SystemAccentColorRgb published_color = {};

  // 结果回调与释放通知。
  SystemAccentColorNotify notify = nullptr;
  gpointer notify_user_data = nullptr;
  GDestroyNotify notify_destroy = nullptr;
};

namespace {

using PortalClient = SystemAccentColorPortalClient;

// 去重后把结果上报给持有者。
//
// 去重规则（docs/48 §9）：与上次已发布 RGB 相同，或连续 unavailable，
// 不再重复上报；stop 之后一律不再上报。
void client_publish(PortalClient* client, gboolean available,
                    SystemAccentColorRgb color) {
  if (client->stopped) {
    return;
  }
  if (client->has_published && client->published_available == available) {
    if (!available ||
        system_accent_color_rgb_equal(color, client->published_color)) {
      return;
    }
  }
  client->has_published = TRUE;
  client->published_available = available;
  client->published_color = color;
  if (client->notify != nullptr) {
    client->notify(available, color, client->notify_user_data);
  }
}

// 把解析结果统一转换为上报行为。
//
// kMissing/kInvalid 对上层都是「未设置强调色」（docs/48 §2.1/§9），
// 区分枚举只为了让诊断日志能说明桌面返回的是缺失还是损坏数据。
void client_publish_parse_result(PortalClient* client,
                                 SystemAccentColorParseResult result,
                                 const SystemAccentColorRgb& color,
                                 const gchar* source) {
  if (result == SystemAccentColorParseResult::kOk) {
    client_publish(client, TRUE, color);
    return;
  }
  if (result == SystemAccentColorParseResult::kMissing) {
    g_debug("系统强调色：%s 未提供 %s/%s，回退品牌蓝", source,
            kAppearanceNamespace, kAccentColorKey);
  } else {
    g_warning("系统强调色：%s 返回非法 accent-color，已丢弃", source);
  }
  client_publish(client, FALSE, SystemAccentColorRgb());
}

// 异步读取一次 namespace 下的全部键（含 accent-color）。
//
// 每次发起前增持引用，回调结束时归还，防止 stop 后回调悬空。
void client_start_read_all(PortalClient* client, GDBusConnection* connection) {
  GVariantBuilder namespaces;
  g_variant_builder_init(&namespaces, G_VARIANT_TYPE("as"));
  g_variant_builder_add(&namespaces, "s", kAppearanceNamespace);

  system_accent_color_portal_client_ref(client);
  g_dbus_connection_call(
      connection, kPortalBusName, kPortalObjectPath, kSettingsInterface,
      kReadAllMethod, g_variant_new("(as)", &namespaces),
      G_VARIANT_TYPE("(a{sa{sv}})"), G_DBUS_CALL_FLAGS_NONE, -1,
      client->cancellable,
      [](GObject* source, GAsyncResult* result, gpointer user_data) {
        auto* client = static_cast<PortalClient*>(user_data);
        g_autoptr(GError) error = nullptr;
        g_autoptr(GVariant) reply = g_dbus_connection_call_finish(
            G_DBUS_CONNECTION(source), result, &error);
        if (reply == nullptr) {
          // 主动取消（stop）不算故障，保持静默；真实失败（如会话没有
          // Settings 接口）上报一次 unavailable，事件流继续等待恢复
          // （docs/48 §9「Settings 接口不存在」行）。
          if (g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
            g_debug("系统强调色：ReadAll 已随订阅取消中止");
          } else {
            g_warning("系统强调色：ReadAll 调用失败: %s", error->message);
            client_publish(client, FALSE, SystemAccentColorRgb());
          }
          system_accent_color_portal_client_unref(client);
          return;
        }
        if (!client->stopped) {
          SystemAccentColorRgb rgb;
          const SystemAccentColorParseResult parsed =
              system_accent_color_try_extract_read_all(reply, &rgb);
          client_publish_parse_result(client, parsed, rgb, "ReadAll");
        }
        system_accent_color_portal_client_unref(client);
      },
      client);
}

// SettingChanged 信号回调：只处理目标 namespace/key，其它事件直接忽略。
void setting_changed_cb(GDBusConnection* connection,
                        const gchar* sender_name,
                        const gchar* object_path,
                        const gchar* interface_name,
                        const gchar* signal_name,
                        GVariant* parameters,
                        gpointer user_data) {
  (void)connection;
  (void)sender_name;
  (void)object_path;
  (void)interface_name;
  (void)signal_name;
  auto* client = static_cast<PortalClient*>(user_data);

  // 信号体为 (ssv)：namespace、key、值 variant（内层即 (ddd)）。
  const gchar* namespace_name = nullptr;
  const gchar* key = nullptr;
  g_autoptr(GVariant) value = nullptr;
  g_variant_get(parameters, "(&s&sv)", &namespace_name, &key, &value);
  if (g_strcmp0(namespace_name, kAppearanceNamespace) != 0 ||
      g_strcmp0(key, kAccentColorKey) != 0) {
    return;
  }

  SystemAccentColorRgb rgb;
  const SystemAccentColorParseResult parsed =
      system_accent_color_try_parse_value(value, &rgb);
  client_publish_parse_result(client, parsed, rgb, "SettingChanged");
}

// portal 服务在总线上出现（含首次连接时已存在）：订阅信号并读取初始值。
//
// 首次订阅与 portal 重启后的恢复共用这条路径；先建立 SettingChanged
// 订阅、再发起 ReadAll，避免读取与订阅之间丢失变化（docs/48 §7.4 第 2 条）。
void portal_name_appeared_cb(GDBusConnection* connection,
                             const gchar* name,
                             const gchar* name_owner,
                             gpointer user_data) {
  (void)name;
  (void)name_owner;
  auto* client = static_cast<PortalClient*>(user_data);
  if (client->stopped) {
    return;
  }

  if (client->signal_subscription_id == 0) {
    client->signal_subscription_id = g_dbus_connection_signal_subscribe(
        connection, kPortalBusName, kSettingsInterface, kSettingChangedSignal,
        kPortalObjectPath, nullptr, G_DBUS_SIGNAL_FLAGS_NONE, setting_changed_cb,
        client, nullptr);
  }
  client_start_read_all(client, connection);
}

// portal 服务从总线消失：保留当前内存颜色，不发任何事件。
//
// 这是 docs/48 §7.4 第 7 条的防闪蓝策略：服务瞬时重启期间继续展示
// 最后有效颜色；服务重新出现时由 appeared 回调重新读取并按值决定
// 是否发布变化。
void portal_name_vanished_cb(GDBusConnection* connection,
                             const gchar* name,
                             gpointer user_data) {
  (void)name;
  auto* client = static_cast<PortalClient*>(user_data);
  if (client->signal_subscription_id != 0) {
    // 解除订阅：名字重现时 appeared 回调会重新订阅，避免重复回调。
    g_dbus_connection_signal_unsubscribe(connection,
                                         client->signal_subscription_id);
    client->signal_subscription_id = 0;
  }
}

// 会话总线连接完成。
void bus_acquired_cb(GObject* source, GAsyncResult* result, gpointer user_data) {
  (void)source;
  auto* client = static_cast<PortalClient*>(user_data);
  g_autoptr(GError) error = nullptr;
  GDBusConnection* connection = g_bus_get_finish(result, &error);
  if (connection == nullptr) {
    // 主动取消保持静默；真实连接失败（无 session bus 等）只诊断一次
    // 并上报 unavailable（docs/48 §9 首行）。
    if (g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
      g_debug("系统强调色：会话总线连接已随订阅取消中止");
    } else {
      g_warning("系统强调色：连接会话总线失败: %s", error->message);
      client_publish(client, FALSE, SystemAccentColorRgb());
    }
    system_accent_color_portal_client_unref(client);
    return;
  }

  if (client->stopped) {
    // 连接完成时订阅已被取消：只回收自己的引用。g_bus_get 返回的是
    // 进程级共享单例连接（GLib 文档明确该对象与其它调用方共享），close
    // 会连带切断 GApplication/GNotification 正在使用的总线。
    g_object_unref(connection);
    system_accent_color_portal_client_unref(client);
    return;
  }

  client->connection = connection;
  // 只注册 name watcher：portal 已在总线上时 appeared 回调会被立即派发，
  // 在其中完成「订阅信号 + ReadAll」，让初始流程与恢复流程共用实现。
  // unwatch 之后 GLib 保证不再派发这两个回调，user_data 无需引用计数。
  client->name_watch_id = g_bus_watch_name_on_connection(
      connection, kPortalBusName, G_BUS_NAME_WATCHER_FLAGS_NONE,
      portal_name_appeared_cb, portal_name_vanished_cb, client, nullptr);
  system_accent_color_portal_client_unref(client);
}

}  // namespace

guint8 system_accent_color_component_to_byte(double v) {
  // 统一 lround 舍入：0→0、0.5→128、1→255，与 Dart 端无需再做二次换算。
  return static_cast<guint8>(std::lround(v * 255.0));
}

SystemAccentColorParseResult system_accent_color_try_parse_value(
    GVariant* value, SystemAccentColorRgb* out) {
  if (value == nullptr || out == nullptr) {
    return SystemAccentColorParseResult::kInvalid;
  }
  if (!g_variant_is_of_type(value, G_VARIANT_TYPE("(ddd)"))) {
    return SystemAccentColorParseResult::kInvalid;
  }
  // 类型匹配的固定 tuple 恒有三个子项，此处显式检查用于防御异常数据。
  if (g_variant_n_children(value) != 3) {
    return SystemAccentColorParseResult::kInvalid;
  }

  gdouble red = 0.0;
  gdouble green = 0.0;
  gdouble blue = 0.0;
  g_variant_get(value, "(ddd)", &red, &green, &blue);

  const gdouble components[3] = {red, green, blue};
  for (const gdouble component : components) {
    // 规范要求超界视为未设置；NaN/Infinity 同样拒绝（docs/48 §2.1）。
    if (!std::isfinite(component) || component < 0.0 || component > 1.0) {
      return SystemAccentColorParseResult::kInvalid;
    }
  }

  out->r = system_accent_color_component_to_byte(red);
  out->g = system_accent_color_component_to_byte(green);
  out->b = system_accent_color_component_to_byte(blue);
  return SystemAccentColorParseResult::kOk;
}

SystemAccentColorParseResult system_accent_color_try_extract_read_all(
    GVariant* read_all_result, SystemAccentColorRgb* out) {
  if (read_all_result == nullptr || out == nullptr) {
    return SystemAccentColorParseResult::kInvalid;
  }
  if (!g_variant_is_of_type(read_all_result, G_VARIANT_TYPE("(a{sa{sv}})"))) {
    return SystemAccentColorParseResult::kInvalid;
  }

  g_autoptr(GVariant) namespaces =
      g_variant_get_child_value(read_all_result, 0);
  g_autoptr(GVariant) keys = g_variant_lookup_value(
      namespaces, kAppearanceNamespace, G_VARIANT_TYPE("a{sv}"));
  if (keys == nullptr) {
    // 命名空间缺失：桌面未声明该能力，属于「未设置」而非数据损坏。
    return SystemAccentColorParseResult::kMissing;
  }

  // a{sv} 的 g_variant_lookup_value 会自动解引用 variant，直接得到
  // 内层 (ddd)，无需手动 g_variant_get_variant。
  g_autoptr(GVariant) color = g_variant_lookup_value(keys, kAccentColorKey, nullptr);
  if (color == nullptr) {
    return SystemAccentColorParseResult::kMissing;
  }
  return system_accent_color_try_parse_value(color, out);
}

SystemAccentColorPortalClient* system_accent_color_portal_client_new(
    SystemAccentColorNotify notify, gpointer user_data,
    GDestroyNotify destroy_notify) {
  auto* client = new SystemAccentColorPortalClient();
  client->notify = notify;
  client->notify_user_data = user_data;
  client->notify_destroy = destroy_notify;
  return client;
}

void system_accent_color_portal_client_start(
    SystemAccentColorPortalClient* client) {
  if (client->started || client->stopped) {
    return;
  }
  client->started = TRUE;
  client->cancellable = g_cancellable_new();

  // 初始尚未有任何结果时不抢先发 unavailable（docs/48 §7.4）：
  // 事件只由 ReadAll 结果或 SettingChanged 触发。
  system_accent_color_portal_client_ref(client);
  g_bus_get(G_BUS_TYPE_SESSION, client->cancellable, bus_acquired_cb, client);
}

void system_accent_color_portal_client_stop(
    SystemAccentColorPortalClient* client) {
  if (client->stopped) {
    return;
  }
  client->stopped = TRUE;

  if (client->cancellable != nullptr) {
    g_cancellable_cancel(client->cancellable);
    g_clear_object(&client->cancellable);
  }
  if (client->signal_subscription_id != 0 && client->connection != nullptr) {
    g_dbus_connection_signal_unsubscribe(client->connection,
                                         client->signal_subscription_id);
    client->signal_subscription_id = 0;
  }
  if (client->name_watch_id != 0) {
    g_bus_unwatch_name(client->name_watch_id);
    client->name_watch_id = 0;
  }
  if (client->connection != nullptr) {
    // 只放下自己的引用，禁止 close：g_bus_get 返回的会话总线连接是
    // 进程级共享单例（与 GApplication/GNotification 共用），主动 close
    // 会让整个应用的总线能力一并失效。信号订阅与 name watcher 已在上方
    // 解除，本客户端不再从该连接收到任何事件。
    g_clear_object(&client->connection);
  }
}

void system_accent_color_portal_client_ref(
    SystemAccentColorPortalClient* client) {
  ++client->ref_count;
}

void system_accent_color_portal_client_unref(
    SystemAccentColorPortalClient* client) {
  if (--client->ref_count != 0) {
    return;
  }
  if (client->notify_destroy != nullptr) {
    client->notify_destroy(client->notify_user_data);
  }
  delete client;
}
