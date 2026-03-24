#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RELEASE_VERSION="${RELEASE_VERSION:-3.0.7}"
TARGET_ARCH="${TARGET_ARCH:-amd64}"
PACKAGE_CHANNEL="${PACKAGE_CHANNEL:-stable}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/build/out/linux/$RELEASE_VERSION/$TARGET_ARCH}"

BUNDLE_ARTIFACT="linglong-store-${RELEASE_VERSION}-linux-${TARGET_ARCH}.tar.gz"
DEB_ARTIFACT="linglong-store_${RELEASE_VERSION}_${TARGET_ARCH}.deb"
RPM_ARCH="${RPM_ARCH:-x86_64}"
RPM_ARTIFACT="linglong-store-${RELEASE_VERSION}-1.${RPM_ARCH}.rpm"
APPIMAGE_ARTIFACT="linglong-store-${RELEASE_VERSION}-${TARGET_ARCH}.AppImage"

run_packaging_step() {
  local script_path="$1"
  shift

  if [[ ! -x "$script_path" ]]; then
    echo "Required packaging script is missing or not executable: $script_path" >&2
    exit 1
  fi

  "$script_path" "$@"
}

assert_artifact_exists() {
  local artifact_path="$1"

  if [[ ! -f "$artifact_path" ]]; then
    echo "Expected artifact was not created: $artifact_path" >&2
    exit 1
  fi
}

assert_file_contains() {
  local pattern="$1"
  local file_path="$2"

  if ! grep -Eq "$pattern" "$file_path"; then
    echo "Expected $file_path to match pattern: $pattern" >&2
    exit 1
  fi
}

verify_nightly_packaged_metadata() {
  local deb_artifact_path="$1"
  (
    local inspect_root

    if ! command -v dpkg-deb >/dev/null 2>&1; then
      echo "dpkg-deb is required to inspect nightly package metadata." >&2
      exit 1
    fi

    inspect_root="$(mktemp -d "${TMPDIR:-/tmp}/linglong-nightly-package.XXXXXX")"
    trap 'rm -rf "$inspect_root"' EXIT

    dpkg-deb -x "$deb_artifact_path" "$inspect_root/deb"

    assert_artifact_exists "$inspect_root/deb/usr/share/applications/linglong-store-nightly.desktop"
    assert_artifact_exists "$inspect_root/deb/usr/share/metainfo/linglong-store.appdata.xml"
    assert_file_contains '^Name=.*Nightly$' \
      "$inspect_root/deb/usr/share/applications/linglong-store-nightly.desktop"
    assert_file_contains '^Comment=.*Nightly$' \
      "$inspect_root/deb/usr/share/applications/linglong-store-nightly.desktop"
    assert_file_contains '<name>.*Nightly</name>' \
      "$inspect_root/deb/usr/share/metainfo/linglong-store.appdata.xml"
    assert_file_contains '<summary>.*Nightly</summary>' \
      "$inspect_root/deb/usr/share/metainfo/linglong-store.appdata.xml"
    assert_file_contains '<launchable type="desktop-id">linglong-store-nightly.desktop</launchable>' \
      "$inspect_root/deb/usr/share/metainfo/linglong-store.appdata.xml"
  )
}

case "$PACKAGE_CHANNEL" in
  stable|nightly)
    ;;
  *)
    echo "Unsupported PACKAGE_CHANNEL: $PACKAGE_CHANNEL" >&2
    exit 64
    ;;
esac

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

run_packaging_step \
  "$ROOT_DIR/build/scripts/package-bundle.sh" \
  --version "$RELEASE_VERSION" \
  --arch "$TARGET_ARCH"

run_packaging_step \
  "$ROOT_DIR/build/scripts/package-deb.sh" \
  --version "$RELEASE_VERSION" \
  --arch "$TARGET_ARCH" \
  --channel "$PACKAGE_CHANNEL"

run_packaging_step \
  "$ROOT_DIR/build/scripts/package-rpm.sh" \
  --version "$RELEASE_VERSION" \
  --arch "$TARGET_ARCH" \
  --channel "$PACKAGE_CHANNEL"

run_packaging_step \
  "$ROOT_DIR/build/scripts/package-appimage.sh" \
  --version "$RELEASE_VERSION" \
  --arch "$TARGET_ARCH" \
  --channel "$PACKAGE_CHANNEL"

assert_artifact_exists "$OUTPUT_DIR/$BUNDLE_ARTIFACT"
assert_artifact_exists "$OUTPUT_DIR/$DEB_ARTIFACT"
assert_artifact_exists "$OUTPUT_DIR/$RPM_ARTIFACT"
assert_artifact_exists "$OUTPUT_DIR/$APPIMAGE_ARTIFACT"

if [[ "$PACKAGE_CHANNEL" == "nightly" ]]; then
  # Inspect the built Debian package so Nightly metadata regressions fail before
  # prepare-nightly-assets.sh renames the files for publishing.
  verify_nightly_packaged_metadata "$OUTPUT_DIR/$DEB_ARTIFACT"
fi

echo "Smoke test passed for $OUTPUT_DIR ($PACKAGE_CHANNEL)"
