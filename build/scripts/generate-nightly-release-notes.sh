#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

nightly_label=""
nightly_date=""
source_commit=""
output_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --nightly-label)
      nightly_label="$2"
      shift 2
      ;;
    --nightly-date)
      nightly_date="$2"
      shift 2
      ;;
    --source-commit)
      source_commit="$2"
      shift 2
      ;;
    --output)
      output_path="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

# 强制要求显式输入，避免 workflow 或本地脚本默默回退到错误上下文。
if [[ -z "$nightly_label" || -z "$nightly_date" || -z "$source_commit" || -z "$output_path" ]]; then
  echo "Usage: generate-nightly-release-notes.sh --nightly-label <label> --nightly-date <YYYYMMDD> --source-commit <sha> --output <path>" >&2
  exit 64
fi

current_head="$(git -C "$PWD" rev-parse HEAD)"
if [[ "$current_head" != "$source_commit" ]]; then
  echo "Expected current HEAD ($current_head) to match --source-commit ($source_commit)." >&2
  exit 1
fi

mkdir -p "$(dirname "$output_path")"

# 月度 Release 反复覆盖说明，因此起点固定为当前 HEAD 可达的最近正式版，展示累计变化。
stable_baseline="$(git -C "$PWD" describe \
  --tags --abbrev=0 --first-parent --match 'v[0-9]*.[0-9]*.[0-9]*' HEAD)"
changelog_content="$({
  LINGLONG_CHANGELOG_CONTEXT_KIND=nightly \
  LINGLONG_RELEASE_TOOL_ROOT="$PWD" \
    bash "$ROOT_DIR/build/scripts/generate-changelog.sh" \
    "$nightly_label" \
    "$stable_baseline"
})"

cat > "$output_path" <<EOF
$changelog_content

## Nightly Build

- Version label: $nightly_label
- Architecture: amd64, arm64

## Download
- amd64: bundle / deb / rpm / AppImage
- arm64: bundle / deb / rpm / AppImage
- Arch Linux (AUR):

  \`paru -S linglong-store-nightly-bin\`

  或者

  \`yay -S linglong-store-nightly-bin\`

## Requirements
- Linux
- GTK 3
- 玲珑运行环境

Nightly source commit: $source_commit
Nightly source date: $nightly_date
Nightly version label: $nightly_label
EOF
