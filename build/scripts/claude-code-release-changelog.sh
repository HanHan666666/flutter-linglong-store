#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_ROOT="${LINGLONG_RELEASE_TOOL_ROOT:-$PWD}"
PROMPT_TEMPLATE_PATH="$ROOT_DIR/build/scripts/ai-release-notes-system-prompt.md"

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

if [[ ! -f "$PROMPT_TEMPLATE_PATH" ]]; then
  echo "Prompt template does not exist: $PROMPT_TEMPLATE_PATH" >&2
  exit 1
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
prompt_path="$tmp_dir/prompt.md"
raw_output_path="$tmp_dir/raw-output.txt"
docs_root_for_prompt="$ROOT_DIR/docs"

build_kind_for_prompt="release"
if [[ "$kind" == "nightly" ]]; then
  build_kind_for_prompt="nightly"
fi

baseline_ref_display="${baseline_ref:-<none>}"

# 渲染 release notes 任务提示词，避免把临时起点规则写死在 prompt 里。
render_prompt_template() {
  local rendered_prompt=""

  rendered_prompt="$(cat "$PROMPT_TEMPLATE_PATH")"
  rendered_prompt="${rendered_prompt//\{\{RELEASE_VERSION\}\}/$release_version}"
  rendered_prompt="${rendered_prompt//\{\{BUILD_KIND\}\}/$build_kind_for_prompt}"
  rendered_prompt="${rendered_prompt//\{\{BASELINE_REF\}\}/$baseline_ref_display}"
  rendered_prompt="${rendered_prompt//\{\{WORKSPACE_ROOT\}\}/$WORKSPACE_ROOT}"
  rendered_prompt="${rendered_prompt//\{\{DOCS_ROOT\}\}/$docs_root_for_prompt}"

  printf '%s' "$rendered_prompt"
}

# 输出给 Claude 的提交列表，只保留范围内的 hash 与标题，避免大段日志诱导复述。
render_commit_summary() {
  if [[ -n "$baseline_ref" ]] && git -C "$WORKSPACE_ROOT" rev-parse --verify "${baseline_ref}^{commit}" >/dev/null 2>&1; then
    git -C "$WORKSPACE_ROOT" log --reverse --format='commit %H%nsubject: %s%n---' "${baseline_ref}..HEAD"
  else
    git -C "$WORKSPACE_ROOT" log --reverse -n 40 --format='commit %H%nsubject: %s%n---'
  fi
}

# 输出每个提交触达的文件，帮助 Claude 识别“同一功能链路”而不是逐条复述提交。
render_changed_files_by_commit() {
  local commit_hash=""
  local commit_subject=""

  if [[ -n "$baseline_ref" ]] && git -C "$WORKSPACE_ROOT" rev-parse --verify "${baseline_ref}^{commit}" >/dev/null 2>&1; then
    git -C "$WORKSPACE_ROOT" log --reverse --format='%H%x1f%s' "${baseline_ref}..HEAD"
  else
    git -C "$WORKSPACE_ROOT" log --reverse -n 40 --format='%H%x1f%s'
  fi | while IFS=$'\x1f' read -r commit_hash commit_subject; do
    [[ -z "$commit_hash" ]] && continue
    printf '### %s\n' "$commit_hash"
    printf 'subject: %s\n' "$commit_subject"
    printf 'files:\n'
    git -C "$WORKSPACE_ROOT" diff-tree --no-commit-id --name-only -r "$commit_hash" \
      | sed 's/^/- /'
    printf '\n'
  done
}

# 摘录范围内改动过的业务文档，最多取少量文件，避免上下文膨胀拖慢 CI。
render_changed_docs_excerpts() {
  local docs_count="0"
  local doc_path=""

  if [[ -z "$baseline_ref" ]] || ! git -C "$WORKSPACE_ROOT" rev-parse --verify "${baseline_ref}^{commit}" >/dev/null 2>&1; then
    printf 'No explicit docs range is available.\n'
    return 0
  fi

  while IFS= read -r doc_path; do
    [[ -z "$doc_path" ]] && continue
    [[ ! -f "$WORKSPACE_ROOT/$doc_path" ]] && continue

    docs_count="$((docs_count + 1))"
    if [[ "$docs_count" -gt 4 ]]; then
      break
    fi

    printf '### %s\n' "$doc_path"
    sed -n '1,120p' "$WORKSPACE_ROOT/$doc_path"
    printf '\n'
  done < <(
    git -C "$WORKSPACE_ROOT" diff --name-only "${baseline_ref}..HEAD" -- 'docs/*.md' 'docs/**/*.md' \
      | sort
  )

  if [[ "$docs_count" == "0" ]]; then
    printf 'No docs markdown files changed in this range.\n'
  fi
}

