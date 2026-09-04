#!/usr/bin/env bash
# 系统强调色纯逻辑单测入口（docs/48 §12.4）。
#
# 独立于 Flutter 构建配置 linux/runner，只编译 XDG Portal 解析模块，
# 不触发 flutter/GTK 依赖（PkgConfig 查找 glib-2.0 与 gio-2.0）。
# 产物与缓存位于 build/tmp/system-accent-color-tests。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
build_dir="$repo_root/build/tmp/system-accent-color-tests"

cmake -S "$repo_root/linux/runner" -B "$build_dir" \
  -DLINGLONG_BUILD_ACCENT_COLOR_TESTS=ON >/dev/null
cmake --build "$build_dir" --target linglong_store_accent_color_tests >/dev/null

"$build_dir/linglong_store_accent_color_tests"
