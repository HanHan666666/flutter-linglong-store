#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

release_version=""
package_channel="stable"
container_image="${LOONG64_QEMU_IMAGE:-ghcr.io/loong64/debian:trixie}"
flutter_release_repo="${LOONG64_FLUTTER_RELEASE_REPO:-Flutter-Dart-loong64/flutter-loong64-releases}"
# Pin the default SDK to the upstream Loong64 build that explicitly validated a
# rebuilt linglong-store_3.3.6_loong64.deb on UOS 25. Newer preview SDKs can
# still be selected via environment overrides after end-to-end verification.
flutter_release_tag="${LOONG64_FLUTTER_RELEASE_TAG:-v2026.05.20.1}"
flutter_sdk_archive="${LOONG64_FLUTTER_SDK_ARCHIVE:-flutter-sdk-linux-loong64-20260520.1-9b43981fc5d6-dartae9f14de3805-enginea7a98649a2c8-fontconfig.tar.xz}"

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

    # The GitHub Actions workspace is bind-mounted from the host, so inside the
    # container root sees both the checked-out repository and the extracted
    # Flutter SDK as foreign-owned Git repos. Mark them safe before running the
    # Flutter tool, otherwise `flutter --version` / `flutter config` aborts with
    # Git "detected dubious ownership" safety checks.
    git config --global --add safe.directory "$WORKSPACE_ROOT"
    git config --global --add safe.directory "$FLUTTER_ROOT"

    # Some upstream Loong64 SDK archives are shipped as packaged source trees
    # without Git metadata. Flutter bootstrap still runs `git rev-parse HEAD`,
    # so seed a local repository when the extracted SDK is not already a valid
    # Git checkout.
    if ! git -C "$FLUTTER_ROOT" rev-parse HEAD >/dev/null 2>&1; then
      echo "Bootstrapping local Git metadata for packaged Loong64 Flutter SDK"
      rm -rf "$FLUTTER_ROOT/.git"
      git -C "$FLUTTER_ROOT" init -q
      git -C "$FLUTTER_ROOT" config user.name "Linglong Store CI"
      git -C "$FLUTTER_ROOT" config user.email "actions@users.noreply.github.com"
      git -C "$FLUTTER_ROOT" add -A
      git -C "$FLUTTER_ROOT" commit -q -m "Bootstrap packaged Flutter SDK"
    fi

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
