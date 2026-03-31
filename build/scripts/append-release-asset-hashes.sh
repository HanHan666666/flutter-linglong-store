#!/usr/bin/env bash
set -euo pipefail

assets_dir=""
notes_file=""
hashes_output=""

usage() {
  cat >&2 <<'EOF'
Usage: append-release-asset-hashes.sh --assets-dir <dir> --notes-file <path> --hashes-output <path>
EOF
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --assets-dir)
      assets_dir="$2"
      shift 2
      ;;
    --notes-file)
      notes_file="$2"
      shift 2
      ;;
    --hashes-output)
      hashes_output="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$assets_dir" || -z "$notes_file" || -z "$hashes_output" ]]; then
  usage
fi

if [[ ! -d "$assets_dir" ]]; then
  echo "Assets directory does not exist: $assets_dir" >&2
  exit 1
fi

if [[ ! -f "$notes_file" ]]; then
  echo "Release notes file does not exist: $notes_file" >&2
  exit 1
fi

if grep -Fq '## SHA256 Hashes of the release artifacts' "$notes_file"; then
  echo "Release notes already contain a SHA256 artifact section: $notes_file" >&2
  exit 1
fi

declare -A asset_paths=()
asset_names=()

while IFS= read -r -d '' asset_path; do
  asset_name="$(basename "$asset_path")"

  case "$asset_name" in
    hashes.sha256)
      # 允许脚本重跑时覆盖旧文件，但不要把旧 hashes.sha256 自己算进新的列表里。
      continue
      ;;
    *.tar.gz|*.tar.gz.asc|*.deb|*.rpm|*.AppImage)
      ;;
    *)
      continue
      ;;
  esac

  if [[ -n "${asset_paths[$asset_name]:-}" ]]; then
    echo "Duplicate release asset name detected: $asset_name" >&2
    exit 1
  fi

  asset_paths["$asset_name"]="$asset_path"
  asset_names+=("$asset_name")
done < <(find "$assets_dir" -type f -print0)

if [[ "${#asset_names[@]}" -eq 0 ]]; then
  echo "No release artifacts found under $assets_dir" >&2
  exit 1
fi

mapfile -t sorted_asset_names < <(printf '%s\n' "${asset_names[@]}" | LC_ALL=C sort)

mkdir -p "$(dirname "$hashes_output")"
tmp_hashes="$(mktemp "${TMPDIR:-/tmp}/release-hashes.XXXXXX")"

cleanup() {
  rm -f "$tmp_hashes"
}

trap cleanup EXIT

for asset_name in "${sorted_asset_names[@]}"; do
  asset_hash="$(sha256sum "${asset_paths[$asset_name]}" | awk '{print $1}')"
  printf '%s  %s\n' "$asset_hash" "$asset_name" >> "$tmp_hashes"
done

mv "$tmp_hashes" "$hashes_output"

hashes_output_name="$(basename "$hashes_output")"
hashes_output_hash="$(sha256sum "$hashes_output" | awk '{print toupper($1)}')"

{
  printf '\n## SHA256 Hashes of the release artifacts\n\n'
  printf -- '- %s\n' "$hashes_output_name"
  printf -- '  - %s\n' "$hashes_output_hash"

  while IFS= read -r hash_line; do
    asset_hash="${hash_line%%  *}"
    asset_name="${hash_line#*  }"
    printf -- '- %s\n' "$asset_name"
    printf -- '  - %s\n' "${asset_hash^^}"
  done < "$hashes_output"
} >> "$notes_file"
