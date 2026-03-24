#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_URL="https://github.com/HanHan666666/flutter-linglong-store"

release_version=""
channel="stable"
package_name=""
aur_version=""
sha256_amd64="${SHA256_AMD64:-}"
sha256_arm64="${SHA256_ARM64:-}"
sha256_sig_amd64="${SHA256_SIG_AMD64:-}"
sha256_sig_arm64="${SHA256_SIG_ARM64:-}"
gpg_key_id="${GPG_KEY_ID:-}"
run_inner="false"

usage() {
  cat <<'EOF' >&2
Usage: validate-aur-package.sh --version <version> [--channel stable|nightly] [--package-name <pkgname>] [--aur-version <pkgver>] [--sha256-amd64 <sha>] [--sha256-arm64 <sha>] [--sha256-sig-amd64 <sha>] [--sha256-sig-arm64 <sha>] [--gpg-key-id <keyid>] [--inner]
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

resolve_channel_defaults() {
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
}

build_release_asset_url() {
  local asset_name="$1"
  local tag_root=""

  # Keep URL resolution aligned with the template renderer's stable/nightly tag model.
  case "$channel" in
    stable)
      tag_root="v${release_version}"
      ;;
    nightly)
      if [[ "$release_version" =~ -nightly\.([0-9]{8})\+[0-9A-Fa-f]+$ ]]; then
        tag_root="nightly-${BASH_REMATCH[1]}"
      else
        echo "Nightly validation requires a version like <semver>-nightly.<YYYYMMDD>+<sha>, got: $release_version" >&2
        exit 64
      fi
      ;;
  esac

  printf '%s/releases/download/%s/%s\n' "$PROJECT_URL" "$tag_root" "$asset_name"
}

create_offline_source_fixtures() {
  local build_dir="$1"
  local fixture_root="$build_dir/.fixture-root"

  mkdir -p "$fixture_root/linglong-store"
  cat > "$fixture_root/linglong-store/linglong_store" <<'EOF'
#!/usr/bin/env bash
printf 'offline fixture\n'
EOF
  chmod +x "$fixture_root/linglong-store/linglong_store"

  # Build a minimal bundle payload so package() can copy a realistic tree offline.
  tar -C "$fixture_root" -czf \
    "$build_dir/linglong-store-${release_version}-linux-amd64.tar.gz" \
    linglong-store
  printf 'offline signature fixture for %s\n' "$release_version" \
    > "$build_dir/linglong-store-${release_version}-linux-amd64.tar.gz.asc"

  if [[ "$channel" == "stable" ]]; then
    cp "$build_dir/linglong-store-${release_version}-linux-amd64.tar.gz" \
      "$build_dir/linglong-store-${release_version}-linux-arm64.tar.gz"
    cp "$build_dir/linglong-store-${release_version}-linux-amd64.tar.gz.asc" \
      "$build_dir/linglong-store-${release_version}-linux-arm64.tar.gz.asc"
  fi
}

prepare_offline_build_workspace() {
  local source_dir="$1"
  local build_dir="$2"
  local desktop_filename="$3"
  local changelog_filename="$4"

  mkdir -p "$build_dir"
  cp "$source_dir/PKGBUILD" "$build_dir/PKGBUILD"
  cp "$source_dir/LICENSE" "$build_dir/LICENSE"
  cp "$source_dir/$desktop_filename" "$build_dir/$desktop_filename"
  cp "$source_dir/linglong-store.metainfo.xml" "$build_dir/linglong-store.metainfo.xml"
  cp "$source_dir/linglong-store.svg" "$build_dir/linglong-store.svg"

  if [[ -f "$source_dir/$changelog_filename" ]]; then
    cp "$source_dir/$changelog_filename" "$build_dir/$changelog_filename"
  fi

  create_offline_source_fixtures "$build_dir"

  # Strip remote URLs from the build copy so makepkg uses the local fixture files only.
  sed -E -i 's#::https?://[^"]+##g' "$build_dir/PKGBUILD"
}

assert_output_contains() {
  local haystack="$1"
  local needle="$2"
  local error_message="$3"

  if ! grep -Fq "$needle" <<<"$haystack"; then
    echo "$error_message" >&2
    exit 1
  fi
}

assert_file_contains() {
  local file_path="$1"
  local needle="$2"
  local error_message="$3"

  if ! grep -Fq "$needle" "$file_path"; then
    echo "$error_message" >&2
    exit 1
  fi
}

