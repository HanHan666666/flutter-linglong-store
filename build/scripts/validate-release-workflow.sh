#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

require_grep() {
  local pattern="$1"
  local file="$2"

  if ! grep -Fq "$pattern" "$file"; then
    echo "Missing expected pattern '$pattern' in $file" >&2
    exit 1
  fi
}

require_grep "workflow_dispatch" .github/workflows/release.yml
require_grep "contents: write" .github/workflows/release.yml
require_grep "ubuntu-24.04-arm" .github/workflows/release.yml
require_grep "always() && needs.build-amd64.result == 'success'" .github/workflows/release.yml
require_grep "needs.build-arm64.result != 'success' && needs.build-arm64-qemu.result == 'success'" .github/workflows/release.yml
require_grep "pull_request" .github/workflows/ci.yml
require_grep "amd64" .github/workflows/ci.yml
require_grep "release-cli-smoke-test.sh" .github/workflows/ci.yml
require_grep "package-smoke-test.sh" .github/workflows/ci.yml

echo "Release workflow validation passed."
