#!/usr/bin/env bash
# 文件定位：统信应用商店（UOS Store）投递脚本，由 Gitee Go 流水线在云端容器内调用。
#
# 为什么需要这个文件：
#   GitHub Actions 的运行器位于境外，访问统信开发者平台 appstore-dev.uniontech.com
#   会被网络链路阻断，导致 release.yml 里的 update-uos-store 任务长期失败。
#   Gitee Go 的构建节点在国内，可以正常访问该平台，因此把这段投递逻辑整体搬到
#   Gitee 侧执行。流水线 YAML 只保留“拉镜像 + 调脚本”这一层薄壳，所有业务细节都
#   收敛在本脚本，便于版本管理、本地复现和后续维护。
#
# 适用场景：
#   发布流程已把 deb 包同步到 Gitee Release 之后，手工触发 Gitee Go 流水线，
#   由本脚本完成“下载产物 → 准备运行环境 → 调用投递工具 → 提交商店”全流程。
#
# 关键约定（改动前请先看 docs/53-uos-store-gitee-go-design.md）：
#   1. 统信商店的登录依赖无头 Chromium（工具内部用 pyppeteer 登录页换取 Cookie），
#      因此容器内必须存在可用的 Chromium，普通 requests 登录不成立。
#   2. 运行节点在国内，所有下载默认走国内镜像源：Docker 镜像用 daocloud、
#      PyPI 用阿里云、Chromium 由工具自带的华为云/npmmirror 回退逻辑处理。
#   3. 真实提交与“只验证登录”必须严格区分：默认 MODE=verify，只有显式传
#      MODE=submit 才会向商店提交包，避免误触发提审。
#   4. 账号密码只通过环境变量注入（Gitee Go 通用变量，密码为密文变量），
#      禁止写进仓库文件或打印到日志。

set -euo pipefail

# ---------- 可配置项（可由 Gitee Go 通用变量覆盖） ----------

# 商店开发者账号，Gitee Go 通用变量注入，缺失时直接失败。
APPSTORE_USERNAME="${APPSTORE_USERNAME:-}"
APPSTORE_PASSWORD="${APPSTORE_PASSWORD:-}"

# 流水线动作：verify 只做登录与能力数据校验；submit 才会真正提交包。
MODE="${MODE:-verify}"

# 待投递的 Release 版本号（形如 v3.5.0）。留空时自动取 Gitee 最新 Release。
RELEASE_TAG="${RELEASE_TAG:-}"

# 存放 deb 产物的 Gitee 仓库，默认与本仓库的镜像仓库一致。
GITEE_REPO="${GITEE_REPO:-hanplus/flutter-linglong-store}"

# 投递工具来源。默认走 GitHub 主仓库；如果日后在 Gitee 建了私有镜像仓库，
# 只需覆盖该变量即可切换到国内地址，无需改动脚本逻辑。
APPSTORE_TOOL_REPO="${APPSTORE_TOOL_REPO:-https://github.com/guanzi008/appstore.git}"
APPSTORE_TOOL_REF="${APPSTORE_TOOL_REF:-main}"

# PyPI 镜像源（国内节点直连官方源不稳定，默认走阿里云）。
PIP_INDEX_URL="${PIP_INDEX_URL:-https://mirrors.aliyun.com/pypi/simple/}"
PIP_TRUSTED_HOST="${PIP_TRUSTED_HOST:-mirrors.aliyun.com}"

# 提交到商店时填写的更新说明。留空则由版本号自动生成。
APPSTORE_NOTE="${APPSTORE_NOTE:-}"

# 工作目录：容器内的一次性目录，每次运行都会重建，避免脏状态互相污染。
WORK_DIR="${WORK_DIR:-${HOME:-/root}/uos-store-submit}"

# 商店开放平台地址，仅用于连通性预检，便于失败时快速定位是网络还是业务问题。
STORE_ORIGIN="${STORE_ORIGIN:-https://appstore-dev.uniontech.com}"

# ---------- 基础工具函数 ----------

log() {
  printf '[uos-store] %s\n' "$*"
}

fail() {
  printf '[uos-store][错误] %s\n' "$*" >&2
  exit 1
}

# 轮询等待 apt/dpkg 锁释放。容器镜像里偶尔会残留 unattended-upgrade 之类进程，
# 直接 apt-get 会因锁冲突失败，这里做有限次重试而不是无限等待。
wait_for_dpkg_lock() {
  local waited=0
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ||
    fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
    if [[ "$waited" -ge 60 ]]; then
      fail "等待 dpkg 锁超时（60s），请检查容器内是否有残留的包管理进程"
    fi
    sleep 3
    waited=$((waited + 3))
  done
}

