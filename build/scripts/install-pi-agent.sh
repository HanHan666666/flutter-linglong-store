#!/usr/bin/env bash
# 在 GitHub Actions 安装固定版本的 Pi；测试可通过显式可执行文件替换，避免联网。
set -euo pipefail

if [[ -n "${LINGLONG_PI_EXECUTABLE:-}" ]]; then
  if [[ ! -x "$LINGLONG_PI_EXECUTABLE" ]]; then
    echo "Configured Pi executable is not executable: $LINGLONG_PI_EXECUTABLE" >&2
    exit 1
  fi
  printf '%s\n' "$LINGLONG_PI_EXECUTABLE"
  exit 0
fi

if command -v pi >/dev/null 2>&1; then
  command -v pi
  exit 0
fi

# 固定版本避免每日自动构建因上游 CLI 变动产生不一致；Node 版本由 workflow 固定。
npm install --global --ignore-scripts @earendil-works/pi-coding-agent@0.99.1 >&2
command -v pi
