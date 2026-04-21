#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

nightly_label=""
nightly_date=""
source_commit=""
previous_source_commit=""
output_path=""

render_fallback_changelog() {
  cat <<'EOF'
## Release Notes

这是首个 Nightly Release，后续 Nightly 将从上一版 Nightly source commit 自动生成变更日志。
EOF
}

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
    --previous-source-commit)
      previous_source_commit="$2"
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
  echo "Usage: generate-nightly-release-notes.sh --nightly-label <label> --nightly-date <YYYYMMDD> --source-commit <sha> [--previous-source-commit <sha>] --output <path>" >&2
  exit 64
fi

current_head="$(git -C "$PWD" rev-parse HEAD)"
if [[ "$current_head" != "$source_commit" ]]; then
  echo "Expected current HEAD ($current_head) to match --source-commit ($source_commit)." >&2
  exit 1
fi

mkdir -p "$(dirname "$output_path")"

if [[ -n "$previous_source_commit" ]]; then
  # release body 里的历史 SHA 可能被人工编辑或因历史改写失效；不可用时降级为首版文案而不是直接炸掉 nightly。
  if git -C "$PWD" rev-parse --verify "${previous_source_commit}^{commit}" >/dev/null 2>&1 \
    && git -C "$PWD" merge-base --is-ancestor "$previous_source_commit" HEAD; then
    # 直接复用正式 release 的 Dart 生成器，同时把 git 上下文显式绑定到当前仓库目录。
    changelog_content="$({
      LINGLONG_RELEASE_TOOL_ROOT="$PWD" \
        bash "$ROOT_DIR/build/scripts/run-release-dart-tool.sh" \
        "$ROOT_DIR/tool/release/generate_changelog.dart" \
        "$nightly_label" \
        "$previous_source_commit"
    })"
  else
    changelog_content="$(render_fallback_changelog)"
  fi
else
  changelog_content="$(render_fallback_changelog)"
fi

cat > "$output_path" <<EOF
$changelog_content

## Nightly Build

- Version label: $nightly_label
- Architecture: amd64, arm64

## Download
- amd64: bundle / deb / rpm / AppImage
- arm64: bundle / deb / rpm / AppImage

## Requirements
- Linux
- GTK 3
- 玲珑运行环境

Nightly source commit: $source_commit
Nightly source date: $nightly_date
Nightly version label: $nightly_label
EOF
