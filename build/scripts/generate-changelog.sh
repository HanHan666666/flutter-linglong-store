#!/usr/bin/env bash
# 为正式版与 Nightly 统一确定变更范围，再交给 Pi 生成发布说明正文。
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_ROOT="${LINGLONG_RELEASE_TOOL_ROOT:-$ROOT_DIR}"

# 正式版未指定起点时沿第一父提交链寻找最近的稳定版本，避开合并分支上的 tag。
resolve_previous_release_ref() {
  local resolved_ref=""
  local stderr_path=""

  stderr_path="$(mktemp "${TMPDIR:-/tmp}/linglong-release-describe.XXXXXX")"
  if resolved_ref="$(git -C "$WORKSPACE_ROOT" describe \
    --tags --abbrev=0 --first-parent \
    --match 'v[0-9]*.[0-9]*.[0-9]*' HEAD 2>"$stderr_path")"; then
    rm -f "$stderr_path"
    printf '%s' "$resolved_ref"
    return 0
  fi

  if grep -Eiq 'no names found|cannot describe' "$stderr_path"; then
    rm -f "$stderr_path"
    return 0
  fi

  cat "$stderr_path" >&2
  rm -f "$stderr_path"
  return 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <release-version> [previous-tag-or-commit]" >&2
  exit 64
fi

release_version="$1"
baseline_ref="${2:-${LINGLONG_RELEASE_NOTES_START_REF:-}}"

# 显式范围写错应当中止发布，不能悄悄改用另一段历史。
if [[ -n "$baseline_ref" ]] && \
  ! git -C "$WORKSPACE_ROOT" rev-parse --verify "${baseline_ref}^{commit}" >/dev/null 2>&1; then
  echo "Release notes start ref does not exist: $baseline_ref" >&2
  exit 1
fi

if [[ -z "$baseline_ref" ]]; then
  baseline_ref="$(resolve_previous_release_ref)"
fi

kind="${LINGLONG_CHANGELOG_CONTEXT_KIND:-stable}"
if [[ "$release_version" == *"-nightly."* ]]; then
  kind="nightly"
fi

bash "$ROOT_DIR/build/scripts/pi-release-changelog.sh" \
  --release-version "$release_version" \
  --kind "$kind" \
  --workspace "$WORKSPACE_ROOT" \
  --baseline-ref "$baseline_ref"
