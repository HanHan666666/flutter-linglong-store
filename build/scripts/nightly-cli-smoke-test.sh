#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT_DIR/build/scripts/lib/application-identity.sh"

load_application_identity "$ROOT_DIR/config/application_identity.conf"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/linglong-nightly-smoke.XXXXXX")"
FAKE_SOURCE_DIR="$TMP_ROOT/source"
RENDER_OUTPUT_DIR="$TMP_ROOT/render"
STABLE_AUR_OUTPUT_DIR="$TMP_ROOT/stable-aur-render"
NIGHTLY_AUR_OUTPUT_DIR="$TMP_ROOT/nightly-aur-render"
LEGACY_NIGHTLY_AUR_OUTPUT_DIR="$TMP_ROOT/legacy-nightly-aur-render"
OUTPUT_DIR="$TMP_ROOT/output"
NIGHTLY_ASSET_FIXTURE_DIR="$TMP_ROOT/nightly-assets"
NIGHTLY_HASHES_OUTPUT_PATH="$NIGHTLY_ASSET_FIXTURE_DIR/hashes.sha256"
FAKE_PI_PATH="$TMP_ROOT/fake-pi.sh"
FAKE_PI_ARGS_PATH="$TMP_ROOT/fake-pi-args.txt"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

unset DEEPSEEK_API_KEY LINGLONG_PI_EXECUTABLE LINGLONG_RELEASE_NOTES_START_REF

assert_no_template_placeholders() {
  local file_path="$1"

  if grep -n '@[A-Z0-9_]\+@' "$file_path" >&2; then
    echo "Unexpected unresolved template placeholder in $file_path" >&2
    exit 1
  fi
}

assert_file_contains() {
  local file_path="$1"
  local pattern="$2"

  if ! grep -Fq -- "$pattern" "$file_path"; then
    echo "Expected $file_path to contain: $pattern" >&2
    exit 1
  fi
}

# 确认同一元数据字段组在 Stable/Nightly 之间存在渠道差异。
assert_metadata_family_differs() {
  local label="$1"
  local pattern="$2"
  local stable_file="$3"
  local nightly_file="$4"
  local stable_lines
  local nightly_lines

  if ! stable_lines="$(grep -E "$pattern" "$stable_file")"; then
    echo "Stable metadata is missing $label: $stable_file" >&2
    exit 1
  fi
  if ! nightly_lines="$(grep -E "$pattern" "$nightly_file")"; then
    echo "Nightly metadata is missing $label: $nightly_file" >&2
    exit 1
  fi
  if [[ "$stable_lines" == "$nightly_lines" ]]; then
    echo "Stable and Nightly metadata unexpectedly share $label: $nightly_file" >&2
    exit 1
  fi
}

metadata_output="$(bash "$ROOT_DIR/build/scripts/resolve-nightly-metadata.sh")"
base_version=""
nightly_date=""
nightly_label=""
nightly_tag=""
eval "$metadata_output"

if [[ ! "$nightly_label" =~ ^[0-9]+\.[0-9]+\.[0-9]+-nightly\.[0-9]{8}\+[0-9a-f]+$ ]]; then
  echo "Unexpected nightly label: $nightly_label" >&2
  exit 1
fi
# 月 tag 只由北京时间日期派生；展示用的版本标签仍保留日和源码 SHA。
test "$nightly_tag" = "nightly-${nightly_date:0:6}"
. "$ROOT_DIR/build/scripts/lib/nightly-release-tag.sh"
test "$(nightly_release_tag_for_label "$nightly_label")" = "$nightly_tag"
test "$(LINGLONG_NIGHTLY_RELEASE_TAG="nightly-$nightly_date" nightly_release_tag_for_label "$nightly_label")" = "nightly-$nightly_date"
if LINGLONG_NIGHTLY_RELEASE_TAG=nightly-199901 nightly_release_tag_for_label "$nightly_label" >/dev/null 2>&1; then
  echo "Nightly tag resolver accepted a tag from another month." >&2
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
touch "$FAKE_SOURCE_DIR/linglong-store-${base_version}-linux-arm64.tar.gz"
touch "$FAKE_SOURCE_DIR/linglong-store_${base_version}_arm64.deb"
touch "$FAKE_SOURCE_DIR/linglong-store-${base_version}-1.aarch64.rpm"
touch "$FAKE_SOURCE_DIR/linglong-store-${base_version}-arm64.AppImage"

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
  --sha256-arm64 deadbeef \
  --sha256-sig-amd64 deadbeef \
  --sha256-sig-arm64 deadbeef \
  --gpg-key-id TESTKEY

