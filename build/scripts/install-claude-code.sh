#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${LINGLONG_CLAUDE_CODE_EXECUTABLE:-}" ]]; then
  if [[ ! -x "${LINGLONG_CLAUDE_CODE_EXECUTABLE}" ]]; then
    echo "Configured Claude Code executable is not executable: ${LINGLONG_CLAUDE_CODE_EXECUTABLE}" >&2
    exit 1
  fi
  printf '%s\n' "${LINGLONG_CLAUDE_CODE_EXECUTABLE}"
  exit 0
fi

if [[ "${LINGLONG_USE_SYSTEM_CLAUDE_CODE:-1}" == "1" ]] && command -v claude >/dev/null 2>&1; then
  command -v claude
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to install Claude Code in CI." >&2
  exit 1
fi

install_root="${LINGLONG_CLAUDE_CODE_INSTALL_DIR:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}/linglong-claude-code}"
package_version="${LINGLONG_CLAUDE_CODE_VERSION:-latest}"
package_spec="@anthropic-ai/claude-code@${package_version}"

resolve_installed_claude_bin() {
  local root="$1"
  local candidate=""

  for candidate in \
    "${root}/node_modules/.bin/claude" \
    "${root}/node_modules/@anthropic-ai/claude-code/bin/claude" \
    "${root}/bin/claude"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

claude_bin="$(resolve_installed_claude_bin "$install_root" || true)"

if [[ ! -x "$claude_bin" || "${LINGLONG_REINSTALL_CLAUDE_CODE:-0}" == "1" ]]; then
  rm -rf "$install_root"
  mkdir -p "$install_root"
  npm install \
    --prefix "$install_root" \
    --silent \
    --no-audit \
    --no-fund \
    "$package_spec" >/dev/null

  claude_bin="$(resolve_installed_claude_bin "$install_root" || true)"
fi

if [[ ! -x "$claude_bin" ]]; then
  echo "Failed to locate an installed Claude Code executable under ${install_root}." >&2
  exit 1
fi

printf '%s\n' "$claude_bin"