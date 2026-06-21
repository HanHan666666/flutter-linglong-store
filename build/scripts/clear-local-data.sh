#!/usr/bin/env bash
# 玲珑应用商店本地数据清理脚本。
#
# 业务定位：
#   还原首次启动状态，清理当前版本和历史版本产生的应用本地数据。
#   本脚本不卸载应用本体、不删除已安装的玲珑应用，也不触碰 linyaps 数据目录。
#
# 安全约束：
#   1. 默认 dry-run，只有 --apply 才执行删除。
#   2. 应用运行时拒绝清理，避免破坏活跃的日志、Hive 和单实例通信。
#   3. 图片缓存目录使用 flutter_cache_manager 通用 key，只按本应用元数据精确删除文件。
#   4. 所有目标均由固定 application-id 和 XDG 根目录组合，不接受任意删除路径。

set -euo pipefail

# ============================================================
# 应用身份与文件名
# ============================================================

APPLICATION_ID="com.dongpl.linglong-store.v2"
LEGACY_APPLICATION_ID="org.linglong-store.LinyapsManager"
BINARY_NAME="linglong_store"
PREFERENCES_FILE_NAME="shared_preferences.json"
IMAGE_CACHE_METADATA_FILE_NAME="libCachedImageData.json"
IMAGE_CACHE_DIRECTORY_NAME="libCachedImageData"

# ============================================================
# 参数与统计
# ============================================================

APPLY=false
KEEP_PREFERENCES=false
TARGET_COUNT=0
SKIPPED_COUNT=0
KEPT_COUNT=0
WARNING_COUNT=0

# 图片缓存文件名先从元数据收集，再在删除数据目录前处理。
declare -a IMAGE_CACHE_FILES=()
declare -A IMAGE_CACHE_FILE_SET=()

# ============================================================
# 路径解析
# ============================================================

# 输出错误并使用配置错误退出码终止，避免路径缺失时降级到危险位置。
fail_configuration() {
  printf '路径配置错误: %s\n' "$1" >&2
  exit 78
}

