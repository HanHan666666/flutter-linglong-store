#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Test template rendering
echo "=== Testing AUR template rendering ==="

temp_dir="$(mktemp -d)"
trap "rm -rf $temp_dir" EXIT

# Test with dummy SHA256
bash "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
  --inner \
  --version "3.0.7" \
  --arch amd64 \
  --output-dir "$temp_dir" \
  --sha256-amd64 "dummy_amd64_sha256" \
  --sha256-arm64 "dummy_arm64_sha256"

echo ""
echo "=== Rendered files ==="
ls -la "$temp_dir/aur/"

echo ""
echo "=== PKGBUILD content (first 30 lines) ==="
head -30 "$temp_dir/aur/PKGBUILD"

echo ""
echo "=== .install content ==="
cat "$temp_dir/aur/linglong-store-bin.install"

echo ""
echo "=== .changelog content ==="
cat "$temp_dir/aur/linglong-store-bin.changelog"

echo ""
echo "=== Validation complete ==="
