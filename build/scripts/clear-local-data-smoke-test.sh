#!/usr/bin/env bash
# 玲珑应用商店本地数据清理脚本回归测试。
#
# 业务定位：
#   使用完全隔离的 HOME/XDG/TMPDIR 验证清理边界，确保测试不会访问开发机真实数据。
#   重点覆盖最新 XDG 路径、历史残留、偏好保留和共享图片缓存精确删除。

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_SCRIPT="$ROOT_DIR/build/scripts/clear-local-data.sh"
TEST_ROOT="$(mktemp -d)"
FAKE_BIN="$TEST_ROOT/bin"

# 测试结束时统一删除隔离目录，避免失败用例留下临时文件。
cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "$FAKE_BIN"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'if [[ "${FAKE_APP_RUNNING:-0}" == "1" ]]; then exit 0; fi' \
  'exit 1' > "$FAKE_BIN/pgrep"
chmod +x "$FAKE_BIN/pgrep"

# 构造包含当前路径、历史路径和恶意元数据的完整测试现场。
create_fixture() {
  local name="$1"
  local root="$TEST_ROOT/$name"
  local data_home="$root/data"
  local config_home="$root/config"
  local cache_home="$root/cache"
  local runtime_home="$root/runtime"
  local documents_home="$root/documents"
  local temp_home="$root/tmp"
  local current_data="$data_home/com.dongpl.linglong-store.v2"
  local binary_data="$data_home/linglong_store"
  local legacy_data="$data_home/org.linglong-store.LinyapsManager"

  mkdir -p \
    "$current_data/logs" \
    "$binary_data/history" \
    "$legacy_data/history" \
    "$config_home/com.dongpl.linglong-store.v2/startup" \
    "$cache_home/com.dongpl.linglong-store.v2" \
    "$runtime_home/com.dongpl.linglong-store.v2" \
    "$documents_home" \
    "$temp_home/libCachedImageData" \
    "$temp_home/linglong-store/logs" \
    "$temp_home/linglong-store-cache"

  printf '{"language":"zh"}\n' > "$current_data/shared_preferences.json"
  printf '{"language":"en"}\n' > "$binary_data/shared_preferences.json"
  printf '{"language":"zh"}\n' > "$legacy_data/shared_preferences.json"
  printf 'log\n' > "$current_data/logs/linglong-store.log"
  printf 'legacy\n' > "$binary_data/history/state"
  printf 'legacy\n' > "$legacy_data/history/state"
  printf '[renderer]\npreferred_mode=software\n' \
    > "$config_home/com.dongpl.linglong-store.v2/startup/renderer_preferences.ini"
  printf 'cache\n' > "$cache_home/com.dongpl.linglong-store.v2/cache.hive"
  printf 'lock\n' > "$cache_home/com.dongpl.linglong-store.v2/cache.lock"
  printf 'lock\n' > "$runtime_home/com.dongpl.linglong-store.v2/linglong-store.lock"
  printf 'socket\n' > "$runtime_home/com.dongpl.linglong-store.v2/linglong-store.sock"
  printf 'legacy cache\n' > "$documents_home/cache.hive"
  printf 'legacy lock\n' > "$documents_home/cache.lock"
  printf 'fallback\n' > "$temp_home/linglong-store/logs/fallback.log"
  printf 'fallback\n' > "$temp_home/linglong-store-cache/cache.hive"
  printf 'lock\n' > "$temp_home/linglong-store.lock"
  printf 'socket\n' > "$temp_home/linglong-store.sock"
  printf 'script\n' > "$temp_home/install-linglong-1.sh"
  printf 'script\n' > "$temp_home/linglong-permission-repair-1.sh"
  printf 'script\n' > "$temp_home/linglong-local-data-repull-1.sh"
  printf 'script\n' > "$temp_home/linglong-storage-move-1.sh"

  printf 'owned\n' > "$temp_home/libCachedImageData/owned.bin"
  printf 'legacy owned\n' > "$temp_home/libCachedImageData/legacy-owned.bin"
  printf 'shared\n' > "$temp_home/libCachedImageData/unreferenced.bin"
  printf 'outside\n' > "$temp_home/outside.bin"
  printf '%s\n' \
    '[{"relativePath":"owned.bin"},{"relativePath":"../outside.bin"}]' \
    > "$current_data/libCachedImageData.json"
  printf '%s\n' \
    '[{"relativePath":"legacy-owned.bin"}]' \
    > "$legacy_data/libCachedImageData.json"
  ln -s "$root/missing-target" "$current_data/broken-link"

  printf '%s\n' "$root"
}

# 在指定测试现场中运行目标脚本，所有路径均显式指向隔离目录。
run_target() {
  local root="$1"
  shift
  env \
    HOME="$root/home" \
    XDG_DATA_HOME="$root/data" \
    XDG_CONFIG_HOME="$root/config" \
    XDG_CACHE_HOME="$root/cache" \
    XDG_RUNTIME_DIR="$root/runtime" \
    XDG_DOCUMENTS_DIR="$root/documents" \
    TMPDIR="$root/tmp" \
    PATH="$FAKE_BIN:$PATH" \
    FAKE_APP_RUNNING="${FAKE_APP_RUNNING:-0}" \
    "$TARGET_SCRIPT" "$@"
}

# 断言路径不存在，失败时输出具体残留路径。
assert_missing() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    printf '预期路径已删除，但仍存在: %s\n' "$target" >&2
    exit 1
  fi
}

# 断言路径存在，失败时输出缺失路径。
assert_exists() {
  local target="$1"
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    printf '预期路径保留，但不存在: %s\n' "$target" >&2
    exit 1
  fi
}

