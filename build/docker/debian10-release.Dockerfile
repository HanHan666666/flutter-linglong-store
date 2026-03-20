FROM debian:buster

# 不传 DEBIAN_SNAPSHOT_TIMESTAMP，configure-debian10-apt.sh 会直接使用 archive.debian.org（速度更快）
ARG DEBIAN_SNAPSHOT_TIMESTAMP=
ARG FLUTTER_VERSION=3.41.4

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

COPY build/scripts/configure-debian10-apt.sh /usr/local/bin/configure-debian10-apt.sh

RUN chmod +x /usr/local/bin/configure-debian10-apt.sh \
  && DEBIAN_APT_PROTOCOL=http DEBIAN_SNAPSHOT_TIMESTAMP="$DEBIAN_SNAPSHOT_TIMESTAMP" /usr/local/bin/configure-debian10-apt.sh \
  && apt-get install -o Dpkg::Use-Pty=0 -yqq --no-install-recommends ca-certificates \
  && DEBIAN_APT_PROTOCOL=https DEBIAN_SNAPSHOT_TIMESTAMP="$DEBIAN_SNAPSHOT_TIMESTAMP" /usr/local/bin/configure-debian10-apt.sh \
  && for attempt in 1 2 3 4 5; do \
    if apt-get install -o Dpkg::Use-Pty=0 -yqq --no-install-recommends \
      clang \
      cmake \
      curl \
      desktop-file-utils \
      fakeroot \
      file \
      git \
      g++ \
      gcc \
      libfuse2 \
      libgtk-3-dev \
      libjsoncpp-dev \
      liblzma-dev \
      librsvg2-bin \
      lld \
      make \
      ninja-build \
      patchelf \
      pkg-config \
      rpm \
      rsync \
      unzip \
      wget \
      xdg-utils \
      xz-utils \
      zip; then \
      break; \
    fi; \
    if [ "$attempt" -eq 5 ]; then \
      exit 1; \
    fi; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /var/cache/apt/archives/partial/*; \
    apt-get update -qq -o Acquire::Check-Valid-Until=false; \
    sleep 2; \
  done \
  && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  multiarch_dir="$(gcc -dumpmachine)"; \
  ln -sfn /usr/include/c++/8 /usr/include/c++/12; \
  mkdir -p "/usr/include/${multiarch_dir}/c++"; \
  if [ -d "/usr/include/${multiarch_dir}/c++/8" ]; then \
    ln -sfn "/usr/include/${multiarch_dir}/c++/8" "/usr/include/${multiarch_dir}/c++/12"; \
  fi; \
  mkdir -p /usr/lib/llvm-7/bin; \
  if [ ! -e /usr/lib/llvm-7/bin/ld ] && [ -x /usr/bin/ld ]; then \
    ln -s /usr/bin/ld /usr/lib/llvm-7/bin/ld; \
  fi; \
  for tool in ar ranlib nm strip objcopy objdump readelf; do \
    if [ ! -e "/usr/lib/llvm-7/bin/${tool}" ] && [ -x "/usr/bin/${tool}" ]; then \
      ln -s "/usr/bin/${tool}" "/usr/lib/llvm-7/bin/${tool}"; \
    fi; \
    if [ ! -e "/usr/lib/llvm-7/bin/llvm-${tool}" ] && [ -x "/usr/bin/${tool}" ]; then \
      ln -s "/usr/bin/${tool}" "/usr/lib/llvm-7/bin/llvm-${tool}"; \
    fi; \
  done

RUN set -eux; \
  git config --global http.version HTTP/1.1; \
  for attempt in 1 2 3 4 5; do \
    rm -rf "$FLUTTER_HOME"; \
    if git clone https://github.com/flutter/flutter.git "$FLUTTER_HOME" --branch "$FLUTTER_VERSION" --depth 1 --single-branch; then \
      break; \
    fi; \
    if [ "$attempt" -eq 5 ]; then \
      exit 1; \
    fi; \
    sleep 2; \
  done; \
  git config --global --add safe.directory "$FLUTTER_HOME"; \
  mkdir -p "$FLUTTER_HOME/bin/cache" "$FLUTTER_HOME/packages/flutter_tools/.dart_tool"; \
  chmod -R a+rwX "$FLUTTER_HOME"

RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
    amd64) appimage_arch="x86_64" ;; \
    arm64) appimage_arch="aarch64" ;; \
    *) echo "Unsupported container architecture: $arch" >&2; exit 1 ;; \
  esac; \
  download_with_retries() { \
    url="$1"; \
    output="$2"; \
    for attempt in 1 2 3 4 5; do \
      if curl --fail --location --continue-at - --output "$output" "$url"; then \
        return 0; \
      fi; \
      if [ "$attempt" -eq 5 ]; then \
        return 1; \
      fi; \
      sleep 2; \
    done; \
  }; \
  download_with_retries "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${appimage_arch}.AppImage" /usr/local/bin/linuxdeploy.AppImage; \
  download_with_retries "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${appimage_arch}.AppImage" /usr/local/bin/appimagetool.AppImage; \
  chmod +x /usr/local/bin/linuxdeploy.AppImage /usr/local/bin/appimagetool.AppImage; \
  printf '#!/usr/bin/env bash\nset -euo pipefail\nexport APPIMAGE_EXTRACT_AND_RUN=1\nexec /usr/local/bin/linuxdeploy.AppImage "$@"\n' > /usr/local/bin/linuxdeploy; \
  printf '#!/usr/bin/env bash\nset -euo pipefail\nexport APPIMAGE_EXTRACT_AND_RUN=1\nexec /usr/local/bin/appimagetool.AppImage "$@"\n' > /usr/local/bin/appimagetool; \
  chmod +x /usr/local/bin/linuxdeploy /usr/local/bin/appimagetool

RUN set -eux; \
  chmod -R a+rwX "$FLUTTER_HOME"
