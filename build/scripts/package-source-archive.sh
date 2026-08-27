#!/usr/bin/env bash
# 制作用于 Fedora Copr 从源码构建的自包含源码归档（stable 渠道专用）。
#
# 产物（输出到 build/out/linux/<version>/source/）：
#   linglong-store-<version>.tar.gz      —— 源码归档：git HEAD 树 + 发版版本
#                                           文件覆盖 + packaging-dist/ 预渲染
#                                           元数据（desktop/图标/AppStream/
#                                           内嵌 Copr spec），顶层目录
#                                           linglong-store-<version>/；
#   linglong-store-<version>.copr.spec   —— 渲染好版本号与 Source0 的 Copr
#                                           spec，随 release 附件发布。
#
# 设计要点：
#   - 归档不含 .git：flutter 工具在无 .git 项目目录下会回退读取
#     pubspec.yaml 版本号，构建不受影响；
#   - 元数据在发版时预渲染进归档，Copr 构建端零渲染依赖（无 dart 脚本、
#     无 rsvg），见 docs/36（生成源码入库策略）与 docs/44（Copr 设计文档）；
#   - tar 归一化（--sort=name/--mtime/@<commit-time>/--owner=0 --numeric-owner
#     + gzip -n）：同一提交产出字节稳定，便于哈希核对。PNG 图标依赖渲染
#     工具版本，跨机器可能不同，完整性以 release 的 hashes.sha256 为准。
#
# 前置条件：工作区已运行 update-version-files.sh 应用目标版本（发版流水线
# 在 prepare-release 阶段完成；本地手动执行前需自行保证）。
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

release_version=""

usage() {
  cat >&2 <<'EOF'
Usage: package-source-archive.sh --version <version>
EOF
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      release_version="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$release_version" ]]; then
  usage
fi

# RPM Version 不允许连字符；Copr 源码构建仅接受纯 semver 的 stable 版本，
# nightly（含 -nightly.<date>+<sha>）在此直接拒绝，防止产出不可构建的 spec。
if [[ "$release_version" == *-* ]]; then
  echo "Copr source archive only supports stable versions without hyphens: $release_version" >&2
  exit 64
fi

# 发版版本为纯三段 semver（resolve-release-version.sh 保证），pubspec 会由
# update-version-files.dart 追加 "+1" 构建号，因此只比较 "+" 前的主版本。
pubspec_version="$(awk '/^version:/ {print $2; exit}' "$ROOT_DIR/pubspec.yaml")"
pubspec_base_version="${pubspec_version%%+*}"
if [[ "$pubspec_base_version" != "$release_version" ]]; then
  echo "pubspec.yaml version ($pubspec_version, base $pubspec_base_version) != requested version ($release_version)." >&2
  echo "Run build/scripts/update-version-files.sh first (release pipeline does this in prepare-release)." >&2
  exit 64
fi

if ! command -v rsvg-convert >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
  echo "Neither rsvg-convert nor ImageMagick convert is available for icon rendering." >&2
  exit 64
fi

commit_time="$(git -C "$ROOT_DIR" log -1 --format=%ct HEAD)"
output_dir="$ROOT_DIR/build/out/linux/$release_version/source"
stage_root="$ROOT_DIR/build/tmp/package-source-archive/$release_version"
rendered_dir="$stage_root/rendered"
content_dir="$stage_root/linglong-store-$release_version"
dist_dir="$content_dir/packaging-dist"
tarball_path="$output_dir/linglong-store-$release_version.tar.gz"
spec_asset_path="$output_dir/linglong-store-$release_version.copr.spec"

# 清理必须在渲染之前：渲染产物同样落在 stage_root 下，先删后建防止
# 上一次执行的残留混入归档，也避免把本轮渲染结果误删。
rm -rf "$stage_root"
mkdir -p "$content_dir" "$dist_dir/compat" "$dist_dir/metainfo" "$dist_dir/icons"

# 渲染桌面入口、AppStream 元数据与 Copr spec；arch 对这些产物无影响，
# 固定传 amd64 仅为满足渲染器参数约束。
bash "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
  --inner \
  --version "$release_version" \
  --arch amd64 \
  --output-dir "$rendered_dir" \
  --channel stable