assert_file_not_contains() {
  local file_path="$1"
  local needle="$2"
  local error_message="$3"

  if grep -Fq "$needle" "$file_path"; then
    echo "$error_message" >&2
    exit 1
  fi
}

run_inner_validation() {
  local metadata_dir
  local build_dir
  local output
  local pkg_path
  local pkginfo
  local pkg_contents
  local desktop_filename
  local changelog_filename
  local expected_conflict
  local expected_pkginfo_pkgver
  local expected_arch_line_primary
  local expected_arch_line_secondary

  run_with_retries pacman -Sy --noconfirm --needed base-devel namcap curl >/dev/null
  useradd -m builder >/dev/null 2>&1 || true

  metadata_dir="$(mktemp -d)"
  trap 'rm -rf "$metadata_dir"' RETURN
  build_dir="$metadata_dir/aur-build"

  if [[ -z "$sha256_amd64" ]]; then
    sha256_amd64="$(compute_release_sha256 "$(build_release_asset_url "linglong-store-${release_version}-linux-amd64.tar.gz")")"
  fi

  if [[ "$channel" == "stable" && -z "$sha256_arm64" ]]; then
    sha256_arm64="$(compute_release_sha256 "$(build_release_asset_url "linglong-store-${release_version}-linux-arm64.tar.gz")")"
  fi

  # Compute signature SHA256 if not provided
  if [[ -z "$sha256_sig_amd64" ]]; then
    sha256_sig_amd64="$(compute_release_sha256 "$(build_release_asset_url "linglong-store-${release_version}-linux-amd64.tar.gz.asc")")"
  fi

  if [[ "$channel" == "stable" && -z "$sha256_sig_arm64" ]]; then
    sha256_sig_arm64="$(compute_release_sha256 "$(build_release_asset_url "linglong-store-${release_version}-linux-arm64.tar.gz.asc")")"
  fi

  case "$channel" in
    stable)
      desktop_filename="linglong-store.desktop"
      changelog_filename="linglong-store-bin.changelog"
      expected_conflict="linglong-store"
      expected_arch_line_primary="arch = x86_64"
      expected_arch_line_secondary="arch = aarch64"
      ;;
    nightly)
      desktop_filename="linglong-store-nightly.desktop"
      changelog_filename="${package_name}.changelog"
      expected_conflict="linglong-store-bin"
      expected_arch_line_primary="arch = x86_64"
      expected_arch_line_secondary="arch = aarch64"
      ;;
  esac
  expected_pkginfo_pkgver="${aur_version}-1"

  bash "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
    --inner \
    --version "$release_version" \
    --arch amd64 \
    --output-dir "$metadata_dir" \
    --channel "$channel" \
    --sha256-amd64 "$sha256_amd64" \
    --sha256-arm64 "$sha256_arm64" \
    --sha256-sig-amd64 "$sha256_sig_amd64" \
    --sha256-sig-arm64 "$sha256_sig_arm64" \
    --gpg-key-id "$gpg_key_id"

  prepare_offline_build_workspace "$metadata_dir/aur" "$build_dir" "$desktop_filename" "$changelog_filename"
  chown -R builder:builder "$metadata_dir"

  output="$(
    runuser -u builder -- /bin/bash <<EOF
set -euo pipefail
cd "$metadata_dir/aur"
makepkg --printsrcinfo > .SRCINFO
cd "$build_dir"
makepkg -f --nodeps --noconfirm --skipinteg >/dev/null
pkg_path="\$(find . -maxdepth 1 -name "${package_name}-${aur_version}-1-*.pkg.tar.zst" ! -name '*-debug-*' -print -quit)"
if [[ -z "\$pkg_path" ]]; then
  echo "Failed to locate built ${package_name} package." >&2
  exit 1
