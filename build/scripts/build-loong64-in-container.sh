#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

release_version=""
package_channel="stable"
container_image="${LOONG64_QEMU_IMAGE:-ghcr.io/loong64/debian:trixie}"
flutter_release_repo="${LOONG64_FLUTTER_RELEASE_REPO:-Flutter-Dart-loong64/flutter-loong64-releases}"
# Keep the GitHub Actions Loong64 package build aligned with the SDK that was
# produced in the same Debian 13/QEMU environment.
flutter_release_tag="${LOONG64_FLUTTER_RELEASE_TAG:-v3.45.0-1.0.pre-198+debian13}"
flutter_sdk_archive="${LOONG64_FLUTTER_SDK_ARCHIVE:-flutter-sdk-linux-loong64-3.45.0-1.0.pre-198-80696cf07439.tar.xz}"

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
    engine_version="80696cf07439b4c4d6ed178b49df5065b9f69e6e"
    export FLUTTER_PREBUILT_ENGINE_VERSION="$engine_version"
    export PATH="$FLUTTER_ROOT/bin:$FLUTTER_ROOT/bin/cache/dart-sdk/bin:$PATH"

    # The Loong64 Flutter SDK ships with prebuilt engine artifacts but no
    # corresponding engine_stamp.json on Google Flutter infra storage.
    # During bootstrap, update_engine_version.sh writes an engine hash,
    # then flutter_tools tries to validate it via engine_stamp.json from
    # storage.googleapis.com -- which returns 404 for Loong64.
    # We patch update_engine_version.sh to write the FLUTTER_PREBUILT hash
    # directly (bypassing content_aware_hash which computes a bogus git hash)
    # AND pre-create the stamp files so flutter_tools finds them before
    # attempting any network fetch.
    cat > "$FLUTTER_ROOT/bin/internal/update_engine_version.sh" <<'EVSCRIPT'
#!/usr/bin/env bash
set -e
: "${FLUTTER_ROOT:?Set FLUTTER_ROOT before running update_engine_version.sh}"
mkdir -p "$FLUTTER_ROOT/bin/cache"
engine_version="${FLUTTER_PREBUILT_ENGINE_VERSION:-0000000000000000000000000000000000000000}"
echo "$engine_version" > "$FLUTTER_ROOT/bin/cache/engine.stamp"
echo "" > "$FLUTTER_ROOT/bin/cache/engine.realm"
EVSCRIPT
    chmod +x "$FLUTTER_ROOT/bin/internal/update_engine_version.sh"

    # Pre-create engine.stamp, engine.realm, and engine_stamp.json before any
    # flutter command. flutter_tools checks the engine_stamp artifact stamp
    # under bin/cache before attempting a Google Storage fetch.
    mkdir -p "$FLUTTER_ROOT/bin/cache"
    echo "$engine_version" > "$FLUTTER_ROOT/bin/cache/engine.stamp"
    echo "" > "$FLUTTER_ROOT/bin/cache/engine.realm"
    echo "$engine_version" > "$FLUTTER_ROOT/bin/cache/engine-dart-sdk.stamp"
    echo "$engine_version" > "$FLUTTER_ROOT/bin/cache/flutter_sdk.stamp"
    echo "$engine_version" > "$FLUTTER_ROOT/bin/cache/linux-sdk.stamp"
    echo "$engine_version" > "$FLUTTER_ROOT/bin/cache/font-subset.stamp"
    echo "$engine_version" > "$FLUTTER_ROOT/bin/cache/engine_stamp.stamp"
    python3 - "$FLUTTER_ROOT/bin/cache/engine_stamp.json" "$engine_version" <<'PY'
import json
import sys
import time
from pathlib import Path

