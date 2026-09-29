#!/usr/bin/env bash
# 在指定源码树运行 Pi，使模型可核对提交、代码与文档，并生成自由格式的发布说明。
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
release_version=""
kind=""
workspace=""
baseline_ref=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release-version) release_version="$2"; shift 2 ;;
    --kind) kind="$2"; shift 2 ;;
    --workspace) workspace="$2"; shift 2 ;;
    --baseline-ref) baseline_ref="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 64 ;;
  esac
done

if [[ -z "$release_version" || -z "$kind" || -z "$workspace" ]]; then
  echo "Missing Pi release notes context." >&2
  exit 64
fi

if [[ -z "${DEEPSEEK_API_KEY:-}" ]]; then
  echo "DEEPSEEK_API_KEY is required for Pi release notes." >&2
  exit 1
fi

pi_bin="$(bash "$ROOT_DIR/build/scripts/install-pi-agent.sh")"
source_commit="$(git -C "$workspace" rev-parse HEAD)"
prompt="$(cat "$ROOT_DIR/build/scripts/pi-release-notes-prompt.md")"
prompt+=$'\n\n'
prompt+="版本：$release_version"$'\n'
prompt+="类型：$kind"$'\n'
prompt+="起点：${baseline_ref:-仓库初始提交}"$'\n'
prompt+="终点：$source_commit"$'\n'
prompt+="源码目录：$workspace"

cd "$workspace"

# 保留 Pi 默认的 read/bash/edit/write 工具；结果仅要求有正文，格式由模型决定。
notes="$("$pi_bin" --print --approve --no-session --provider deepseek --model deepseek-flash -- "$prompt")"
if [[ -z "${notes//[[:space:]]/}" ]]; then
  echo "Pi returned empty release notes for $release_version." >&2
  exit 1
fi

printf '## Release Notes\n\n%s\n' "$notes"
