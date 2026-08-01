#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT_DIR/build/scripts/linux-arch-utils.sh"
. "$ROOT_DIR/build/scripts/lib/application-identity.sh"

load_application_identity "$ROOT_DIR/config/application_identity.conf"

if [[ "${1:-}" != "--inner" && -z "${LINGLONG_RELEASE_CONTAINER:-}" ]]; then
  exec "$ROOT_DIR/build/scripts/run-in-release-container.sh" "$ROOT_DIR/build/scripts/render-packaging-templates.sh" "$@"
fi

if [[ "${1:-}" == "--inner" ]]; then
  shift
fi

release_version=""
target_arch=""
output_dir=""
installed_size_kb="0"
release_number="1"
payload_dir=""
channel="stable"
sha256_amd64=""
sha256_arm64=""
sha256_sig_amd64=""
sha256_sig_arm64=""
gpg_key_id=""

# Read from environment if available
sha256_amd64="${SHA256_AMD64:-$sha256_amd64}"
sha256_arm64="${SHA256_ARM64:-$sha256_arm64}"
sha256_sig_amd64="${SHA256_SIG_AMD64:-$sha256_sig_amd64}"
sha256_sig_arm64="${SHA256_SIG_ARM64:-$sha256_sig_arm64}"
gpg_key_id="${GPG_KEY_ID:-$gpg_key_id}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      release_version="$2"
      shift 2
      ;;
    --arch)
      target_arch="$2"
      shift 2
      ;;
    --output-dir)
      output_dir="$2"
      shift 2
      ;;
    --installed-size-kb)
      installed_size_kb="$2"
      shift 2
      ;;
    --release)
      release_number="$2"
      shift 2
      ;;
    --payload-dir)
      payload_dir="$2"
      shift 2
      ;;
    --channel)
      channel="$2"
      shift 2
      ;;
    --sha256-amd64)
      sha256_amd64="$2"
      shift 2
      ;;
    --sha256-arm64)
      sha256_arm64="$2"
      shift 2
      ;;
    --sha256-sig-amd64)
      sha256_sig_amd64="$2"
      shift 2
      ;;
    --sha256-sig-arm64)
      sha256_sig_arm64="$2"
      shift 2
      ;;
    --gpg-key-id)
      gpg_key_id="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--inner] --version <version> --arch <amd64|arm64|loong64|loongarch64> --output-dir <dir> [--installed-size-kb <kb>] [--release <n>] [--payload-dir <dir>] [--channel stable|nightly]" >&2
      exit 64
      ;;
  esac
done

if [[ -z "$release_version" || -z "$target_arch" || -z "$output_dir" ]]; then
  echo "--version, --arch and --output-dir are required." >&2
  exit 64
fi

normalize_linux_release_arch "$target_arch"

package_name="linglong-store"
# DEB/RPM 控制字段不支持在同一文件嵌入全部 locale，保持英文包索引元数据；
# XDG/AppStream 的自然语言字段由 ARB 生成器单独渲染，禁止在 Shell 声明翻译。
package_summary_text="Linyaps Store Community Edition"
package_description_text="Desktop store for browsing, installing, and managing Linyaps applications."
app_id="$APPLICATION_ID"
desktop_filename="$CANONICAL_DESKTOP_ID"
launchable_desktop_id="$desktop_filename"
executable_name="linglong-store"
icon_name="linglong-store"
wm_class="$WM_CLASS"
project_url="https://github.com/HanHan666666/flutter-linglong-store"
maintainer="Linglong Store Community <community@linglong.dev>"
maintainer_name="HanHan666666"
maintainer_email="tar.zip@outlook.com"
release_url_base="https://github.com/HanHan666666/flutter-linglong-store/releases/download"
aur_pkgname="linglong-store-bin"
aur_pkgver="$release_version"
aur_arch_values="'x86_64' 'aarch64'"
aur_provides_values="'linglong-store'"
aur_conflicts_values="'linglong-store'"
aur_changelog_filename="linglong-store-bin.changelog"
aur_source_version="$release_version"
aur_source_tag_root="v${release_version}"
aur_source_aarch64_block=$'source_aarch64=(\n  "linglong-store-@AUR_SOURCE_VERSION@-linux-arm64.tar.gz::@RELEASE_URL_BASE@/@AUR_SOURCE_TAG_ROOT@/linglong-store-@AUR_SOURCE_VERSION@-linux-arm64.tar.gz"\n  "linglong-store-@AUR_SOURCE_VERSION@-linux-arm64.tar.gz.asc::@RELEASE_URL_BASE@/@AUR_SOURCE_TAG_ROOT@/linglong-store-@AUR_SOURCE_VERSION@-linux-arm64.tar.gz.asc"\n)'
aur_sha256sums_aarch64_block=$'sha256sums_aarch64=(\n  \'@SHA256_ARM64@\'\n  \'@SHA256_SIG_ARM64@\'\n)'
should_render_aur="false"

