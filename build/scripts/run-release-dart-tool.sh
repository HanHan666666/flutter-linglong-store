#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <tool-script.dart> [args...]" >&2
  exit 64
fi

tool_script="$1"
shift
workspace_root="${LINGLONG_RELEASE_TOOL_ROOT:-$PWD}"

resolve_dart_bin() {
  local flutter_bin=""
  local flutter_root=""

  if [[ -n "${LINGLONG_RELEASE_DART_BIN:-}" ]]; then
    printf '%s\n' "$LINGLONG_RELEASE_DART_BIN"
    return 0
  fi

  if [[ -n "${FLUTTER_ROOT:-}" && -x "${FLUTTER_ROOT}/bin/dart" ]]; then
    printf '%s\n' "${FLUTTER_ROOT}/bin/dart"
    return 0
  fi

  if command -v dart > /dev/null 2>&1; then
    command -v dart
    return 0
  fi

  if command -v flutter > /dev/null 2>&1; then
    flutter_bin="$(command -v flutter)"
    flutter_root="$(cd "$(dirname "$flutter_bin")/.." && pwd)"
    if [[ -x "${flutter_root}/bin/dart" ]]; then
      printf '%s\n' "${flutter_root}/bin/dart"
      return 0
    fi
  fi

  if [[ -n "${HOME:-}" && -x "${HOME}/flutter/bin/dart" ]]; then
    printf '%s\n' "${HOME}/flutter/bin/dart"
    return 0
  fi

  if [[ -x /opt/flutter/bin/dart ]]; then
    printf '%s\n' /opt/flutter/bin/dart
    return 0
  fi

  echo "Unable to find a usable Dart executable for release tooling." >&2
  exit 1
}

dart_bin="$(resolve_dart_bin)"

cd "$workspace_root"

# Run release tools as plain Dart scripts so command substitution gets only the payload,
# not Flutter bootstrap noise such as "Running build hooks...".
exec "$dart_bin" --disable-dart-dev "$tool_script" "$@"
