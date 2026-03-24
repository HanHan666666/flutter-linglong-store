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
aur_srcinfo_container_image="${AUR_SRCINFO_CONTAINER_IMAGE:-archlinux:latest}"

extract_repo_name() {
  local repo_url="$1"
  local repo_basename=""

  repo_basename="${repo_url##*/}"
  if [[ "$repo_basename" == "$repo_url" ]]; then
    repo_basename="${repo_url##*:}"
  fi

  repo_basename="${repo_basename%.git}"
  printf '%s\n' "$repo_basename"
}

generate_srcinfo() {
  local repo_dir="$1"

  if command -v makepkg >/dev/null 2>&1; then
    (
      cd "$repo_dir"
      makepkg --printsrcinfo > .SRCINFO
    )
    return 0
  fi

  if ! command -v docker >/dev/null 2>&1; then
    echo "Generating .SRCINFO requires makepkg or a Docker-based Arch Linux fallback." >&2
    exit 1
  fi

  # GitHub's Ubuntu runners do not ship makepkg, so fall back to a short-lived
  # Arch container to keep AUR metadata generation consistent with validation.
  docker run --rm \
    -v "$repo_dir:/aur" \
    -w /aur \
    "$aur_srcinfo_container_image" \
    /bin/bash -lc '
      set -euo pipefail
      pacman -Sy --noconfirm --needed base-devel >/dev/null
      useradd -m builder >/dev/null 2>&1 || true
      work_dir="$(mktemp -d)"
      trap "rm -rf \"$work_dir\"" EXIT
      cp -a /aur/. "$work_dir/"
      chown -R builder:builder "$work_dir"
      runuser -u builder -- /bin/bash -lc "cd \"$work_dir\" && makepkg --printsrcinfo > .SRCINFO"
      install -m 644 "$work_dir/.SRCINFO" /aur/.SRCINFO
      chown --reference=/aur/PKGBUILD /aur/.SRCINFO
    '
}

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
  (
    local work_dir
    local metadata_dir=""
    local desktop_filename
    local changelog_filename
    local rendered_pkgname
    local rendered_pkgver
    local repo_name
    work_dir="$(mktemp -d)"
    trap 'cd /; rm -rf "$work_dir" "$metadata_dir"; rm -f ~/.ssh/aur_key' EXIT

    repo_name="$(extract_repo_name "$aur_repo_url")"
    if [[ "$repo_name" != "$package_name" ]]; then
      echo "AUR repo ${repo_name} does not match package name ${package_name}." >&2
      exit 64
    fi

    echo "Cloning AUR repository..."
    git clone --depth 1 "$aur_repo_url" "$work_dir"

    cd "$work_dir"

    # Render templates
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

    rendered_pkgname="$(sed -n 's/^pkgname=//p' "$metadata_dir/aur/PKGBUILD")"
    if [[ "$rendered_pkgname" != "$package_name" ]]; then
      echo "Rendered PKGBUILD pkgname $rendered_pkgname did not match expected package name $package_name." >&2
      exit 1
    fi

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

    find . -maxdepth 1 -type f -name '*.desktop' ! -name "$desktop_filename" -delete
    find . -maxdepth 1 -type f -name '*.changelog' ! -name "$changelog_filename" -delete

    # Copy rendered AUR files.
    cp "$metadata_dir/aur/PKGBUILD" PKGBUILD
    cp "$metadata_dir/aur/$changelog_filename" "$changelog_filename"
    cp "$metadata_dir/aur/LICENSE" LICENSE
    cp "$metadata_dir/aur/$desktop_filename" "$desktop_filename"
    cp "$metadata_dir/aur/linglong-store.metainfo.xml" linglong-store.metainfo.xml
    cp "$metadata_dir/aur/linglong-store.svg" linglong-store.svg

    # Keep .SRCINFO generation aligned with the same Arch tooling that validates
    # the PKGBUILD, even when the host runner is Ubuntu.
    generate_srcinfo "$work_dir"

    # Validate with namcap if available
    if command -v namcap &>/dev/null; then
      echo "Running namcap validation..."
      namcap PKGBUILD || true
    fi

    # Commit and push
    git add -A
    # Re-renders can legitimately be identical on rerun; treat that as success.
    if git diff --cached --quiet; then
      echo "AUR repo already up to date for ${package_name} ${aur_version}; skipping publish."
      exit 0
    fi

    git -c user.name="HanHan666666" -c user.email="tar.zip@outlook.com" commit -m "Update to version $aur_version"
    git push origin master

    echo "AUR package updated to version $aur_version"
  )
}

main() {
  setup_aur_ssh
  update_aur_repo "$release_version"
}

main