# 验证 dry-run 只展示目标，不改变任何文件。
test_dry_run() {
  local root
  root="$(create_fixture dry-run)"
  run_target "$root" > "$root/output.log"

  assert_exists "$root/data/com.dongpl.linglong-store.v2"
  assert_exists "$root/config/com.dongpl.linglong-store.v2"
  assert_exists "$root/cache/com.dongpl.linglong-store.v2"
  assert_exists "$root/runtime/com.dongpl.linglong-store.v2"
  assert_exists "$root/tmp/libCachedImageData/owned.bin"
}

# 验证默认执行删除全部应用残留，但保留共享缓存中的无归属文件。
test_apply() {
  local root
  root="$(create_fixture apply)"
  run_target "$root" --apply > "$root/output.log"

  assert_missing "$root/data/com.dongpl.linglong-store.v2"
  assert_missing "$root/data/linglong_store"
  assert_missing "$root/data/org.linglong-store.LinyapsManager"
  assert_missing "$root/config/com.dongpl.linglong-store.v2"
  assert_missing "$root/cache/com.dongpl.linglong-store.v2"
  assert_missing "$root/runtime/com.dongpl.linglong-store.v2"
  assert_missing "$root/documents/cache.hive"
  assert_missing "$root/documents/cache.lock"
  assert_missing "$root/tmp/libCachedImageData/owned.bin"
  assert_missing "$root/tmp/libCachedImageData/legacy-owned.bin"
  assert_exists "$root/tmp/libCachedImageData/unreferenced.bin"
  assert_exists "$root/tmp/outside.bin"
  assert_missing "$root/tmp/linglong-store"
  assert_missing "$root/tmp/linglong-store-cache"
  assert_missing "$root/tmp/install-linglong-1.sh"
  assert_missing "$root/tmp/linglong-permission-repair-1.sh"
  assert_missing "$root/tmp/linglong-local-data-repull-1.sh"
  assert_missing "$root/tmp/linglong-storage-move-1.sh"
}

# 验证保留偏好模式只保留三个候选数据目录中的偏好文件。
test_keep_preferences() {
  local root
  root="$(create_fixture keep-preferences)"
  run_target "$root" --apply --keep-preferences > "$root/output.log"

  assert_exists "$root/data/com.dongpl.linglong-store.v2/shared_preferences.json"
  assert_exists "$root/data/linglong_store/shared_preferences.json"
  assert_exists "$root/data/org.linglong-store.LinyapsManager/shared_preferences.json"
  assert_missing "$root/data/com.dongpl.linglong-store.v2/logs"
  assert_missing "$root/data/com.dongpl.linglong-store.v2/broken-link"
  assert_missing "$root/data/linglong_store/history"
  assert_missing "$root/data/org.linglong-store.LinyapsManager/history"
  assert_missing "$root/config/com.dongpl.linglong-store.v2"
  assert_missing "$root/cache/com.dongpl.linglong-store.v2"
  assert_missing "$root/runtime/com.dongpl.linglong-store.v2"
}

# 验证运行中保护在任何删除动作前终止脚本。
test_running_guard() {
  local root
  root="$(create_fixture running-guard)"
  if FAKE_APP_RUNNING=1 run_target "$root" --apply > "$root/output.log" 2>&1; then
    printf '应用运行中时脚本应返回非零退出码\n' >&2
    exit 1
  fi

  assert_exists "$root/data/com.dongpl.linglong-store.v2"
  assert_exists "$root/cache/com.dongpl.linglong-store.v2"
}

# 验证 HOME 缺失时不会把历史 Documents 路径错误解析为系统根目录。
test_missing_home_does_not_target_root_documents() {
  local root="$TEST_ROOT/missing-home"
  mkdir -p "$root/data" "$root/config" "$root/cache" "$root/runtime" "$root/tmp"

  env -u HOME -u XDG_DOCUMENTS_DIR \
    XDG_DATA_HOME="$root/data" \
    XDG_CONFIG_HOME="$root/config" \
    XDG_CACHE_HOME="$root/cache" \
    XDG_RUNTIME_DIR="$root/runtime" \
    TMPDIR="$root/tmp" \
    PATH="$FAKE_BIN:$PATH" \
    FAKE_APP_RUNNING=0 \
    "$TARGET_SCRIPT" > "$root/output.log"

  if grep -Fq '/Documents/cache.' "$root/output.log"; then
    printf 'HOME 缺失时不得生成 /Documents 清理目标\n' >&2
    exit 1
  fi
}

# 验证任一清理根目录指向 / 时立即拒绝，避免固定文件名落到系统根目录。
test_root_directory_is_rejected() {
  local root="$TEST_ROOT/root-directory"
  mkdir -p "$root/data" "$root/config" "$root/cache" "$root/runtime" "$root/tmp"

  if env \
    HOME="$root/home" \
    XDG_DATA_HOME="$root/data" \
    XDG_CONFIG_HOME="$root/config" \
    XDG_CACHE_HOME="$root/cache" \
    XDG_RUNTIME_DIR="$root/runtime" \
    XDG_DOCUMENTS_DIR=/ \
    TMPDIR="$root/tmp" \
    PATH="$FAKE_BIN:$PATH" \
    FAKE_APP_RUNNING=0 \
    "$TARGET_SCRIPT" > "$root/output.log" 2>&1; then
    printf '清理根目录指向 / 时脚本应拒绝执行\n' >&2
    exit 1
  fi
}

test_dry_run
test_apply
test_keep_preferences
test_running_guard
test_missing_home_does_not_target_root_documents
test_root_directory_is_rejected

printf 'clear-local-data smoke tests passed\n'
