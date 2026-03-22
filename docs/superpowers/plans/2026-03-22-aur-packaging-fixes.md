# AUR 打包规范修复实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复 AUR 打包脚本的所有规范问题，使其符合 Arch Linux 打包指南

**Architecture:**
1. 将 PKGBUILD 从脚本内嵌改为模板文件，便于维护和验证
2. 添加 .install 文件用于用户提示
3. 在 CI 中添加 namcap 验证
4. 完善依赖声明和元数据

**Tech Stack:** Bash, PKGBUILD, GitHub Actions

---

## 文件结构

```
build/
├── packaging/linux/aur/          # 新增目录
│   ├── PKGBUILD.in               # PKGBUILD 模板
│   ├── linglong-store-bin.install.in  # 安装脚本模板
│   └── linglong-store-bin.changelog.in # 变更日志模板
├── scripts/
│   ├── publish-aur.sh            # 重构：从模板生成 PKGBUILD
│   └── render-packaging-templates.sh  # 修改：添加 AUR 支持
└── ...

.github/workflows/release.yml     # 添加 namcap 验证步骤
```

---

## Task 1: 创建 AUR 打包模板目录和文件

**Files:**
- Create: `build/packaging/linux/aur/PKGBUILD.in`
- Create: `build/packaging/linux/aur/linglong-store-bin.install.in`
- Create: `build/packaging/linux/aur/linglong-store-bin.changelog.in`

### Task 1.1: 创建 PKGBUILD 模板

- [ ] **Step 1: 创建 AUR 打包目录**

```bash
mkdir -p /home/han/linglong-store/flutter-linglong-store/build/packaging/linux/aur
```

- [ ] **Step 2: 创建 PKGBUILD.in 模板文件**

文件: `build/packaging/linux/aur/PKGBUILD.in`

```bash
cat > /home/han/linglong-store/flutter-linglong-store/build/packaging/linux/aur/PKGBUILD.in << 'EOF'
# Maintainer: @MAINTAINER_NAME@ <@MAINTAINER_EMAIL@>
pkgname=linglong-store-bin
pkgver=@VERSION@
pkgrel=1
pkgdesc="Linglong Application Store Community Edition - 玲珑应用商店社区版"
arch=('x86_64' 'aarch64')
url="@PROJECT_URL@"
license=('MIT')
depends=(
  'gtk3'
  'xz'
  'libstdc++'
  'glibc'
  'gcc-libs'
  'hicolor-icon-theme'
)
optdepends=(
  'linglong: 玲珑运行环境（必需）'
)
provides=('linglong-store')
conflicts=('linglong-store')
install=linglong-store-bin.install
changelog=linglong-store-bin.changelog

source_x86_64=("linglong-store-${pkgver}-linux-amd64.tar.gz::@RELEASE_URL_BASE@/v${pkgver}/linglong-store-${pkgver}-linux-amd64.tar.gz")
source_aarch64=("linglong-store-${pkgver}-linux-arm64.tar.gz::@RELEASE_URL_BASE@/v${pkgver}/linglong-store-${pkgver}-linux-arm64.tar.gz")

sha256sums_x86_64=('@SHA256_AMD64@')
sha256sums_aarch64=('@SHA256_ARM64@')

package() {
  # Install application files
  install -dm755 "${pkgdir}/opt/linglong-store"
  cp -a "${srcdir}/linglong-store/." "${pkgdir}/opt/linglong-store/"

  # Install launcher script
  install -dm755 "${pkgdir}/usr/bin"
  cat > "${pkgdir}/usr/bin/linglong-store" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail
exec /opt/linglong-store/linglong_store "$@"
LAUNCHER
  chmod 755 "${pkgdir}/usr/bin/linglong-store"

  # Install desktop entry
  install -dm755 "${pkgdir}/usr/share/applications"
  cat > "${pkgdir}/usr/share/applications/linglong-store.desktop" <<'DESKTOP'
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

  # Validate desktop file if tool available
  if command -v desktop-file-validate &>/dev/null; then
    desktop-file-validate "${pkgdir}/usr/share/applications/linglong-store.desktop" || true
  fi

  # Install icon
  install -dm755 "${pkgdir}/usr/share/icons/hicolor/256x256/apps"
  if [[ -f "${srcdir}/linglong-store/logo.png" ]]; then
    install -m644 "${srcdir}/linglong-store/logo.png" "${pkgdir}/usr/share/icons/hicolor/256x256/apps/linglong-store.png"
  elif [[ -f "${srcdir}/linglong-store/data/flutter_assets/assets/icons/logo.png" ]]; then
    install -m644 "${srcdir}/linglong-store/data/flutter_assets/assets/icons/logo.png" "${pkgdir}/usr/share/icons/hicolor/256x256/apps/linglong-store.png"
  fi

  # Install metainfo
  install -dm755 "${pkgdir}/usr/share/metainfo"
  if [[ -f "${srcdir}/linglong-store/linglong-store.metainfo.xml" ]]; then
    install -m644 "${srcdir}/linglong-store/linglong-store.metainfo.xml" "${pkgdir}/usr/share/metainfo/linglong-store.metainfo.xml"
  fi

  # Install LICENSE
  install -dm755 "${pkgdir}/usr/share/licenses/${pkgname}"
  if [[ -f "${srcdir}/linglong-store/LICENSE" ]]; then
    install -m644 "${srcdir}/linglong-store/LICENSE" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
  fi
}
EOF
```

