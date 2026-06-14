#!/usr/bin/env bash
# 玲珑应用商店（flutter-linglong-store）本地数据清理脚本
#
# 业务定位：
#   还原"第一次安装"效果，清理应用本地状态：
#   - SharedPreferences（语言/主题/用户偏好/安装队列）
#   - Hive 缓存（应用详情、推荐页快照等）
#   - flutter_cache_manager 缓存：元数据 libCachedImageData.json + 实际下载文件 /tmp/libCachedImageData/
#   - 应用日志（linglong-store.log 轮转系列）
#   - Linux 渲染器偏好（startup/renderer_preferences.ini）
#   - 单实例锁文件（/tmp/linglong-store.lock / .sock）
#
# 安全设计：
#   1. 默认 dry-run，只列出会删什么；加 --apply 才真删
#   2. 应用在运行时拒绝执行，避免破坏活跃数据
#   3. 不触碰 ~/.linglong / ~/.config/linglong / ~/.cache/linglong，
#      这些是玲珑运行时（ll-cli / linyaps）管理的目录，超出本应用范围。
#      特别说明：~/.linglong/<appId>/private/home/<user>/.ssh、.gnupg 是
#      玲珑沙箱 home 隔离的预创建占位符（每个玲珑应用都有），跟本应用数据无关。
#   4. 不在本脚本中卸载"通过商店装的玲珑应用"——ll-cli list 的输出
#      不记录应用来源（无 Origin/installer 字段），无法可靠区分哪些是
#      本商店装的。如需卸载已安装应用，请用 ll-cli list + ll-cli uninstall 手动处理。
#
# 适用场景：
#   - 开发联调时还原首启动状态
#   - 验证迁移逻辑、首启动引导、Onboarding 等
#
# 使用示例：
#   ./build/scripts/clear-local-data.sh                     # dry-run，预览
#   ./build/scripts/clear-local-data.sh --apply             # 执行清理
#   ./build/scripts/clear-local-data.sh --apply --keep-preferences

set -euo pipefail

# ============================================================
# 常量定义
# ============================================================

# Linux CMakeLists.txt 中声明的 APPLICATION_ID
APPLICATION_ID="com.dongpl.linglong-store.v2"
# Flutter 可执行文件名（linglong_store）
BINARY_NAME="linglong_store"

# XDG 数据根目录：优先 XDG_DATA_HOME，其次 ~/.local/share
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# path_provider_linux 行为：getApplicationSupportPath() 优先返回
#   <DATA_HOME>/<APPLICATION_ID>，存在则用之；
#   否则回退到 <DATA_HOME>/<BINARY_NAME>（向后兼容历史目录），存在则用之；
#   都不存在则创建 APPLICATION_ID 目录。
# 当前用户环境观察到 SharedPreferences / libCachedImageData.json 落到了
# BINARY_NAME 目录，是历史回退产物。两个目录都纳入清理，避免遗漏。
APP_DEFAULT_DIR="$DATA_HOME/$BINARY_NAME"
APP_ID_DIR="$DATA_HOME/$APPLICATION_ID"

# Hive 缓存：Hive.initFlutter 走 getApplicationDocumentsDirectory，
# 在 Linux 上由 path_provider_linux 解析为 XDG_DOCUMENTS_DIR 或 ~/.Documents。
DOCUMENTS_DIR="${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
HIVE_CACHE_FILE="$DOCUMENTS_DIR/cache.hive"

# flutter_cache_manager 实际下载文件存放目录（DefaultCacheManager.key='libCachedImageData'）
# 源：flutter_cache_manager-3.4.1/lib/src/storage/file_system/file_system_io.dart
# getTemporaryDirectory 在 Linux 上是 /tmp 或 $TMPDIR
CACHE_FILES_DIR="${TMPDIR:-/tmp}/libCachedImageData"

