#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_ROOT="${LINGLONG_RELEASE_TOOL_ROOT:-$PWD}"

release_version=""
baseline_ref=""
kind="stable"
base_changelog_file=""

usage() {
  echo "Usage: $0 --release-version <version> --base-changelog-file <path> [--kind stable|nightly] [--baseline-ref <ref>]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release-version)
      release_version="$2"
      shift 2
      ;;
    --baseline-ref)
      baseline_ref="$2"
      shift 2
      ;;
    --kind)
      kind="$2"
      shift 2
      ;;
    --base-changelog-file)
      base_changelog_file="$2"
      shift 2
      ;;
    *)
      usage
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

if [[ -z "$release_version" || -z "$base_changelog_file" ]]; then
  usage
  exit 64
fi

if [[ ! -f "$base_changelog_file" ]]; then
  echo "Base changelog file does not exist: $base_changelog_file" >&2
  exit 1
fi

if [[ -z "${CLAUDE_CODE_SETTINGS_JSON:-}" ]]; then
  echo "CLAUDE_CODE_SETTINGS_JSON is required for Claude changelog generation." >&2
  exit 1
fi

home_dir="${HOME:-}"
cleanup_home="0"
if [[ -z "$home_dir" ]]; then
  home_dir="$(mktemp -d "${TMPDIR:-/tmp}/linglong-claude-home.XXXXXX")"
  cleanup_home="1"
fi
export HOME="$home_dir"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/linglong-claude-run.XXXXXX")"
cleanup() {
  rm -rf "$tmp_dir"
  if [[ "$cleanup_home" == "1" ]]; then
    rm -rf "$home_dir"
  fi
}

trap cleanup EXIT

install -d -m 700 "$HOME/.claude"
settings_path="$HOME/.claude/settings.json"
printf '%s' "$CLAUDE_CODE_SETTINGS_JSON" > "$settings_path"
chmod 600 "$settings_path"
jq -e . "$settings_path" >/dev/null

claude_bin="$({ bash "$ROOT_DIR/build/scripts/install-claude-code.sh"; })"

context_path="$tmp_dir/context.txt"
prompt_path="$tmp_dir/prompt.txt"
raw_output_path="$tmp_dir/raw-output.txt"

range_args=()
if [[ -n "$baseline_ref" ]] && git -C "$WORKSPACE_ROOT" rev-parse --verify "${baseline_ref}^{commit}" >/dev/null 2>&1; then
  range_args=("${baseline_ref}..HEAD")
fi

git_log_output=""
if [[ "${#range_args[@]}" -gt 0 ]]; then
  git_log_output="$({
    git -C "$WORKSPACE_ROOT" log --format='commit %H%nsubject: %s%nbody:%n%b%n---' "${range_args[@]}"
  })"
else
  git_log_output="$({
    git -C "$WORKSPACE_ROOT" log -n 40 --format='commit %H%nsubject: %s%nbody:%n%b%n---'
  })"
fi

cat > "$context_path" <<EOF
# Release Notes Context

Kind: $kind
Target version: $release_version
Baseline ref: ${baseline_ref:-<none>}

## Existing deterministic changelog

$(cat "$base_changelog_file")

## Workflow constraints

$(sed -n '1,220p' "$ROOT_DIR/docs/12-github-workflow-maintenance.md")

## Project summary

$(sed -n '1,120p' "$ROOT_DIR/README.md")

## Commit log

$git_log_output
EOF

cat > "$prompt_path" <<EOF
You are writing the GitHub Release changelog section for the flutter-linglong-store project.

Requirements:
- Respond in Simplified Chinese.
- Use only the information from the provided context document.
- Output Markdown only.
- The first line must be exactly: ## Release Notes
- Keep the output focused on the changelog section only.
- Do not include download instructions, requirements, nightly metadata lines, hashes, signatures, or any text outside the changelog section.
- Do not mention AI, prompts, or the existence of the context bundle.
- Prefer concise, user-facing summaries. Do not invent features or claims not supported by the context.
EOF

cat "$context_path" | "$claude_bin" -p \
  --bare \
  --setting-sources user \
  --tools "" \
  --max-turns 1 \
  --no-session-persistence \
  --append-system-prompt-file "$prompt_path" \
  "Generate the final Markdown changelog section for version ${release_version}." > "$raw_output_path"

extract_release_notes_markdown() {
  local raw_path="$1"
  local extracted=""

  if extracted="$(jq -er '.release_notes_markdown' "$raw_path" 2>/dev/null)"; then
    printf '%s' "$extracted"
    return 0
  fi

  if extracted="$(jq -er '.structured_output.release_notes_markdown' "$raw_path" 2>/dev/null)"; then
    printf '%s' "$extracted"
    return 0
  fi

  if extracted="$(jq -er '.result.structured_output.release_notes_markdown' "$raw_path" 2>/dev/null)"; then
    printf '%s' "$extracted"
    return 0
  fi

  extracted="$(cat "$raw_path")"
  if [[ "$extracted" == '```'* ]]; then
    extracted="$(printf '%s' "$extracted" | sed -e '/^```[[:alnum:]]*$/d' -e '/^```$/d')"
  fi

  if [[ "$extracted" == '## Release Notes'* ]]; then
    printf '%s' "$extracted"
    return 0
  fi

  return 1
}

validate_release_notes_markdown() {
  local candidate_path="$1"
  local first_line=""

  first_line="$(sed -n '1p' "$candidate_path")"
  if [[ "$first_line" != "## Release Notes" ]]; then
    return 1
  fi

  if grep -Fq '## SHA256 Hashes of the release artifacts' "$candidate_path"; then
    return 1
  fi

  if grep -Fq 'Nightly source commit:' "$candidate_path"; then
    return 1
  fi

  if grep -Fq 'Nightly source date:' "$candidate_path"; then
    return 1
  fi

  if grep -Fq 'Nightly version label:' "$candidate_path"; then
    return 1
  fi

  return 0
}

candidate_path="$tmp_dir/release-notes.md"
extract_release_notes_markdown "$raw_output_path" > "$candidate_path"
validate_release_notes_markdown "$candidate_path"
printf '%s' "$(cat "$candidate_path")"