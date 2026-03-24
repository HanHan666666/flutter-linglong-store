#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/linglong-nightly-smoke.XXXXXX")"
FAKE_SOURCE_DIR="$TMP_ROOT/source"
RENDER_OUTPUT_DIR="$TMP_ROOT/render"
OUTPUT_DIR="$TMP_ROOT/output"

cleanup() {
  rm -rf "$TMP_ROOT"
}

trap cleanup EXIT

metadata_output="$(bash "$ROOT_DIR/build/scripts/resolve-nightly-metadata.sh")"
eval "$metadata_output"

if [[ ! "$nightly_label" =~ ^[0-9]+\.[0-9]+\.[0-9]+-nightly\.[0-9]{8}\+[0-9a-f]+$ ]]; then
  echo "Unexpected nightly label: $nightly_label" >&2
  exit 1
fi

mkdir -p "$FAKE_SOURCE_DIR"
touch "$FAKE_SOURCE_DIR/linglong-store-${base_version}-linux-amd64.tar.gz"
touch "$FAKE_SOURCE_DIR/linglong-store_${base_version}_amd64.deb"
touch "$FAKE_SOURCE_DIR/linglong-store-${base_version}-1.x86_64.rpm"
touch "$FAKE_SOURCE_DIR/linglong-store-${base_version}-amd64.AppImage"

bash "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
  --inner \
  --version "$base_version" \
  --arch amd64 \
  --output-dir "$RENDER_OUTPUT_DIR" \
  --channel nightly

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