# 把 Debian 官方源换成国内镜像。基础镜像默认指向 deb.debian.org，从国内节点
# 访问速度不可控（实测同一个 apt 步骤能拖到数分钟）。这里是尽力而为：
# 源文件不存在或不存在旧域名时原样保留，不影响后续安装。
configure_debian_mirror() {
  local mirror="${DEBIAN_MIRROR:-mirrors.aliyun.com}"
  local file
  for file in /etc/apt/sources.list /etc/apt/sources.list.d/debian.sources; do
    [[ -f "$file" ]] || continue
    sed -i "s|deb.debian.org|${mirror}|g; s|security.debian.org|${mirror}|g" "$file"
  done
}

# 统一封装的 apt 安装入口：只在需要时更新索引，失败信息完整保留便于排查。
apt_install() {
  configure_debian_mirror
  wait_for_dpkg_lock
  DEBIAN_FRONTEND=noninteractive apt-get update -qq
  wait_for_dpkg_lock
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends "$@"
}

# ---------- 前置校验 ----------

[[ -n "$APPSTORE_USERNAME" ]] || fail "缺少 APPSTORE_USERNAME，请在 Gitee Go「通用变量」中配置商店账号"
[[ -n "$APPSTORE_PASSWORD" ]] || fail "缺少 APPSTORE_PASSWORD，请在 Gitee Go「通用变量」中配置商店密码"

case "$MODE" in
  verify | submit) ;;
  *) fail "MODE 只支持 verify 或 submit，当前为：$MODE" ;;
esac

log "模式：$MODE，仓库：$GITEE_REPO"

# ---------- 1. 预检商店连通性 ----------

# 用 Python 标准库做探测：python:3.12-slim 里的基础镜像并不自带 curl，
# 如果在这里用 curl，会因为 command not found 直接失败，掩盖真正的网络问题。
log "预检商店连通性：$STORE_ORIGIN"
python3 - "$STORE_ORIGIN" <<'PY' || fail "无法访问统信开发者平台，当前节点网络不可达"
import sys
import urllib.error
import urllib.request

url = sys.argv[1]
try:
    urllib.request.urlopen(url, timeout=30)
except urllib.error.HTTPError:
    # 能拿到 HTTP 状态码说明链路是通的，业务层的 4xx/5xx 不算网络问题。
    pass
except Exception as exc:  # noqa: BLE001
    print(f"[uos-store][错误] {url} 不可达：{type(exc).__name__} {exc}", file=sys.stderr)
    sys.exit(1)
PY

# ---------- 2. 解析 Release 版本 ----------

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

if [[ -z "$RELEASE_TAG" ]]; then
  # Gitee 的 releases/latest 接口对公开仓库免鉴权，直接取最新 Release 即可，
  # 避免在流水线里再引入一个 Gitee Token 变量。
  log "未指定 RELEASE_TAG，读取 Gitee 最新 Release"
  RELEASE_TAG="$(python3 - "$GITEE_REPO" <<'PY'
import json
import sys
import urllib.request

repo = sys.argv[1]
with urllib.request.urlopen(
    f"https://gitee.com/api/v5/repos/{repo}/releases/latest", timeout=30
) as response:
    print(json.load(response).get("tag_name", ""))
PY
  )" || fail "读取 Gitee 最新 Release 失败"
fi
[[ -n "$RELEASE_TAG" ]] || fail "未能解析出 Release 版本号"

# 资产文件名规则为 linglong-store_<版本>_<架构>.deb，版本号去掉前缀 v。
VERSION="${RELEASE_TAG#v}"
[[ "$VERSION" != "$RELEASE_TAG" ]] || log "提示：Release 版本号不含 v 前缀，按原样使用"

log "目标版本：$RELEASE_TAG（$VERSION），将提交 amd64 与 arm64 两个包"

# ---------- 3. 下载 deb 产物 ----------

# 只提交 amd64/arm64：商店当前受理这两个架构，loong64 走 OBS 单独渠道。
DEB_FILES=()
for arch in amd64 arm64; do
  deb_name="linglong-store_${VERSION}_${arch}.deb"
  deb_url="https://gitee.com/${GITEE_REPO}/releases/download/${RELEASE_TAG}/${deb_name}"
  log "下载 $deb_name"
  python3 - "$deb_url" "$deb_name" <<'PY' || fail "下载失败：$deb_url"
import sys
import urllib.request

url, target = sys.argv[1], sys.argv[2]
with urllib.request.urlopen(url, timeout=600) as response, open(target, "wb") as out:
    while chunk := response.read(1 << 20):
        out.write(chunk)
PY
  # 产物必须非空，避免把空文件交给商店接口造成难排查的远端报错。
  [[ -s "$deb_name" ]] || fail "下载得到空文件：$deb_name"
  DEB_FILES+=("$WORK_DIR/$deb_name")