has_any_aur_inputs="false"
if [[ -n "$sha256_amd64" || -n "$sha256_arm64" || -n "$sha256_sig_amd64" || -n "$sha256_sig_arm64" || -n "$gpg_key_id" ]]; then
  has_any_aur_inputs="true"
fi

require_aur_prerequisites() {
  local mode="$1"
  shift

  local missing=()
  local name
  for name in "$@"; do
    if [[ -z "${!name}" ]]; then
      missing+=("$name")
    fi
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    echo "$mode AUR rendering requires: ${missing[*]}" >&2
    exit 64
  fi
}

case "$channel" in
  stable)
    if [[ "$has_any_aur_inputs" == "true" ]]; then
      require_aur_prerequisites \
        "Stable" \
        sha256_amd64 \
        sha256_arm64 \
        sha256_sig_amd64 \
        sha256_sig_arm64 \
        gpg_key_id
      should_render_aur="true"
    fi
    ;;
  nightly)
    # Nightly only changes the visible metadata; layout and executable stay stable.
    package_summary_text="Linyaps Store Community Edition Nightly"
    aur_pkgname="linglong-store-nightly-bin"
    # Nightly reuses the stable install paths, so both the concrete stable
    # package name and the shared virtual package must be treated as conflicts.
    aur_conflicts_values="'linglong-store' 'linglong-store-bin'"
    aur_changelog_filename="linglong-store-nightly-bin.changelog"

    if [[ "$has_any_aur_inputs" == "true" ]]; then
      require_aur_prerequisites \
        "Nightly" \
        sha256_amd64 \
        sha256_arm64 \
        sha256_sig_amd64 \
        sha256_sig_arm64 \
        gpg_key_id
      should_render_aur="true"
    fi

    if [[ "$release_version" =~ -nightly\.([0-9]{8})\+[0-9A-Fa-f]+$ ]]; then
      # AUR pkgver cannot preserve the nightly prerelease separators verbatim.
      aur_pkgver="$(bash "$ROOT_DIR/build/scripts/normalize-nightly-aur-version.sh" "$release_version")"
      aur_source_tag_root="nightly-${BASH_REMATCH[1]}"
    elif [[ "$should_render_aur" == "true" ]]; then
      echo "Nightly AUR rendering requires a version like <semver>-nightly.<YYYYMMDD>+<sha>, got: $release_version" >&2
      exit 64
    fi
    ;;
  *)
    echo "Unsupported channel: $channel" >&2
    exit 64
    ;;
esac

# 兼容入口由身份配置按渠道提供；渲染器和下游打包均按列表处理。
mapfile -t compat_desktop_filenames < <(
  application_identity_compat_desktop_ids "$channel"
)
if [[ "${#compat_desktop_filenames[@]}" -eq 0 ]]; then
  echo "No compatibility desktop IDs configured for channel: $channel" >&2
  exit 78
fi

compat_desktop_file_entries=""
for compat_desktop_filename in "${compat_desktop_filenames[@]}"; do
  compat_desktop_file_entries+="/usr/share/applications/${compat_desktop_filename}"$'\n'
done
compat_desktop_file_entries="${compat_desktop_file_entries%$'\n'}"

render_file() {
  local input_path="$1"
  local output_path="$2"
  local content

  mkdir -p "$(dirname "$output_path")"
  content="$(<"$input_path")"
  content="${content//@PACKAGE_NAME@/$package_name}"
  content="${content//@SUMMARY@/$package_summary_text}"
  content="${content//@DESCRIPTION@/$package_description_text}"
  content="${content//@EXECUTABLE_NAME@/$executable_name}"
  content="${content//@ICON_NAME@/$icon_name}"
  content="${content//@DESKTOP_FILENAME@/$desktop_filename}"
  content="${content//@COMPAT_DESKTOP_FILE_ENTRIES@/$compat_desktop_file_entries}"
  content="${content//@WM_CLASS@/$wm_class}"
  content="${content//@LAUNCHABLE_DESKTOP_ID@/$launchable_desktop_id}"
  content="${content//@VERSION@/$release_version}"
  content="${content//@DEB_ARCH@/$deb_arch}"
  content="${content//@RPM_ARCH@/$rpm_arch}"
  content="${content//@INSTALLED_SIZE_KB@/$installed_size_kb}"
  content="${content//@RELEASE@/$release_number}"
  content="${content//@PAYLOAD_DIR@/$payload_dir}"
  content="${content//@APP_ID@/$app_id}"
  content="${content//@PROJECT_URL@/$project_url}"
  content="${content//@MAINTAINER@/$maintainer}"
  printf '%s\n' "$content" > "$output_path"
}

