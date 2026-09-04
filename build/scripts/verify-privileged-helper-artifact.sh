#!/usr/bin/env bash
# 特权 helper 产物 smoke 校验（docs/47 §13.2 打包检查）。
#
# 在 release bundle 上断言：
# 1. bundle 的 libexec/ 内携带 helper 二进制；
# 2. helper 只依赖系统库（libstdc++/libgcc/libc/libm），不依赖
#    libflutter_linux_gtk.so、bundle lib/ 或任何 Flutter/GTK 动态库；
# 3. helper 无 RPATH/RUNPATH 条目（§4.2：禁止继承 GUI 的 $ORIGIN/lib）。
#
# 用法：bash build/scripts/verify-privileged-helper-artifact.sh [bundle_dir]
# 缺省 bundle 目录为 build/linux/x64/release/bundle。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bundle_dir="${1:-$repo_root/build/linux/x64/release/bundle}"
helper="$bundle_dir/libexec/linglong_store_helper"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[[ -x "$helper" ]] || fail "helper 不存在或不可执行: $helper"

# 依赖白名单：仅系统运行时库（ldd 的加载器行是绝对路径，统一取 basename）。
bad_deps="$(ldd "$helper" | awk '{print $1}' | xargs -r -n1 basename | grep -vE \
  '^(linux-vdso|libstdc\+\+|libgcc_s|libc|libm|ld-linux)' || true)"
[[ -z "$bad_deps" ]] || fail "helper 存在白名单外依赖: $bad_deps"

ldd "$helper" | grep -qE "flutter|gtk" && fail "helper 依赖了 Flutter/GTK 动态库"

# RPATH/RUNPATH 必须完全为空。
if readelf -d "$helper" | grep -qE "RPATH|RUNPATH"; then
  fail "helper 携带 RPATH/RUNPATH 条目"
fi

echo "PASS: helper 产物校验通过 ($helper)"
