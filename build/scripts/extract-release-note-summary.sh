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
    BEGIN {
      in_notes = 0
      line_count = 0
    }

    /^## Release Notes$/ {
      in_notes = 1
      next
    }

    in_notes && /^## / {
      exit
    }

    in_notes && /^[0-9]+、/ {
      print
      line_count++
    }

    END {
      if (line_count == 0) {
        exit 1
      }
    }
  ' "$notes_file"
})"

printf '%s\n' "$summary"