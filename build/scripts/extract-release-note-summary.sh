#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <release-notes-file>" >&2
  exit 64
fi

notes_file="$1"

if [[ ! -f "$notes_file" ]]; then
  echo "Release notes file does not exist: $notes_file" >&2
  exit 1
fi

summary="$({
  awk '
    /^## Release Notes$/ {
      in_notes = 1
      next
    }

    # Pi 可自行写段落与小标题；只有后续脚本添加的固定区块才结束正文。
    in_notes && /^## (Download|Requirements|Nightly Build)$/ {
      exit
    }

    in_notes {
      if (NF || started) {
        lines[++count] = $0
        if (NF) {
          started = 1
          last_content = count
        }
      }
    }

    END {
      if (!last_content) {
        exit 1
      }
      for (i = 1; i <= last_content; i++) {
        print lines[i]
      }
    }
  ' "$notes_file"
})"

printf '%s\n' "$summary"
