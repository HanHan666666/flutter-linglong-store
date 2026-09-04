// 系统强调色纯逻辑单测（docs/48 §12.4）。
//
// 覆盖范围：(ddd) 值解析（合法/越界/非有限值/类型错误）、ReadAll
// (a{sa{sv}}) 提取（缺 namespace/缺 key/内层非法）、分量 8-bit 舍入边界。
// 运行方式：build/scripts/test-system-accent-color.sh（cmake 开启
// LINGLONG_BUILD_ACCENT_COLOR_TESTS 后构建并执行本程序）。
// 只链接 GLib/GIO，不依赖 flutter/GTK，保证解析逻辑独立可验证。

#include <cmath>
#include <cstdio>
#include <limits>

#include "system_accent_color_portal.h"

namespace {

int gFailures = 0;
int gChecks = 0;

void expectTrue(bool condition, const char* what) {
  ++gChecks;
  if (!condition) {
    ++gFailures;
    fprintf(stderr, "FAIL: %s\n", what);
  }
}

void expectEqInt(long actual, long expected, const char* what) {
  ++gChecks;
  if (actual != expected) {
    ++gFailures;
    fprintf(stderr, "FAIL: %s\n  expected: %ld\n  actual:   %ld\n", what,
            expected, actual);
  }
}

// 持有一个浮动引用 GVariant 的便捷包装，作用域结束自动释放。
// 测试大量构造临时 GVariant，统一 sink 避免逐个手动 unref。
struct VariantHolder {
  GVariant* value = nullptr;

