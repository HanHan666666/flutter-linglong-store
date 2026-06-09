#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/linglong-nightly-smoke.XXXXXX")"
FAKE_SOURCE_DIR="$TMP_ROOT/source"
RENDER_OUTPUT_DIR="$TMP_ROOT/render"
STABLE_AUR_OUTPUT_DIR="$TMP_ROOT/stable-aur-render"
NIGHTLY_AUR_OUTPUT_DIR="$TMP_ROOT/nightly-aur-render"
OUTPUT_DIR="$TMP_ROOT/output"
NIGHTLY_ASSET_FIXTURE_DIR="$TMP_ROOT/nightly-assets"
NIGHTLY_HASHES_OUTPUT_PATH="$NIGHTLY_ASSET_FIXTURE_DIR/hashes.sha256"
FAKE_CLAUDE_SUCCESS_PATH="$TMP_ROOT/fake-claude-success.sh"
FAKE_CLAUDE_FAILURE_PATH="$TMP_ROOT/fake-claude-failure.sh"
FAKE_CLAUDE_INPUT_PATH="$TMP_ROOT/fake-claude-input.txt"
FAKE_CLAUDE_ARGS_PATH="$TMP_ROOT/fake-claude-args.txt"
FAKE_CLAUDE_SETTINGS_PATH="$TMP_ROOT/fake-claude-settings.json"
FAKE_CLAUDE_HOME="$TMP_ROOT/fake-claude-home"
FAKE_CLAUDE_PROMPT_PATH="$TMP_ROOT/fake-claude-prompt.md"

cleanup() {
  rm -rf "$TMP_ROOT"
}

trap cleanup EXIT

unset \
  CLAUDE_CODE_SETTINGS_JSON \
  LINGLONG_CLAUDE_CODE_EXECUTABLE \
  LINGLONG_CLAUDE_CODE_INSTALL_DIR \
  LINGLONG_CLAUDE_CODE_VERSION \
  LINGLONG_REINSTALL_CLAUDE_CODE \
  LINGLONG_USE_SYSTEM_CLAUDE_CODE \
  LINGLONG_RELEASE_NOTES_START_REF

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

metadata_output="$(bash "$ROOT_DIR/build/scripts/resolve-nightly-metadata.sh")"
base_version=""
nightly_date=""
nightly_label=""
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
grep -q '/releases/tag/nightly-'"$nightly_date"'$' "$NIGHTLY_AUR_OUTPUT_DIR/aur/linglong-store-nightly-bin.changelog"
grep -q '^source_aarch64=(' "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"
grep -q 'linglong-store-'"$nightly_label"'-linux-arm64.tar.gz::https://github.com/HanHan666666/flutter-linglong-store/releases/download/nightly-'"$nightly_date"'/linglong-store-'"$nightly_label"'-linux-arm64.tar.gz' \
  "$NIGHTLY_AUR_OUTPUT_DIR/aur/PKGBUILD"

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
NOTES_OUTPUT_FIRST_RELEASE="$TMP_ROOT/nightly-release-notes-first.md"
NOTES_OUTPUT_INVALID_BASELINE="$TMP_ROOT/nightly-release-notes-invalid-baseline.md"
NOTES_OUTPUT_WITH_LOONG64="$TMP_ROOT/nightly-release-notes-with-loong64.md"

mkdir -p "$NOTES_FIXTURE_REPO"
git init "$NOTES_FIXTURE_REPO" >/dev/null 2>&1
git -C "$NOTES_FIXTURE_REPO" config user.name "Nightly Smoke"
git -C "$NOTES_FIXTURE_REPO" config user.email "nightly-smoke@example.com"

cat > "$NOTES_FIXTURE_REPO/notes.txt" <<'EOF'
initial
EOF
git -C "$NOTES_FIXTURE_REPO" add notes.txt
git -C "$NOTES_FIXTURE_REPO" commit -m "feat: initial nightly baseline" >/dev/null 2>&1
previous_source_commit="$(git -C "$NOTES_FIXTURE_REPO" rev-parse HEAD)"

cat > "$NOTES_FIXTURE_REPO/notes.txt" <<'EOF'
current
EOF
git -C "$NOTES_FIXTURE_REPO" add notes.txt
git -C "$NOTES_FIXTURE_REPO" commit -m "fix: append nightly changelog" >/dev/null 2>&1
current_source_commit="$(git -C "$NOTES_FIXTURE_REPO" rev-parse HEAD)"

(
  cd "$NOTES_FIXTURE_REPO"
  bash "$ROOT_DIR/build/scripts/generate-nightly-release-notes.sh" \
    --nightly-label "$nightly_label" \
    --nightly-date "$nightly_date" \
    --source-commit "$current_source_commit" \
    --previous-source-commit "$previous_source_commit" \
    --output "$NOTES_OUTPUT_WITH_HISTORY"
)

assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "## Release Notes"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "1、本次版本暂无需要特别说明的用户可见变化。"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "Nightly source commit: $current_source_commit"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "Nightly source date: $nightly_date"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "Nightly version label: $nightly_label"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "- Architecture: amd64, arm64"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "## Download"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "- amd64: bundle / deb / rpm / AppImage"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "- arm64: bundle / deb / rpm / AppImage"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "paru -S linglong-store-bin"
assert_file_contains "$NOTES_OUTPUT_WITH_HISTORY" "## Requirements"

cp "$NOTES_OUTPUT_WITH_HISTORY" "$NOTES_OUTPUT_WITH_LOONG64"
bash "$ROOT_DIR/build/scripts/augment-nightly-release-notes-loong64.sh" \
  --notes-file "$NOTES_OUTPUT_WITH_LOONG64"
bash "$ROOT_DIR/build/scripts/augment-nightly-release-notes-loong64.sh" \
  --notes-file "$NOTES_OUTPUT_WITH_LOONG64"

assert_file_contains "$NOTES_OUTPUT_WITH_LOONG64" "- Architecture: amd64, arm64, loong64"
assert_file_contains "$NOTES_OUTPUT_WITH_LOONG64" "- loong64: bundle / deb"
test "$(grep -c '^- loong64: bundle / deb$' "$NOTES_OUTPUT_WITH_LOONG64")" = "1"

(
  cd "$NOTES_FIXTURE_REPO"
  bash "$ROOT_DIR/build/scripts/generate-nightly-release-notes.sh" \
    --nightly-label "$nightly_label" \
    --nightly-date "$nightly_date" \
    --source-commit "$current_source_commit" \
    --output "$NOTES_OUTPUT_FIRST_RELEASE"
)

assert_file_contains "$NOTES_OUTPUT_FIRST_RELEASE" "## Release Notes"
assert_file_contains "$NOTES_OUTPUT_FIRST_RELEASE" "1、这是首个 Nightly Release，后续 Nightly 将从上一版 Nightly source commit 自动生成变更日志。"

(
  cd "$NOTES_FIXTURE_REPO"
  bash "$ROOT_DIR/build/scripts/generate-nightly-release-notes.sh" \
    --nightly-label "$nightly_label" \
    --nightly-date "$nightly_date" \
    --source-commit "$current_source_commit" \
    --previous-source-commit deadbeef \
    --output "$NOTES_OUTPUT_INVALID_BASELINE"
)

assert_file_contains "$NOTES_OUTPUT_INVALID_BASELINE" "## Release Notes"
assert_file_contains "$NOTES_OUTPUT_INVALID_BASELINE" "1、这是首个 Nightly Release，后续 Nightly 将从上一版 Nightly source commit 自动生成变更日志。"

cat > "$FAKE_CLAUDE_SETTINGS_PATH" <<'EOF'
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "nightly-token",
    "ANTHROPIC_BASE_URL": "http://claude.example.test"
  },
  "model": "sonnet"
}
EOF

cat > "$FAKE_CLAUDE_SUCCESS_PATH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" > "$FAKE_CLAUDE_ARGS_PATH"
previous_arg=""
prompt_file=""
for arg in "$@"; do
  if [[ "$previous_arg" == "--append-system-prompt-file" ]]; then
    prompt_file="$arg"
    break
  fi
  previous_arg="$arg"
done

if [[ -n "${FAKE_CLAUDE_PROMPT_PATH:-}" && -n "$prompt_file" ]]; then
  cat "$prompt_file" > "$FAKE_CLAUDE_PROMPT_PATH"
fi

cat > "$FAKE_CLAUDE_INPUT_PATH"
test "$(jq -S . "$HOME/.claude/settings.json")" = "$(jq -S . "$FAKE_CLAUDE_SETTINGS_PATH")"
cat <<'OUT'
{"items":["修复 Nightly 构建中的更新日志展示问题。"]}
OUT
EOF
chmod +x "$FAKE_CLAUDE_SUCCESS_PATH"

cat > "$FAKE_CLAUDE_FAILURE_PATH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 1
EOF
chmod +x "$FAKE_CLAUDE_FAILURE_PATH"

NOTES_OUTPUT_WITH_AI="$TMP_ROOT/nightly-release-notes-with-ai.md"

(
  cd "$NOTES_FIXTURE_REPO"
  HOME="$FAKE_CLAUDE_HOME" \
  CLAUDE_CODE_SETTINGS_JSON="$(cat "$FAKE_CLAUDE_SETTINGS_PATH")" \
  FAKE_CLAUDE_ARGS_PATH="$FAKE_CLAUDE_ARGS_PATH" \
  FAKE_CLAUDE_INPUT_PATH="$FAKE_CLAUDE_INPUT_PATH" \
  FAKE_CLAUDE_PROMPT_PATH="$FAKE_CLAUDE_PROMPT_PATH" \
  FAKE_CLAUDE_SETTINGS_PATH="$FAKE_CLAUDE_SETTINGS_PATH" \
  LINGLONG_CLAUDE_CODE_EXECUTABLE="$FAKE_CLAUDE_SUCCESS_PATH" \
  LINGLONG_USE_SYSTEM_CLAUDE_CODE=0 \
  bash "$ROOT_DIR/build/scripts/generate-nightly-release-notes.sh" \
    --nightly-label "$nightly_label" \
    --nightly-date "$nightly_date" \
    --source-commit "$current_source_commit" \
    --previous-source-commit "$previous_source_commit" \
    --output "$NOTES_OUTPUT_WITH_AI"
)

