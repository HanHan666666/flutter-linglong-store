#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

release_version=""
channel="stable"
package_name=""
aur_version=""
target_arch="x86_64"
aur_repo_url=""

# SHA256 checksums from environment (set by CI)
sha256_amd64="${SHA256_AMD64:-}"
sha256_arm64="${SHA256_ARM64:-}"
sha256_sig_amd64="${SHA256_SIG_AMD64:-}"
sha256_sig_arm64="${SHA256_SIG_ARM64:-}"
gpg_key_id="${GPG_KEY_ID:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      release_version="$2"
      shift 2
      ;;
    --channel)
      channel="$2"
      shift 2
      ;;
    --package-name)
      package_name="$2"
      shift 2
      ;;
    --repo-url)
      aur_repo_url="$2"
      shift 2
      ;;
    --aur-version)
      aur_version="$2"
      shift 2
      ;;
    --arch)
      target_arch="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 --version <version> [--channel stable|nightly] [--package-name <pkgname>] [--repo-url <url>] [--aur-version <pkgver>] [--arch x86_64|aarch64]" >&2
      exit 64
      ;;
  esac
done

if [[ -z "$release_version" ]]; then
  echo "--version is required." >&2
  exit 64
fi

case "$channel" in
  stable)
    : "${package_name:=linglong-store-bin}"
    : "${aur_version:=$release_version}"
    ;;
  nightly)
    : "${package_name:=linglong-store-nightly-bin}"
    if [[ -z "$aur_version" ]]; then
      aur_version="$(bash "$ROOT_DIR/build/scripts/normalize-nightly-aur-version.sh" "$release_version")"
    fi
    ;;
  *)
    echo "Unsupported channel: $channel" >&2
    exit 64
    ;;
esac

if [[ -z "$aur_repo_url" ]]; then
  aur_repo_url="ssh://aur@aur.archlinux.org/${package_name}.git"
fi

# Map architecture names
case "$target_arch" in
  amd64|x86_64)
    target_arch="x86_64"
    ;;
  arm64|aarch64)
    target_arch="aarch64"
    ;;
  *)
    echo "Unsupported architecture: $target_arch" >&2
    exit 64
    ;;
esac

# Validate SHA256 checksums
if [[ -z "$sha256_amd64" || -z "$sha256_sig_amd64" ]]; then
  echo "Error: SHA256_AMD64 and SHA256_SIG_AMD64 environment variables are required" >&2
  exit 1
fi

if [[ "$channel" == "stable" && ( -z "$sha256_arm64" || -z "$sha256_sig_arm64" ) ]]; then
  echo "Error: stable AUR publishing requires SHA256_ARM64 and SHA256_SIG_ARM64" >&2
  exit 1
fi

if [[ "$channel" == "nightly" && "$target_arch" != "x86_64" ]]; then
  echo "Nightly AUR publishing only supports the x86_64 package set." >&2
  exit 64
fi

# Setup SSH for AUR
setup_aur_ssh() {
  if [[ -n "${AUR_SSH_PRIVATE_KEY:-}" ]]; then
    mkdir -p ~/.ssh
    echo "$AUR_SSH_PRIVATE_KEY" > ~/.ssh/aur_key
    chmod 600 ~/.ssh/aur_key
    cat >> ~/.ssh/config <<EOF
Host aur.archlinux.org
  IdentityFile ~/.ssh/aur_key
  User aur
EOF
    chmod 600 ~/.ssh/config
    ssh-keyscan aur.archlinux.org >> ~/.ssh/known_hosts 2>/dev/null
  fi
}

# Update AUR repository
update_aur_repo() {
  local version="$1"
  local work_dir
  local desktop_filename
  local changelog_filename
  local rendered_pkgver
  work_dir="$(mktemp -d)"

  echo "Cloning AUR repository..."
  git clone --depth 1 "$aur_repo_url" "$work_dir"

  cd "$work_dir"

  # Render templates
  local metadata_dir
  metadata_dir="$(mktemp -d)"

  SHA256_AMD64="$sha256_amd64" \
  SHA256_ARM64="$sha256_arm64" \
  SHA256_SIG_AMD64="$sha256_sig_amd64" \
  SHA256_SIG_ARM64="$sha256_sig_arm64" \
  GPG_KEY_ID="$gpg_key_id" \
  "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
    --inner \
    --version "$version" \
    --arch "amd64" \
    --output-dir "$metadata_dir" \
    --channel "$channel" \
    --sha256-amd64 "$sha256_amd64" \
    --sha256-arm64 "$sha256_arm64" \
    --sha256-sig-amd64 "$sha256_sig_amd64" \
    --sha256-sig-arm64 "$sha256_sig_arm64" \
    --gpg-key-id "$gpg_key_id"

  rendered_pkgver="$(sed -n 's/^pkgver=//p' "$metadata_dir/aur/PKGBUILD")"
  if [[ "$rendered_pkgver" != "$aur_version" ]]; then
    echo "Rendered PKGBUILD pkgver $rendered_pkgver did not match expected AUR version $aur_version." >&2
    exit 1
  fi

  mapfile -t rendered_desktop_files < <(find "$metadata_dir/aur" -maxdepth 1 -type f -name '*.desktop' | sort)
  if [[ "${#rendered_desktop_files[@]}" -ne 1 ]]; then
    echo "Expected exactly one rendered AUR desktop file in $metadata_dir/aur, found ${#rendered_desktop_files[@]}" >&2
    exit 1
  fi

  desktop_filename="$(basename "${rendered_desktop_files[0]}")"

  mapfile -t rendered_changelog_files < <(find "$metadata_dir/aur" -maxdepth 1 -type f -name '*.changelog' | sort)
  if [[ "${#rendered_changelog_files[@]}" -ne 1 ]]; then
    echo "Expected exactly one rendered AUR changelog file in $metadata_dir/aur, found ${#rendered_changelog_files[@]}" >&2
    exit 1
  fi

  changelog_filename="$(basename "${rendered_changelog_files[0]}")"

  # Copy rendered AUR files.
  cp "$metadata_dir/aur/PKGBUILD" PKGBUILD
  cp "$metadata_dir/aur/$changelog_filename" "$changelog_filename"
  cp "$metadata_dir/aur/LICENSE" LICENSE
  cp "$metadata_dir/aur/$desktop_filename" "$desktop_filename"
  cp "$metadata_dir/aur/linglong-store.metainfo.xml" linglong-store.metainfo.xml
  cp "$metadata_dir/aur/linglong-store.svg" linglong-store.svg

  # Generate .SRCINFO
  makepkg --printsrcinfo > .SRCINFO

  # Validate with namcap if available
  if command -v namcap &>/dev/null; then
    echo "Running namcap validation..."
    namcap PKGBUILD || true
  fi

  # Commit and push
  git add PKGBUILD .SRCINFO "$changelog_filename" LICENSE "$desktop_filename" linglong-store.metainfo.xml linglong-store.svg
  git -c user.name="HanHan666666" -c user.email="tar.zip@outlook.com" commit -m "Update to version $aur_version"
  git push origin master

  echo "AUR package updated to version $aur_version"

  # Cleanup
  cd /
  rm -rf "$work_dir" "$metadata_dir"
  rm -f ~/.ssh/aur_key
}

main() {
  setup_aur_ssh
  update_aur_repo "$release_version"
}

main
