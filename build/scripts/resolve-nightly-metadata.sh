#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

base_version="$(sed -n 's/^version: //p' "$ROOT_DIR/pubspec.yaml" | head -n1 | cut -d+ -f1)"
if [[ -z "$base_version" ]]; then
  echo "Failed to resolve base version from pubspec.yaml" >&2
  exit 1
fi

short_sha="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
if [[ -z "$short_sha" ]]; then
  echo "Failed to resolve current git SHA" >&2
  exit 1
fi

nightly_date="$(TZ=Asia/Shanghai date +%Y%m%d)"
nightly_label="${base_version}-nightly.${nightly_date}+${short_sha}"

printf "base_version=%q\n" "$base_version"
printf "nightly_date=%q\n" "$nightly_date"
printf "short_sha=%q\n" "$short_sha"
printf "nightly_label=%q\n" "$nightly_label"