done
ls -lh "$WORK_DIR"/*.deb

# ---------- 4. 准备容器运行环境 ----------

# 先补齐脚本自身依赖的基础命令：clone 工具需要 git。
# 只在缺失时安装，避免每次运行都重复 apt-get update 浪费时间与核分。
if ! command -v git >/dev/null 2>&1; then
  log "安装基础工具：git"
  apt_install ca-certificates git
fi

# 工具本身是纯 Python，但登录必须靠无头 Chromium（pyppeteer）。
# 优先安装发行版自带的 Chromium：一条命令带齐所有运行库，比让工具下载
# 快照再补依赖更可控；装不上时退回到由工具自行下载 Chromium 快照。
if ! command -v chromium >/dev/null 2>&1 &&
  ! command -v chromium-browser >/dev/null 2>&1 &&
  ! command -v google-chrome >/dev/null 2>&1; then
  log "安装发行版 Chromium"
  apt_install chromium ||
    log "警告：发行版 Chromium 安装失败，改由投递工具下载 Chromium 快照"
fi

# ---------- 5. 获取投递工具并安装依赖 ----------

log "拉取投递工具：$APPSTORE_TOOL_REPO（$APPSTORE_TOOL_REF）"
if ! git clone --depth 1 --branch "$APPSTORE_TOOL_REF" "$APPSTORE_TOOL_REPO" appstore-tool; then
  # GitHub 在国内偶发抖动，退化为 tarball 下载，失败才真正终止。
  log "git clone 失败，改用 tarball 下载"
  rm -rf appstore-tool appstore.tar.gz
  python3 - "${APPSTORE_TOOL_REPO%.git}/archive/refs/heads/${APPSTORE_TOOL_REF}.tar.gz" <<'PY' ||
    fail "投递工具获取失败，请检查 APPSTORE_TOOL_REPO 是否可达"
import sys
import urllib.request

url, target = sys.argv[1], "appstore.tar.gz"
with urllib.request.urlopen(url, timeout=300) as response, open(target, "wb") as out:
    while chunk := response.read(1 << 20):
        out.write(chunk)
PY
  mkdir -p appstore-tool
  tar -xzf appstore.tar.gz -C appstore-tool --strip-components=1
fi
[[ -f appstore-tool/appstore/upload_batch.py ]] ||
  fail "投递工具目录结构异常，缺少 appstore/upload_batch.py"

log "安装 Python 依赖（镜像：$PIP_INDEX_URL）"
python3 -m pip install -q --disable-pip-version-check \
  --index-url "$PIP_INDEX_URL" --trusted-host "$PIP_TRUSTED_HOST" \
  -r appstore-tool/appstore/requirements.txt

# 工具以 `python -m appstore.upload_batch` 方式运行，必须把工具根目录加入
# PYTHONPATH，否则找不到 appstore 包。
export PYTHONPATH="$WORK_DIR/appstore-tool${PYTHONPATH:+:$PYTHONPATH}"

# 强制把 Chromium 下载锁定在国内镜像。工具会按 TZ/locale 自动判断区域，
# 但容器默认是 UTC 且没有中文 locale，不显式指定会先去试被墙的谷歌源。
export TZ="${TZ:-Asia/Shanghai}"
export UTPUBLISHER_CHROMIUM_REGION="${UTPUBLISHER_CHROMIUM_REGION:-cn}"
export PYPPETEER_DOWNLOAD_HOST="${PYPPETEER_DOWNLOAD_HOST:-https://repo.huaweicloud.com}"

# ---------- 6. 执行投递 ----------

CAPABILITY_CACHE="$WORK_DIR/capabilities"
OUTPUT_DIR="$WORK_DIR/output"
mkdir -p "$OUTPUT_DIR"

log "同步商店能力数据（同时验证账号可用性）"
python3 -m appstore.upload_batch sync-capabilities \
  --cache-dir "$CAPABILITY_CACHE" \
  --username "$APPSTORE_USERNAME" \
  --password "$APPSTORE_PASSWORD"

if [[ "$MODE" == "verify" ]]; then
  log "MODE=verify：登录与能力校验通过，未向商店提交任何内容"
  log "如需真实提交，请以 MODE=submit 重新运行流水线"
  exit 0
fi

if [[ -z "$APPSTORE_NOTE" ]]; then
  APPSTORE_NOTE="玲珑应用商店社区版 ${VERSION} 更新"
fi

log "提交到商店：$APPSTORE_NOTE"
python3 -m appstore.upload_batch upload-packages "${DEB_FILES[@]}" \
  --output-dir "$OUTPUT_DIR" \
  --capabilities-cache "$CAPABILITY_CACHE" \
  --username "$APPSTORE_USERNAME" \
  --password "$APPSTORE_PASSWORD" \
  --mode api \
  --release-key latest-release \
  --note "$APPSTORE_NOTE" \
  --headless

log "投递完成，报告目录：$OUTPUT_DIR"
ls -la "$OUTPUT_DIR" || true
