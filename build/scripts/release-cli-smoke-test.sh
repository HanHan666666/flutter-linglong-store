#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/linglong-release-smoke.XXXXXX")"
RENDER_OUTPUT_DIR="$TMP_ROOT/render"
RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR="$TMP_ROOT/release-artifacts-download"
RELEASE_ASSET_FIXTURE_DIR="$TMP_ROOT/release-assets"
RELEASE_NOTES_FIXTURE_PATH="$TMP_ROOT/release-notes.md"
HASHES_OUTPUT_PATH="$RELEASE_ASSET_FIXTURE_DIR/hashes.sha256"
FAKE_CLAUDE_SUCCESS_PATH="$TMP_ROOT/fake-claude-success.sh"
FAKE_CLAUDE_INVALID_PATH="$TMP_ROOT/fake-claude-invalid.sh"
FAKE_CLAUDE_ZERO_NUMBER_PATH="$TMP_ROOT/fake-claude-zero-number.sh"
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

CHANGELOG_FIXTURE_DIR="$TMP_ROOT/changelog-fixture"
mkdir -p "$CHANGELOG_FIXTURE_DIR"

git -C "$CHANGELOG_FIXTURE_DIR" init >/dev/null 2>&1
git -C "$CHANGELOG_FIXTURE_DIR" config user.name "Copilot Smoke Test"
git -C "$CHANGELOG_FIXTURE_DIR" config user.email "copilot-smoke@example.com"

printf 'bootstrap\n' > "$CHANGELOG_FIXTURE_DIR/base.txt"
git -C "$CHANGELOG_FIXTURE_DIR" add base.txt
git -C "$CHANGELOG_FIXTURE_DIR" commit -m "feat: bootstrap release repo" >/dev/null 2>&1
default_branch="$(git -C "$CHANGELOG_FIXTURE_DIR" symbolic-ref --quiet --short HEAD)"
initial_commit="$(git -C "$CHANGELOG_FIXTURE_DIR" rev-parse HEAD)"

printf 'stable release baseline\n' > "$CHANGELOG_FIXTURE_DIR/mainline.txt"
git -C "$CHANGELOG_FIXTURE_DIR" add mainline.txt
git -C "$CHANGELOG_FIXTURE_DIR" commit -m "feat: release line 3.1.0 work" >/dev/null 2>&1
git -C "$CHANGELOG_FIXTURE_DIR" tag v3.1.0

git -C "$CHANGELOG_FIXTURE_DIR" checkout -b maintenance "$initial_commit" >/dev/null 2>&1
printf 'hotfix branch\n' > "$CHANGELOG_FIXTURE_DIR/hotfix.txt"
git -C "$CHANGELOG_FIXTURE_DIR" add hotfix.txt
git -C "$CHANGELOG_FIXTURE_DIR" commit -m "fix: hotfix merged after the previous release" >/dev/null 2>&1
git -C "$CHANGELOG_FIXTURE_DIR" tag v99.0.0

git -C "$CHANGELOG_FIXTURE_DIR" checkout "$default_branch" >/dev/null 2>&1
git -C "$CHANGELOG_FIXTURE_DIR" merge --no-ff maintenance -m "Merge branch 'maintenance'" >/dev/null 2>&1
printf 'release workflow guard\n' > "$CHANGELOG_FIXTURE_DIR/workflow.txt"
git -C "$CHANGELOG_FIXTURE_DIR" add workflow.txt
git -C "$CHANGELOG_FIXTURE_DIR" commit -m "fix: add checkout for update-uos-store job" >/dev/null 2>&1
printf 'release workflow docs\n' > "$CHANGELOG_FIXTURE_DIR/docs.txt"
git -C "$CHANGELOG_FIXTURE_DIR" add docs.txt
git -C "$CHANGELOG_FIXTURE_DIR" commit -m "docs: document release workflow" >/dev/null 2>&1
printf 'release workflow tests\n' > "$CHANGELOG_FIXTURE_DIR/tests.txt"
git -C "$CHANGELOG_FIXTURE_DIR" add tests.txt
git -C "$CHANGELOG_FIXTURE_DIR" commit -m "test: cover release workflow" >/dev/null 2>&1
printf 'current release candidate\n' > "$CHANGELOG_FIXTURE_DIR/current.txt"
git -C "$CHANGELOG_FIXTURE_DIR" add current.txt
git -C "$CHANGELOG_FIXTURE_DIR" commit -m "feat: current release candidate" >/dev/null 2>&1

