#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${LINGLONG_RELEASE_ENV_FILE:-/home/han/linglong-repo.sh}"

derive_github_repo() {
  local remote_url

  remote_url="$(git -C "$ROOT_DIR" remote get-url origin 2>/dev/null || true)"
  case "$remote_url" in
    https://github.com/*)
      remote_url="${remote_url#https://github.com/}"
      ;;
    git@github.com:*)
      remote_url="${remote_url#git@github.com:}"
      ;;
    *)
      remote_url=""
      ;;
  esac

  remote_url="${remote_url%.git}"
  printf '%s\n' "$remote_url"
}

if [[ -f "$ENV_FILE" ]]; then
  # Shared local environment file already contains the release tokens for GitHub/Gitee.
  # Keep this sourcing at the entrypoint so the Python tool remains environment-agnostic.
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

if [[ -z "${GITHUB_REPO:-}" ]]; then
  GITHUB_REPO="$(derive_github_repo)"
fi

export GITHUB_REPO="${GITHUB_REPO:-HanHan666666/flutter-linglong-store}"
export GITEE_REPO="${GITEE_REPO:-hanplus/flutter-linglong-store}"

exec python3 "$ROOT_DIR/tool/release/sync_github_release_to_gitee.py" "$@"
