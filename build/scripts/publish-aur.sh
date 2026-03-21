#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

release_version=""
target_arch="x86_64"
aur_repo_url="ssh://aur@aur.archlinux.org/linglong-store-bin.git"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      release_version="$2"
      shift 2
      ;;
    --arch)
      target_arch="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 --version <version> [--arch x86_64|aarch64]" >&2
      exit 64
      ;;
  esac
done

if [[ -z "$release_version" ]]; then
  echo "--version is required." >&2
  exit 64
fi

# Map architecture names
case "$target_arch" in
  amd64|x86_64)
    target_arch="x86_64"
    ;;
  arm64|aarch64)
    target_arch="aarch64"
    ;;
  *)
    echo "Unsupported architecture: $target_arch" >&2
    exit 64
    ;;
esac

# Generate PKGBUILD
generate_pkgbuild() {
  local version="$1"
  local arch="$2"
  local download_url="https://github.com/HanHan666666/flutter-linglong-store/releases/download/v${version}/linglong-store-${version}-linux-amd64.tar.gz"
  local pkgver="${version//-/.}"

  cat <<EOF
# Maintainer: HanHan666666 <tar.zip@outlook.com>
pkgname=linglong-store-bin
pkgver=${pkgver}
pkgrel=1
pkgdesc="Linglong Application Store Community Edition"
arch=('x86_64' 'aarch64')
url="https://github.com/HanHan666666/flutter-linglong-store"
license=('MIT')
depends=('gtk3' 'xz' 'libstdc++')
provides=('linglong-store')
conflicts=('linglong-store')

source_x86_64=("linglong-store-\${pkgver}-linux-amd64.tar.gz::https://github.com/HanHan666666/flutter-linglong-store/releases/download/v\${pkgver}/linglong-store-\${pkgver}-linux-amd64.tar.gz")
source_aarch64=("linglong-store-\${pkgver}-linux-arm64.tar.gz::https://github.com/HanHan666666/flutter-linglong-store/releases/download/v\${pkgver}/linglong-store-\${pkgver}-linux-arm64.tar.gz")

sha256sums_x86_64=('SKIP')
sha256sums_aarch64=('SKIP')

package() {
  install -dm755 "\${pkgdir}/opt/linglong-store"
  cp -a "\${srcdir}/linglong-store/." "\${pkgdir}/opt/linglong-store/"

  install -dm755 "\${pkgdir}/usr/bin"
  cat > "\${pkgdir}/usr/bin/linglong-store" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail
exec /opt/linglong-store/linglong_store "\$@"
LAUNCHER
  chmod +x "\${pkgdir}/usr/bin/linglong-store"

  install -dm755 "\${pkgdir}/usr/share/applications"
  cat > "\${pkgdir}/usr/share/applications/linglong-store.desktop" <<'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Linglong Store
Name[zh_CN]=玲珑应用商店社区版
GenericName=Application Store
GenericName[zh_CN]=应用商店
Comment=Linglong Application Store Community Edition
Comment[zh_CN]=玲珑应用商店社区版
Exec=linglong-store
Icon=linglong-store
StartupWMClass=org.linglong-store.LinyapsManager
Terminal=false
Categories=System;PackageManager;
Keywords=linglong;store;app;package;
DESKTOP

  install -dm755 "\${pkgdir}/usr/share/icons/hicolor/256x256/apps"
  if [[ -f "\${srcdir}/linglong-store/data/flutter_assets/assets/icons/logo.png" ]]; then
    cp "\${srcdir}/linglong-store/data/flutter_assets/assets/icons/logo.png" "\${pkgdir}/usr/share/icons/hicolor/256x256/apps/linglong-store.png"
  else
    rsvg-convert -w 256 -h 256 "\${srcdir}/linglong-store/data/flutter_assets/assets/icons/logo.svg" -o "\${pkgdir}/usr/share/icons/hicolor/256x256/apps/linglong-store.png" 2>/dev/null || true
  fi
}
EOF
}

# Setup SSH for AUR
setup_aur_ssh() {
  if [[ -n "${AUR_SSH_PRIVATE_KEY:-}" ]]; then
    mkdir -p ~/.ssh
    echo "$AUR_SSH_PRIVATE_KEY" > ~/.ssh/aur_key
    chmod 600 ~/.ssh/aur_key
    cat >> ~/.ssh/config <<EOF
Host aur.archlinux.org
  IdentityFile ~/.ssh/aur_key
  User aur
EOF
    chmod 600 ~/.ssh/config
  fi
}

# Clone AUR repo and update
update_aur_repo() {
  local version="$1"
  local work_dir
  work_dir="$(mktemp -d)"

  echo "Cloning AUR repository..."
  git clone --depth 1 "$aur_repo_url" "$work_dir"

  cd "$work_dir"

  # Generate new PKGBUILD
  generate_pkgbuild "$version" "$target_arch" > PKGBUILD

  # Generate .SRCINFO
  makepkg --printsrcinfo > .SRCINFO

  # Commit and push
  git add PKGBUILD .SRCINFO
  git -c user.name="HanHan666666" -c user.email="tar.zip@outlook.com" commit -m "Update to version $version"
  git push origin master

  echo "AUR package updated to version $version"

  # Cleanup
  cd /
  rm -rf "$work_dir"
  rm -f ~/.ssh/aur_key
}

main() {
  setup_aur_ssh
  update_aur_repo "$release_version"
}

main