# 单实例锁文件（lib/core/platform/single_instance.dart）
LOCK_FILE="/tmp/linglong-store.lock"
SOCK_FILE="/tmp/linglong-store.sock"

# ============================================================
# 参数与状态
# ============================================================

APPLY=false
KEEP_PREFERENCES=false

# 累计计数，用于结尾汇总
# - TARGET_COUNT：dry-run 时为"将删"，apply 时为"已删"
# - SKIPPED_COUNT：目标不存在，自动跳过
# - KEPT_COUNT：被 --keep-preferences 等显式保留
TARGET_COUNT=0
SKIPPED_COUNT=0
KEPT_COUNT=0

# ============================================================
# 辅助函数
# ============================================================

# 打印帮助信息
print_help() {
  cat <<EOF
玲珑应用商店本地数据清理脚本

用法: $(basename "$0") [选项]

选项:
      --apply                       真正执行删除（默认 dry-run，仅预览）
      --keep-preferences            保留 SharedPreferences（语言/主题/设置）
  -h, --help                        显示帮助

默认清理范围（dry-run 仅预览，加 --apply 才真删）:
  - $APP_DEFAULT_DIR      SharedPreferences + flutter_cache_manager 元数据
                            （历史回退路径；首次安装后实际可能落到 APP_ID_DIR）
  - $APP_ID_DIR           日志、渲染器偏好，也可能含 SP/libCachedImageData
  - $HIVE_CACHE_FILE      Hive 缓存（cache box）
  - $CACHE_FILES_DIR      flutter_cache_manager 实际下载的图片缓存
  - $LOCK_FILE / $SOCK_FILE  单实例锁残留

不会触碰（超出本应用范围，需要手动处理）:
  - ~/.linglong / ~/.config/linglong / ~/.cache/linglong
    （玲珑运行时管理；~/.linglong/<appId>/private/home 是沙箱 home 占位符）
  - 已安装的玲珑应用
    （ll-cli list 不记录来源，无法可靠区分本商店装的应用；
     如需卸载请用 ll-cli list / ll-cli uninstall 手动处理）
EOF
}

# 处理单个文件或目录：dry-run 仅展示，--apply 才真删
# 参数：$1=目标路径  $2=中文描述（出现在日志里）
process_path() {
  local target="$1"
  local description="$2"

  if [[ ! -e "$target" ]]; then
    printf "  [跳过] %s\n        不存在 — %s\n" "$target" "$description"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    return 0
  fi

  # 计算大小用于展示，失败时降级为 "?"
  local size
  size=$(du -sh "$target" 2>/dev/null | awk '{print $1}')
  size="${size:-?}"

  if $APPLY; then
    rm -rf -- "$target"
    printf "  [已删] %s\n        (%s) — %s\n" "$target" "$size" "$description"
  else
    printf "  [预览] %s\n        (%s) — %s\n" "$target" "$size" "$description"
  fi
  TARGET_COUNT=$((TARGET_COUNT + 1))
}

# 处理 SharedPreferences：根据 --keep-preferences 决定保留还是清空整个文件
# 参数：$1=SharedPreferences 文件完整路径
process_preferences() {
  local prefs_file="$1"

  if [[ ! -f "$prefs_file" ]]; then
    printf "  [跳过] %s\n        不存在 — SharedPreferences\n" "$prefs_file"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    return 0
  fi

  if $KEEP_PREFERENCES; then
    printf "  [保留] %s\n        已通过 --keep-preferences 跳过\n" "$prefs_file"
    KEPT_COUNT=$((KEPT_COUNT + 1))
    return 0
  fi

  process_path "$prefs_file" "SharedPreferences（语言/主题/安装队列等）"
}

