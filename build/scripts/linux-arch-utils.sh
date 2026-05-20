#!/usr/bin/env bash

detect_debian_arch() {
  if command -v dpkg >/dev/null 2>&1; then
    dpkg --print-architecture 2>/dev/null | tr -d '[:space:]'
  fi
}

normalize_linux_release_arch() {
  local requested_arch="$1"
  local debian_arch=""

  target_arch=""
  deb_arch=""
  rpm_arch=""
  appimage_arch=""
  flutter_arch_dir=""
  flutter_target_platform=""
  dart_arch=""

  case "$requested_arch" in
    amd64|x86_64)
      target_arch="amd64"
      deb_arch="amd64"
      rpm_arch="x86_64"
      appimage_arch="x86_64"
      flutter_arch_dir="x64"
      dart_arch="x64"
      ;;
    arm64|aarch64)
      target_arch="arm64"
      deb_arch="arm64"
      rpm_arch="aarch64"
      appimage_arch="aarch64"
      flutter_arch_dir="arm64"
      dart_arch="arm64"
      ;;
    loong64)
      target_arch="loong64"
      deb_arch="loong64"
      rpm_arch="loongarch64"
      appimage_arch="loongarch64"
      flutter_arch_dir="loong64"
      flutter_target_platform="linux-loong64"
      dart_arch="loong64"
      ;;
    loongarch64)
      debian_arch="$(detect_debian_arch)"
      if [[ "$debian_arch" == "loong64" ]]; then
        target_arch="loong64"
        deb_arch="loong64"
      else
        target_arch="loongarch64"
        deb_arch="loongarch64"
      fi
      rpm_arch="loongarch64"
      appimage_arch="loongarch64"
      flutter_arch_dir="loong64"
      flutter_target_platform="linux-loong64"
      dart_arch="loong64"
      ;;
    *)
      echo "Unsupported architecture: $requested_arch" >&2
      return 64
      ;;
  esac
}