rm -rf "$output_dir"
mkdir -p "$output_dir/deb" "$output_dir/rpm" "$output_dir/appimage" "$output_dir/aur"

render_file \
  "$ROOT_DIR/build/packaging/linux/linglong-store.desktop.in" \
  "$output_dir/$desktop_filename"

for compat_desktop_filename in "${compat_desktop_filenames[@]}"; do
  render_file \
    "$ROOT_DIR/build/packaging/linux/linglong-store-compat.desktop.in" \
    "$output_dir/compat/$compat_desktop_filename"
done

render_file \
  "$ROOT_DIR/build/packaging/linux/deb/control.in" \
  "$output_dir/deb/control"

render_file \
  "$ROOT_DIR/build/packaging/linux/rpm/linglong-store.spec.in" \
  "$output_dir/rpm/linglong-store.spec"

cp "$ROOT_DIR/build/packaging/linux/appimage/AppRun" "$output_dir/appimage/AppRun"
render_file \
  "$ROOT_DIR/build/packaging/linux/appimage/linglong-store.appdata.xml" \
  "$output_dir/appimage/linglong-store.appdata.xml"

# 所有自然语言字段由同一 ARB 目录生成；Shell 只传渠道和待渲染文件位置。
LINGLONG_RELEASE_TOOL_ROOT="$ROOT_DIR" \
  bash "$ROOT_DIR/build/scripts/run-release-dart-tool.sh" \
  "$ROOT_DIR/build/scripts/render_localized_linux_metadata.dart" \
  --channel "$channel" \
  --desktop-file "$output_dir/$desktop_filename" \
  --compat-directory "$output_dir/compat" \
  --appstream-file "$output_dir/appimage/linglong-store.appdata.xml"

chmod +x "$output_dir/appimage/AppRun"

# AUR templates (only if sha256 provided)
render_aur_template() {
  local input_path="$1"
  local output_path="$2"
  local sha_amd64="$3"
  local sha_arm64="$4"
  local sha_license="$5"
  local sha_desktop="$6"
  local sha_metainfo="$7"
  local sha_icon="$8"
  local sha_sig_amd64="${9:-}"
  local sha_sig_arm64="${10:-}"
  local key_id="${11:-}"

  mkdir -p "$(dirname "$output_path")"
  local content
  content="$(<"$input_path")"
  content="${content//@PACKAGE_NAME@/$package_name}"
  content="${content//@DESKTOP_FILENAME@/$desktop_filename}"
  content="${content//@AUR_COMPAT_DESKTOP_SOURCES@/$aur_compat_desktop_sources}"
  content="${content//@AUR_COMPAT_DESKTOP_SHA256SUMS@/$aur_compat_desktop_sha256sums}"
  content="${content//@AUR_COMPAT_DESKTOP_INSTALL_COMMANDS@/$aur_compat_desktop_install_commands}"
  content="${content//@AUR_COMPAT_DESKTOP_VALIDATE_COMMANDS@/$aur_compat_desktop_validate_commands}"
  # Expand optional architecture blocks before substituting the values they
  # reference, otherwise nested placeholders leak into the rendered PKGBUILD.
  content="${content//@AUR_SOURCE_AARCH64_BLOCK@/$aur_source_aarch64_block}"
  content="${content//@AUR_SHA256SUMS_AARCH64_BLOCK@/$aur_sha256sums_aarch64_block}"
  content="${content//@VERSION@/$release_version}"
  content="${content//@MAINTAINER_NAME@/$maintainer_name}"
  content="${content//@MAINTAINER_EMAIL@/$maintainer_email}"
  content="${content//@PROJECT_URL@/$project_url}"
  content="${content//@RELEASE_URL_BASE@/$release_url_base}"
  content="${content//@SHA256_LICENSE@/$sha_license}"
  content="${content//@SHA256_DESKTOP@/$sha_desktop}"
  content="${content//@SHA256_METAINFO@/$sha_metainfo}"
  content="${content//@SHA256_ICON@/$sha_icon}"
  content="${content//@SHA256_AMD64@/$sha_amd64}"
  content="${content//@SHA256_ARM64@/$sha_arm64}"
  content="${content//@SHA256_SIG_AMD64@/$sha_sig_amd64}"
  content="${content//@SHA256_SIG_ARM64@/$sha_sig_arm64}"
  content="${content//@GPG_KEY_ID@/$key_id}"
  content="${content//@AUR_PKGNAME@/$aur_pkgname}"
  content="${content//@AUR_PKGVER@/$aur_pkgver}"
  content="${content//@AUR_ARCH_VALUES@/$aur_arch_values}"
  content="${content//@AUR_PROVIDES_VALUES@/$aur_provides_values}"
  content="${content//@AUR_CONFLICTS_VALUES@/$aur_conflicts_values}"
  content="${content//@AUR_CHANGELOG_FILENAME@/$aur_changelog_filename}"
  content="${content//@AUR_SOURCE_VERSION@/$aur_source_version}"
  content="${content//@AUR_SOURCE_TAG_ROOT@/$aur_source_tag_root}"
  printf '%s\n' "$content" > "$output_path"
}