# 以 git HEAD 树为基础（文件 mtime 继承提交时间），随后覆盖发版版本文件，
# 保证归档内容与最终发版 tag 树一致（流水线中版本文件尚未提交）。
git -C "$ROOT_DIR" archive HEAD | tar -x -C "$content_dir"

cp "$ROOT_DIR/pubspec.yaml" "$content_dir/pubspec.yaml"
cp "$ROOT_DIR/linux/pubspec.yaml" "$content_dir/linux/pubspec.yaml"
cp "$ROOT_DIR/lib/core/config/app_config.dart" "$content_dir/lib/core/config/app_config.dart"

# packaging-dist/：Copr spec 的 %install 直接消费这些预渲染产物。
desktop_filename="$(basename "$(find "$rendered_dir" -maxdepth 1 -name '*.desktop' -print -quit)")"
if [[ -z "$desktop_filename" ]]; then
  echo "No rendered desktop file found under $rendered_dir" >&2
  exit 1
fi
cp "$rendered_dir/$desktop_filename" "$dist_dir/$desktop_filename"
cp -a "$rendered_dir/compat/." "$dist_dir/compat/"
cp "$rendered_dir/appimage/linglong-store.appdata.xml" "$dist_dir/metainfo/linglong-store.appdata.xml"
if [[ ! -f "$rendered_dir/copr/linglong-store.spec" ]]; then
  echo "Rendered Copr spec is missing; stable-channel rendering failed." >&2
  exit 1
fi
cp "$rendered_dir/copr/linglong-store.spec" "$dist_dir/linglong-store.spec"

if command -v rsvg-convert >/dev/null 2>&1; then
  rsvg-convert -w 256 -h 256 "$ROOT_DIR/assets/icons/logo.svg" -o "$dist_dir/icons/linglong-store-256.png"
else
  convert -background none -resize 256x256 "$ROOT_DIR/assets/icons/logo.svg" "$dist_dir/icons/linglong-store-256.png"
fi

# 防御性校验：docs/36 约定生成源码全部入库，Copr 构建不跑 build_runner。
# 此处抽查关键输入，避免策略被破坏后产出的归档在 Copr 端必然构建失败。
if [[ ! -f "$content_dir/pubspec.lock" ]]; then
  echo "pubspec.lock is missing from the archive tree; Copr build cannot resolve locked deps." >&2
  exit 1
fi
generated_count="$(find "$content_dir/lib" -name '*.g.dart' -o -name '*.freezed.dart' | wc -l)"
if [[ "$generated_count" -lt 10 ]]; then
  echo "Expected checked-in generated sources under lib/, found only $generated_count files." >&2
  exit 1
fi

mkdir -p "$output_dir"
# 先移除旧产物，避免失败重跑时把上一轮 tarball 误判为本轮结果。
rm -f "$tarball_path" "$spec_asset_path"

# 归一化打包：排序 + 固定 mtime（提交时间）+ 固定属主 + gzip 无时间戳。
(
  cd "$stage_root"
  tar \
    --sort=name \
    --mtime="@$commit_time" \
    --owner=0 --group=0 --numeric-owner \
    -cf - "linglong-store-$release_version" \
    | gzip -n > "$tarball_path"
)

cp "$rendered_dir/copr/linglong-store.spec" "$spec_asset_path"

# 冒烟检查：归档必须包含 Copr spec 引用的全部预渲染产物。
# 用 awk 做整行字符串精确比较而非 grep 正则，规避 BRE 元字符
# （版本号/桌面文件名含 + 和 .）带来的匹配歧义。
archive_entries="$(tar -tzf "$tarball_path")"
for required_entry in \
  "packaging-dist/$desktop_filename" \
  "packaging-dist/compat" \
  "packaging-dist/metainfo/linglong-store.appdata.xml" \
  "packaging-dist/icons/linglong-store-256.png" \
  "packaging-dist/linglong-store.spec" \
  "pubspec.lock"; do
  if ! awk \
    -v entry="linglong-store-$release_version/$required_entry" \
    'index($0, entry) == 1 { found = 1; exit } END { exit !found }' \
    <<< "$archive_entries"; then
    echo "Source archive is missing required entry: $required_entry" >&2
    exit 1
  fi
done

echo "Source archive: $tarball_path"
sha256sum "$tarball_path"
echo "Copr spec:      $spec_asset_path"