### Task 1.2: 创建安装脚本模板

- [ ] **Step 1: 创建 .install 模板文件**

文件: `build/packaging/linux/aur/linglong-store-bin.install.in`

```bash
cat > /home/han/linglong-store/flutter-linglong-store/build/packaging/linux/aur/linglong-store-bin.install.in << 'EOF'
post_install() {
  echo ""
  echo "==> 玲珑应用商店社区版安装完成"
  echo "==> "
  echo "==> 重要提示："
  echo "==>   本软件需要玲珑运行环境才能正常工作"
  echo "==>   请安装 linglong 包: yay -S linglong"
  echo "==> "
  echo "==> 启动方式："
  echo "==>   从应用菜单启动 'Linglong Store'"
  echo "==>   或运行命令: linglong-store"
  echo ""
}

post_upgrade() {
  post_install
}

pre_remove() {
  echo "==> 感谢使用玲珑应用商店社区版"
}
EOF
```

### Task 1.3: 创建变更日志模板

- [ ] **Step 1: 创建 changelog 模板文件**

文件: `build/packaging/linux/aur/linglong-store-bin.changelog.in`

```bash
cat > /home/han/linglong-store/flutter-linglong-store/build/packaging/linux/aur/linglong-store-bin.changelog.in << 'EOF'
@VERSION@-1
  * Release @VERSION@
  * See: @PROJECT_URL@/releases/tag/v@VERSION@
EOF
```

- [ ] **Step 2: Commit Task 1**

```bash
cd /home/han/linglong-store/flutter-linglong-store
git add build/packaging/linux/aur/
git commit -m "feat(aur): add PKGBUILD template and install script"
```

---

## Task 2: 修改 render-packaging-templates.sh 支持 AUR

**Files:**
- Modify: `build/scripts/render-packaging-templates.sh`

- [ ] **Step 1: 添加 AUR 模板渲染函数**

在 `render-packaging-templates.sh` 中添加 AUR 模板渲染支持。修改文件，在 `render_file` 函数后添加新的变量和渲染调用：

找到这一行（约 74 行后）：
```bash
package_name="linglong-store"
```

在变量定义区域添加：
```bash
maintainer_name="HanHan666666"
maintainer_email="tar.zip@outlook.com"
release_url_base="https://github.com/HanHan666666/flutter-linglong-store/releases/download"
```

找到这一行（约 111 行）：
```bash
rm -rf "$output_dir"
mkdir -p "$output_dir/deb" "$output_dir/rpm" "$output_dir/appimage"
```

修改为：
```bash
rm -rf "$output_dir"
mkdir -p "$output_dir/deb" "$output_dir/rpm" "$output_dir/appimage" "$output_dir/aur"
```

