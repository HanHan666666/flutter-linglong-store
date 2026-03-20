#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RELEASE_VERSION="${RELEASE_VERSION:-3.0.7}"
TARGET_ARCH="${TARGET_ARCH:-amd64}"
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

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

run_packaging_step \
  "$ROOT_DIR/build/scripts/package-bundle.sh" \
  --version "$RELEASE_VERSION" \
  --arch "$TARGET_ARCH"

run_packaging_step \
  "$ROOT_DIR/build/scripts/package-deb.sh" \
  --version "$RELEASE_VERSION" \
  --arch "$TARGET_ARCH"

run_packaging_step \
  "$ROOT_DIR/build/scripts/package-rpm.sh" \
  --version "$RELEASE_VERSION" \
  --arch "$TARGET_ARCH"

run_packaging_step \
  "$ROOT_DIR/build/scripts/package-appimage.sh" \
  --version "$RELEASE_VERSION" \
  --arch "$TARGET_ARCH"

assert_artifact_exists "$OUTPUT_DIR/$BUNDLE_ARTIFACT"
assert_artifact_exists "$OUTPUT_DIR/$DEB_ARTIFACT"
assert_artifact_exists "$OUTPUT_DIR/$RPM_ARTIFACT"
assert_artifact_exists "$OUTPUT_DIR/$APPIMAGE_ARTIFACT"

echo "Smoke test passed for $OUTPUT_DIR"