path = Path(sys.argv[1])
engine_version = sys.argv[2]
stamp = {
    "build_time_ms": int(time.time() * 1000),
    "git_revision": engine_version,
    "git_revision_date": "2026-05-20T00:00:00+00:00",
    "content_hash": engine_version,
}
path.write_text(json.dumps(stamp, separators=(",", ":")) + "\n")
PY

    mkdir -p "$FLUTTER_ROOT/bin/cache/pkg"
    if [[ ! -d "$FLUTTER_ROOT/bin/cache/pkg/sky_engine" ]] &&
       [[ -d "$FLUTTER_ROOT/engine/src/flutter/sky/packages/sky_engine" ]]; then
      cp -a "$FLUTTER_ROOT/engine/src/flutter/sky/packages/sky_engine" \
        "$FLUTTER_ROOT/bin/cache/pkg/sky_engine"
    fi
    if [[ ! -d "$FLUTTER_ROOT/bin/cache/pkg/flutter_gpu" ]] &&
       [[ -d "$FLUTTER_ROOT/engine/src/flutter/lib/gpu" ]]; then
      cp -a "$FLUTTER_ROOT/engine/src/flutter/lib/gpu" \
        "$FLUTTER_ROOT/bin/cache/pkg/flutter_gpu"
    fi

    engine_artifacts="$FLUTTER_ROOT/bin/cache/artifacts/engine"
    release_engine="$engine_artifacts/linux-loong64-release"
    for cache_name in linux-loong64 linux-loong64-debug linux-loong64-profile linux-loong64-release; do
      if [[ ! -d "$engine_artifacts/$cache_name" ]] && [[ -d "$release_engine" ]]; then
        cp -a "$release_engine" "$engine_artifacts/$cache_name"
      fi
    done

    # The GitHub Actions workspace is bind-mounted from the host, so inside the
    # container root sees both the checked-out repository and the extracted
    # Flutter SDK as foreign-owned Git repos. Mark them safe before running the
    # Flutter tool, otherwise `flutter --version` / `flutter config` aborts with
    # Git "detected dubious ownership" safety checks.
    git config --global --add safe.directory "$WORKSPACE_ROOT"
    git config --global --add safe.directory "$FLUTTER_ROOT"

    # Some upstream Loong64 SDK archives are shipped as packaged source trees
    # without Git metadata. Since the SDK is unpacked under the workspace,
    # plain `git rev-parse HEAD` would incorrectly walk up to the parent
    # repository. Require the Flutter SDK path itself to be the git toplevel
    # before trusting any existing checkout metadata.
    flutter_git_toplevel="$(git -C "$FLUTTER_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ ! -e "$FLUTTER_ROOT/.git" || "$flutter_git_toplevel" != "$FLUTTER_ROOT" ]]; then
      echo "Bootstrapping local Git metadata for packaged Loong64 Flutter SDK"
      rm -rf "$FLUTTER_ROOT/.git"
      git -C "$FLUTTER_ROOT" init -q
      git -C "$FLUTTER_ROOT" config user.name "Linglong Store CI"
      git -C "$FLUTTER_ROOT" config user.email "actions@users.noreply.github.com"
      git -C "$FLUTTER_ROOT" add -A
      git -C "$FLUTTER_ROOT" commit -q -m "Bootstrap packaged Flutter SDK"
    fi

    # Flutter bootstrap (triggered on the first `flutter` invocation) compares
    # flutter_tools.stamp against the current git revision (plus FLUTTER_TOOL_ARGS).
    # Our synthetic local commit changes the revision hash, so we must rewrite the
    # stamp BEFORE any flutter command runs — otherwise Flutter thinks the snapshot
    # is stale and tries to download the non-existent upstream Linux loong64 Dart SDK
    # zip (259-byte error page) and fails.
    flutter_local_revision="$(git -C "$FLUTTER_ROOT" rev-parse HEAD)"
    if [[ -f "$FLUTTER_ROOT/bin/cache/flutter_tools.snapshot" ]]; then
      printf "%s:%s" "$flutter_local_revision" "${FLUTTER_TOOL_ARGS:-}" > "$FLUTTER_ROOT/bin/cache/flutter_tools.stamp"
    fi

    if [[ ! -f "$FLUTTER_ROOT/bin/cache/artifacts/engine/linux-loong64-release/libflutter_linux_gtk.so" ]]; then
      echo "Loong64 Flutter SDK is missing linux-loong64 release engine artifacts." >&2
      exit 1
    fi

    flutter --disable-analytics >/dev/null 2>&1 || true
    dart --disable-analytics >/dev/null 2>&1 || true
    flutter config --enable-linux-desktop
    flutter config --enable-loong64
    export LINGLONG_RELEASE_SKIP_BUILD_RUNNER="${LINGLONG_RELEASE_SKIP_BUILD_RUNNER:-0}"
    export LINGLONG_RELEASE_ALLOW_RIVERPOD_GENERATOR_FAILURE="${LINGLONG_RELEASE_ALLOW_RIVERPOD_GENERATOR_FAILURE:-1}"
    if [[ -z "${LINGLONG_RELEASE_BUILD_RUNNER_FILTERS:-}" ]]; then
      LINGLONG_RELEASE_BUILD_RUNNER_FILTERS="$(printf "%s\n" \
        "lib/application/providers/*.freezed.dart" \
        "lib/data/models/*.freezed.dart" \
        "lib/data/models/*.g.dart" \
        "lib/domain/models/*.freezed.dart" \
        "lib/domain/models/*.g.dart")"
      export LINGLONG_RELEASE_BUILD_RUNNER_FILTERS
    fi

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