  explicit VariantHolder(GVariant* floating) {
    value = floating != nullptr ? g_variant_ref_sink(floating) : nullptr;
  }
  ~VariantHolder() {
    if (value != nullptr) {
      g_variant_unref(value);
    }
  }
  GVariant* get() const { return value; }
};

// 构造 accent-color 的 (ddd) 值。
GVariant* make_color_tuple(double r, double g, double b) {
  return g_variant_new("(ddd)", r, g, b);
}

// 构造 ReadAll 的 (a{sa{sv}}) 返回值；namespace 或 value 传 nullptr
// 表示对应层级缺失，用于生成「缺 namespace」「缺 key」用例。
GVariant* make_read_all_result(GVariant* appearance_value) {
  GVariantBuilder namespaces;
  g_variant_builder_init(&namespaces, G_VARIANT_TYPE("a{sa{sv}}"));
  if (appearance_value != nullptr) {
    GVariantBuilder keys;
    g_variant_builder_init(&keys, G_VARIANT_TYPE("a{sv}"));
    g_variant_builder_add(&keys, "{sv}", "accent-color", appearance_value);
    g_variant_builder_add(&namespaces, "{s@a{sv}}",
                          "org.freedesktop.appearance",
                          g_variant_builder_end(&keys));
  }
  // 注意格式串必须用 "@a{sa{sv}}"：裸 "a{sa{sv}}" 期望 GVariantBuilder*
  // 参数，而这里传入的是 builder_end 的现成 GVariant。
  return g_variant_new("(@a{sa{sv}})", g_variant_builder_end(&namespaces));
}

// ---- 分量舍入边界 ----

void testComponentToByte() {
  expectEqInt(system_accent_color_component_to_byte(0.0), 0, "0.0 -> 0");
  expectEqInt(system_accent_color_component_to_byte(1.0), 255, "1.0 -> 255");
  // 0.5*255 = 127.5，lround 按 away-from-zero 舍入到 128。
  expectEqInt(system_accent_color_component_to_byte(0.5), 128, "0.5 -> 128");
  // 0.25*255 = 63.75 -> 64；0.1*255 = 25.5 -> 26。
  expectEqInt(system_accent_color_component_to_byte(0.25), 64, "0.25 -> 64");
  expectEqInt(system_accent_color_component_to_byte(0.1), 26, "0.1 -> 26");
  // 0.75*255 = 191.25 -> 191，验证非半数边界的常规四舍五入。
  expectEqInt(system_accent_color_component_to_byte(0.75), 191, "0.75 -> 191");
}

// ---- (ddd) 合法值解析 ----

void testParseValidTuple() {
  SystemAccentColorRgb rgb;
  VariantHolder full(make_color_tuple(1.0, 0.5, 0.0));
  expectTrue(system_accent_color_try_parse_value(full.get(), &rgb) ==
                 SystemAccentColorParseResult::kOk,
             "valid (ddd) parses ok");
  expectEqInt(rgb.r, 255, "red 1.0 -> 255");
  expectEqInt(rgb.g, 128, "green 0.5 -> 128");
  expectEqInt(rgb.b, 0, "blue 0.0 -> 0");

  VariantHolder zeros(make_color_tuple(0.0, 0.0, 0.0));
  expectTrue(system_accent_color_try_parse_value(zeros.get(), &rgb) ==
                 SystemAccentColorParseResult::kOk,
             "all-zero tuple parses ok");
  expectEqInt(rgb.r, 0, "zero red");
  expectEqInt(rgb.g, 0, "zero green");
  expectEqInt(rgb.b, 0, "zero blue");

  VariantHolder ones(make_color_tuple(1.0, 1.0, 1.0));
  expectTrue(system_accent_color_try_parse_value(ones.get(), &rgb) ==
                 SystemAccentColorParseResult::kOk,
             "all-max tuple parses ok");
  expectEqInt(rgb.r, 255, "max red");
  expectEqInt(rgb.g, 255, "max green");
  expectEqInt(rgb.b, 255, "max blue");
}

// ---- 越界与非有限值拒绝 ----

void testParseRejectsInvalidValues() {
  SystemAccentColorRgb rgb;
  const double nan_value = std::numeric_limits<double>::quiet_NaN();
  const double inf_value = std::numeric_limits<double>::infinity();

  struct Case {
    double r;
    double g;
    double b;
    const char* what;
  };
  const Case cases[] = {
      {-0.1, 0.5, 0.5, "negative red rejected"},
      {0.5, -0.1, 0.5, "negative green rejected"},
      {0.5, 0.5, -0.1, "negative blue rejected"},
      {1.1, 0.5, 0.5, "red above one rejected"},
      {0.5, 1.1, 0.5, "green above one rejected"},
      {0.5, 0.5, 1.1, "blue above one rejected"},
  };
  for (const Case& item : cases) {
    VariantHolder value(make_color_tuple(item.r, item.g, item.b));
    expectTrue(system_accent_color_try_parse_value(value.get(), &rgb) ==
                   SystemAccentColorParseResult::kInvalid,
               item.what);
  }

  VariantHolder nan_case(make_color_tuple(nan_value, 0.5, 0.5));
  expectTrue(
      system_accent_color_try_parse_value(nan_case.get(), &rgb) ==
          SystemAccentColorParseResult::kInvalid,
      "NaN component rejected");

  VariantHolder inf_case(make_color_tuple(0.5, inf_value, 0.5));
  expectTrue(
      system_accent_color_try_parse_value(inf_case.get(), &rgb) ==
          SystemAccentColorParseResult::kInvalid,
      "Infinity component rejected");

  VariantHolder neg_inf_case(make_color_tuple(0.5, 0.5, -inf_value));
  expectTrue(
      system_accent_color_try_parse_value(neg_inf_case.get(), &rgb) ==
          SystemAccentColorParseResult::kInvalid,
      "-Infinity component rejected");
}

// ---- GVariant 类型错误拒绝 ----

void testParseRejectsWrongTypes() {
  SystemAccentColorRgb rgb;

  VariantHolder uints(g_variant_new("(uuu)", 1u, 2u, 3u));
  expectTrue(system_accent_color_try_parse_value(uints.get(), &rgb) ==
                 SystemAccentColorParseResult::kInvalid,
             "(uuu) rejected");

  VariantHolder two_doubles(g_variant_new("(dd)", 0.5, 0.5));
  expectTrue(system_accent_color_try_parse_value(two_doubles.get(), &rgb) ==
                 SystemAccentColorParseResult::kInvalid,
             "(dd) rejected");

  VariantHolder bare_double(g_variant_new("d", 0.5));
  expectTrue(system_accent_color_try_parse_value(bare_double.get(), &rgb) ==
                 SystemAccentColorParseResult::kInvalid,
             "bare double rejected");

  VariantHolder strings(g_variant_new("(sss)", "a", "b", "c"));
  expectTrue(system_accent_color_try_parse_value(strings.get(), &rgb) ==
                 SystemAccentColorParseResult::kInvalid,
             "(sss) rejected");

  expectTrue(
      system_accent_color_try_parse_value(nullptr, &rgb) ==
          SystemAccentColorParseResult::kInvalid,
      "null variant rejected");
}

// ---- ReadAll 结果提取 ----

void testExtractReadAll() {
  SystemAccentColorRgb rgb;

  VariantHolder full(make_read_all_result(make_color_tuple(1.0, 0.5, 0.0)));
  expectTrue(
      system_accent_color_try_extract_read_all(full.get(), &rgb) ==
          SystemAccentColorParseResult::kOk,
      "read all with valid accent-color extracts ok");
  expectEqInt(rgb.r, 255, "extracted red");
  expectEqInt(rgb.g, 128, "extracted green");
  expectEqInt(rgb.b, 0, "extracted blue");

  // 命名空间整体缺失：视为桌面未设置（kMissing），不是数据损坏。
  VariantHolder no_namespace(make_read_all_result(nullptr));
  expectTrue(
      system_accent_color_try_extract_read_all(no_namespace.get(), &rgb) ==
          SystemAccentColorParseResult::kMissing,
      "missing namespace -> kMissing");

  // namespace 存在但没有 accent-color 键。
  GVariantBuilder keys;
  g_variant_builder_init(&keys, G_VARIANT_TYPE("a{sv}"));
  g_variant_builder_add(&keys, "{sv}", "color-scheme",
                        g_variant_new_string("prefer-dark"));
  GVariantBuilder namespaces;
  g_variant_builder_init(&namespaces, G_VARIANT_TYPE("a{sa{sv}}"));
  g_variant_builder_add(&namespaces, "{s@a{sv}}", "org.freedesktop.appearance",
                        g_variant_builder_end(&keys));
  VariantHolder no_key(
      g_variant_new("(@a{sa{sv}})", g_variant_builder_end(&namespaces)));
  expectTrue(
      system_accent_color_try_extract_read_all(no_key.get(), &rgb) ==
          SystemAccentColorParseResult::kMissing,
      "missing accent-color key -> kMissing");

  // 键存在但内层值非法（越界）。
  VariantHolder invalid_value(
      make_read_all_result(make_color_tuple(1.5, 0.5, 0.5)));
  expectTrue(
      system_accent_color_try_extract_read_all(invalid_value.get(), &rgb) ==
          SystemAccentColorParseResult::kInvalid,
      "out-of-range value inside read all -> kInvalid");

  // 键存在但内层类型错误（字符串而非 (ddd)）。
  VariantHolder wrong_type_value(
      make_read_all_result(g_variant_new_string("#ff0000")));
  expectTrue(
      system_accent_color_try_extract_read_all(wrong_type_value.get(), &rgb) ==
          SystemAccentColorParseResult::kInvalid,
      "string value inside read all -> kInvalid");

  // 顶层不是 (a{sa{sv}}) 的 tuple（ReadAll 结果必须被 tuple 包裹）。
  // 空数组的构造同样必须走 builder：g_variant_new 的数组格式没有
  // 无参数形式，总是要求 GVariantBuilder*。
  GVariantBuilder empty_namespaces;
  g_variant_builder_init(&empty_namespaces, G_VARIANT_TYPE("a{sa{sv}}"));
  VariantHolder bare_dict(g_variant_builder_end(&empty_namespaces));
  expectTrue(
      system_accent_color_try_extract_read_all(bare_dict.get(), &rgb) ==
          SystemAccentColorParseResult::kInvalid,
      "bare a{sa{sv}} without tuple wrapper -> kInvalid");

  expectTrue(
      system_accent_color_try_extract_read_all(nullptr, &rgb) ==
          SystemAccentColorParseResult::kInvalid,
      "null read all result rejected");
}

}  // namespace

int main() {
  testComponentToByte();
  testParseValidTuple();
  testParseRejectsInvalidValues();
  testParseRejectsWrongTypes();
  testExtractReadAll();
  fprintf(stderr, "system accent color tests: %d checks, %d failures\n",
          gChecks, gFailures);
  return gFailures == 0 ? 0 : 1;
}
