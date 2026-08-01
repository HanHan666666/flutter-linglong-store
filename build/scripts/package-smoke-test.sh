#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT_DIR/build/scripts/lib/application-identity.sh"

load_application_identity "$ROOT_DIR/config/application_identity.conf"

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

# 确认打包后的元数据与 ARB 生成器输出完全一致。
assert_files_equal() {
  local expected_path="$1"
  local actual_path="$2"

  assert_artifact_exists "$expected_path"
  assert_artifact_exists "$actual_path"
  if ! cmp -s "$expected_path" "$actual_path"; then
    echo "Packaged metadata differs from generated metadata: $actual_path" >&2
    diff -u "$expected_path" "$actual_path" >&2 || true
    exit 1
  fi
}

# 检查 Nightly DEB 中安装的用户可见元数据和兼容入口。
verify_nightly_packaged_metadata() {
  local deb_artifact_path="$1"
  (
    local inspect_root
    local expected_metadata_root
    local canonical_desktop_path
    local expected_canonical_desktop_path
    local appstream_path
    local expected_appstream_path
    local compat_desktop_id
    local compat_desktop_path
    local expected_compat_desktop_path
    local -a nightly_compat_desktop_ids=()

    if ! command -v dpkg-deb >/dev/null 2>&1; then
      echo "dpkg-deb is required to inspect nightly package metadata." >&2
      exit 1
    fi

    inspect_root="$(mktemp -d "${TMPDIR:-/tmp}/linglong-nightly-package.XXXXXX")"
    trap 'rm -rf "$inspect_root"' EXIT

    dpkg-deb -x "$deb_artifact_path" "$inspect_root/deb"

    # package-deb 保留当次 ARB 渲染结果；逐字节比较可以验证
    # Desktop Entry/AppStream 确实完整进入最终安装包。
    expected_metadata_root="$ROOT_DIR/build/tmp/package-deb/$RELEASE_VERSION-$TARGET_ARCH/rendered"
    canonical_desktop_path="$inspect_root/deb/usr/share/applications/$CANONICAL_DESKTOP_ID"
    expected_canonical_desktop_path="$expected_metadata_root/$CANONICAL_DESKTOP_ID"
    appstream_path="$inspect_root/deb/usr/share/metainfo/linglong-store.appdata.xml"
    expected_appstream_path="$expected_metadata_root/appimage/linglong-store.appdata.xml"
    mapfile -t nightly_compat_desktop_ids < <(
      application_identity_compat_desktop_ids nightly
    )

    assert_files_equal "$expected_canonical_desktop_path" "$canonical_desktop_path"
    assert_files_equal "$expected_appstream_path" "$appstream_path"
    assert_file_contains '^X-GNOME-UsesNotifications=true$' \
      "$canonical_desktop_path"
    for compat_desktop_id in "${nightly_compat_desktop_ids[@]}"; do
      compat_desktop_path="$inspect_root/deb/usr/share/applications/$compat_desktop_id"
      expected_compat_desktop_path="$expected_metadata_root/compat/$compat_desktop_id"
      assert_files_equal "$expected_compat_desktop_path" "$compat_desktop_path"
      assert_file_contains '^NoDisplay=true$' "$compat_desktop_path"
      assert_file_contains '^MimeType=x-scheme-handler/og;$' \
        "$compat_desktop_path"
    done
    assert_file_contains "<launchable type=\"desktop-id\">$CANONICAL_DESKTOP_ID</launchable>" \
      "$appstream_path"
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
