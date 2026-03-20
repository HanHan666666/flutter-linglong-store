#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ "${1:-}" != "--inner" && -z "${LINGLONG_RELEASE_CONTAINER:-}" ]]; then
  exec "$ROOT_DIR/build/scripts/run-in-release-container.sh" "$ROOT_DIR/build/scripts/package-deb.sh" "$@"
fi

if [[ "${1:-}" == "--inner" ]]; then
  shift
fi

release_version=""
target_arch=""

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
    *)
      echo "Usage: $0 [--inner] --version <version> --arch <amd64|arm64>" >&2
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
    ;;
  arm64|aarch64)
    target_arch="arm64"
    ;;
  *)
    echo "Unsupported architecture: $target_arch" >&2
    exit 64
    ;;
esac

output_dir="$ROOT_DIR/build/out/linux/$release_version/$target_arch"
bundle_dir="$output_dir/bundle/linglong-store"
stage_root="$ROOT_DIR/build/tmp/package-deb/$release_version-$target_arch"
payload_dir="$stage_root/payload"
metadata_dir="$stage_root/rendered"
artifact_path="$output_dir/linglong-store_${release_version}_${target_arch}.deb"
icon_path="$payload_dir/usr/share/icons/hicolor/256x256/apps/linglong-store.png"

"$ROOT_DIR/build/scripts/build-linux-bundle.sh" --inner --version "$release_version" --arch "$target_arch"

rm -rf "$stage_root"
mkdir -p \
  "$payload_dir/DEBIAN" \
  "$payload_dir/opt/linglong-store" \
  "$payload_dir/usr/bin" \
  "$payload_dir/usr/share/applications" \
  "$payload_dir/usr/share/icons/hicolor/256x256/apps" \
  "$payload_dir/usr/share/metainfo"

cp -a "$bundle_dir/." "$payload_dir/opt/linglong-store/"

# Keep the real Flutter binary in /opt so its adjacent data/lib layout stays intact.
cat > "$payload_dir/usr/bin/linglong-store" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec /opt/linglong-store/linglong_store "$@"
EOF
chmod +x "$payload_dir/usr/bin/linglong-store"

rsvg-convert -w 256 -h 256 "$ROOT_DIR/assets/icons/logo.svg" -o "$icon_path"

installed_size_kb="$(du -sk "$payload_dir" | cut -f1)"
"$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
  --inner \
  --version "$release_version" \
  --arch "$target_arch" \
  --output-dir "$metadata_dir" \
  --installed-size-kb "$installed_size_kb"

cp "$metadata_dir/deb/control" "$payload_dir/DEBIAN/control"
cp "$metadata_dir/linglong-store.desktop" "$payload_dir/usr/share/applications/linglong-store.desktop"
cp "$metadata_dir/appimage/linglong-store.appdata.xml" "$payload_dir/usr/share/metainfo/linglong-store.appdata.xml"

rm -f "$artifact_path"
fakeroot dpkg-deb --build "$payload_dir" "$artifact_path"
