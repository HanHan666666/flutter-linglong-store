#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

release_version=""
package_channel="stable"
container_image="${LOONG64_QEMU_IMAGE:-ghcr.io/loong64/debian:trixie}"
flutter_release_repo="${LOONG64_FLUTTER_RELEASE_REPO:-Flutter-Dart-loong64/flutter-loong64-releases}"
flutter_release_tag="${LOONG64_FLUTTER_RELEASE_TAG:-v3.45.0-1.0.pre-198}"
flutter_sdk_archive="${LOONG64_FLUTTER_SDK_ARCHIVE:-flutter-sdk-linux-loong64-3.45.0-1.0.pre-198-0fed39475439.tar.xz}"

usage() {
  cat >&2 <<'EOF'
Usage: build-loong64-in-container.sh --version <version> [--channel stable|nightly]
EOF
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      release_version="$2"
      shift 2
      ;;
    --channel)
      package_channel="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$release_version" ]]; then
  usage
fi

case "$package_channel" in
  stable|nightly)
    ;;
  *)
    echo "Unsupported --channel value: $package_channel" >&2
    exit 64
    ;;
esac

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required to build Loong64 artifacts under QEMU." >&2
  exit 1
fi

host_uid="$(id -u)"
host_gid="$(id -g)"
sdk_cache_root="$ROOT_DIR/build/.loong64-flutter-cache"
sdk_extract_root="$ROOT_DIR/build/.loong64-flutter-sdk/${flutter_release_tag}"
container_home="$ROOT_DIR/build/.loong64-home"
pub_cache="$ROOT_DIR/build/.loong64-pub-cache"
output_dir="$ROOT_DIR/build/out/linux/$release_version/loong64"

mkdir -p "$sdk_cache_root" "$container_home" "$pub_cache" "$output_dir"

docker run --rm \
  --platform linux/loong64 \
  -e HOST_UID="$host_uid" \
  -e HOST_GID="$host_gid" \
  -e PACKAGE_CHANNEL="$package_channel" \
  -e RELEASE_VERSION="$release_version" \
  -e WORKSPACE_ROOT="$ROOT_DIR" \
  -e FLUTTER_RELEASE_REPO="$flutter_release_repo" \
  -e FLUTTER_RELEASE_TAG="$flutter_release_tag" \
  -e FLUTTER_SDK_ARCHIVE="$flutter_sdk_archive" \
  -v "$ROOT_DIR:$ROOT_DIR" \
  -w "$ROOT_DIR" \
  "$container_image" \
  bash -lc '
    set -euo pipefail

    export HOME="$WORKSPACE_ROOT/build/.loong64-home"
    export PUB_CACHE="$WORKSPACE_ROOT/build/.loong64-pub-cache"
    mkdir -p "$HOME" "$PUB_CACHE"

    bash "$WORKSPACE_ROOT/build/scripts/install-loong64-build-deps.sh"

    archive_path="$WORKSPACE_ROOT/build/.loong64-flutter-cache/$FLUTTER_RELEASE_TAG/$FLUTTER_SDK_ARCHIVE"
    extract_root="$WORKSPACE_ROOT/build/.loong64-flutter-sdk/$FLUTTER_RELEASE_TAG"
    archive_url="https://github.com/$FLUTTER_RELEASE_REPO/releases/download/$FLUTTER_RELEASE_TAG/$FLUTTER_SDK_ARCHIVE"

    mkdir -p "$(dirname "$archive_path")"

    if [[ ! -f "$archive_path" ]]; then
      echo "Downloading Loong64 Flutter SDK from $archive_url"
      curl --fail --location --output "$archive_path" "$archive_url"
    fi

    if [[ ! -x "$extract_root/flutter/bin/flutter" ]]; then
      rm -rf "$extract_root"
      mkdir -p "$extract_root"
      tar -xJf "$archive_path" -C "$extract_root"
    fi

    export FLUTTER_ROOT="$extract_root/flutter"
    export PATH="$FLUTTER_ROOT/bin:$FLUTTER_ROOT/bin/cache/dart-sdk/bin:$PATH"

    if [[ ! -f "$FLUTTER_ROOT/bin/cache/artifacts/engine/linux-loong64-release/libflutter_linux_gtk.so" ]]; then
      echo "Loong64 Flutter SDK is missing linux-loong64 release engine artifacts." >&2
      exit 1
    fi

    flutter --disable-analytics >/dev/null 2>&1 || true
    dart --disable-analytics >/dev/null 2>&1 || true
    flutter config --enable-linux-desktop
    flutter config --enable-loong64

    # Reuse the existing packaging entrypoints so Loong64 stays aligned with the
    # stable release bundle/deb layout instead of forking a parallel build path.
    bash "$WORKSPACE_ROOT/build/scripts/package-bundle.sh" --inner --version "$RELEASE_VERSION" --arch loong64
    bash "$WORKSPACE_ROOT/build/scripts/package-deb.sh" --inner --version "$RELEASE_VERSION" --arch loong64 --channel "$PACKAGE_CHANNEL"

    chown -R "$HOST_UID:$HOST_GID" \
      "$WORKSPACE_ROOT/build/out/linux/$RELEASE_VERSION/loong64" \
      "$WORKSPACE_ROOT/build/.loong64-flutter-cache" \
      "$WORKSPACE_ROOT/build/.loong64-flutter-sdk" \
      "$HOME" \
      "$PUB_CACHE"
  '
