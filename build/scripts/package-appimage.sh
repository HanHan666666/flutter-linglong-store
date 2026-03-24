#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ "${1:-}" != "--inner" && -z "${LINGLONG_RELEASE_CONTAINER:-}" ]]; then
  exec "$ROOT_DIR/build/scripts/run-in-release-container.sh" "$ROOT_DIR/build/scripts/package-appimage.sh" "$@"
fi

if [[ "${1:-}" == "--inner" ]]; then
  shift
fi

release_version=""
target_arch=""
channel="stable"

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
    --channel)
      channel="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--inner] --version <version> --arch <amd64|arm64> [--channel stable|nightly]" >&2
      exit 64
      ;;
  esac
done

if [[ -z "$release_version" || -z "$target_arch" ]]; then
  echo "Both --version and --arch are required." >&2
  exit 64
fi

case "$target_arch" in
  amd64|x86_64)
    target_arch="amd64"
    appimage_arch="x86_64"
    ;;
  arm64|aarch64)
    target_arch="arm64"
    appimage_arch="aarch64"
    ;;
  *)
    echo "Unsupported architecture: $target_arch" >&2
    exit 64
    ;;
esac

case "$channel" in
  stable|nightly)
    ;;
  *)
    echo "Unsupported channel: $channel" >&2
    exit 64
    ;;
esac

output_dir="$ROOT_DIR/build/out/linux/$release_version/$target_arch"
bundle_dir="$output_dir/bundle/linglong-store"
stage_root="$ROOT_DIR/build/tmp/package-appimage/$release_version-$target_arch"
metadata_dir="$stage_root/rendered"
appdir="$stage_root/AppDir"
artifact_path="$output_dir/linglong-store-${release_version}-${target_arch}.AppImage"

"$ROOT_DIR/build/scripts/build-linux-bundle.sh" --inner --version "$release_version" --arch "$target_arch"

rm -rf "$stage_root"
mkdir -p \
  "$appdir/opt/linglong-store" \
  "$appdir/usr/bin" \
  "$appdir/usr/share/applications" \
  "$appdir/usr/share/icons/hicolor/256x256/apps" \
  "$appdir/usr/share/metainfo"

cp -a "$bundle_dir/." "$appdir/opt/linglong-store/"

cat > "$appdir/usr/bin/linglong-store" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPDIR_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$APPDIR_ROOT/opt/linglong-store/linglong_store" "$@"
EOF
chmod +x "$appdir/usr/bin/linglong-store"

"$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
  --inner \
  --version "$release_version" \
  --arch "$target_arch" \
  --output-dir "$metadata_dir" \
  --channel "$channel"

mapfile -t rendered_desktop_files < <(find "$metadata_dir" -maxdepth 1 -type f -name '*.desktop' | sort)
if [[ "${#rendered_desktop_files[@]}" -ne 1 ]]; then
  echo "Expected exactly one rendered desktop file in $metadata_dir, found ${#rendered_desktop_files[@]}" >&2
  exit 1
fi

desktop_filename="$(basename "${rendered_desktop_files[0]}")"

rsvg-convert -w 256 -h 256 "$ROOT_DIR/assets/icons/logo.svg" -o "$appdir/linglong-store.png"
cp "$appdir/linglong-store.png" "$appdir/usr/share/icons/hicolor/256x256/apps/linglong-store.png"
cp "$metadata_dir/$desktop_filename" "$appdir/$desktop_filename"
cp "$metadata_dir/$desktop_filename" "$appdir/usr/share/applications/$desktop_filename"
cp "$metadata_dir/appimage/AppRun" "$appdir/AppRun"
cp "$metadata_dir/appimage/linglong-store.appdata.xml" "$appdir/usr/share/metainfo/linglong-store.appdata.xml"
chmod +x "$appdir/AppRun"

linuxdeploy \
  --appdir "$appdir" \
  --desktop-file "$appdir/$desktop_filename" \
  --icon-file "$appdir/linglong-store.png"

rm -f "$artifact_path"
ARCH="$appimage_arch" appimagetool "$appdir" "$artifact_path"
