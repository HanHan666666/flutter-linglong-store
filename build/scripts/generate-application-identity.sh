#!/usr/bin/env bash
# 从唯一身份声明生成 Dart 与 CMake 的编译期适配文件。
#
# 默认模式原子更新生成物；--check 只验证内容，供 CI 和发布流程阻止配置漂移。

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_PATH="$ROOT_DIR/config/application_identity.conf"
DART_TARGET="$ROOT_DIR/lib/core/config/generated/application_identity.g.dart"
CMAKE_TARGET="$ROOT_DIR/linux/generated/application_identity.cmake"

. "$ROOT_DIR/build/scripts/lib/application-identity.sh"

mode="write"
case "${1:-}" in
  "")
    ;;
  --check)
    mode="check"
    ;;
  *)
    printf '用法: %s [--check]\n' "$0" >&2
    exit 64
    ;;
esac

load_application_identity "$CONFIG_PATH"

GENERATION_TEMP_DIR="$(mktemp -d)"

# 生成结束后清理候选文件；目标文件只会通过同目录原子替换更新。
cleanup_generation_temp_dir() {
  rm -rf -- "$GENERATION_TEMP_DIR"
}
trap cleanup_generation_temp_dir EXIT

dart_candidate="$GENERATION_TEMP_DIR/application_identity.g.dart"
cmake_candidate="$GENERATION_TEMP_DIR/application_identity.cmake"

# 输出 Dart 字符串列表。身份读取器已限制字符集，这里无需通用转义器。
write_dart_string_list() {
  local encoded_ids="$1"
  local -a desktop_ids=()
  local desktop_id

  IFS=',' read -r -a desktop_ids <<<"$encoded_ids"
  for desktop_id in "${desktop_ids[@]}"; do
    printf "    '%s',\n" "$desktop_id"
  done
}

{
  printf '%s\n' \
    '/// Linux 应用身份的编译期常量。' \
    '///' \
    '/// 本文件由 build/scripts/generate-application-identity.sh 根据' \
    '/// config/application_identity.conf 生成，请勿手工修改。' \
    'library;' \
    '' \
    '/// 为 Dart 运行时提供与 Linux 构建、打包完全一致的应用身份。' \
    'abstract final class ApplicationIdentity {' \
    '  /// GLib、XDG 数据命名空间共同使用的主应用 ID。' \
    "  static const String applicationId = '$APPLICATION_ID';" \
    '' \
    '  /// Freedesktop/AppStream 使用的 canonical desktop ID。' \
    '  static const String canonicalDesktopId =' \
    "      '$CANONICAL_DESKTOP_ID';" \
    '' \
    '  /// Linux runner 与 Dart 端共同使用的系统通知 MethodChannel。' \
    '  static const String systemNotificationChannel =' \
    "      '$SYSTEM_NOTIFICATION_CHANNEL';" \
    '' \
    '  /// Stable 包保留的隐藏 desktop 兼容入口。' \
    '  static const List<String> stableCompatDesktopIds = <String>['
  write_dart_string_list "$STABLE_COMPAT_DESKTOP_IDS"
  printf '%s\n' \
    '  ];' \
    '' \
    '  /// Nightly 包保留的隐藏 desktop 兼容入口。' \
    '  static const List<String> nightlyCompatDesktopIds = <String>['
  write_dart_string_list "$NIGHTLY_COMPAT_DESKTOP_IDS"
  printf '%s\n' \
    '  ];' \
    '}'
} >"$dart_candidate"

{
  printf '%s\n' \
    '# Linux runner 使用的主应用身份。' \
    '#' \
    '# 本文件由 build/scripts/generate-application-identity.sh 根据' \
    '# config/application_identity.conf 生成，请勿手工修改。' \
    "set(APPLICATION_ID \"$APPLICATION_ID\")"
} >"$cmake_candidate"

# 检查或原子更新单个生成物，避免构建中断留下不完整目标文件。
sync_generated_file() {
  local candidate="$1"
  local target="$2"

  if [[ -f "$target" ]] && cmp -s "$candidate" "$target"; then
    return 0
  fi

  if [[ "$mode" == "check" ]]; then
    printf '应用身份生成物不是最新状态: %s\n' "${target#"$ROOT_DIR"/}" >&2
    return 1
  fi

  mkdir -p "$(dirname "$target")"
  local replacement
  replacement="$(mktemp "${target}.tmp.XXXXXX")"
  install -m 0644 "$candidate" "$replacement"
  mv -f -- "$replacement" "$target"
  printf '已更新应用身份生成物: %s\n' "${target#"$ROOT_DIR"/}"
}

sync_generated_file "$dart_candidate" "$DART_TARGET"
sync_generated_file "$cmake_candidate" "$CMAKE_TARGET"
