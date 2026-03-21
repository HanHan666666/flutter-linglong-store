#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ "${1:-}" != "--inner" && -z "${LINGLONG_RELEASE_CONTAINER:-}" ]]; then
  exec "$ROOT_DIR/build/scripts/run-in-release-container.sh" "$ROOT_DIR/build/scripts/package-bundle.sh" "$@"
fi

if [[ "${1:-}" == "--inner" ]]; then
  shift
fi

release_version=""
target_arch=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      release_version="$2"
      shift 2
      ;;
    --arch)
      target_arch="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--inner] --version <version> --arch <amd64|arm64>" >&2
      exit 64
      ;;
  esac
done

if [[ -z "$release_version" || -z "$target_arch" ]]; then
  echo "Both --version and --arch are required." >&2
  exit 64
fi

case "$target_arch" in
  amd64|x86_64)
    target_arch="amd64"
    ;;
  arm64|aarch64)
    target_arch="arm64"
    ;;
  *)
    echo "Unsupported architecture: $target_arch" >&2
    exit 64
    ;;
esac

output_dir="$ROOT_DIR/build/out/linux/$release_version/$target_arch"
bundle_dir="$output_dir/bundle/linglong-store"
artifact_path="$output_dir/linglong-store-${release_version}-linux-${target_arch}.tar.gz"

"$ROOT_DIR/build/scripts/build-linux-bundle.sh" --inner --version "$release_version" --arch "$target_arch"

if [[ ! -d "$bundle_dir" ]]; then
  echo "Bundle directory is missing: $bundle_dir" >&2
  exit 1
fi

rm -f "$artifact_path"
tar -C "$output_dir/bundle" -czf "$artifact_path" "linglong-store"

# Calculate sha256 for AUR packaging (filename includes arch to avoid merge conflicts)
sha256_file="$output_dir/sha256sum-${target_arch}.txt"
sha256sum "$artifact_path" | cut -d' ' -f1 > "$sha256_file"
echo "SHA256 ($target_arch): $(cat "$sha256_file")"
