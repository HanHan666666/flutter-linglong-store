#!/usr/bin/env bash
# 特权 helper 纯逻辑单测入口（docs/47 §13.1 第 3 步）。
#
# 独立于 Flutter 构建配置 CMake，只编译协议与串行状态机两个纯逻辑模块，
# 不触发 GTK/Flutter 依赖。产物与缓存位于 build/tmp/privileged-helper-tests。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
build_dir="$repo_root/build/tmp/privileged-helper-tests"

cmake -S "$repo_root/linux/privileged_helper" -B "$build_dir" \
  -DLINGLONG_BUILD_HELPER_TESTS=ON >/dev/null
cmake --build "$build_dir" --target linglong_store_helper_tests >/dev/null

"$build_dir/linglong_store_helper_tests"
