#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ "${1:-}" != "--inner" && -z "${LINGLONG_RELEASE_CONTAINER:-}" ]]; then
  exec "$ROOT_DIR/build/scripts/run-in-release-container.sh" "$ROOT_DIR/build/scripts/package-rpm.sh" "$@"
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
    rpm_arch="x86_64"
    ;;
  arm64|aarch64)
    target_arch="arm64"
    rpm_arch="aarch64"
    ;;
  *)
    echo "Unsupported architecture: $target_arch" >&2
    exit 64
    ;;
esac

output_dir="$ROOT_DIR/build/out/linux/$release_version/$target_arch"
bundle_dir="$output_dir/bundle/linglong-store"
stage_root="$ROOT_DIR/build/tmp/package-rpm/$release_version-$target_arch"
payload_dir="$stage_root/payload"
metadata_dir="$stage_root/rendered"
rpmbuild_root="$stage_root/rpmbuild"
artifact_path="$output_dir/linglong-store-${release_version}-1.${rpm_arch}.rpm"
icon_path="$payload_dir/usr/share/icons/hicolor/256x256/apps/linglong-store.png"

"$ROOT_DIR/build/scripts/build-linux-bundle.sh" --inner --version "$release_version" --arch "$target_arch"

rm -rf "$stage_root"
mkdir -p \
  "$payload_dir/opt/linglong-store" \
  "$payload_dir/usr/bin" \
  "$payload_dir/usr/share/applications" \
  "$payload_dir/usr/share/icons/hicolor/256x256/apps" \
  "$payload_dir/usr/share/metainfo" \
  "$rpmbuild_root/BUILD" \
  "$rpmbuild_root/BUILDROOT" \
  "$rpmbuild_root/RPMS" \
  "$rpmbuild_root/SOURCES" \
  "$rpmbuild_root/SPECS" \
  "$rpmbuild_root/SRPMS"

cp -a "$bundle_dir/." "$payload_dir/opt/linglong-store/"

cat > "$payload_dir/usr/bin/linglong-store" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec /opt/linglong-store/linglong_store "$@"
EOF
chmod +x "$payload_dir/usr/bin/linglong-store"

rsvg-convert -w 256 -h 256 "$ROOT_DIR/assets/icons/logo.svg" -o "$icon_path"

"$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
  --inner \
  --version "$release_version" \
  --arch "$target_arch" \
  --output-dir "$metadata_dir" \
  --payload-dir "$payload_dir"

cp "$metadata_dir/linglong-store.desktop" "$payload_dir/usr/share/applications/linglong-store.desktop"
cp "$metadata_dir/appimage/linglong-store.appdata.xml" "$payload_dir/usr/share/metainfo/linglong-store.appdata.xml"
cp "$metadata_dir/rpm/linglong-store.spec" "$rpmbuild_root/SPECS/linglong-store.spec"

rm -f "$artifact_path"
rpmbuild -bb \
  --define "_topdir $rpmbuild_root" \
  --define "_build_id_links none" \
  --target "$rpm_arch" \
  "$rpmbuild_root/SPECS/linglong-store.spec"

cp "$rpmbuild_root/RPMS/$rpm_arch/linglong-store-${release_version}-1.${rpm_arch}.rpm" "$artifact_path"