test -f "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
assert_no_template_placeholders "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
test -f "$NIGHTLY_AUR_OUTPUT_DIR/aur/linglong-store-nightly-bin.changelog"
assert_no_template_placeholders "$NIGHTLY_AUR_OUTPUT_DIR/aur/linglong-store-nightly-bin.changelog"
grep -q '^pkgname=linglong-store-nightly-bin$' "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q "^pkgver=${current_nightly_aur_version}$" "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q "^arch=('x86_64' 'aarch64')$" "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q '^conflicts=('"'linglong-store' 'linglong-store-bin'"')$' "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q '/releases/tag/'"$nightly_tag"'$' "$NIGHTLY_AUR_OUTPUT_DIR/aur/linglong-store-nightly-bin.changelog"
grep -q '^source_aarch64=(' "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q 'linglong-store-'"$nightly_label"'-linux-arm64.tar.gz::https://github.com/HanHan666666/flutter-linglong-store/releases/download/'"$nightly_tag"'/linglong-store-'"$nightly_label"'-linux-arm64.tar.gz' \
  "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"

# 历史日版未清理，手动补发 AUR 必须继续引用它原来的日 tag。
LINGLONG_NIGHTLY_RELEASE_TAG="nightly-$nightly_date" \
  bash "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
    --inner \
    --version "$nightly_label" \
    --arch amd64 \
    --output-dir "$LEGACY_NIGHTLY_AUR_OUTPUT_DIR" \
    --channel nightly \
    --sha256-amd64 deadbeef \
    --sha256-arm64 deadbeef \
    --sha256-sig-amd64 deadbeef \
    --sha256-sig-arm64 deadbeef \
    --gpg-key-id TESTKEY
grep -Fq "/releases/download/nightly-$nightly_date/" "$LEGACY_NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"

desktop_count="$(find "$RENDER_OUTPUT_DIR" -maxdepth 1 -type f -name '*.desktop' | awk 'END { print NR }')"
test "$desktop_count" = "1"
canonical_desktop_path="$RENDER_OUTPUT_DIR/$CANONICAL_DESKTOP_ID"
stable_canonical_desktop_path="$STABLE_AUR_OUTPUT_DIR/$CANONICAL_DESKTOP_ID"
test -f "$canonical_desktop_path"
test -f "$stable_canonical_desktop_path"
assert_metadata_family_differs \
  'Desktop Entry Name' \
  '^Name(\[[^]]+\])?=' \
  "$stable_canonical_desktop_path" \
  "$canonical_desktop_path"
assert_metadata_family_differs \
  'Desktop Entry Comment' \
  '^Comment(\[[^]]+\])?=' \
  "$stable_canonical_desktop_path" \
  "$canonical_desktop_path"
grep -q '^X-GNOME-UsesNotifications=true$' "$canonical_desktop_path"
mapfile -t nightly_compat_desktop_ids < <(
  application_identity_compat_desktop_ids nightly
)
for compat_desktop_id in "${nightly_compat_desktop_ids[@]}"; do
  compat_desktop_path="$RENDER_OUTPUT_DIR/compat/$compat_desktop_id"
  test -f "$compat_desktop_path"
  grep -q '^NoDisplay=true$' "$compat_desktop_path"
  grep -q '^MimeType=x-scheme-handler/og;$' "$compat_desktop_path"
done
assert_metadata_family_differs \
  'AppStream name' \
  '^[[:space:]]*<name( xml:lang="[^"]+")?>.*</name>$' \
  "$STABLE_AUR_OUTPUT_DIR/appimage/linglong-store.appdata.xml" \
  "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"
assert_metadata_family_differs \
  'AppStream summary' \
  '^[[:space:]]*<summary( xml:lang="[^"]+")?>.*</summary>$' \
  "$STABLE_AUR_OUTPUT_DIR/appimage/linglong-store.appdata.xml" \
  "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"
grep -Fq "<launchable type=\"desktop-id\">$CANONICAL_DESKTOP_ID</launchable>" \
  "$RENDER_OUTPUT_DIR/appimage/linglong-store.appdata.xml"

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

bash "$ROOT_DIR/build/scripts/prepare-nightly-assets.sh" \
  --base-version "$base_version" \
  --nightly-label "$nightly_label" \
  --arch arm64 \
  --source-dir "$FAKE_SOURCE_DIR" \
  --output-dir "$OUTPUT_DIR-arm64"

