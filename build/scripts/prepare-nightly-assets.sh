#!/usr/bin/env bash
set -euo pipefail

base_version=""
nightly_label=""
target_arch=""
source_dir=""
output_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-version)
      base_version="$2"
      shift 2
      ;;
    --nightly-label)
      nightly_label="$2"
      shift 2
      ;;
    --arch)
      target_arch="$2"
      shift 2
      ;;
    --source-dir)
      source_dir="$2"
      shift 2
      ;;
    --output-dir)
      output_dir="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 --base-version <version> --nightly-label <label> --arch <amd64|arm64> --source-dir <dir> --output-dir <dir>" >&2
      exit 64
      ;;
  esac
done

if [[ -z "$base_version" || -z "$nightly_label" || -z "$target_arch" || -z "$source_dir" || -z "$output_dir" ]]; then
  echo "All arguments are required." >&2
  exit 64
fi

case "$target_arch" in
  amd64|x86_64)
    target_arch="amd64"
    rpm_arch="x86_64"
    ;;
  arm64|aarch64)
    target_arch="arm64"
    rpm_arch="aarch64"
    ;;
  *)
    echo "Unsupported architecture: $target_arch" >&2
    exit 64
    ;;
esac

bundle_source="$source_dir/linglong-store-${base_version}-linux-${target_arch}.tar.gz"
deb_source="$source_dir/linglong-store_${base_version}_${target_arch}.deb"
rpm_source="$source_dir/linglong-store-${base_version}-1.${rpm_arch}.rpm"
appimage_source="$source_dir/linglong-store-${base_version}-${target_arch}.AppImage"

for asset_path in "$bundle_source" "$deb_source" "$rpm_source" "$appimage_source"; do
  if [[ ! -f "$asset_path" ]]; then
    echo "Missing source asset: $asset_path" >&2
    exit 1
  fi
done

rm -rf "$output_dir"
mkdir -p "$output_dir"

cp "$bundle_source" "$output_dir/linglong-store-${nightly_label}-linux-${target_arch}.tar.gz"
cp "$deb_source" "$output_dir/linglong-store-${nightly_label}-${target_arch}.deb"
cp "$rpm_source" "$output_dir/linglong-store-${nightly_label}-${rpm_arch}.rpm"
cp "$appimage_source" "$output_dir/linglong-store-${nightly_label}-${target_arch}.AppImage"
