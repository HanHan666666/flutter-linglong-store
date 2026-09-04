#ifndef FLUTTER_SYSTEM_ACCENT_COLOR_PORTAL_H_
#define FLUTTER_SYSTEM_ACCENT_COLOR_PORTAL_H_

#include <gio/gio.h>
#include <glib.h>

#include <cstddef>

// XDG Portal 系统强调色读取模块（docs/48 §5.3/§7.4）。
//
// 业务定位：纯 GLib/GIO 实现，负责从 org.freedesktop.portal.Settings 读取
// 与订阅 org.freedesktop.appearance/accent-color，做 GVariant 校验、8-bit
// 转换与去重后通过回调上报。本模块刻意不依赖 flutter_linux 头文件，
// 以便单测独立编译（见 linux/runner/CMakeLists.txt 的测试 target）。

// 归一化后的 8-bit sRGB 分量组合。
struct SystemAccentColorRgb {
  guint8 r = 0;
  guint8 g = 0;
  guint8 b = 0;
};

// 判断两个 RGB 是否完全相同，用于事件去重。
inline bool system_accent_color_rgb_equal(const SystemAccentColorRgb& a,
                                          const SystemAccentColorRgb& b) {
  return a.r == b.r && a.g == b.g && a.b == b.b;
}

// 把 [0,1] 的 double 分量按统一舍入规则转换为 0..255 的 8-bit 值。
//
// 舍入规则固定为 lround(v*255.0)，保证 native 与后续主题种子使用同一
// 换算口径；调用方必须已完成区间校验。
guint8 system_accent_color_component_to_byte(double v);

// 解析结果分类：合法 / 标准键缺失 / 数据非法。
//
// 区分 kMissing 与 kInvalid 是为了诊断日志能区分「桌面未提供该能力」
// 与「桌面返回了损坏数据」，两者对上层都表现为不可用（docs/48 §9）。
enum class SystemAccentColorParseResult {
  kOk,
  kMissing,
  kInvalid,
};

// 校验并解析 accent-color 的 (ddd) GVariant。
//
// 规范要求三个分量均为有限 double 且落在 [0,1]；NaN、Infinity、越界、
// 类型错误或子项数不足一律返回 kInvalid，禁止把损坏数据带入主题系统。
SystemAccentColorParseResult system_accent_color_try_parse_value(
    GVariant* value, SystemAccentColorRgb* out);

// 从 ReadAll(["org.freedesktop.appearance"]) 的 (a{sa{sv}}) 结果中提取
// accent-color。
//
// namespace 或 key 缺失返回 kMissing（视为桌面未设置强调色）；找到键后
// 走 system_accent_color_try_parse_value 做值级校验。
SystemAccentColorParseResult system_accent_color_try_extract_read_all(
    GVariant* read_all_result, SystemAccentColorRgb* out);

// 强调色上报回调。
//
// available 为 FALSE 时 color 无意义。回调在 GLib 主上下文（即 Flutter
// platform 线程）被调用，实现方无需额外加锁。
using SystemAccentColorNotify =
    void (*)(gboolean available, SystemAccentColorRgb color, gpointer user_data);

// Portal 订阅客户端（不透明类型，内部为普通 C 风格结构 + 引用计数）。
//
// 生命周期契约（docs/48 §7.4）：
// - new 后调用 start 开始异步连接；stop 请求停止并释放全部 D-Bus 资源；
// - 引用计数管理：持有者持有 1 个引用，模块内部每发起一个在飞异步操作
//   （g_bus_get / g_dbus_connection_call）临时增持 1 个，回调结束时归还，
//   保证 stop 之后回调不会访问已释放内存；
// - stop 后不再产生任何上报。
struct SystemAccentColorPortalClient;

// 创建客户端。notify/user_data 为结果回调；destroy_notify 在客户端内存
// 真正释放前调用（可为 nullptr）。user_data 生命周期必须覆盖到 destroy_notify。
SystemAccentColorPortalClient* system_accent_color_portal_client_new(
    SystemAccentColorNotify notify, gpointer user_data,
    GDestroyNotify destroy_notify);

// 开始异步订阅。重复调用或 stop 之后调用均为无操作。
void system_accent_color_portal_client_start(SystemAccentColorPortalClient* client);

// 停止订阅：取消未完成调用、解除信号订阅与 name watcher、断开连接引用。
// 只做资源清理，不等待在飞 D-Bus 回调（由引用计数兜底）。
void system_accent_color_portal_client_stop(SystemAccentColorPortalClient* client);

// 增持/归还引用。
void system_accent_color_portal_client_ref(SystemAccentColorPortalClient* client);
void system_accent_color_portal_client_unref(SystemAccentColorPortalClient* client);

#endif  // FLUTTER_SYSTEM_ACCENT_COLOR_PORTAL_H_
