#!/usr/bin/env bash
set -euo pipefail

notes_file=""

usage() {
  cat >&2 <<'EOF'
Usage: augment-nightly-release-notes-loong64.sh --notes-file <path>
EOF
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --notes-file)
      notes_file="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$notes_file" ]]; then
  usage
fi

if [[ ! -f "$notes_file" ]]; then
  echo "Nightly release notes file does not exist: $notes_file" >&2
  exit 1
fi

python3 - "$notes_file" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
lines = path.read_text(encoding='utf-8').splitlines()

try:
    nightly_index = lines.index('## Nightly Build')
    download_index = lines.index('## Download')
except ValueError as exc:
    raise SystemExit(f'Missing expected nightly release notes section: {exc}')

requirements_index = None
for idx in range(download_index + 1, len(lines)):
    if lines[idx].startswith('## '):
        requirements_index = idx
        break

if requirements_index is None:
    requirements_index = len(lines)

architecture_updated = False
for idx in range(nightly_index + 1, download_index):
    if lines[idx].startswith('- Architecture:'):
        if 'loong64' not in lines[idx]:
            lines[idx] = f"{lines[idx]}, loong64"
        architecture_updated = True
        break

if not architecture_updated:
    insert_at = download_index
    for idx in range(nightly_index + 1, download_index):
        if lines[idx].startswith('- Version label:'):
            insert_at = idx + 1
            break
    lines.insert(insert_at, '- Architecture: loong64')
    download_index += 1
    requirements_index += 1

if not any(line.startswith('- loong64:') for line in lines[download_index + 1:requirements_index]):
    insert_at = requirements_index
    for idx in range(download_index + 1, requirements_index):
        if lines[idx].startswith('- arm64:'):
            insert_at = idx + 1
            break
    lines.insert(insert_at, '- loong64: bundle / deb')

path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
PY