# 检测应用是否仍在运行
# 判定依据：精确匹配进程名 linglong_store
#
# 不使用 flock 测试锁文件的原因：
#   Dart 的 RandomAccessFile.lock() 在 Linux 上走 fcntl(F_SETLK, F_WRLCK)
#   （字节范围锁），而 shell flock 走 flock(2)（整文件锁）。两者是独立的
#   锁机制，互不感知，所以 `flock -n /tmp/linglong-store.lock` 即使应用
#   持锁也会"成功"——会误报"应用未运行"。
#   实测：进程 425569 持有 fcntl 写锁时，flock -n 仍返回 0。
check_app_running() {
  if command -v pgrep >/dev/null 2>&1; then
    # 精确匹配进程名（linglong_store 14 字符，未超 Linux TASK_COMM_LEN=15 字符截断限制）
    if pgrep -x "$BINARY_NAME" >/dev/null 2>&1; then
      return 0
    fi
  fi

  return 1
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
      echo "未知参数: $1" >&2
      echo "" >&2
      print_help >&2
      exit 64
      ;;
  esac
  shift
done

# ============================================================
# 主流程
# ============================================================

echo "============================================================"
echo " 玲珑应用商店本地数据清理"
if $APPLY; then
  echo " 模式：执行删除（--apply）"
else
  echo " 模式：dry-run 预览（加 --apply 才真删）"
fi
echo "============================================================"
echo ""

# 1. 应用运行检测：拒绝在运行时清理，避免破坏活跃数据
echo "[1/5] 检查应用是否在运行 ..."
if check_app_running; then
  echo "  [拒绝] 检测到应用正在运行，请先完全退出应用再清理。" >&2
  echo "         排查：pgrep -x $BINARY_NAME" >&2
  exit 1
fi
echo "  应用未运行，继续"
echo ""

# 2. 清理 Flutter 应用数据目录
# SharedPreferences 可能落到 APP_DEFAULT_DIR 或 APP_ID_DIR（取决于 path_provider 回退路径），
# 两个位置都检查；libCachedImageData.json 同理。
echo "[2/5] 清理 Flutter 应用数据目录 ..."
process_preferences "$APP_DEFAULT_DIR/shared_preferences.json"
process_preferences "$APP_ID_DIR/shared_preferences.json"
process_path \
  "$APP_DEFAULT_DIR/libCachedImageData.json" \
  "flutter_cache_manager 缓存元数据（libCachedImageData.json）"
process_path \
  "$APP_ID_DIR/libCachedImageData.json" \
  "flutter_cache_manager 缓存元数据（libCachedImageData.json，applicationId 路径）"
echo ""

# 3. 清理 Hive 缓存
echo "[3/5] 清理 Hive 缓存 ..."
process_path "$HIVE_CACHE_FILE" "Hive 缓存（cache box，含应用详情/推荐页快照等）"
echo ""

# 4. 清理 flutter_cache_manager 实际下载文件目录
echo "[4/5] 清理 flutter_cache_manager 下载缓存 ..."
process_path "$CACHE_FILES_DIR" "flutter_cache_manager 实际下载的图片缓存"
echo ""

# 5. 清理 APPLICATION_ID 目录（日志、渲染器偏好）+ /tmp 锁文件
echo "[5/5] 清理应用日志目录与单实例锁 ..."
process_path "$APP_ID_DIR" "应用日志目录（linglong-store.log 系列、env 安装日志、渲染器偏好）"
process_path "$LOCK_FILE" "单实例锁文件"
process_path "$SOCK_FILE" "单实例 socket 文件"
echo ""

# ============================================================
# 汇总
# ============================================================

echo "============================================================"
if $APPLY; then
  echo " 清理完成：已删 $TARGET_COUNT 项，跳过 $SKIPPED_COUNT 项，保留 $KEPT_COUNT 项"
else
  echo " 预览完成：将删 $TARGET_COUNT 项，跳过 $SKIPPED_COUNT 项，保留 $KEPT_COUNT 项"
  echo " 确认无误后，执行：$0 --apply$(
    $KEEP_PREFERENCES && echo ' --keep-preferences' || true)"
fi
echo "============================================================"