fixture_changelog="$({
  LINGLONG_RELEASE_TOOL_ROOT="$CHANGELOG_FIXTURE_DIR" \
    bash build/scripts/generate-changelog.sh \
    3.1.1 \
    v3.1.0
})"

grep -q '^1、current release candidate$' <<< "$fixture_changelog"
grep -q '^2、hotfix merged after the previous release$' <<< "$fixture_changelog"
if grep -q -- 'release line 3.1.0 work' <<< "$fixture_changelog"; then
  echo "Expected auto-resolved previous release tag to exclude the already released mainline commit." >&2
  exit 1
fi
if grep -q -- 'Merge branch' <<< "$fixture_changelog"; then
  echo "Expected formatted release notes to ignore non user-facing maintenance commits." >&2
  exit 1
fi
if grep -q -- 'add checkout for update-uos-store job' <<< "$fixture_changelog"; then
  echo "Expected update-uos-store maintenance fixes to be filtered from deterministic release notes." >&2
  exit 1
fi
if grep -q -- 'document release workflow' <<< "$fixture_changelog"; then
  echo "Expected docs commits to be filtered from deterministic release notes." >&2
  exit 1
fi
if grep -q -- 'cover release workflow' <<< "$fixture_changelog"; then
  echo "Expected test commits to be filtered from deterministic release notes." >&2
  exit 1
fi

cat > "$FAKE_CLAUDE_SETTINGS_PATH" <<'EOF'
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "test-token",
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
{"items":["支持从网页商店拉起客户端并加入安装队列。"]}
OUT
EOF
chmod +x "$FAKE_CLAUDE_SUCCESS_PATH"

cat > "$FAKE_CLAUDE_INVALID_PATH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat >/dev/null
cat <<'OUT'
{"items":[123]}
OUT
EOF
chmod +x "$FAKE_CLAUDE_INVALID_PATH"

cat > "$FAKE_CLAUDE_ZERO_NUMBER_PATH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat >/dev/null
cat <<'OUT'
## Release Notes

0、错误编号不应进入最终发布说明。
OUT
EOF
chmod +x "$FAKE_CLAUDE_ZERO_NUMBER_PATH"

cat > "$FAKE_CLAUDE_FAILURE_PATH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 1
EOF
chmod +x "$FAKE_CLAUDE_FAILURE_PATH"

ai_changelog="$({
  HOME="$FAKE_CLAUDE_HOME" \
  CLAUDE_CODE_SETTINGS_JSON="$(cat "$FAKE_CLAUDE_SETTINGS_PATH")" \
  FAKE_CLAUDE_ARGS_PATH="$FAKE_CLAUDE_ARGS_PATH" \
  FAKE_CLAUDE_INPUT_PATH="$FAKE_CLAUDE_INPUT_PATH" \
  FAKE_CLAUDE_PROMPT_PATH="$FAKE_CLAUDE_PROMPT_PATH" \
  FAKE_CLAUDE_SETTINGS_PATH="$FAKE_CLAUDE_SETTINGS_PATH" \
  LINGLONG_CLAUDE_CODE_EXECUTABLE="$FAKE_CLAUDE_SUCCESS_PATH" \
  LINGLONG_USE_SYSTEM_CLAUDE_CODE=0 \
  LINGLONG_RELEASE_TOOL_ROOT="$CHANGELOG_FIXTURE_DIR" \
    bash build/scripts/generate-changelog.sh 3.1.1 v3.1.0
})"

grep -q '^## Release Notes$' <<< "$ai_changelog"
grep -q '^1、支持从网页商店拉起客户端并加入安装队列。$' <<< "$ai_changelog"
grep -q -- '--bare' "$FAKE_CLAUDE_ARGS_PATH"
grep -q -- '--setting-sources user' "$FAKE_CLAUDE_ARGS_PATH"
grep -q -- '--tools' "$FAKE_CLAUDE_ARGS_PATH"
grep -q -- '--max-turns 1' "$FAKE_CLAUDE_ARGS_PATH"
if grep -Fq '特殊用户要求' "$FAKE_CLAUDE_PROMPT_PATH"; then
  echo "Expected release notes prompt to avoid temporary special user requirements." >&2
  exit 1
