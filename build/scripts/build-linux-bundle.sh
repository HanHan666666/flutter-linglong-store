#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ "${1:-}" != "--inner" && -z "${LINGLONG_RELEASE_CONTAINER:-}" ]]; then
  exec "$ROOT_DIR/build/scripts/run-in-release-container.sh" "$ROOT_DIR/build/scripts/build-linux-bundle.sh" "$@"
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
    flutter_arch_dir="x64"
    ;;
  arm64|aarch64)
    target_arch="arm64"
    flutter_arch_dir="arm64"
    ;;
  *)
    echo "Unsupported architecture: $target_arch" >&2
    exit 64
    ;;
esac

output_dir="$ROOT_DIR/build/out/linux/$release_version/$target_arch"
bundle_dir="$output_dir/bundle/linglong-store"
manifest_path="$output_dir/bundle/manifest.env"
workspace_root=""
source_copy_dir=""
expected_bundle_dir=""

run_with_retries() {
  local max_attempts="$1"
  shift

  local attempt=1
  while true; do
    if "$@"; then
      return 0
    fi

    if [[ "$attempt" -ge "$max_attempts" ]]; then
      return 1
    fi

    attempt=$((attempt + 1))
    sleep 2
  done
}

bootstrap_flutter_dart_sdk() {
  local cache_dir="/opt/flutter/bin/cache"
  local engine_version
  local dart_arch
  local sdk_zip
  local sdk_url

  if [[ -x "$cache_dir/dart-sdk/bin/dart" ]]; then
    return 0
  fi

  case "$target_arch" in
    amd64)
      dart_arch="x64"
      ;;
    arm64)
      dart_arch="arm64"
      ;;
    *)
      echo "Unsupported Flutter Dart SDK architecture: $target_arch" >&2
      return 64
      ;;
  esac

  engine_version="$(cat /opt/flutter/bin/internal/engine.version)"
  sdk_zip="$cache_dir/downloads/dart-sdk-linux-${dart_arch}.zip"
  sdk_url="https://storage.googleapis.com/flutter_infra_release/flutter/${engine_version}/dart-sdk-linux-${dart_arch}.zip"

  mkdir -p "$cache_dir/downloads"

  local attempt=1
  while true; do
    if curl --fail --location --continue-at - --output "$sdk_zip" "$sdk_url" \
      && unzip -q -o "$sdk_zip" -d "$cache_dir"; then
      printf '%s' "$engine_version" > "$cache_dir/engine.stamp"
      printf '%s' "$engine_version" > "$cache_dir/engine-dart-sdk.stamp"
      return 0
    fi

    rm -rf "$cache_dir/dart-sdk"
    if [[ "$attempt" -ge 5 ]]; then
      return 1
    fi

    attempt=$((attempt + 1))
    sleep 2
  done
}

cleanup_workspace() {
  if [[ -n "$workspace_root" ]]; then
    rm -rf "$workspace_root"
  fi
}

trap cleanup_workspace EXIT

has_reusable_bundle() {
  [[ -d "$bundle_dir" ]] \
    && [[ -x "$bundle_dir/linglong_store" ]] \
    && [[ -f "$manifest_path" ]] \
    && grep -qx "version=$release_version" "$manifest_path" \
    && grep -qx "arch=$target_arch" "$manifest_path"
}

if has_reusable_bundle; then
  exit 0
fi

workspace_root="$(mktemp -d "${TMPDIR:-/tmp}/linglong-store-linux-bundle-${release_version}-${target_arch}.XXXXXX")"
source_copy_dir="$workspace_root/source"
expected_bundle_dir="$source_copy_dir/build/linux/$flutter_arch_dir/release/bundle"

rm -rf "$bundle_dir"
mkdir -p "$source_copy_dir" "$output_dir/bundle"

# Build from a disposable copy so release-version rewrites never dirty the worktree.
rsync -a \
  --delete \
  --exclude '.git' \
  --exclude '.dart_tool' \
  --exclude 'build/out' \
  --exclude 'build/tmp' \
  --exclude 'build/.release-home' \
  --exclude 'build/.release-pub-cache' \
  --exclude 'build/.release-flutter-cache' \
  "$ROOT_DIR/" \
  "$source_copy_dir/"

pushd "$source_copy_dir" > /dev/null
bootstrap_flutter_dart_sdk
run_with_retries 5 flutter --disable-analytics
run_with_retries 5 dart --disable-analytics
run_with_retries 5 flutter config --enable-linux-desktop
dart run tool/release/update_version_files.dart "$release_version"
run_with_retries 5 flutter pub get
run_with_retries 5 dart run build_runner build --delete-conflicting-outputs
run_with_retries 3 flutter build linux --release
popd > /dev/null

if [[ ! -d "$expected_bundle_dir" ]]; then
  echo "Flutter bundle directory was not produced: $expected_bundle_dir" >&2
  exit 1
fi

cp -a "$expected_bundle_dir" "$bundle_dir"

printf 'version=%s\narch=%s\nbundle_dir=%s\n' \
  "$release_version" \
  "$target_arch" \
  "$bundle_dir" \
  > "$manifest_path"