# Render AUR templates only when the caller provides the checksum coverage
# required for the selected channel.
if [[ "$should_render_aur" == "true" ]]; then
  # Keep AUR metadata files in the package repo so icon/metainfo/license do not
  # rely on optional extras bundled into the binary release archive.
  cp "$ROOT_DIR/LICENSE" "$output_dir/aur/LICENSE"
  cp "$output_dir/$desktop_filename" "$output_dir/aur/$desktop_filename"
  cp "$output_dir/appimage/linglong-store.appdata.xml" "$output_dir/aur/linglong-store.metainfo.xml"
  cp "$ROOT_DIR/assets/icons/logo.svg" "$output_dir/aur/linglong-store.svg"

  sha256_license="$(sha256sum "$output_dir/aur/LICENSE" | awk '{print $1}')"
  sha256_desktop="$(sha256sum "$output_dir/aur/$desktop_filename" | awk '{print $1}')"
  sha256_metainfo="$(sha256sum "$output_dir/aur/linglong-store.metainfo.xml" | awk '{print $1}')"
  sha256_icon="$(sha256sum "$output_dir/aur/linglong-store.svg" | awk '{print $1}')"

  # AUR 的 source/checksum/install/validate 块必须由同一别名列表生成，
  # 否则增加历史 desktop ID 时极易只更新其中一处。
  aur_compat_desktop_sources=""
  aur_compat_desktop_sha256sums=""
  aur_compat_desktop_install_commands=""
  aur_compat_desktop_validate_commands=""
  for compat_desktop_filename in "${compat_desktop_filenames[@]}"; do
    cp "$output_dir/compat/$compat_desktop_filename" \
      "$output_dir/aur/$compat_desktop_filename"
    sha256_compat_desktop="$(
      sha256sum "$output_dir/aur/$compat_desktop_filename" | awk '{print $1}'
    )"
    aur_compat_desktop_sources+="  '${compat_desktop_filename}'"$'\n'
    aur_compat_desktop_sha256sums+="  '${sha256_compat_desktop}'"$'\n'
    aur_compat_desktop_install_commands+="  install -Dm644 \"\${srcdir}/${compat_desktop_filename}\" \"\${pkgdir}/usr/share/applications/${compat_desktop_filename}\""$'\n'
    aur_compat_desktop_validate_commands+="    desktop-file-validate \"\${pkgdir}/usr/share/applications/${compat_desktop_filename}\" || true"$'\n'
  done
  aur_compat_desktop_sources="${aur_compat_desktop_sources%$'\n'}"
  aur_compat_desktop_sha256sums="${aur_compat_desktop_sha256sums%$'\n'}"
  aur_compat_desktop_install_commands="${aur_compat_desktop_install_commands%$'\n'}"
  aur_compat_desktop_validate_commands="${aur_compat_desktop_validate_commands%$'\n'}"

  render_aur_template \
    "$ROOT_DIR/build/packaging/linux/aur/PKGBUILD.in" \
    "$output_dir/aur/PKGBUILD" \
    "$sha256_amd64" \
    "$sha256_arm64" \
    "$sha256_license" \
    "$sha256_desktop" \
    "$sha256_metainfo" \
    "$sha256_icon" \
    "$sha256_sig_amd64" \
    "$sha256_sig_arm64" \
    "$gpg_key_id"

  render_aur_template \
    "$ROOT_DIR/build/packaging/linux/aur/linglong-store-bin.changelog.in" \
    "$output_dir/aur/$aur_changelog_filename" \
    "$sha256_amd64" \
    "$sha256_arm64" \
    "$sha256_license" \
    "$sha256_desktop" \
    "$sha256_metainfo" \
    "$sha256_icon" \
    "$sha256_sig_amd64" \
    "$sha256_sig_arm64" \
    "$gpg_key_id"
fi