fi
if grep -Fq 'git提交' "$FAKE_CLAUDE_PROMPT_PATH"; then
  echo "Expected release notes prompt to avoid repository mutation instructions." >&2
  exit 1
fi
grep -q '请根据输入中的 release notes 范围和候选变更，为版本 3.1.1（release）生成最终的 JSON 文案条目。' "$FAKE_CLAUDE_ARGS_PATH"
grep -q '^# Release Notes Context$' "$FAKE_CLAUDE_INPUT_PATH"
grep -q '^# flutter-linglong-store GitHub Release 更新日志条目生成 Prompt$' "$FAKE_CLAUDE_PROMPT_PATH"
grep -q '当前版本：3.1.1' "$FAKE_CLAUDE_PROMPT_PATH"
grep -q '当前构建类型：release' "$FAKE_CLAUDE_PROMPT_PATH"
grep -q '当前基线引用：v3.1.0' "$FAKE_CLAUDE_PROMPT_PATH"
grep -q '当前代码库根目录：.*/changelog-fixture' "$FAKE_CLAUDE_PROMPT_PATH"
grep -q '当前文档目录：.*/docs' "$FAKE_CLAUDE_PROMPT_PATH"
grep -q '^Start ref: v3.1.0$' "$FAKE_CLAUDE_INPUT_PATH"
grep -q '^End ref: HEAD$' "$FAKE_CLAUDE_INPUT_PATH"
grep -q 'subject: feat: current release candidate' "$FAKE_CLAUDE_INPUT_PATH"

release_notes_for_uos="$TMP_ROOT/release-notes-for-uos.md"
cat > "$release_notes_for_uos" <<EOF
$ai_changelog

