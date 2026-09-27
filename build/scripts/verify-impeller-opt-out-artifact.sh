#!/usr/bin/env bash
# Linux Flutter 产物的 Impeller 关闭契约校验。
#
# Flutter 3.47+ 的 release 包只能由 runner 调用公开 embedder API 关闭
# Impeller；源码中存在调用并不代表干净构建后的 ELF 一定保留该调用。本脚本同时
# 检查引擎导出符号与 runner 动态引用，避免 CMake 条件判断失效后静默发布花屏产物。
#
# 用法：
#   bash build/scripts/verify-impeller-opt-out-artifact.sh [bundle_dir]
#   bash build/scripts/verify-impeller-opt-out-artifact.sh \
#     --allow-missing-api <bundle_dir>
#
# `--allow-missing-api` 仅供锁定 Flutter 3.46、引擎本身没有 Impeller 的 Loong64
# 构建使用；一旦引擎导出关闭 API，runner 仍必须引用它。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bundle_dir="$repo_root/build/linux/x64/release/bundle"
allow_missing_api=false

# 统一输出稳定错误格式，便于 CI 日志直接定位损坏的产物契约。
fail() {
  echo "FAIL: $1" >&2
  exit 1
}

# 只接受精确参数，避免拼写错误让 Loong64 兼容豁免扩散到其他架构。
while [[ $# -gt 0 ]]; do
  case "$1" in
    --allow-missing-api)
      allow_missing_api=true
      shift
      ;;
    --*)
      fail "不支持的参数: $1"
      ;;
    *)
      bundle_dir="$1"
      shift
      ;;
  esac
done

runner="$bundle_dir/linglong_store"
flutter_library="$bundle_dir/lib/libflutter_linux_gtk.so"
impeller_switch_symbol="fl_dart_project_set_enable_impeller"

command -v readelf >/dev/null 2>&1 || fail "缺少 readelf，无法检查 ELF 动态符号"
[[ -x "$runner" ]] || fail "Flutter runner 不存在或不可执行: $runner"
[[ -f "$flutter_library" ]] || fail "Flutter 引擎库不存在: $flutter_library"

# 动态符号可能携带版本后缀（例如 @@VERSION），比较前需要移除后缀。
has_dynamic_symbol() {
  local binary_path="$1"
  local expected_symbol="$2"

  readelf --dyn-syms --wide "$binary_path" | awk -v expected="$expected_symbol" '
    {
      symbol = $NF
      sub(/@.*/, "", symbol)
      if (symbol == expected) {
        found = 1
      }
    }
    END { exit found ? 0 : 1 }
  '
}

if ! has_dynamic_symbol "$flutter_library" "$impeller_switch_symbol"; then
  if [[ "$allow_missing_api" == true ]]; then
    echo "PASS: 当前 Flutter 引擎不提供 Impeller 开关 API，按兼容策略跳过 ($flutter_library)"
    exit 0
  fi

  fail "Flutter 引擎未导出 $impeller_switch_symbol；必须重新评估 Impeller 兼容策略"
fi

if ! has_dynamic_symbol "$runner" "$impeller_switch_symbol"; then
  fail "runner 未引用 $impeller_switch_symbol，Impeller 关闭逻辑未进入最终产物"
fi

echo "PASS: runner 已保留 Impeller 关闭调用 ($runner)"
