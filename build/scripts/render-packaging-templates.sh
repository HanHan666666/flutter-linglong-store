#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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
      echo "Usage: $0 [--inner] --version <version> --arch <amd64|arm64> --output-dir <dir> [--installed-size-kb <kb>] [--release <n>] [--payload-dir <dir>] [--channel stable|nightly]" >&2
      exit 64
      ;;
  esac
done

if [[ -z "$release_version" || -z "$target_arch" || -z "$output_dir" ]]; then
  echo "--version, --arch and --output-dir are required." >&2
  exit 64
fi

case "$target_arch" in
  amd64|x86_64)
    deb_arch="amd64"
    rpm_arch="x86_64"
    ;;
  arm64|aarch64)
    deb_arch="arm64"
    rpm_arch="aarch64"
    ;;
  *)
    echo "Unsupported architecture: $target_arch" >&2
    exit 64
    ;;
esac

package_name="linglong-store"
display_name="玲珑应用商店社区版"
summary_text="Linglong Store Community Edition"
description_text="Desktop store for browsing and installing Linglong applications."
desktop_filename="linglong-store.desktop"
launchable_desktop_id="$desktop_filename"
executable_name="linglong-store"
icon_name="linglong-store"
wm_class="org.linglong-store.LinyapsManager"
app_id="org.linglongstore.linglong_store"
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
    display_name="玲珑应用商店社区版 Nightly"
    summary_text="Linglong Store Community Edition Nightly"
    desktop_filename="linglong-store-nightly.desktop"
    launchable_desktop_id="$desktop_filename"
    aur_pkgname="linglong-store-nightly-bin"
    aur_arch_values="'x86_64'"
    aur_conflicts_values="'linglong-store-bin'"
    aur_changelog_filename="linglong-store-nightly-bin.changelog"
    aur_source_aarch64_block=""
    aur_sha256sums_aarch64_block=""

    if [[ "$has_any_aur_inputs" == "true" ]]; then
      require_aur_prerequisites \
        "Nightly" \
        sha256_amd64 \
        sha256_sig_amd64 \
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

render_file() {
  local input_path="$1"
  local output_path="$2"
  local content

  mkdir -p "$(dirname "$output_path")"
  content="$(<"$input_path")"
  content="${content//@PACKAGE_NAME@/$package_name}"
  content="${content//@DISPLAY_NAME@/$display_name}"
  content="${content//@SUMMARY@/$summary_text}"
  content="${content//@DESCRIPTION@/$description_text}"
  content="${content//@EXECUTABLE_NAME@/$executable_name}"
  content="${content//@ICON_NAME@/$icon_name}"
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
