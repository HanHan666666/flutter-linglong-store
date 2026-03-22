#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_URL="https://github.com/HanHan666666/flutter-linglong-store"

release_version=""
sha256_amd64="${SHA256_AMD64:-}"
sha256_arm64="${SHA256_ARM64:-}"
run_inner="false"

usage() {
  cat <<'EOF' >&2
Usage: validate-aur-package.sh --version <version> [--sha256-amd64 <sha>] [--sha256-arm64 <sha>] [--inner]
EOF
}

compute_release_sha256() {
  local url="$1"
  local attempt

  for attempt in 1 2 3; do
    if curl -LfsS "$url" | sha256sum | awk '{print $1}'; then
      return 0
    fi

    sleep 2
  done

  return 1
}

run_with_retries() {
  local attempt

  for attempt in 1 2 3; do
    if "$@"; then
      return 0
    fi

    sleep 2
  done

  return 1
}

run_inner_validation() {
  local metadata_dir
  local output
  local pkg_path
  local pkginfo

  run_with_retries pacman -Sy --noconfirm --needed base-devel namcap curl git >/dev/null
  useradd -m builder >/dev/null 2>&1 || true

  metadata_dir="$(mktemp -d)"
  trap 'rm -rf "$metadata_dir"' RETURN
  chown -R builder:builder "$metadata_dir"

  if [[ -z "$sha256_amd64" ]]; then
    sha256_amd64="$(compute_release_sha256 "$PROJECT_URL/releases/download/v${release_version}/linglong-store-${release_version}-linux-amd64.tar.gz")"
  fi

  if [[ -z "$sha256_arm64" ]]; then
    sha256_arm64="$(compute_release_sha256 "$PROJECT_URL/releases/download/v${release_version}/linglong-store-${release_version}-linux-arm64.tar.gz")"
  fi

  bash "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
    --inner \
    --version "$release_version" \
    --arch amd64 \
    --output-dir "$metadata_dir" \
    --sha256-amd64 "$sha256_amd64" \
    --sha256-arm64 "$sha256_arm64"
  chown -R builder:builder "$metadata_dir"

  output="$(
    runuser -u builder -- /bin/bash <<EOF
set -euo pipefail
cd "$metadata_dir/aur"
makepkg --printsrcinfo > .SRCINFO
makepkg --verifysource --nodeps >/dev/null
makepkg -f --nodeps --noconfirm >/dev/null
pkg_path="\$(find . -maxdepth 1 -name "linglong-store-bin-${release_version}-1-*.pkg.tar.zst" ! -name '*-debug-*' -print -quit)"
if [[ -z "\$pkg_path" ]]; then
  echo "Failed to locate built linglong-store-bin package." >&2
  exit 1
fi
printf '%s\n' "\$pkg_path" > .pkg-path
namcap "\$pkg_path" 2>&1 || true
EOF
  )"
  pkg_path="$(<"$metadata_dir/aur/.pkg-path")"
  pkginfo="$(bsdtar -xOf "$metadata_dir/aur/$pkg_path" .PKGINFO)"

  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  fi

  if grep -Fq "Directory (usr/share/licenses/linglong-store-bin) is empty" <<<"$output"; then
    echo "AUR package still ships an empty license directory." >&2
    exit 1
  fi

  if grep -Fq "Directory (usr/share/icons/hicolor" <<<"$output"; then
    echo "AUR package still ships an empty icon directory." >&2
    exit 1
  fi

  if grep -Fq "Directory (usr/share/metainfo) is empty" <<<"$output"; then
    echo "AUR package still ships an empty metainfo directory." >&2
    exit 1
  fi

  if ! grep -Fq "depend = glib2" <<<"$pkginfo"; then
    echo "AUR package metadata is still missing the glib2 runtime dependency." >&2
    exit 1
  fi

  if ! grep -Fq "depend = bash" <<<"$pkginfo"; then
    echo "AUR package metadata is still missing the bash runtime dependency." >&2
    exit 1
  fi

  if grep -Fq $'\tinstall =' "$metadata_dir/aur/.SRCINFO"; then
    echo "AUR metadata still includes an install script for informational hooks." >&2
    exit 1
  fi

  if ! grep -Fq "pkgdesc = Community store for browsing and installing Linglong applications" "$metadata_dir/aur/.SRCINFO"; then
    echo "AUR metadata did not render the expected package description." >&2
    exit 1
  fi

  echo "AUR package validation passed."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      release_version="$2"
      shift 2
      ;;
    --sha256-amd64)
      sha256_amd64="$2"
      shift 2
      ;;
    --sha256-arm64)
      sha256_arm64="$2"
      shift 2
      ;;
    --inner)
      run_inner="true"
      shift
      ;;
    *)
      usage
      exit 64
      ;;
  esac
done

if [[ "$run_inner" == "true" ]]; then
  run_inner_validation
  exit 0
fi

if [[ -z "$release_version" ]]; then
  usage
  exit 64
fi

docker run --rm \
  -v "$ROOT_DIR:/workspace" \
  -w /workspace \
  -e SHA256_AMD64="$sha256_amd64" \
  -e SHA256_ARM64="$sha256_arm64" \
  archlinux:latest \
  /bin/bash build/scripts/validate-aur-package.sh --inner --version "$release_version"