# 校验删除根目录必须是绝对路径，符合 XDG 规范并防止相对路径误删。
validate_absolute_path() {
  local name="$1"
  local value="$2"
  if [[ -z "$value" || "$value" != /* ]]; then
    fail_configuration "$name 必须是绝对路径，当前值: ${value:-<空>}"
  fi
  if [[ "$value" == "/" ]]; then
    fail_configuration "$name 禁止指向系统根目录"
  fi
}

if [[ -n "${XDG_DATA_HOME:-}" ]]; then
  DATA_HOME="$XDG_DATA_HOME"
elif [[ -n "${HOME:-}" ]]; then
  DATA_HOME="$HOME/.local/share"
else
  fail_configuration 'XDG_DATA_HOME 和 HOME 均未设置'
fi

if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
  CONFIG_HOME="$XDG_CONFIG_HOME"
elif [[ -n "${HOME:-}" ]]; then
  CONFIG_HOME="$HOME/.config"
else
  fail_configuration 'XDG_CONFIG_HOME 和 HOME 均未设置'
fi

if [[ -n "${XDG_CACHE_HOME:-}" ]]; then
  CACHE_HOME="$XDG_CACHE_HOME"
elif [[ -n "${HOME:-}" ]]; then
  CACHE_HOME="$HOME/.cache"
else
  fail_configuration 'XDG_CACHE_HOME 和 HOME 均未设置'
fi

TEMP_HOME="${TMPDIR:-/tmp}"

if [[ -n "${XDG_DOCUMENTS_DIR:-}" ]]; then
  DOCUMENTS_HOME="$XDG_DOCUMENTS_DIR"
elif command -v xdg-user-dir >/dev/null 2>&1; then
  DOCUMENTS_HOME="$(xdg-user-dir DOCUMENTS 2>/dev/null || true)"
  if [[ -z "$DOCUMENTS_HOME" && -n "${HOME:-}" ]]; then
    DOCUMENTS_HOME="$HOME/Documents"
  fi
elif [[ -n "${HOME:-}" ]]; then
  DOCUMENTS_HOME="$HOME/Documents"
else
  DOCUMENTS_HOME=""
fi

validate_absolute_path DATA_HOME "$DATA_HOME"
validate_absolute_path CONFIG_HOME "$CONFIG_HOME"
validate_absolute_path CACHE_HOME "$CACHE_HOME"
validate_absolute_path TEMP_HOME "$TEMP_HOME"
if [[ -n "$DOCUMENTS_HOME" ]]; then
  validate_absolute_path DOCUMENTS_HOME "$DOCUMENTS_HOME"
fi
if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
  validate_absolute_path XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR"
fi

CURRENT_DATA_DIR="$DATA_HOME/$APPLICATION_ID"
BINARY_DATA_DIR="$DATA_HOME/$BINARY_NAME"
LEGACY_DATA_DIR="$DATA_HOME/$LEGACY_APPLICATION_ID"
CURRENT_CONFIG_DIR="$CONFIG_HOME/$APPLICATION_ID"
CURRENT_CACHE_DIR="$CACHE_HOME/$APPLICATION_ID"
CURRENT_RUNTIME_DIR="${XDG_RUNTIME_DIR:+$XDG_RUNTIME_DIR/$APPLICATION_ID}"
IMAGE_CACHE_DIR="$TEMP_HOME/$IMAGE_CACHE_DIRECTORY_NAME"
FALLBACK_CACHE_DIR="$TEMP_HOME/linglong-store-cache"
FALLBACK_LOG_DIR="$TEMP_HOME/linglong-store"
FALLBACK_LOCK_FILE="$TEMP_HOME/linglong-store.lock"
FALLBACK_SOCKET_FILE="$TEMP_HOME/linglong-store.sock"
LEGACY_HIVE_FILE="${DOCUMENTS_HOME:+$DOCUMENTS_HOME/cache.hive}"
LEGACY_HIVE_LOCK_FILE="${DOCUMENTS_HOME:+$DOCUMENTS_HOME/cache.lock}"

APP_DATA_DIRS=(
  "$CURRENT_DATA_DIR"
  "$BINARY_DATA_DIR"
  "$LEGACY_DATA_DIR"
)

# ============================================================
# 通用辅助函数
# ============================================================

# 判断普通路径或断链符号链接是否存在，避免残留链接被误判为不存在。
path_exists() {
  [[ -e "$1" || -L "$1" ]]
}

# 打印警告并累计数量；警告不会中断其他安全清理项。
warn() {
  printf '  [警告] %s\n' "$1" >&2
  WARNING_COUNT=$((WARNING_COUNT + 1))
}

# 处理单个文件或目录；dry-run 只展示，apply 使用 -- 防止路径被解析为选项。
process_path() {
  local target="$1"
  local description="$2"

  if ! path_exists "$target"; then
    printf '  [跳过] %s\n        不存在 — %s\n' "$target" "$description"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    return 0
  fi

  local size
  size="$(du -sh -- "$target" 2>/dev/null | awk '{print $1}' || true)"
  size="${size:-?}"

  if $APPLY; then
    rm -rf -- "$target"
    printf '  [已删] %s\n        (%s) — %s\n' "$target" "$size" "$description"
  else
    printf '  [预览] %s\n        (%s) — %s\n' "$target" "$size" "$description"
  fi
  TARGET_COUNT=$((TARGET_COUNT + 1))
}

# 在保留偏好模式下，仅保留数据目录顶层的 SharedPreferences 文件。
process_app_data_directory() {
  local directory="$1"
  local description="$2"

  if ! path_exists "$directory"; then
    printf '  [跳过] %s\n        不存在 — %s\n' "$directory" "$description"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    return 0
  fi

  if ! $KEEP_PREFERENCES; then
    process_path "$directory" "$description"
    return 0
  fi

  local preferences_file="$directory/$PREFERENCES_FILE_NAME"
  if ! path_exists "$preferences_file"; then
    process_path "$directory" "$description（未发现可保留的 SharedPreferences）"
    return 0
  fi

  printf '  [保留] %s\n        --keep-preferences 仅保留该文件\n' "$preferences_file"
  KEPT_COUNT=$((KEPT_COUNT + 1))

  local entries=()
  shopt -s dotglob nullglob
  entries=("$directory"/*)
  shopt -u dotglob nullglob

  local entry
  for entry in "${entries[@]}"; do
    if [[ "$entry" == "$preferences_file" ]]; then
      continue
    fi
    process_path "$entry" "$description中的非偏好数据"
  done
}

# 检测 Flutter 主进程是否运行；pgrep 不可用时维持历史兼容并继续执行。
check_app_running() {
  if command -v pgrep >/dev/null 2>&1 && pgrep -x "$BINARY_NAME" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# 输出命令帮助和按当前环境解析后的主要清理路径。
print_help() {
  cat <<EOF
玲珑应用商店本地数据清理脚本

用法: $(basename "$0") [选项]

选项:
      --apply               真正执行删除（默认 dry-run）
      --keep-preferences    保留 SharedPreferences，删除其他本地状态
  -h, --help                显示帮助

当前主要清理范围:
  - $CURRENT_DATA_DIR
  - $CURRENT_CONFIG_DIR
  - $CURRENT_CACHE_DIR
  - ${CURRENT_RUNTIME_DIR:-<XDG_RUNTIME_DIR 未设置，使用临时回退文件>}
  - $BINARY_DATA_DIR
  - $LEGACY_DATA_DIR
  - ${LEGACY_HIVE_FILE:-<Documents 无法解析，跳过历史 Hive>} ${LEGACY_HIVE_LOCK_FILE:+/ $LEGACY_HIVE_LOCK_FILE}
  - $FALLBACK_CACHE_DIR / $FALLBACK_LOG_DIR

不会触碰:
  - ~/.linglong / ~/.config/linglong / ~/.cache/linglong / /var/lib/linglong
  - 通过商店安装的玲珑应用
  - 系统包管理器安装的应用本体和桌面文件
EOF
}

# ============================================================
# 图片缓存精确清理
# ============================================================

# 从单个 flutter_cache_manager JSON 元数据中收集经过白名单校验的文件名。
collect_image_cache_metadata() {
  local metadata_file="$1"
  if [[ ! -f "$metadata_file" ]]; then
    return 0
  fi

  local token
  local relative_path
  while IFS= read -r token; do
    relative_path="$(sed -E 's/^"relativePath"[[:space:]]*:[[:space:]]*"([^"]*)"$/\1/' <<< "$token")"
    if [[ ! "$relative_path" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] ||
       [[ "$relative_path" == "." || "$relative_path" == ".." ]]; then
      warn "忽略非法图片缓存相对路径: $relative_path（来源: $metadata_file）"
      continue
    fi

    if [[ -z "${IMAGE_CACHE_FILE_SET[$relative_path]+x}" ]]; then
      IMAGE_CACHE_FILE_SET["$relative_path"]=1
      IMAGE_CACHE_FILES+=("$relative_path")
    fi
  done < <(
    LC_ALL=C grep -oE '"relativePath"[[:space:]]*:[[:space:]]*"[^"]*"' \
      "$metadata_file" 2>/dev/null || true
  )
}

# 收集当前和两个历史数据目录中的图片缓存归属信息。
collect_image_cache_files() {
  local directory
  for directory in "${APP_DATA_DIRS[@]}"; do
    collect_image_cache_metadata "$directory/$IMAGE_CACHE_METADATA_FILE_NAME"
  done
}

# 只删除元数据引用的图片文件，并仅在共享目录为空时移除目录本身。
process_image_cache_files() {
  local relative_path
  for relative_path in "${IMAGE_CACHE_FILES[@]}"; do
    process_path "$IMAGE_CACHE_DIR/$relative_path" "本应用 flutter_cache_manager 图片缓存"
  done

  if $APPLY && [[ -d "$IMAGE_CACHE_DIR" ]]; then
    rmdir -- "$IMAGE_CACHE_DIR" 2>/dev/null || true
  fi
}

# ============================================================
# 临时残留清理
# ============================================================

# 清理当前用户拥有的项目临时脚本，避免误删其他用户的同名文件。
process_owned_temporary_scripts() {
  local candidates=()
  shopt -s nullglob
  candidates=(
    "$TEMP_HOME"/install-linglong-*.sh
    "$TEMP_HOME"/linglong-permission-repair-*.sh
    "$TEMP_HOME"/linglong-local-data-repull-*.sh
    "$TEMP_HOME"/linglong-storage-move-*.sh
  )
  shopt -u nullglob

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -O "$candidate" ]]; then
      process_path "$candidate" "异常退出后残留的应用临时脚本"
    else
      warn "跳过不属于当前用户的临时脚本: $candidate"
    fi
  done
}

# ============================================================
# 参数解析
# ============================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=true
      ;;
    --keep-preferences)
      KEEP_PREFERENCES=true
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      printf '未知参数: %s\n\n' "$1" >&2
      print_help >&2
      exit 64
      ;;
  esac
  shift
done

# ============================================================
# 主流程
# ============================================================

printf '%s\n' '============================================================'
printf '%s\n' ' 玲珑应用商店本地数据清理'
if $APPLY; then
  printf '%s\n' ' 模式：执行删除（--apply）'
else
  printf '%s\n' ' 模式：dry-run 预览（加 --apply 才真删）'
fi
printf '%s\n\n' '============================================================'

printf '%s\n' '[1/6] 检查应用是否在运行 ...'
if check_app_running; then
  printf '  [拒绝] 检测到应用正在运行，请先完全退出应用再清理。\n' >&2
  printf '         排查: pgrep -x %s\n' "$BINARY_NAME" >&2
  exit 1
fi
printf '%s\n\n' '  应用未运行，继续'

printf '%s\n' '[2/6] 清理本应用图片缓存 ...'
collect_image_cache_files
process_image_cache_files
printf '\n'

printf '%s\n' '[3/6] 清理当前 XDG 配置、缓存和运行时目录 ...'
process_path "$CURRENT_CONFIG_DIR" "应用配置（含渲染器偏好）"
process_path "$CURRENT_CACHE_DIR" "Hive 缓存（含 cache.hive/cache.lock）"
if [[ -n "$CURRENT_RUNTIME_DIR" ]]; then
  process_path "$CURRENT_RUNTIME_DIR" "单实例 XDG 运行时目录"
else
  printf '%s\n' '  [说明] XDG_RUNTIME_DIR 未设置，跳过运行时子目录并处理临时回退文件'
fi
printf '\n'

printf '%s\n' '[4/6] 清理历史 Hive 和应用专属临时回退 ...'
if [[ -n "$LEGACY_HIVE_FILE" ]]; then
  process_path "$LEGACY_HIVE_FILE" "历史 Documents Hive 缓存"
  process_path "$LEGACY_HIVE_LOCK_FILE" "历史 Documents Hive 锁文件"
else
  printf '%s\n' '  [说明] HOME 和 XDG Documents 均无法解析，跳过历史 Documents Hive'
fi
process_path "$FALLBACK_CACHE_DIR" "HOME/XDG 缺失时的 Hive 临时回退目录"
process_path "$FALLBACK_LOG_DIR" "HOME/XDG 缺失时的日志临时回退目录"
process_path "$FALLBACK_LOCK_FILE" "单实例临时回退锁文件"
process_path "$FALLBACK_SOCKET_FILE" "单实例临时回退 socket 文件"
printf '\n'

printf '%s\n' '[5/6] 清理当前和历史应用数据目录 ...'
process_app_data_directory "$CURRENT_DATA_DIR" "当前 application-id 数据目录"
process_app_data_directory "$BINARY_DATA_DIR" "历史可执行文件名数据目录"
process_app_data_directory "$LEGACY_DATA_DIR" "旧 application-id 数据目录"
printf '\n'

printf '%s\n' '[6/6] 清理异常退出残留的临时脚本 ...'
process_owned_temporary_scripts
printf '\n'

printf '%s\n' '============================================================'
if $APPLY; then
  printf ' 清理完成：已删 %d 项，跳过 %d 项，保留 %d 项，警告 %d 项\n' \
    "$TARGET_COUNT" "$SKIPPED_COUNT" "$KEPT_COUNT" "$WARNING_COUNT"
else
  printf ' 预览完成：将删 %d 项，跳过 %d 项，保留 %d 项，警告 %d 项\n' \
    "$TARGET_COUNT" "$SKIPPED_COUNT" "$KEPT_COUNT" "$WARNING_COUNT"
  printf ' 确认无误后执行: %s --apply%s\n' \
    "$0" "$($KEEP_PREFERENCES && printf ' --keep-preferences' || true)"
fi
printf '%s\n' '============================================================'