test -f "$OUTPUT_DIR-arm64/linglong-store-${nightly_label}-linux-arm64.tar.gz"
test -f "$OUTPUT_DIR-arm64/linglong-store-${nightly_label}-arm64.deb"
test -f "$OUTPUT_DIR-arm64/linglong-store-${nightly_label}-aarch64.rpm"
test -f "$OUTPUT_DIR-arm64/linglong-store-${nightly_label}-arm64.AppImage"

NOTES_FIXTURE_REPO="$TMP_ROOT/notes-repo"
NOTES_OUTPUT_WITH_HISTORY="$TMP_ROOT/nightly-release-notes-with-history.md"
NOTES_OUTPUT_WITH_LOONG64="$TMP_ROOT/nightly-release-notes-with-loong64.md"

mkdir -p "$NOTES_FIXTURE_REPO"
git init "$NOTES_FIXTURE_REPO" >/dev/null 2>&1
git -C "$NOTES_FIXTURE_REPO" config user.name "Nightly Smoke"
git -C "$NOTES_FIXTURE_REPO" config user.email "nightly-smoke@example.com"
printf 'initial\n' > "$NOTES_FIXTURE_REPO/notes.txt"
git -C "$NOTES_FIXTURE_REPO" add notes.txt
git -C "$NOTES_FIXTURE_REPO" commit -m "feat: initial nightly baseline" >/dev/null 2>&1
git -C "$NOTES_FIXTURE_REPO" tag v3.0.0
printf 'current\n' >> "$NOTES_FIXTURE_REPO/notes.txt"
git -C "$NOTES_FIXTURE_REPO" commit -am "fix: improve nightly details" >/dev/null 2>&1
current_source_commit="$(git -C "$NOTES_FIXTURE_REPO" rev-parse HEAD)"

cat > "$FAKE_PI_PATH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "$FAKE_PI_ARGS_PATH"
printf 'Nightly 修复了安装进度显示。\n\n### 体验改进\n\n- 状态更及时。\n'
EOF
chmod +x "$FAKE_PI_PATH"

(
  cd "$NOTES_FIXTURE_REPO"
  DEEPSEEK_API_KEY=test-key LINGLONG_PI_EXECUTABLE="$FAKE_PI_PATH" FAKE_PI_ARGS_PATH="$FAKE_PI_ARGS_PATH" \
    bash "$ROOT_DIR/build/scripts/generate-nightly-release-notes.sh" \
      --nightly-label "$nightly_label" \
      --nightly-date "$nightly_date" \
      --source-commit "$current_source_commit" \
      --output "$NOTES_OUTPUT_WITH_HISTORY"
)

assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "## Release Notes"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "Nightly 修复了安装进度显示。"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "### 体验改进"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "Nightly source commit: $current_source_commit"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "Nightly source date: $nightly_date"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "Nightly version label: $nightly_label"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "- Architecture: amd64, arm64"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "## Download"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "## Requirements"
assert_file_contains "$FAKE_PI_ARGS_PATH" "起点：v3.0.0"
assert_file_contains "$FAKE_PI_ARGS_PATH" "类型：nightly"
assert_file_contains "$FAKE_PI_ARGS_PATH" "deepseek-flash"
if grep -Eq '^--(no-tools|tools|exclude-tools|no-builtin-tools)$' "$FAKE_PI_ARGS_PATH"; then
  echo "Pi tools must remain available in nightly Actions." >&2
  exit 1
fi

cp "$NOTES_OUTPUT_WITH_HISTORY" "$NOTES_OUTPUT_WITH_LOONG64"
bash "$ROOT_DIR/build/scripts/augment-nightly-release-notes-loong64.sh" \
  --notes-file "$NOTES_OUTPUT_WITH_LOONG64"
bash "$ROOT_DIR/build/scripts/augment-nightly-release-notes-loong64.sh" \
  --notes-file "$NOTES_OUTPUT_WITH_LOONG64"
assert_file_contains "$NOTES_OUTPUT_WITH_LOONG64" "- Architecture: amd64, arm64, loong64"
assert_file_contains "$NOTES_OUTPUT_WITH_LOONG64" "- loong64: bundle / deb"
test "$(grep -c '^- loong64: bundle / deb$' "$NOTES_OUTPUT_WITH_LOONG64")" = "1"

# 模型调用失败时不落地半份 Nightly 发布说明。
cat > "$FAKE_PI_PATH" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$FAKE_PI_PATH"
if (
  cd "$NOTES_FIXTURE_REPO"
  DEEPSEEK_API_KEY=test-key LINGLONG_PI_EXECUTABLE="$FAKE_PI_PATH" \
    bash "$ROOT_DIR/build/scripts/generate-nightly-release-notes.sh" \
      --nightly-label "$nightly_label" \
      --nightly-date "$nightly_date" \
      --source-commit "$current_source_commit" \
      --output "$TMP_ROOT/failed-nightly-notes.md"
); then
  echo "Nightly notes unexpectedly succeeded after Pi failure." >&2
  exit 1
