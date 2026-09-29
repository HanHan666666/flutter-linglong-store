#!/usr/bin/env bash
# 用本地假 Pi 验证发版范围、自由格式、UOS 摘要和错误传播，不调用真实模型。
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/linglong-pi-notes-smoke.XXXXXX")"
trap 'rm -rf "$tmp_root"' EXIT

fixture_repo="$tmp_root/source"
mkdir -p "$fixture_repo"
git -C "$fixture_repo" init -q
git -C "$fixture_repo" config user.name 'Pi Smoke Test'
git -C "$fixture_repo" config user.email 'pi-smoke@example.com'
printf 'first\n' > "$fixture_repo/change.txt"
git -C "$fixture_repo" add change.txt
git -C "$fixture_repo" commit -qm 'feat: earlier stable work'
git -C "$fixture_repo" tag v3.1.0
printf 'second\n' >> "$fixture_repo/change.txt"
git -C "$fixture_repo" commit -qam 'feat: current user change'
source_commit="$(git -C "$fixture_repo" rev-parse HEAD)"

fake_pi="$tmp_root/pi"
cat > "$fake_pi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "$PI_TEST_ARGS"
printf '%s\n' "$DEEPSEEK_API_KEY" > "$PI_TEST_KEY"
printf '这次更新让安装过程更清楚。\n\n### 体验改进\n\n- 任务状态会及时刷新。\n'
EOF
chmod +x "$fake_pi"

notes="$({
  DEEPSEEK_API_KEY=test-key \
  LINGLONG_PI_EXECUTABLE="$fake_pi" \
  LINGLONG_RELEASE_TOOL_ROOT="$fixture_repo" \
  PI_TEST_ARGS="$tmp_root/args" \
  PI_TEST_KEY="$tmp_root/key" \
    bash "$ROOT_DIR/build/scripts/generate-changelog.sh" 3.1.1
})"

grep -Fq -- '--provider' "$tmp_root/args"
grep -Fxq 'deepseek' "$tmp_root/args"
grep -Fxq 'deepseek-flash' "$tmp_root/args"
grep -Fxq -- '--approve' "$tmp_root/args"
grep -Fxq -- '--no-session' "$tmp_root/args"
if grep -Eq '^--(no-tools|tools|exclude-tools|no-builtin-tools)$' "$tmp_root/args"; then
  echo 'Pi tools must remain available in Actions.' >&2
  exit 1
fi
grep -Fq '起点：v3.1.0' "$tmp_root/args"
grep -Fq "终点：$source_commit" "$tmp_root/args"
grep -Fq '版本：3.1.1' "$tmp_root/args"
grep -Fq '类型：stable' "$tmp_root/args"
grep -Fxq 'test-key' "$tmp_root/key"
grep -Fq '### 体验改进' <<< "$notes"

# 固定下载区块追加后，UOS 摘要须保留 Pi 的段落与小标题。
printf '%s\n\n## Download\n- amd64\n' "$notes" > "$tmp_root/release-notes.md"
summary="$(bash "$ROOT_DIR/build/scripts/extract-release-note-summary.sh" "$tmp_root/release-notes.md")"
grep -Fq '### 体验改进' <<< "$summary"
grep -Fq '任务状态会及时刷新' <<< "$summary"
if grep -Fq 'amd64' <<< "$summary"; then
  echo 'UOS summary included download metadata.' >&2
  exit 1
fi

DEEPSEEK_API_KEY=test-key LINGLONG_PI_EXECUTABLE="$fake_pi" \
  LINGLONG_RELEASE_TOOL_ROOT="$fixture_repo" PI_TEST_ARGS="$tmp_root/args" \
  PI_TEST_KEY="$tmp_root/key" LINGLONG_RELEASE_NOTES_START_REF=v3.1.0 \
  bash "$ROOT_DIR/build/scripts/generate-changelog.sh" 3.1.1 > /dev/null
grep -Fq '起点：v3.1.0' "$tmp_root/args"

if DEEPSEEK_API_KEY=test-key LINGLONG_PI_EXECUTABLE="$fake_pi" \
  LINGLONG_RELEASE_TOOL_ROOT="$fixture_repo" \
  bash "$ROOT_DIR/build/scripts/generate-changelog.sh" 3.1.1 missing-tag > /dev/null 2>&1; then
  echo 'Invalid release baseline unexpectedly succeeded.' >&2
  exit 1
fi

if LINGLONG_PI_EXECUTABLE="$fake_pi" LINGLONG_RELEASE_TOOL_ROOT="$fixture_repo" \
  bash "$ROOT_DIR/build/scripts/generate-changelog.sh" 3.1.1 > /dev/null 2>&1; then
  echo 'Release notes unexpectedly succeeded without DeepSeek key.' >&2
  exit 1
fi

cat > "$fake_pi" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$fake_pi"
if DEEPSEEK_API_KEY=test-key LINGLONG_PI_EXECUTABLE="$fake_pi" \
  LINGLONG_RELEASE_TOOL_ROOT="$fixture_repo" \
  bash "$ROOT_DIR/build/scripts/generate-changelog.sh" 3.1.1 > /dev/null 2>&1; then
  echo 'Pi failure unexpectedly fell back to deterministic notes.' >&2
  exit 1
fi

echo 'Pi release notes smoke test passed.'