在文件末尾的 `render_file` 调用后添加：
```bash
# AUR templates (only if sha256 provided)
render_aur_template() {
  local input_path="$1"
  local output_path="$2"
  local sha_amd64="$3"
  local sha_arm64="$4"

  mkdir -p "$(dirname "$output_path")"
  local content
  content="$(<"$input_path")"
  content="${content//@PACKAGE_NAME@/$package_name}"
  content="${content//@VERSION@/$release_version}"
  content="${content//@MAINTAINER_NAME@/$maintainer_name}"
  content="${content//@MAINTAINER_EMAIL@/$maintainer_email}"
  content="${content//@PROJECT_URL@/$project_url}"
  content="${content//@RELEASE_URL_BASE@/$release_url_base}"
  content="${content//@SHA256_AMD64@/$sha_amd64}"
  content="${content//@SHA256_ARM64@/$sha_arm64}"
  printf '%s\n' "$content" > "$output_path"
}

# Render AUR templates if sha256 checksums are provided
if [[ -n "${sha256_amd64:-}" && -n "${sha256_arm64:-}" ]]; then
  render_aur_template \
    "$ROOT_DIR/build/packaging/linux/aur/PKGBUILD.in" \
    "$output_dir/aur/PKGBUILD" \
    "$sha256_amd64" \
    "$sha256_arm64"

  render_file \
    "$ROOT_DIR/build/packaging/linux/aur/linglong-store-bin.install.in" \
    "$output_dir/aur/linglong-store-bin.install"

  render_file \
    "$ROOT_DIR/build/packaging/linux/aur/linglong-store-bin.changelog.in" \
    "$output_dir/aur/linglong-store-bin.changelog"
fi
```

同时需要在脚本开头添加 sha256 参数解析：

在 `while` 循环中添加：
```bash
    --sha256-amd64)
      sha256_amd64="$2"
      shift 2
      ;;
    --sha256-arm64)
      sha256_arm64="$2"
      shift 2
      ;;
```

- [ ] **Step 2: Commit Task 2**

```bash
cd /home/han/linglong-store/flutter-linglong-store
git add build/scripts/render-packaging-templates.sh
git commit -m "feat(aur): add AUR template rendering support"
```

---

## Task 3: 重构 publish-aur.sh 使用模板

**Files:**
- Modify: `build/scripts/publish-aur.sh`

- [ ] **Step 1: 重构脚本使用模板渲染**

修改 `publish-aur.sh`，移除内嵌的 `generate_pkgbuild` 函数，改用模板渲染：

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

release_version=""
target_arch="x86_64"
aur_repo_url="ssh://aur@aur.archlinux.org/linglong-store-bin.git"

# SHA256 checksums from environment (set by CI)
sha256_amd64="${SHA256_AMD64:-}"
sha256_arm64="${SHA256_ARM64:-}"

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

# Validate SHA256 checksums
if [[ -z "$sha256_amd64" || -z "$sha256_arm64" ]]; then
  echo "Error: SHA256_AMD64 and SHA256_ARM64 environment variables are required" >&2
  exit 1
fi

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
    ssh-keyscan aur.archlinux.org >> ~/.ssh/known_hosts 2>/dev/null
  fi
}

