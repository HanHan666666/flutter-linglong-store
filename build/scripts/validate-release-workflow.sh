#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

require_grep() {
  local pattern="$1"
  local file="$2"

  if ! grep -Fq -- "$pattern" "$file"; then
    echo "Missing expected pattern '$pattern' in $file" >&2
    exit 1
  fi
}

require_no_grep() {
  local pattern="$1"
  local file="$2"

  if grep -Fq -- "$pattern" "$file"; then
    echo "Unexpected pattern '$pattern' found in $file" >&2
    exit 1
  fi
}

require_grep "workflow_dispatch" .github/workflows/release.yml
require_grep "contents: write" .github/workflows/release.yml
require_grep "ubuntu-24.04-arm" .github/workflows/release.yml
require_grep "always() && needs.build-amd64.result == 'success'" .github/workflows/release.yml
require_grep "needs.build-arm64.result != 'success' && needs.build-arm64-qemu.result == 'success'" .github/workflows/release.yml
require_grep "finalize-release-state" .github/workflows/release.yml
require_grep "Checkout repository for release note hashes" .github/workflows/release.yml
require_grep "Download versioned release files" .github/workflows/release.yml
require_grep "append-release-asset-hashes.sh" .github/workflows/release.yml
require_grep "normalize-release-assets.sh" .github/workflows/release.yml
require_grep "release-assets/hashes.sha256" .github/workflows/release.yml
require_grep "release-assets/*" .github/workflows/release.yml
require_no_grep "/home/han/flutter" .github/workflows/release.yml
require_grep "pull_request" .github/workflows/ci.yml
require_grep "release-cli-smoke-test.sh" .github/workflows/ci.yml
require_grep "nightly-cli-smoke-test.sh" .github/workflows/ci.yml
require_grep "schedule" .github/workflows/nightly.yml
require_grep "workflow_dispatch" .github/workflows/nightly.yml
require_grep "force_aur_publish" .github/workflows/nightly.yml
require_grep "aur_release_tag" .github/workflows/nightly.yml
require_grep "package-smoke-test.sh" .github/workflows/nightly.yml
require_grep "PACKAGE_CHANNEL: nightly" .github/workflows/nightly.yml
require_grep "nightly" .github/workflows/nightly.yml
require_grep "publish-aur-nightly:" .github/workflows/nightly.yml
require_grep "should_publish_release" .github/workflows/nightly.yml
require_grep "should_publish_aur" .github/workflows/nightly.yml
require_grep "aur_asset_source" .github/workflows/nightly.yml
require_grep "aur_nightly_label" .github/workflows/nightly.yml
require_grep "aur_nightly_tag" .github/workflows/nightly.yml
require_grep "previous_nightly_source_commit" .github/workflows/nightly.yml
require_grep "needs.prepare-nightly.outputs.should_publish_release == 'true'" .github/workflows/nightly.yml
require_grep "needs.prepare-nightly.outputs.should_publish_aur == 'true'" .github/workflows/nightly.yml
require_grep "generate-nightly-release-notes.sh" .github/workflows/nightly.yml
require_grep "append-release-asset-hashes.sh" .github/workflows/nightly.yml
require_grep "nightly-artifacts/hashes.sha256" .github/workflows/nightly.yml
require_grep "gh release download" .github/workflows/nightly.yml
require_grep "signed-nightly-assets-amd64" .github/workflows/nightly.yml
require_grep 'linglong-store-${{ needs.prepare-nightly.outputs.aur_nightly_label }}-linux-amd64.tar.gz' .github/workflows/nightly.yml
require_grep 'linglong-store-${{ needs.prepare-nightly.outputs.aur_nightly_label }}-linux-amd64.tar.gz.asc' .github/workflows/nightly.yml
require_grep "normalize-nightly-aur-version.sh" .github/workflows/nightly.yml
require_grep "render-packaging-templates.sh" .github/workflows/nightly.yml
require_grep "Render nightly AUR metadata with publish inputs" .github/workflows/nightly.yml
require_grep "validate-aur-package.sh" .github/workflows/nightly.yml
require_grep "publish-aur.sh" .github/workflows/nightly.yml
require_grep "linglong-store-nightly-bin" .github/workflows/nightly.yml
require_grep "ssh://aur@aur.archlinux.org/linglong-store-nightly-bin.git" .github/workflows/nightly.yml
require_grep "listReleases" .github/workflows/nightly.yml
require_grep 'PACKAGE_CHANNEL="${PACKAGE_CHANNEL:-stable}"' build/scripts/package-smoke-test.sh
require_grep '--channel "$PACKAGE_CHANNEL"' build/scripts/package-smoke-test.sh
require_grep "linglong-store-nightly.desktop" build/scripts/package-smoke-test.sh
require_grep "SHA256 Hashes of the release artifacts" build/scripts/release-cli-smoke-test.sh
require_grep "SHA256 Hashes of the release artifacts" build/scripts/nightly-cli-smoke-test.sh
require_grep "git diff --cached --quiet" build/scripts/publish-aur.sh
require_grep "Generating .SRCINFO requires makepkg or a Docker-based Arch Linux fallback" build/scripts/publish-aur.sh

echo "Release workflow validation passed."