fi
pkg_path="\${pkg_path#./}"
printf '%s\n' "\$pkg_path" > .pkg-path
namcap "\$pkg_path" 2>&1 || true
EOF
  )"
  pkg_path="$(<"$build_dir/.pkg-path")"
  pkginfo="$(bsdtar -xOf "$build_dir/$pkg_path" .PKGINFO)"
  pkg_contents="$(bsdtar -tf "$build_dir/$pkg_path")"

  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  fi

  if grep -Fq "Directory (usr/share/licenses/${package_name}) is empty" <<<"$output"; then
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

  assert_file_contains "$metadata_dir/aur/.SRCINFO" "pkgname = ${package_name}" \
    "AUR metadata did not render the expected package name."
  assert_file_contains "$metadata_dir/aur/.SRCINFO" "pkgver = ${aur_version}" \
    "AUR metadata did not render the expected pkgver."
  assert_file_contains "$metadata_dir/aur/.SRCINFO" "pkgdesc = Community store for browsing and installing Linglong applications" \
    "AUR metadata did not render the expected package description."
  assert_file_contains "$metadata_dir/aur/.SRCINFO" "changelog = ${changelog_filename}" \
    "AUR metadata did not render the expected changelog filename."
  assert_file_contains "$metadata_dir/aur/.SRCINFO" "source = ${desktop_filename}" \
    "AUR metadata did not render the expected desktop filename."
  assert_file_contains "$metadata_dir/aur/.SRCINFO" "provides = linglong-store" \
    "AUR metadata did not render the expected provides entry."
  assert_file_contains "$metadata_dir/aur/.SRCINFO" "conflicts = ${expected_conflict}" \
    "AUR metadata did not render the expected conflicts entry."
  assert_file_contains "$metadata_dir/aur/.SRCINFO" "$expected_arch_line_primary" \
    "AUR metadata did not render the expected primary architecture."

  if [[ "$channel" == "stable" ]]; then
    assert_file_contains "$metadata_dir/aur/.SRCINFO" "$expected_arch_line_secondary" \
      "Stable AUR metadata is still missing the arm64 architecture."
  else
    assert_file_not_contains "$metadata_dir/aur/.SRCINFO" "$expected_arch_line_secondary" \
      "Nightly AUR metadata unexpectedly rendered the arm64 architecture."
    assert_file_not_contains "$metadata_dir/aur/.SRCINFO" "source_aarch64 =" \
      "Nightly AUR metadata unexpectedly rendered source_aarch64 entries."
  fi

  assert_output_contains "$pkginfo" "pkgname = ${package_name}" \
    "Built AUR package did not keep the expected package name."
  assert_output_contains "$pkginfo" "pkgver = ${expected_pkginfo_pkgver}" \
    "Built AUR package did not keep the expected pkgver."
  assert_output_contains "$pkginfo" "depend = glib2" \
    "AUR package metadata is still missing the glib2 runtime dependency."
  assert_output_contains "$pkginfo" "depend = bash" \
    "AUR package metadata is still missing the bash runtime dependency."
  assert_output_contains "$pkginfo" "provides = linglong-store" \
    "Built AUR package did not keep the expected provides entry."
  assert_output_contains "$pkginfo" "conflict = ${expected_conflict}" \
    "Built AUR package did not keep the expected conflicts entry."
  assert_output_contains "$pkg_contents" "usr/share/applications/${desktop_filename}" \
    "Built AUR package did not install the expected desktop file."
  assert_output_contains "$pkg_contents" "opt/linglong-store/linglong_store" \
    "Built AUR package did not install the expected application payload."

  echo "AUR package validation passed."
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
    --aur-version)
      aur_version="$2"
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
    --sha256-sig-amd64)
      sha256_sig_amd64="$2"
      shift 2
      ;;
    --sha256-sig-arm64)
      sha256_sig_arm64="$2"
      shift 2
      ;;
    --gpg-key-id)
      gpg_key_id="$2"
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

if [[ -z "$release_version" ]]; then
  usage
  exit 64
fi

resolve_channel_defaults

if [[ "$run_inner" == "true" ]]; then
  run_inner_validation
  exit 0
fi

docker run --rm \
  -v "$ROOT_DIR:/workspace" \
  -w /workspace \
  -e SHA256_AMD64="$sha256_amd64" \
  -e SHA256_ARM64="$sha256_arm64" \
  -e SHA256_SIG_AMD64="$sha256_sig_amd64" \
  -e SHA256_SIG_ARM64="$sha256_sig_arm64" \
  -e GPG_KEY_ID="$gpg_key_id" \
  archlinux:latest \
  /bin/bash build/scripts/validate-aur-package.sh \
    --inner \
    --version "$release_version" \
    --channel "$channel" \
    --package-name "$package_name" \
    --aur-version "$aur_version"
