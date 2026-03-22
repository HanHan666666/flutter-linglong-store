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
    *)
      echo "Usage: $0 [--inner] --version <version> --arch <amd64|arm64> --output-dir <dir> [--installed-size-kb <kb>] [--release <n>] [--payload-dir <dir>]" >&2
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
executable_name="linglong-store"
icon_name="linglong-store"
wm_class="org.linglong-store.LinyapsManager"
app_id="org.linglongstore.linglong_store"
project_url="https://github.com/HanHan666666/flutter-linglong-store"
maintainer="Linglong Store Community <community@linglong.dev>"

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
mkdir -p "$output_dir/deb" "$output_dir/rpm" "$output_dir/appimage"

render_file \
  "$ROOT_DIR/build/packaging/linux/linglong-store.desktop.in" \
  "$output_dir/linglong-store.desktop"

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