fi
test ! -e "$TMP_ROOT/failed-nightly-notes.md"

mkdir -p "$NIGHTLY_ASSET_FIXTURE_DIR"

# 构造 nightly prerelease 的对外发布资产，确保哈希段落和 hashes.sha256 会一起生成。
printf 'nightly bundle\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-linux-amd64.tar.gz"
printf 'nightly bundle signature\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-linux-amd64.tar.gz.asc"
printf 'nightly deb\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-amd64.deb"
printf 'nightly rpm\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-x86_64.rpm"
printf 'nightly appimage\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-amd64.AppImage"
printf 'nightly arm64 bundle\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-linux-arm64.tar.gz"
printf 'nightly arm64 bundle signature\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-linux-arm64.tar.gz.asc"
printf 'nightly arm64 deb\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-arm64.deb"
printf 'nightly arm64 rpm\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-aarch64.rpm"
printf 'nightly arm64 appimage\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-arm64.AppImage"

bash "$ROOT_DIR/build/scripts/append-release-asset-hashes.sh" \
  --assets-dir "$NIGHTLY_ASSET_FIXTURE_DIR" \
  --notes-file "$NOTES_OUTPUT_WITH_HISTORY" \
  --hashes-output "$NIGHTLY_HASHES_OUTPUT_PATH"

test -f "$NIGHTLY_HASHES_OUTPUT_PATH"
nightly_hashes_hash="$(sha256sum "$NIGHTLY_HASHES_OUTPUT_PATH" | awk '{print toupper($1)}')"
nightly_bundle_hash="$(sha256sum "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-linux-amd64.tar.gz" | awk '{print toupper($1)}')"

assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "## SHA256 Hashes of the release artifacts"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "- hashes.sha256"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "$nightly_hashes_hash"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "linglong-store-${nightly_label}-linux-amd64.tar.gz"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "$nightly_bundle_hash"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "linglong-store-${nightly_label}-linux-arm64.tar.gz"
grep -q 'linglong-store-'"$nightly_label"'-amd64.AppImage$' "$NIGHTLY_HASHES_OUTPUT_PATH"
grep -q 'linglong-store-'"$nightly_label"'-x86_64.rpm$' "$NIGHTLY_HASHES_OUTPUT_PATH"
grep -q 'linglong-store-'"$nightly_label"'-arm64.AppImage$' "$NIGHTLY_HASHES_OUTPUT_PATH"
grep -q 'linglong-store-'"$nightly_label"'-aarch64.rpm$' "$NIGHTLY_HASHES_OUTPUT_PATH"

printf 'nightly loong64 bundle\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-linux-loong64.tar.gz"
printf 'nightly loong64 bundle signature\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-linux-loong64.tar.gz.asc"
printf 'nightly loong64 deb\n' > "$NIGHTLY_ASSET_FIXTURE_DIR/linglong-store-${nightly_label}-loong64.deb"

bash "$ROOT_DIR/build/scripts/augment-nightly-release-notes-loong64.sh" \
  --notes-file "$NOTES_OUTPUT_WITH_HISTORY"

bash "$ROOT_DIR/build/scripts/append-release-asset-hashes.sh" \
  --replace-existing \
  --assets-dir "$NIGHTLY_ASSET_FIXTURE_DIR" \
  --notes-file "$NOTES_OUTPUT_WITH_HISTORY" \
  --hashes-output "$NIGHTLY_HASHES_OUTPUT_PATH"

assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "- Architecture: amd64, arm64, loong64"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "- loong64: bundle / deb"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "linglong-store-${nightly_label}-linux-loong64.tar.gz"
test "$(grep -c '^## SHA256 Hashes of the release artifacts$' "$NOTES_OUTPUT_WITH_HISTORY")" = "1"
grep -q 'linglong-store-'"$nightly_label"'-linux-loong64.tar.gz$' "$NIGHTLY_HASHES_OUTPUT_PATH"
grep -q 'linglong-store-'"$nightly_label"'-linux-loong64.tar.gz.asc$' "$NIGHTLY_HASHES_OUTPUT_PATH"
grep -q 'linglong-store-'"$nightly_label"'-loong64.deb$' "$NIGHTLY_HASHES_OUTPUT_PATH"

echo "Nightly CLI smoke test passed."
