#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE_TAG="${LINGLONG_RELEASE_IMAGE_TAG:-linglong-store/debian10-release:local}"
HOME_DIR="$ROOT_DIR/build/.release-home"
PUB_CACHE_DIR="$ROOT_DIR/build/.release-pub-cache"
FLUTTER_CACHE_DIR="$ROOT_DIR/build/.release-flutter-cache"
GIT_COMMON_DIR="${GIT_COMMON_DIR:-}"
GIT_DIR_PATH="${GIT_DIR_PATH:-}"
DOCKER_PLATFORM="${DOCKER_PLATFORM:-}"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <script-path> [args...]" >&2
  exit 64
fi

SCRIPT_PATH="$1"
shift

mkdir -p "$HOME_DIR" "$PUB_CACHE_DIR" "$FLUTTER_CACHE_DIR"

if [[ -z "$GIT_COMMON_DIR" ]] && git -C "$ROOT_DIR" rev-parse --git-common-dir > /dev/null 2>&1; then
  GIT_COMMON_DIR="$(git -C "$ROOT_DIR" rev-parse --git-common-dir)"
fi

if [[ -z "$GIT_DIR_PATH" ]] && git -C "$ROOT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  GIT_DIR_PATH="$(git -C "$ROOT_DIR" rev-parse --git-dir)"
fi

if [[ -n "$DOCKER_PLATFORM" ]]; then
  docker buildx build \
    --load \
    --platform "$DOCKER_PLATFORM" \
    -f "$ROOT_DIR/build/docker/debian10-release.Dockerfile" \
    -t "$IMAGE_TAG" \
    "$ROOT_DIR"
else
  docker build \
    -f "$ROOT_DIR/build/docker/debian10-release.Dockerfile" \
    -t "$IMAGE_TAG" \
    "$ROOT_DIR"
fi

docker_run_cmd=(
  docker run
  --rm
  --user "$(id -u):$(id -g)"
  -e HOME="$HOME_DIR"
  -e PUB_CACHE="$PUB_CACHE_DIR"
  -e GIT_CONFIG_COUNT=2
  -e GIT_CONFIG_KEY_0=safe.directory
  -e "GIT_CONFIG_VALUE_0=$ROOT_DIR"
  -e GIT_CONFIG_KEY_1=safe.directory
  -e GIT_CONFIG_VALUE_1=/opt/flutter
  -e LINGLONG_RELEASE_CONTAINER=1
  -v "$ROOT_DIR:$ROOT_DIR"
  -v "$FLUTTER_CACHE_DIR:/opt/flutter/bin/cache"
  -w "$ROOT_DIR"
)

if [[ -n "$GIT_COMMON_DIR" && -d "$GIT_COMMON_DIR" ]]; then
  docker_run_cmd+=(-v "$GIT_COMMON_DIR:$GIT_COMMON_DIR")
fi

if [[ -n "$GIT_DIR_PATH" && -d "$GIT_DIR_PATH" && "$GIT_DIR_PATH" != "$GIT_COMMON_DIR" ]]; then
  docker_run_cmd+=(-v "$GIT_DIR_PATH:$GIT_DIR_PATH")
fi

if [[ -n "$DOCKER_PLATFORM" ]]; then
  docker_run_cmd+=(--platform "$DOCKER_PLATFORM")
fi

docker_run_cmd+=(
  "$IMAGE_TAG"
  # Keep Dockerfile ENV PATH entries for flutter/dart; login shells reset PATH on Debian.
  bash -c 'set -euo pipefail; mkdir -p "$HOME" "$PUB_CACHE"; exec "$@"'
  _
  "$SCRIPT_PATH"
  --inner
  "$@"
)

exec "${docker_run_cmd[@]}"