assert_file_contains "$NOTES_OUTPUT_WITH_AI" "1、修复 Nightly 构建中的更新日志展示问题。"
assert_file_contains "$NOTES_OUTPUT_WITH_AI" "Nightly source commit: $current_source_commit"
assert_file_contains "$NOTES_OUTPUT_WITH_AI" "Nightly source date: $nightly_date"
assert_file_contains "$NOTES_OUTPUT_WITH_AI" "Nightly version label: $nightly_label"
assert_file_contains "$NOTES_OUTPUT_WITH_AI" "## Nightly Build"
assert_file_contains "$NOTES_OUTPUT_WITH_AI" "## Download"
assert_file_contains "$NOTES_OUTPUT_WITH_AI" "## Requirements"
assert_file_contains "$FAKE_CLAUDE_INPUT_PATH" "subject: fix: append nightly changelog"
assert_file_contains "$FAKE_CLAUDE_ARGS_PATH" "--setting-sources user"
assert_file_contains "$FAKE_CLAUDE_ARGS_PATH" "--tools"
assert_file_contains "$FAKE_CLAUDE_ARGS_PATH" "请根据输入中的 release notes 范围和候选变更，为版本 ${nightly_label}（nightly）生成最终的 JSON 文案条目。"
assert_file_contains "$FAKE_CLAUDE_PROMPT_PATH" "当前版本：${nightly_label}"
assert_file_contains "$FAKE_CLAUDE_PROMPT_PATH" "当前构建类型：nightly"
assert_file_contains "$FAKE_CLAUDE_PROMPT_PATH" "当前基线引用：${previous_source_commit}"
assert_file_contains "$FAKE_CLAUDE_PROMPT_PATH" "当前代码库根目录：${NOTES_FIXTURE_REPO}"
assert_file_contains "$FAKE_CLAUDE_PROMPT_PATH" "当前文档目录：${ROOT_DIR}/docs"
assert_file_contains "$FAKE_CLAUDE_INPUT_PATH" "Start ref: ${previous_source_commit}"
if grep -Fq '特殊用户要求' "$FAKE_CLAUDE_PROMPT_PATH"; then
  echo "Expected nightly release notes prompt to avoid temporary special user requirements." >&2
  exit 1
fi
if grep -Fq 'git提交' "$FAKE_CLAUDE_PROMPT_PATH"; then
  echo "Expected nightly release notes prompt to avoid repository mutation instructions." >&2
  exit 1
fi

NOTES_OUTPUT_WITH_AI_FALLBACK="$TMP_ROOT/nightly-release-notes-with-ai-fallback.md"

(
  cd "$NOTES_FIXTURE_REPO"
  HOME="$FAKE_CLAUDE_HOME" \
  CLAUDE_CODE_SETTINGS_JSON="$(cat "$FAKE_CLAUDE_SETTINGS_PATH")" \
  FAKE_CLAUDE_ARGS_PATH="$FAKE_CLAUDE_ARGS_PATH" \
  FAKE_CLAUDE_INPUT_PATH="$FAKE_CLAUDE_INPUT_PATH" \
  FAKE_CLAUDE_SETTINGS_PATH="$FAKE_CLAUDE_SETTINGS_PATH" \
  LINGLONG_CLAUDE_CODE_EXECUTABLE="$FAKE_CLAUDE_FAILURE_PATH" \
  LINGLONG_USE_SYSTEM_CLAUDE_CODE=0 \
  bash "$ROOT_DIR/build/scripts/generate-nightly-release-notes.sh" \
    --nightly-label "$nightly_label" \
    --nightly-date "$nightly_date" \
    --source-commit "$current_source_commit" \
    --previous-source-commit "$previous_source_commit" \
    --output "$NOTES_OUTPUT_WITH_AI_FALLBACK"
)

assert_file_contains "$NOTES_OUTPUT_WITH_AI_FALLBACK" "## Release Notes"
assert_file_contains "$NOTES_OUTPUT_WITH_AI_FALLBACK" "1、本次版本暂无需要特别说明的用户可见变化。"
assert_file_contains "$NOTES_OUTPUT_WITH_AI_FALLBACK" "Nightly source commit: $current_source_commit"
assert_file_contains "$NOTES_OUTPUT_WITH_AI_FALLBACK" "Nightly source date: $nightly_date"
assert_file_contains "$NOTES_OUTPUT_WITH_AI_FALLBACK" "Nightly version label: $nightly_label"

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
