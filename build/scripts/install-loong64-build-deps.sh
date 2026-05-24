#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
  echo "install-loong64-build-deps.sh must run as root inside the Loong64 container." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "Loong64 dependency bootstrap currently only supports apt-based images." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
# Keep the dependency list focused on the existing bundle/deb pipeline so the
# first Loong64 rollout only solves the formats we can verify end to end today.
apt-get install -yqq --no-install-recommends \
  ca-certificates \
  clang \
  cmake \
  curl \
  dpkg-dev \
  fakeroot \
  file \
  g++ \
  gcc \
  git \
  libgtk-3-dev \
  libjsoncpp-dev \
  liblzma-dev \
  librsvg2-bin \
  make \
  ninja-build \
  pkg-config \
  python3 \
  rsync \
  unzip \
  xz-utils \
  zip
rm -rf /var/lib/apt/lists/*