## Download
- amd64: bundle / deb / rpm / AppImage
- arm64: bundle / deb / rpm / AppImage
- Arch Linux (AUR): \`paru -S linglong-store-bin\`
EOF

uos_note="$({
  bash build/scripts/extract-release-note-summary.sh "$release_notes_for_uos"
})"

test "$uos_note" = '1、支持从网页商店拉起客户端并加入安装队列。'

ai_changelog_from_env="$({
  HOME="$FAKE_CLAUDE_HOME" \
  CLAUDE_CODE_SETTINGS_JSON="$(cat "$FAKE_CLAUDE_SETTINGS_PATH")" \
  FAKE_CLAUDE_ARGS_PATH="$FAKE_CLAUDE_ARGS_PATH" \
  FAKE_CLAUDE_INPUT_PATH="$FAKE_CLAUDE_INPUT_PATH" \
  FAKE_CLAUDE_PROMPT_PATH="$FAKE_CLAUDE_PROMPT_PATH" \
  FAKE_CLAUDE_SETTINGS_PATH="$FAKE_CLAUDE_SETTINGS_PATH" \
  LINGLONG_CLAUDE_CODE_EXECUTABLE="$FAKE_CLAUDE_SUCCESS_PATH" \
  LINGLONG_USE_SYSTEM_CLAUDE_CODE=0 \
  LINGLONG_RELEASE_NOTES_START_REF=v3.1.0 \
  LINGLONG_RELEASE_TOOL_ROOT="$CHANGELOG_FIXTURE_DIR" \
    bash build/scripts/generate-changelog.sh 3.1.1
})"

grep -q '^1、支持从网页商店拉起客户端并加入安装队列。$' <<< "$ai_changelog_from_env"
grep -q '当前基线引用：v3.1.0' "$FAKE_CLAUDE_PROMPT_PATH"
grep -q '^Start ref: v3.1.0$' "$FAKE_CLAUDE_INPUT_PATH"

invalid_ai_changelog="$({
  HOME="$FAKE_CLAUDE_HOME" \
  CLAUDE_CODE_SETTINGS_JSON="$(cat "$FAKE_CLAUDE_SETTINGS_PATH")" \
  FAKE_CLAUDE_ARGS_PATH="$FAKE_CLAUDE_ARGS_PATH" \
  FAKE_CLAUDE_INPUT_PATH="$FAKE_CLAUDE_INPUT_PATH" \
  FAKE_CLAUDE_SETTINGS_PATH="$FAKE_CLAUDE_SETTINGS_PATH" \
  LINGLONG_CLAUDE_CODE_EXECUTABLE="$FAKE_CLAUDE_INVALID_PATH" \
  LINGLONG_USE_SYSTEM_CLAUDE_CODE=0 \
  LINGLONG_RELEASE_TOOL_ROOT="$CHANGELOG_FIXTURE_DIR" \
    bash build/scripts/generate-changelog.sh 3.1.1 v3.1.0
})"

test "$invalid_ai_changelog" = "$fixture_changelog"

zero_number_ai_changelog="$({
  HOME="$FAKE_CLAUDE_HOME" \
  CLAUDE_CODE_SETTINGS_JSON="$(cat "$FAKE_CLAUDE_SETTINGS_PATH")" \
  FAKE_CLAUDE_ARGS_PATH="$FAKE_CLAUDE_ARGS_PATH" \
  FAKE_CLAUDE_INPUT_PATH="$FAKE_CLAUDE_INPUT_PATH" \
  FAKE_CLAUDE_SETTINGS_PATH="$FAKE_CLAUDE_SETTINGS_PATH" \
  LINGLONG_CLAUDE_CODE_EXECUTABLE="$FAKE_CLAUDE_ZERO_NUMBER_PATH" \
  LINGLONG_USE_SYSTEM_CLAUDE_CODE=0 \
  LINGLONG_RELEASE_TOOL_ROOT="$CHANGELOG_FIXTURE_DIR" \
    bash build/scripts/generate-changelog.sh 3.1.1 v3.1.0
})"

test "$zero_number_ai_changelog" = "$fixture_changelog"
if grep -q '^0、' <<< "$zero_number_ai_changelog"; then
  echo "Expected invalid AI output starting from 0 to be rejected." >&2
  exit 1
fi

fallback_ai_changelog="$({
  HOME="$FAKE_CLAUDE_HOME" \
  CLAUDE_CODE_SETTINGS_JSON="$(cat "$FAKE_CLAUDE_SETTINGS_PATH")" \
  FAKE_CLAUDE_ARGS_PATH="$FAKE_CLAUDE_ARGS_PATH" \
  FAKE_CLAUDE_INPUT_PATH="$FAKE_CLAUDE_INPUT_PATH" \
  FAKE_CLAUDE_SETTINGS_PATH="$FAKE_CLAUDE_SETTINGS_PATH" \
  LINGLONG_CLAUDE_CODE_EXECUTABLE="$FAKE_CLAUDE_FAILURE_PATH" \
  LINGLONG_USE_SYSTEM_CLAUDE_CODE=0 \
  LINGLONG_RELEASE_TOOL_ROOT="$CHANGELOG_FIXTURE_DIR" \
    bash build/scripts/generate-changelog.sh 3.1.1 v3.1.0
})"

test "$fallback_ai_changelog" = "$fixture_changelog"

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
  "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-arm64" \
  "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-loong64"

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
printf 'loong64 bundle\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-loong64/linglong-store-${version_output}-linux-loong64.tar.gz"
printf 'loong64 bundle signature\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-loong64/linglong-store-${version_output}-linux-loong64.tar.gz.asc"
printf 'loong64 deb\n' > "$RELEASE_ASSET_DOWNLOAD_FIXTURE_DIR/release-assets-loong64/linglong-store_${version_output}_loong64.deb"

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
grep -q 'linglong-store-'"$version_output"'-linux-loong64.tar.gz' "$RELEASE_NOTES_FIXTURE_PATH"
grep -q 'linglong-store_'"$version_output"'_arm64.deb$' "$HASHES_OUTPUT_PATH"
grep -q 'linglong-store-'"$version_output"'-1.aarch64.rpm$' "$HASHES_OUTPUT_PATH"
grep -q 'linglong-store_'"$version_output"'_loong64.deb$' "$HASHES_OUTPUT_PATH"
test -f "$RELEASE_ASSET_FIXTURE_DIR/linglong-store-${version_output}-linux-loong64.tar.gz.asc"
test -f "$RELEASE_ASSET_FIXTURE_DIR/linglong-store-${version_output}-linux-amd64.tar.gz.asc"

echo "Release CLI smoke test passed."
