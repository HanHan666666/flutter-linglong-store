#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT_DIR"

exec bash "$ROOT_DIR/build/scripts/run-release-dart-tool.sh" tool/release/generate_changelog.dart "$@"
