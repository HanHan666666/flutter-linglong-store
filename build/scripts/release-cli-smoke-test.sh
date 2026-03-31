#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/linglong-release-smoke.XXXXXX")"
RENDER_OUTPUT_DIR="$TMP_ROOT/render"
RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR="$TMP_ROOT/release-artifacts-download"
RELEASE_ASSET_FIXTURE_DIR="$TMP_ROOT/release-assets"
RELEASE_NOTES_FIXTURE_PATH="$TMP_ROOT/release-notes.md"
HASHES_OUTPUT_PATH="$RELEASE_ASSET_FIXTURE_DIR/hashes.sha256"

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

desktop_count="$(find "$RENDER_OUTPUT_DIR" -maxdepth 1 -type f -name '*.desktop' | awk 'END { print NR }')"
test "$desktop_count" = "1"
test -f "$RENDER_OUTPUT_DIR/linglong-store.desktop"
grep -q '^Name=玲珑应用商店社区版$' "$RENDER_OUTPUT_DIR/linglong-store.desktop"
grep -q '^Comment=Linglong Store Community Edition$' "$RENDER_OUTPUT_DIR/linglong-store.desktop"
grep -q '<name>玲珑应用商店社区版</name>' "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"
grep -q '<summary>Linglong Store Community Edition</summary>' "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"
grep -q '<launchable type="desktop-id">linglong-store.desktop</launchable>' "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"

mkdir -p \
  "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-amd64" \
  "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-arm64"

# 构造 GitHub Actions 下载后的正式 release 双架构资产目录，
# 校验规范化步骤与 notes 哈希段落的最终格式。
cat > "$RELEASE_NOTES_FIXTURE_PATH" <<'EOF'
## Release Notes

Smoke test body.
EOF

printf 'amd64 bundle\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-amd64/linglong-store-${version_output}-linux-amd64.tar.gz"
printf 'amd64 bundle signature\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-amd64/linglong-store-${version_output}-linux-amd64.tar.gz.asc"
printf 'amd64 deb\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-amd64/linglong-store_${version_output}_amd64.deb"
printf 'amd64 rpm\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-amd64/linglong-store-${version_output}-1.x86_64.rpm"
printf 'amd64 appimage\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-amd64/linglong-store-${version_output}-amd64.AppImage"
printf 'arm64 bundle\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-arm64/linglong-store-${version_output}-linux-arm64.tar.gz"
printf 'arm64 bundle signature\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-arm64/linglong-store-${version_output}-linux-arm64.tar.gz.asc"
printf 'arm64 deb\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-arm64/linglong-store_${version_output}_arm64.deb"
printf 'arm64 rpm\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-arm64/linglong-store-${version_output}-1.aarch64.rpm"
printf 'arm64 appimage\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-arm64/linglong-store-${version_output}-arm64.AppImage"

bash build/scripts/normalize-release-assets.sh \
  --input-dir "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR" \
  --output-dir "$RELEASE_ASSET_FIXTURE_DIR"

bash build/scripts/append-release-asset-hashes.sh \
  --assets-dir "$RELEASE_ASSET_FIXTURE_DIR" \
  --notes-file "$RELEASE_NOTES_FIXTURE_PATH" \
  --hashes-output "$HASHES_OUTPUT_PATH"

test -f "$HASHES_OUTPUT_PATH"
notes_hash="$(sha256sum "$HASHES_OUTPUT_PATH" | awk '{print toupper($1)}')"
amd64_bundle_hash="$(sha256sum "$RELEASE_ASSET_FIXTURE_DIR/linglong-store-${version_output}-linux-amd64.tar.gz" | awk '{print toupper($1)}')"

grep -q '^## SHA256 Hashes of the release artifacts$' "$RELEASE_NOTES_FIXTURE_PATH"
grep -q '^- hashes.sha256$' "$RELEASE_NOTES_FIXTURE_PATH"
grep -q "$notes_hash" "$RELEASE_NOTES_FIXTURE_PATH"
grep -q 'linglong-store-'"$version_output"'-linux-amd64.tar.gz' "$RELEASE_NOTES_FIXTURE_PATH"
grep -q "$amd64_bundle_hash" "$RELEASE_NOTES_FIXTURE_PATH"
grep -q 'linglong-store_'"$version_output"'_arm64.deb$' "$HASHES_OUTPUT_PATH"
grep -q 'linglong-store-'"$version_output"'-1.aarch64.rpm$' "$HASHES_OUTPUT_PATH"
test -f "$RELEASE_ASSET_FIXTURE_DIR/linglong-store-${version_output}-linux-amd64.tar.gz.asc"

echo "Release CLI smoke test passed."
