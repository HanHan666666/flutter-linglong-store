#!/usr/bin/env bash
set -euo pipefail

input_dir=""
output_dir=""

usage() {
  cat >&2 <<'EOF'
Usage: normalize-release-assets.sh --input-dir <dir> --output-dir <dir>
EOF
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input-dir)
      input_dir="$2"
      shift 2
      ;;
    --output-dir)
      output_dir="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$input_dir" || -z "$output_dir" ]]; then
  usage
fi

if [[ ! -d "$input_dir" ]]; then
  echo "Input assets directory does not exist: $input_dir" >&2
  exit 1
fi

declare -A asset_paths=()
asset_names=()

while IFS= read -r -d '' asset_path; do
  asset_name="$(basename "$asset_path")"

  case "$asset_name" in
    *.tar.gz|*.tar.gz.asc|*.deb|*.rpm|*.AppImage)
      ;;
    *)
      continue
      ;;
  esac

  if [[ -n "${asset_paths[$asset_name]:-}" ]]; then
    echo "Duplicate release asset name detected while normalizing: $asset_name" >&2
    exit 1
  fi

  asset_paths["$asset_name"]="$asset_path"
  asset_names+=("$asset_name")
done < <(find "$input_dir" -type f -print0)

if [[ "${#asset_names[@]}" -eq 0 ]]; then
  echo "No supported release assets found under $input_dir" >&2
  exit 1
fi

rm -rf "$output_dir"
mkdir -p "$output_dir"

mapfile -t sorted_asset_names < <(printf '%s\n' "${asset_names[@]}" | LC_ALL=C sort)

for asset_name in "${sorted_asset_names[@]}"; do
  cp "${asset_paths[$asset_name]}" "$output_dir/$asset_name"
done

echo "Normalized ${#sorted_asset_names[@]} release assets into $output_dir"
