#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/linglong-nightly-smoke.XXXXXX")"
FAKE_SOURCE_DIR="$TMP_ROOT/source"
RENDER_OUTPUT_DIR="$TMP_ROOT/render"
STABLE_AUR_OUTPUT_DIR="$TMP_ROOT/stable-aur-render"
NIGHTLY_AUR_OUTPUT_DIR="$TMP_ROOT/nightly-aur-render"
OUTPUT_DIR="$TMP_ROOT/output"

cleanup() {
  rm -rf "$TMP_ROOT"
}

trap cleanup EXIT

assert_no_template_placeholders() {
  local file_path="$1"

  if grep -n '@[A-Z0-9_]\+@' "$file_path" >&2; then
    echo "Unexpected unresolved template placeholder in $file_path" >&2
    exit 1
  fi
}

metadata_output="$(bash "$ROOT_DIR/build/scripts/resolve-nightly-metadata.sh")"
eval "$metadata_output"

if [[ ! "$nightly_label" =~ ^[0-9]+\.[0-9]+\.[0-9]+-nightly\.[0-9]{8}\+[0-9a-f]+$ ]]; then
  echo "Unexpected nightly label: $nightly_label" >&2
  exit 1
fi

normalized_aur_version="$(bash "$ROOT_DIR/build/scripts/normalize-nightly-aur-version.sh" \
  "3.0.2-nightly.20260324+8190b89")"
test "$normalized_aur_version" = "3.0.2_nightly.20260324.8190b89"
if bash "$ROOT_DIR/build/scripts/normalize-nightly-aur-version.sh" "3.0.2" >/dev/null 2>&1; then
  echo "normalize-nightly-aur-version.sh unexpectedly accepted a non-nightly version." >&2
  exit 1
fi
current_nightly_aur_version="$(bash "$ROOT_DIR/build/scripts/normalize-nightly-aur-version.sh" \
  "$nightly_label")"

mkdir -p "$FAKE_SOURCE_DIR"
touch "$FAKE_SOURCE_DIR/linglong-store-${base_version}-linux-amd64.tar.gz"
touch "$FAKE_SOURCE_DIR/linglong-store_${base_version}_amd64.deb"
touch "$FAKE_SOURCE_DIR/linglong-store-${base_version}-1.x86_64.rpm"
touch "$FAKE_SOURCE_DIR/linglong-store-${base_version}-amd64.AppImage"

bash "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
  --inner \
  --version "$base_version" \
  --arch amd64 \
  --output-dir "$STABLE_AUR_OUTPUT_DIR" \
  --sha256-amd64 deadbeef \
  --sha256-arm64 deadbeef \
  --sha256-sig-amd64 deadbeef \
  --sha256-sig-arm64 deadbeef \
  --gpg-key-id TESTKEY

test -f "$STABLE_AUR_OUTPUT_DIR/aur/PKGBUILD"
assert_no_template_placeholders "$STABLE_AUR_OUTPUT_DIR/aur/PKGBUILD"
test -f "$STABLE_AUR_OUTPUT_DIR/aur/linglong-store-bin.changelog"
assert_no_template_placeholders "$STABLE_AUR_OUTPUT_DIR/aur/linglong-store-bin.changelog"
grep -q '^pkgname=linglong-store-bin$' "$STABLE_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q "^arch=('x86_64' 'aarch64')$" "$STABLE_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q 'linglong-store-'"$base_version"'-linux-arm64.tar.gz::https://github.com/HanHan666666/flutter-linglong-store/releases/download/v'"$base_version"'/linglong-store-'"$base_version"'-linux-arm64.tar.gz' \
  "$STABLE_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q "^  'deadbeef'$" "$STABLE_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q '/releases/tag/v'"$base_version"'$' "$STABLE_AUR_OUTPUT_DIR/aur/linglong-store-bin.changelog"

bash "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
  --inner \
  --version "$nightly_label" \
  --arch amd64 \
  --output-dir "$RENDER_OUTPUT_DIR" \
  --channel nightly

bash "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
  --inner \
  --version "$nightly_label" \
  --arch amd64 \
  --output-dir "$NIGHTLY_AUR_OUTPUT_DIR" \
  --channel nightly \
  --sha256-amd64 deadbeef \
  --sha256-sig-amd64 deadbeef \
  --gpg-key-id TESTKEY

test -f "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
assert_no_template_placeholders "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
test -f "$NIGHTLY_AUR_OUTPUT_DIR/aur/linglong-store-nightly-bin.changelog"
assert_no_template_placeholders "$NIGHTLY_AUR_OUTPUT_DIR/aur/linglong-store-nightly-bin.changelog"
grep -q '^pkgname=linglong-store-nightly-bin$' "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q "^pkgver=${current_nightly_aur_version}$" "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q "^arch=('x86_64')$" "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q '^conflicts=('"'linglong-store-bin'"')$' "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q '/releases/tag/nightly-'"$nightly_date"'$' "$NIGHTLY_AUR_OUTPUT_DIR/aur/linglong-store-nightly-bin.changelog"
if grep -q '^source_aarch64=' "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"; then
  echo "Nightly PKGBUILD unexpectedly rendered source_aarch64 block." >&2
  exit 1
fi

desktop_count="$(find "$RENDER_OUTPUT_DIR" -maxdepth 1 -type f -name '*.desktop' | awk 'END { print NR }')"
test "$desktop_count" = "1"
test -f "$RENDER_OUTPUT_DIR/linglong-store-nightly.desktop"
grep -q '^Name=.*Nightly' "$RENDER_OUTPUT_DIR/linglong-store-nightly.desktop"
grep -q '^Comment=.*Nightly' "$RENDER_OUTPUT_DIR/linglong-store-nightly.desktop"
grep -q '<name>.*Nightly</name>' "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"
grep -q '<summary>.*Nightly</summary>' "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"
grep -q '<launchable type="desktop-id">linglong-store-nightly.desktop</launchable>' "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"

bash "$ROOT_DIR/build/scripts/prepare-nightly-assets.sh" \
  --base-version "$base_version" \
  --nightly-label "$nightly_label" \
  --arch amd64 \
  --source-dir "$FAKE_SOURCE_DIR" \
  --output-dir "$OUTPUT_DIR"

test -f "$OUTPUT_DIR/linglong-store-${nightly_label}-linux-amd64.tar.gz"
test -f "$OUTPUT_DIR/linglong-store-${nightly_label}-amd64.deb"
test -f "$OUTPUT_DIR/linglong-store-${nightly_label}-x86_64.rpm"
test -f "$OUTPUT_DIR/linglong-store-${nightly_label}-amd64.AppImage"

echo "Nightly CLI smoke test passed."
