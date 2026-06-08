#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_ROOT="${LINGLONG_RELEASE_TOOL_ROOT:-$ROOT_DIR}"

cd "$ROOT_DIR"

# 将 Dart 原始分组 changelog 规整为发布页使用的编号列表。
format_release_notes_markdown() {
	awk '
		function is_internal_change(text, lower_text) {
			lower_text = tolower(text)

			if (lower_text ~ /(^|[^[:alnum:]_])(ci|workflow|test|tests|refactor|tooling|script|scripts|packaging|package|package smoke|smoke test|release note|release notes|release process|changelog|claude code|uos store|appstore|aur|hash|signature|signing|checkout|update-uos-store|docs|documentation|document|template|templates|guideline|guidelines|mandatory comment|code documentation|technology stack)([^[:alnum:]_]|$)/) {
				return 1
			}

			if (text ~ /(文档|测试|重构|打包|发布流程|发布说明|更新日志|工作流|工具链|脚本|签名|哈希|构建校验|冒烟|应用商店|仓库维护|注释规范|技术栈模板|模板文档)/) {
				return 1
			}

			return 0
		}

		function is_visible_change(section, text) {
			if (section != "新增" && section != "修复") {
				return 0
			}

			if (is_internal_change(text)) {
				return 0
			}

			return 1
		}

		BEGIN {
			in_notes = 0
			section = ""
			fallback_text = ""
			item_count = 0
		}

		/^## Release Notes$/ {
			in_notes = 1
			next
		}

		!in_notes {
			next
		}

		/^## feat$/ {
			section = "新增"
			next
		}

		/^## fix$/ {
			section = "修复"
			next
		}

		/^## / {
			section = ""
			next
		}

		/^- / {
			text = substr($0, 3)
			if (item_count < 5 && is_visible_change(section, text)) {
				items[++item_count] = item_count "、" section "：" text
			}
			next
		}

		NF {
			if (section == "" && fallback_text == "") {
				fallback_text = $0
			}
		}

		END {
			print "## Release Notes"
			print ""

			if (item_count > 0) {
				for (item_index = 1; item_index <= item_count; item_index++) {
					print items[item_index]
				}
				exit 0
			}

			if (fallback_text != "") {
				print "1、" fallback_text
				exit 0
			}

			print "1、本次版本暂无需要特别说明的功能新增或问题修复。"
		}
	'
}

# stable release 未显式指定起点时，沿用 Dart 工具的 first-parent stable tag 规则。
resolve_previous_release_ref() {
	local resolved_ref=""
	local stderr_path=""
	local status="0"

	stderr_path="$(mktemp "${TMPDIR:-/tmp}/linglong-release-describe.XXXXXX")"
	if resolved_ref="$(git -C "$WORKSPACE_ROOT" describe \
		--tags \
		--abbrev=0 \
		--first-parent \
		--match 'v[0-9]*.[0-9]*.[0-9]*' \
		HEAD 2>"$stderr_path")"; then
		rm -f "$stderr_path"
		printf '%s' "$resolved_ref"
		return 0
	fi

	status="$?"
	if grep -Eiq 'no names found|cannot describe' "$stderr_path"; then
		rm -f "$stderr_path"
		return 0
	fi

	cat "$stderr_path" >&2
	rm -f "$stderr_path"
	return "$status"
}

# 显式起点出错时必须失败，避免发布说明悄悄改用错误范围。
validate_explicit_start_ref() {
	local start_ref="$1"

	if [[ -z "$start_ref" ]]; then
		return 0
	fi

	if ! git -C "$WORKSPACE_ROOT" rev-parse --verify "${start_ref}^{commit}" >/dev/null 2>&1; then
		echo "Release notes start ref does not exist: $start_ref" >&2
		return 1
	fi
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
	echo "Usage: $0 <release-version> [previous-tag-or-commit]" >&2
	exit 64
fi

release_version="$1"
positional_start_ref="${2:-}"
env_start_ref="${LINGLONG_RELEASE_NOTES_START_REF:-}"
explicit_start_ref="${positional_start_ref:-$env_start_ref}"
baseline_ref="$explicit_start_ref"

validate_explicit_start_ref "$explicit_start_ref"

if [[ -z "$baseline_ref" ]]; then
	baseline_ref="$(resolve_previous_release_ref)"
fi

dart_args=("$release_version")
if [[ -n "$baseline_ref" ]]; then
	dart_args+=("$baseline_ref")
fi

base_changelog_raw="$({
	bash "$ROOT_DIR/build/scripts/run-release-dart-tool.sh" "$ROOT_DIR/tool/release/generate_changelog.dart" "${dart_args[@]}"
})"

base_changelog="$(printf '%s\n' "$base_changelog_raw" | format_release_notes_markdown)"

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