# Update AUR repository
update_aur_repo() {
  local version="$1"
  local work_dir
  work_dir="$(mktemp -d)"

  echo "Cloning AUR repository..."
  git clone --depth 1 "$aur_repo_url" "$work_dir"

  cd "$work_dir"

  # Render templates
  local metadata_dir
  metadata_dir="$(mktemp -d)"

  SHA256_AMD64="$sha256_amd64" \
  SHA256_ARM64="$sha256_arm64" \
  "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
    --inner \
    --version "$version" \
    --arch "amd64" \
    --output-dir "$metadata_dir" \
    --sha256-amd64 "$sha256_amd64" \
    --sha256-arm64 "$sha256_arm64"

  # Copy rendered AUR files
  cp "$metadata_dir/aur/PKGBUILD" PKGBUILD
  cp "$metadata_dir/aur/linglong-store-bin.install" linglong-store-bin.install
  cp "$metadata_dir/aur/linglong-store-bin.changelog" linglong-store-bin.changelog

  # Generate .SRCINFO
  makepkg --printsrcinfo > .SRCINFO

  # Validate with namcap if available
  if command -v namcap &>/dev/null; then
    echo "Running namcap validation..."
    namcap PKGBUILD || true
  fi

  # Commit and push
  git add PKGBUILD .SRCINFO linglong-store-bin.install linglong-store-bin.changelog
  git -c user.name="HanHan666666" -c user.email="tar.zip@outlook.com" commit -m "Update to version $version"
  git push origin master

  echo "AUR package updated to version $version"

  # Cleanup
  cd /
  rm -rf "$work_dir" "$metadata_dir"
  rm -f ~/.ssh/aur_key
}

main() {
  setup_aur_ssh
  update_aur_repo "$release_version"
}

main
```

- [ ] **Step 2: Commit Task 3**

```bash
cd /home/han/linglong-store/flutter-linglong-store
git add build/scripts/publish-aur.sh
git commit -m "refactor(aur): use template-based PKGBUILD generation"
```

---

## Task 4: 确保 bundle 包含 metainfo 文件

**Files:**
- Modify: `build/scripts/build-linux-bundle.sh`

- [ ] **Step 1: 在 bundle 中添加 metainfo 文件**

在 `build-linux-bundle.sh` 的 bundle 构建完成后添加 metainfo 文件复制。

找到这一行（约 206-209 行）：
```bash
# Copy LICENSE to bundle
if [[ -f "$ROOT_DIR/LICENSE" ]]; then
  cp "$ROOT_DIR/LICENSE" "$bundle_dir/LICENSE"
fi
```

在其后添加：
```bash
# Copy metainfo to bundle for AUR packaging
metainfo_src="$ROOT_DIR/build/packaging/linux/appimage/linglong-store.appdata.xml"
if [[ -f "$metainfo_src" ]]; then
  # Convert appdata to metainfo format (same format, different name)
  cp "$metainfo_src" "$bundle_dir/linglong-store.metainfo.xml"
fi
```

- [ ] **Step 2: Commit Task 4**

```bash
cd /home/han/linglong-store/flutter-linglong-store
git add build/scripts/build-linux-bundle.sh
git commit -m "feat(bundle): include metainfo for AUR packaging"
```

---

## Task 5: 在 CI 中添加 namcap 验证

**Files:**
- Modify: `.github/workflows/release.yml`

- [ ] **Step 1: 添加 AUR 验证 job**

在 `publish-aur` job 之前添加验证步骤。修改 `publish-aur` job：

找到 `publish-aur` job（约 262 行），在 `Publish AUR package` step 之前添加：

```yaml
      - name: Install namcap
        run: |
          sudo apt-get update
          sudo apt-get install -y namcap

      - name: Validate PKGBUILD with namcap
        run: |
          # Generate PKGBUILD for validation
          metadata_dir="$(mktemp -d)"
          SHA256_AMD64="${{ steps.sha256sums.outputs.sha_amd64 }}" \
          SHA256_ARM64="${{ steps.sha256sums.outputs.sha_arm64 }}" \
          bash build/scripts/render-packaging-templates.sh \
            --inner \
            --version "${{ needs.prepare-release.outputs.version }}" \
            --arch amd64 \
            --output-dir "$metadata_dir" \
            --sha256-amd64 "${{ steps.sha256sums.outputs.sha_amd64 }}" \
            --sha256-arm64 "${{ steps.sha256sums.outputs.sha_arm64 }}"

          # Run namcap validation
          echo "Running namcap on PKGBUILD..."
          namcap "$metadata_dir/aur/PKGBUILD" || echo "namcap warnings (non-blocking)"
