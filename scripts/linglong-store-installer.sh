#!/usr/bin/env bash
set -euo pipefail

# 玲珑商店安装器脚本
#
# 用法：
#   ./linglong-store-installer.sh [选项]
#
# 选项：
#   --help, -h        显示帮助信息
#   --version, -v     显示版本信息
#   --uninstall, -u   卸载玲珑商店
#
# 环境变量：
#   LINGLONG_SOURCE   强制指定下载源（可选）
#                     可选值：github, gitee
#                     若不设置，则自动检测网络环境选择最优源
#                     示例：LINGLONG_SOURCE=github ./linglong-store-installer.sh
#
# 说明：
#   - 脚本会自动检测网络环境，优先选择最快的下载源
#   - 若指定了 LINGLONG_SOURCE 环境变量，则跳过网络探测，直接使用指定的源
#   - GitHub 适合国际互联网环境，Gitee 适合国内互联网环境
#   - 若首选源下载失败，会自动切换到备用源重试

# ========= 前置检查 =========
# 检测到 银河麒麟v10 和 NixOS 时，给出特殊提示并退出
is_kylin_v10="false"
is_nixos="false"

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release

  if [[ "${ID:-}" == "nixos" ]] || [[ "${NAME:-}" == *"NixOS"* ]] || [[ "${PRETTY_NAME:-}" == *"NixOS"* ]]; then
    is_nixos="true"
  fi

  if [[ "${ID:-}" == "kylin" ]] || [[ "${NAME:-}" == *"Kylin"* ]] || [[ "${NAME:-}" == *"银河麒麟"* ]] || \
     [[ "${PRETTY_NAME:-}" == *"Kylin"* ]] || [[ "${PRETTY_NAME:-}" == *"银河麒麟"* ]]; then
    if [[ "${VERSION_ID:-}" == "V10" ]] || [[ "${VERSION_ID:-}" == "10" ]] || [[ "${VERSION:-}" == *"V10"* ]] || \
       [[ "${PRETTY_NAME:-}" == *"V10"* ]]; then
      is_kylin_v10="true"
    fi
  fi
fi

if [[ -f /etc/NIXOS ]]; then
  is_nixos="true"
fi

if [[ -f /etc/kylin-version ]] && grep -qi "V10" /etc/kylin-version; then
  is_kylin_v10="true"
fi
if [[ -f /etc/kylin-release ]] && grep -qi "V10" /etc/kylin-release; then
  is_kylin_v10="true"
fi

if [[ "$is_kylin_v10" == "true" ]]; then
  echo -e "\033[1;33m[提示]\033[0m 银河麒麟 V10 系统因为有应用保护，请手动安装玲珑环境。"
  echo "安装方法见：https://bbs.deepin.org.cn/phone/zh/post/289061"
  echo "如果已安装，或者已经安装完成，可手动安装商店："
  echo "  ll-cli repo add --alias=testing stable https://cdn-linglong.odata.cc"
  echo "  ll-cli install com.dongpl.linglong-store.v2 --repo testing"
  exit 0
fi

if [[ "$is_nixos" == "true" ]]; then
  echo "[INFO] NixOS detected, manual installation is required."
  echo "[INFO] Please enable the linyaps service in /etc/nixos/configuration.nix and rebuild your system."
  echo ""
  echo "Example configuration:"
  echo "  services.linyaps.enable = true;"
  echo ""
  echo "Then run:"
  echo "  sudo nixos-rebuild switch"
  echo ""
  echo "  ll-cli repo add --alias=testing stable https://cdn-linglong.odata.cc"
  echo "  ll-cli install com.dongpl.linglong-store.v2 --repo testing"
  exit 0
fi
# Arch 系 Linux 检测：tk 包是安装器的依赖，部分 Arch 发行版默认未安装
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" == "arch" ]] || [[ "${ID_LIKE:-}" == *"arch"* ]] || \
     [[ "${NAME:-}" == *"Arch"* ]] || [[ "${PRETTY_NAME:-}" == *"Arch"* ]] || \
     [[ "${ID:-}" == "manjaro" ]] || [[ "${ID:-}" == "garuda" ]] || \
     [[ "${ID:-}" == "endeavouros" ]] || [[ "${ID:-}" == "artix" ]]; then
    if ! pacman -Q tk >/dev/null 2>&1; then
      echo -e "\033[1;33m[提示]\033[0m 检测到 Arch 系 Linux，如果启动报错，请确认已安装 tk 包（安装器依赖）。"
      echo "  安装命令：sudo pacman -S tk"
      echo "更建议使用AUR版本：paru -S linglong-store-bin"
    fi
  fi
fi

# ========= 前置检查结束 =========


# ========= 基本配置 =========
REPO_NAME="linglong-installer"
VERSION="latest"
GITHUB_REPO_OWNER="HanHan666666"
GITEE_REPO_OWNER="hanplus"

# 环境变量：强制指定下载源（可选值：github, gitee）
# 若设置，则跳过网络探测，直接使用指定的源
LINGLONG_SOURCE="${LINGLONG_SOURCE:-}"

# Google generate_204 只用于判断优先级，不直接等价于 GitHub release/CDN 一定可达。
# 脚本会先按探测结果选择首选源，若下载失败再自动回退到另一个源。
NETWORK_PROBE_URL="https://www.google.com/generate_204"
NETWORK_PROBE_CONNECT_TIMEOUT_SECONDS="3"
NETWORK_PROBE_MAX_TIME_SECONDS="5"
DOWNLOAD_CONNECT_TIMEOUT_SECONDS="10"
DOWNLOAD_MAX_TIME_SECONDS="120"

