#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT_DIR"

if [[ $# -lt 1 || $# -gt 2 ]]; then
	echo "Usage: $0 <release-version> [previous-tag-or-commit]" >&2
	exit 64
fi

release_version="$1"
baseline_ref="${2:-}"

base_changelog="$({
	bash "$ROOT_DIR/build/scripts/run-release-dart-tool.sh" "$ROOT_DIR/tool/release/generate_changelog.dart" "$@"
})"

# AI changelog is an optional enhancement. Publishing must stay deterministic when
# Claude is unavailable, misconfigured, or intentionally disabled.
if [[ -z "${CLAUDE_CODE_SETTINGS_JSON:-}" ]]; then
	printf '%s' "$base_changelog"
	exit 0
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/linglong-ai-changelog.XXXXXX")"
cleanup() {
	rm -rf "$tmp_dir"
}

trap cleanup EXIT

base_changelog_path="$tmp_dir/base-changelog.md"
printf '%s' "$base_changelog" > "$base_changelog_path"

kind="${LINGLONG_CHANGELOG_CONTEXT_KIND:-stable}"
if [[ "$release_version" == *"-nightly."* ]]; then
	kind="nightly"
fi

if ai_changelog="$({
	bash "$ROOT_DIR/build/scripts/claude-code-release-changelog.sh" \
		--release-version "$release_version" \
		--kind "$kind" \
		--base-changelog-file "$base_changelog_path" \
		${baseline_ref:+--baseline-ref "$baseline_ref"}
})"; then
	printf '%s' "$ai_changelog"
else
	echo "Claude Code changelog generation failed for ${release_version}; falling back to deterministic changelog." >&2
	printf '%s' "$base_changelog"
fi
