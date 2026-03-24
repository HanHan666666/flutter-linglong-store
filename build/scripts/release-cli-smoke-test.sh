#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/linglong-release-smoke.XXXXXX")"
RENDER_OUTPUT_DIR="$TMP_ROOT/render"

cleanup() {
  rm -rf "$TMP_ROOT"
}

trap cleanup EXIT

cd "$ROOT_DIR"

version_output="$(bash build/scripts/resolve-release-version.sh)"
version_output="${version_output//$'\n'/}"

if [[ ! "$version_output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Expected a clean semver from resolve-release-version.sh, got: $version_output" >&2
  exit 1
fi

changelog_output="$(bash build/scripts/generate-changelog.sh "$version_output")"
first_line="$(printf '%s\n' "$changelog_output" | sed -n '1p')"

if [[ "$first_line" != "## Release Notes" ]]; then
  echo "Expected generate-changelog.sh to start with release notes header, got: $first_line" >&2
  exit 1
fi

bash build/scripts/render-packaging-templates.sh \
  --inner \
  --version "$version_output" \
  --arch amd64 \
  --output-dir "$RENDER_OUTPUT_DIR"

test -f "$RENDER_OUTPUT_DIR/linglong-store.desktop"
grep -q '^Name=玲珑应用商店社区版$' "$RENDER_OUTPUT_DIR/linglong-store.desktop"
grep -q '^Comment=Linglong Store Community Edition$' "$RENDER_OUTPUT_DIR/linglong-store.desktop"
grep -q '<name>玲珑应用商店社区版</name>' "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"
grep -q '<summary>Linglong Store Community Edition</summary>' "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"
grep -q '<launchable type="desktop-id">linglong-store.desktop</launchable>' "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"

echo "Release CLI smoke test passed."