range_args=()
if [[ -n "$baseline_ref" ]] && git -C "$WORKSPACE_ROOT" rev-parse --verify "${baseline_ref}^{commit}" >/dev/null 2>&1; then
  range_args=("${baseline_ref}..HEAD")
fi

cat > "$context_path" <<EOF
# Release Notes Context

Kind: $build_kind_for_prompt
Target version: $release_version
Start ref: $baseline_ref_display
End ref: HEAD
Range: ${range_args[*]:-last 40 commits}

## Candidate commits

$(render_commit_summary)

## Changed files by commit

$(render_changed_files_by_commit)

## Changed docs excerpts

$(render_changed_docs_excerpts)
EOF

render_prompt_template > "$prompt_path"

if grep -Fq '{{' "$prompt_path"; then
  echo "Prompt template rendering failed: unresolved placeholders remain in $prompt_path" >&2
  exit 1
fi

(
  cd "$WORKSPACE_ROOT"
  cat "$context_path" | "$claude_bin" -p \
    --bare \
    --setting-sources user \
    --tools "" \
    --max-turns 1 \
    --no-session-persistence \
    --append-system-prompt-file "$prompt_path" \
    "请根据输入中的 release notes 范围和候选变更，为版本 ${release_version}（${build_kind_for_prompt}）生成最终的 JSON 更新日志条目。"
) > "$raw_output_path"

# 尝试从 Claude 原始输出中提取 {"items":[...]}，兼容纯 JSON 和 JSON envelope。
try_extract_items_json_from_text() {
  local raw_text="$1"
  local cleaned_text=""

  cleaned_text="$(printf '%s' "$raw_text" | sed -e '/^```json$/d' -e '/^```[[:alnum:]]*$/d' -e '/^```$/d')"
  if printf '%s' "$cleaned_text" | jq -e 'type == "object" and (.items | type == "array")' >/dev/null 2>&1; then
    printf '%s' "$cleaned_text" | jq -c '{items: .items}'
    return 0
  fi

  return 1
}

# 提取结构化条目，不能解析时返回失败并触发上层 deterministic fallback。
extract_release_notes_items_json() {
  local raw_path="$1"
  local extracted=""
  local raw_content=""

  raw_content="$(cat "$raw_path")"
  if try_extract_items_json_from_text "$raw_content"; then
    return 0
  fi

  if extracted="$(jq -er '.result // empty' "$raw_path" 2>/dev/null)" \
    && try_extract_items_json_from_text "$extracted"; then
    return 0
  fi

  if extracted="$(jq -cer '.structured_output // empty' "$raw_path" 2>/dev/null)" \
    && try_extract_items_json_from_text "$extracted"; then
    return 0
  fi

  if extracted="$(jq -cer '.release_notes // empty' "$raw_path" 2>/dev/null)" \
    && try_extract_items_json_from_text "$extracted"; then
    return 0
  fi

  return 1
}

# 校验 JSON 条目，避免维护项、编号和 Markdown 污染最终发布说明。
validate_release_notes_items_json() {
  local candidate_path="$1"

  jq -e '
    type == "object"
    and (.items | type == "array")
    and (.items | length <= 5)
    and all(.items[]; (
      (.kind == "新增" or .kind == "修复")
      and (.text | type == "string")
      and (.text | length > 0)
      and (.text | length <= 120)
      and ((.text | test("[\r\n#]")) | not)
      and ((.text | test("^(新增|修复)[：:]")) | not)
      and ((.text | test("^[0-9０-９]+[、.]")) | not)
      and ((.text | test("(AI|prompt|Prompt|commit|Git|git|CI|workflow|Workflow|AUR|UOS|AGENTS|CLAUDE|文档|测试|重构|打包|发布流程|工具链|脚本|注释规范|哈希|签名)")) | not)
    ))
  ' "$candidate_path" >/dev/null
}

# 只有脚本负责 Markdown 编号，避免模型再次生成 0 起始列表。
render_release_notes_markdown_from_items_json() {
  local candidate_path="$1"
  local item_count=""

  item_count="$(jq '.items | length' "$candidate_path")"
  printf '## Release Notes\n\n'

  if [[ "$item_count" == "0" ]]; then
    printf '1、本次版本暂无需要特别说明的功能新增或问题修复。'
    return 0
  fi

  jq -r '.items | to_entries[] | "\(.key + 1)、\(.value.kind)：\(.value.text)"' "$candidate_path"
}

candidate_path="$tmp_dir/release-notes-items.json"
extract_release_notes_items_json "$raw_output_path" > "$candidate_path"
validate_release_notes_items_json "$candidate_path"
render_release_notes_markdown_from_items_json "$candidate_path"
