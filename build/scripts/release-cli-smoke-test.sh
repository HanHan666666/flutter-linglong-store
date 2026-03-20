#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

version_output="$(bash build/scripts/resolve-release-version.sh)"
version_output="${version_output//$'\n'/}"

if [[ ! "$version_output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Expected a clean semver from resolve-release-version.sh, got: $version_output" >&2
  exit 1
fi

changelog_output="$(bash build/scripts/generate-changelog.sh "$version_output")"
first_line="$(printf '%s\n' "$changelog_output" | sed -n '1p')"

if [[ "$first_line" != "## Release Notes" ]]; then
  echo "Expected generate-changelog.sh to start with release notes header, got: $first_line" >&2
  exit 1
fi

echo "Release CLI smoke test passed."
