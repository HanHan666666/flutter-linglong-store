#!/usr/bin/env bash
# 应用身份声明、严格解析和生成物一致性的轻量 smoke 测试。
#
# 只覆盖会导致跨语言身份漂移或执行不可信配置的真实边界，不复制业务测试。

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IDENTITY_LIBRARY="$ROOT_DIR/build/scripts/lib/application-identity.sh"
IDENTITY_CONFIG="$ROOT_DIR/config/application_identity.conf"
TEST_ROOT="$(mktemp -d)"

# 测试结束时删除隔离配置和诊断输出。
cleanup_test_root() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup_test_root EXIT

. "$IDENTITY_LIBRARY"
load_application_identity "$IDENTITY_CONFIG"

[[ "$CANONICAL_DESKTOP_ID" == "${APPLICATION_ID}.desktop" ]]
[[ "$WM_CLASS" == "$APPLICATION_ID" ]]
[[ "$SYSTEM_NOTIFICATION_CHANNEL" == "${APPLICATION_ID}/system_notification" ]]

mapfile -t stable_aliases < <(application_identity_compat_desktop_ids stable)
mapfile -t nightly_aliases < <(application_identity_compat_desktop_ids nightly)
IFS=',' read -r -a expected_stable_aliases <<<"$STABLE_COMPAT_DESKTOP_IDS"
IFS=',' read -r -a expected_nightly_aliases <<<"$NIGHTLY_COMPAT_DESKTOP_IDS"
[[ "${stable_aliases[*]}" == "${expected_stable_aliases[*]}" ]]
[[ "${nightly_aliases[*]}" == "${expected_nightly_aliases[*]}" ]]

"$ROOT_DIR/build/scripts/generate-application-identity.sh" --check

# 在独立 Bash 进程中验证非法配置，避免只读身份变量污染后续用例。
expect_invalid_config() {
  local name="$1"
  local expected_diagnostic="$2"
  local config_content="$3"
  local config_path="$TEST_ROOT/$name.conf"
  local output_path="$TEST_ROOT/$name.log"

  printf '%s\n' "$config_content" >"$config_path"
  if bash -c \
    '. "$1"; load_application_identity "$2"' \
    identity-smoke "$IDENTITY_LIBRARY" "$config_path" \
    >"$output_path" 2>&1; then
    printf '非法应用身份配置被错误接受: %s\n' "$name" >&2
    exit 1
  fi

  if ! grep -Fq "$expected_diagnostic" "$output_path"; then
    printf '非法配置诊断不符合预期: %s\n' "$name" >&2
    cat "$output_path" >&2
    exit 1
  fi
}

expect_invalid_config \
  unknown-field \
  '包含未知字段' \
  $'APPLICATION_ID=com.example.store\nSTABLE_COMPAT_DESKTOP_IDS=store.desktop\nNIGHTLY_COMPAT_DESKTOP_IDS=store-nightly.desktop\nSHELL_COMMAND=$(touch /tmp/should-not-run)'

expect_invalid_config \
  duplicate-field \
  '重复定义字段 APPLICATION_ID' \
  $'APPLICATION_ID=com.example.store\nAPPLICATION_ID=com.example.other\nSTABLE_COMPAT_DESKTOP_IDS=store.desktop\nNIGHTLY_COMPAT_DESKTOP_IDS=store-nightly.desktop'

expect_invalid_config \
  invalid-application-id \
  'APPLICATION_ID 不符合反向 DNS/GLib 标识格式' \
  $'APPLICATION_ID=$(touch-danger)\nSTABLE_COMPAT_DESKTOP_IDS=store.desktop\nNIGHTLY_COMPAT_DESKTOP_IDS=store-nightly.desktop'

expect_invalid_config \
  canonical-alias \
  '兼容 desktop ID 不能等于 canonical desktop ID' \
  $'APPLICATION_ID=com.example.store\nSTABLE_COMPAT_DESKTOP_IDS=com.example.store.desktop\nNIGHTLY_COMPAT_DESKTOP_IDS=store-nightly.desktop'

expect_invalid_config \
  duplicate-alias \
  '兼容 desktop ID 重复' \
  $'APPLICATION_ID=com.example.store\nSTABLE_COMPAT_DESKTOP_IDS=store.desktop\nNIGHTLY_COMPAT_DESKTOP_IDS=store.desktop'

printf 'application identity smoke tests passed\n'
