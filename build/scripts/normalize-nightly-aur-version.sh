#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <nightly-version>" >&2
  exit 64
fi

nightly_version="$1"
if [[ -z "$nightly_version" ]]; then
  echo "Nightly version must not be empty." >&2
  exit 64
fi

if [[ ! "$nightly_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+-nightly\.[0-9]{8}\+[0-9A-Fa-f]+$ ]]; then
  echo "Nightly version must match <semver>-nightly.<YYYYMMDD>+<sha>." >&2
  exit 64
fi

normalized_version="${nightly_version/-nightly./_nightly.}"
normalized_version="${normalized_version//+/.}"

printf '%s\n' "$normalized_version"