```

- [ ] **Step 2: Commit Task 5**

```bash
cd /home/han/linglong-store/flutter-linglong-store
git add .github/workflows/release.yml
git commit -m "ci(aur): add namcap validation step"
```

---

## Task 6: 修复 URL 不一致问题

**Files:**
- Modify: `build/scripts/render-packaging-templates.sh`

- [ ] **Step 1: 统一项目 URL**

修改 `render-packaging-templates.sh` 中的 `project_url` 变量：

找到（约 82 行）：
```bash
project_url="https://github.com/SXFreell/linglong-store"
```

修改为：
```bash
project_url="https://github.com/HanHan666666/flutter-linglong-store"
```

- [ ] **Step 2: Commit Task 6**

```bash
cd /home/han/linglong-store/flutter-linglong-store
git add build/scripts/render-packaging-templates.sh
git commit -m "fix: unify project URL across packaging templates"
```

---

## Task 7: 更新 deb/rpm 依赖声明

**Files:**
- Modify: `build/packaging/linux/deb/control.in`
- Modify: `build/packaging/linux/rpm/linglong-store.spec.in`

- [ ] **Step 1: 更新 deb control 依赖**

修改 `build/packaging/linux/deb/control.in`：

找到：
```bash
Depends: libc6, libgtk-3-0, liblzma5, libstdc++6
```

修改为：
```bash
Depends: libc6, libgtk-3-0, liblzma5, libstdc++6, gcc-libs-base, hicolor-icon-theme
```

- [ ] **Step 2: 更新 rpm spec 依赖**

修改 `build/packaging/linux/rpm/linglong-store.spec.in`：

找到：
```bash
Requires: gtk3, xz-libs, libstdc++
```

修改为：
```bash
Requires: gtk3, xz-libs, libstdc++, glibc, hicolor-icon-theme
```

- [ ] **Step 3: Commit Task 7**

```bash
cd /home/han/linglong-store/flutter-linglong-store
git add build/packaging/linux/deb/control.in build/packaging/linux/rpm/linglong-store.spec.in
git commit -m "fix: add missing dependencies to deb/rpm packages"
```

---

## Task 8: 验证和测试

**Files:**
- Test: 本地验证脚本

- [ ] **Step 1: 创建本地验证脚本**

```bash
cat > /home/han/linglong-store/flutter-linglong-store/build/scripts/validate-aur-package.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Test template rendering
echo "=== Testing AUR template rendering ==="

temp_dir="$(mktemp -d)"
trap "rm -rf $temp_dir" EXIT

# Test with dummy SHA256
bash "$ROOT_DIR/build/scripts/render-packaging-templates.sh" \
  --inner \
  --version "3.0.7" \
  --arch amd64 \
  --output-dir "$temp_dir" \
  --sha256-amd64 "dummy_amd64_sha256" \
  --sha256-arm64 "dummy_arm64_sha256"

echo ""
echo "=== Rendered files ==="
ls -la "$temp_dir/aur/"

echo ""
echo "=== PKGBUILD content ==="
cat "$temp_dir/aur/PKGBUILD"

echo ""
echo "=== .install content ==="
cat "$temp_dir/aur/linglong-store-bin.install"

echo ""
echo "=== Validation complete ==="
EOF
chmod +x /home/han/linglong-store/flutter-linglong-store/build/scripts/validate-aur-package.sh
```

- [ ] **Step 2: 运行验证**

```bash
cd /home/han/linglong-store/flutter-linglong-store
bash build/scripts/validate-aur-package.sh
```

- [ ] **Step 3: Commit validation script**

```bash
cd /home/han/linglong-store/flutter-linglong-store
git add build/scripts/validate-aur-package.sh
git commit -m "feat(aur): add local validation script"
```

---

## 验收标准

- [ ] PKGBUILD 使用模板文件而非内嵌字符串
- [ ] 依赖声明完整（包含 glibc, gcc-libs, hicolor-icon-theme）
- [ ] 有 .install 文件用于用户提示
- [ ] 有 changelog 文件
- [ ] CI 中有 namcap 验证步骤
- [ ] metainfo 文件包含在 bundle 中
- [ ] 所有打包格式（deb/rpm/aur）的 URL 一致
- [ ] 本地验证脚本可正常运行