# 二进制基础名（不带架构）
BIN_NAME="linglong-store-installer"

err() {
  echo -e "\033[1;31m[ERROR]\033[0m $*" >&2
  exit 1
}

info() {
  echo -e "\033[1;34m[INFO]\033[0m $*"
}

warn() {
  echo -e "\033[1;33m[WARN]\033[0m $*"
}

# 网络探测与实际下载都依赖 curl，提前失败比把问题误报成网络异常更清晰。
require_dependencies() {
  command -v curl >/dev/null 2>&1 || err "缺少 curl，请先安装 curl 后再运行此脚本。"
}

# 统一在一个位置维护源名称，避免日志与分支判断分散。
source_label() {
  case "$1" in
    github)
      printf '%s' 'GitHub'
      ;;
    gitee)
      printf '%s' 'Gitee'
      ;;
    *)
      printf '%s' "$1"
      ;;
  esac
}

# GitHub 的 latest 下载路径与 Gitee 的 latest 下载路径格式不同，这里统一封装。
build_download_url() {
  local source="$1"
  local bin_file="$2"

  case "$source" in
    github)
      if [[ "$VERSION" == "latest" ]]; then
        printf '%s' "https://github.com/${GITHUB_REPO_OWNER}/${REPO_NAME}/releases/latest/download/${bin_file}"
      else
        printf '%s' "https://github.com/${GITHUB_REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/${bin_file}"
      fi
      ;;
    gitee)
      printf '%s' "https://gitee.com/${GITEE_REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/${bin_file}"
      ;;
    *)
      return 1
      ;;
  esac
}

# 这里探测的是“更像外网可直连”的信号，只用于决定先尝试哪个源。
can_reach_preferred_network() {
  curl -fsSL \
    --connect-timeout "$NETWORK_PROBE_CONNECT_TIMEOUT_SECONDS" \
    --max-time "$NETWORK_PROBE_MAX_TIME_SECONDS" \
    -o /dev/null \
    "$NETWORK_PROBE_URL"
}

download_from_source() {
  local source="$1"
  local destination="$2"
  local url
  local file_magic

  url="$(build_download_url "$source" "$BIN_FILE")" || return 1
  rm -f "$destination"

  info "正在从 $(source_label "$source") 下载安装器..."
  if curl -fL --show-error \
    --connect-timeout "$DOWNLOAD_CONNECT_TIMEOUT_SECONDS" \
    --max-time "$DOWNLOAD_MAX_TIME_SECONDS" \
    --retry 1 \
    "$url" \
    -o "$destination"; then
    # 发布资产是 Go 构建出的 Linux 二进制，这里校验 ELF 魔数，避免把 HTML 错误页当成成功下载。
    file_magic="$(od -An -t x1 -N 4 "$destination" 2>/dev/null | tr -d '[:space:]')"
    if [[ -s "$destination" && "$file_magic" == "7f454c46" ]]; then
      return 0
    fi

    warn "从 $(source_label "$source") 下载的文件不是预期的 ELF 二进制，已丢弃。"
    rm -f "$destination"
    return 1
  fi

  rm -f "$destination"
  return 1
}

download_installer() {
  local destination="$1"
  local source
  local tried_sources=()
  local download_sources=()

  # 优先使用环境变量指定的源
  if [[ -n "$LINGLONG_SOURCE" ]]; then
    if [[ "$LINGLONG_SOURCE" == "github" ]]; then
      info "环境变量指定使用 GitHub 源。"
      download_sources=("github" "gitee")
    elif [[ "$LINGLONG_SOURCE" == "gitee" ]]; then
      info "环境变量指定使用 Gitee 源。"
      download_sources=("gitee" "github")
    else
      err "环境变量 LINGLONG_SOURCE 值无效：$LINGLONG_SOURCE（可选值：github, gitee）"
    fi
  else
    # 未指定环境变量，则自动检测网络环境
    if can_reach_preferred_network; then
      info "International internet environment detected, prioritizing GitHub."
      download_sources=("github" "gitee")
    else
      warn "检测到国内互联网环境，优先使用 Gitee。"
      download_sources=("gitee" "github")
    fi
  fi

  for source in "${download_sources[@]}"; do
    tried_sources+=("$(source_label "$source")")

    if download_from_source "$source" "$destination"; then
      SELECTED_SOURCE="$source"
      return 0
    fi

    warn "从 $(source_label "$source") 下载失败，尝试下一个源。"
  done

  err "无法下载安装器，已尝试：${tried_sources[*]}"
}

# ========= 架构检测 =========
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64 | amd64)
    ARCH_SUFFIX="amd64"
    ;;
  aarch64 | arm64)
    ARCH_SUFFIX="arm64"
    ;;
  *)
    err "不支持的架构: $ARCH"
    ;;
esac

BIN_FILE="${BIN_NAME}-${ARCH_SUFFIX}"
SELECTED_SOURCE=""

# ========= 下载目录 =========
WORKDIR="$(mktemp -d)"
BIN_PATH="${WORKDIR}/${BIN_FILE}"

cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

require_dependencies
download_installer "$BIN_PATH"
info "已从 $(source_label "$SELECTED_SOURCE") 下载完成，开始启动安装器。"

chmod +x "$BIN_PATH"


"$BIN_PATH"
