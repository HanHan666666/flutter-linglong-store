# GitHub Release Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 Flutter 仓库补齐 Debian 10 容器化的 GitHub Actions CI / Release 流程，支持 `push` / `pull_request` 的 `amd64` 校验，以及 `workflow_dispatch` 下自动或手动版本的双架构正式发布，产出 `bundle`、`.deb`、`.rpm`、`.AppImage` 并自动创建 GitHub Release。

**Architecture:** 保持 Flutter 应用本身的业务代码不扩散，把发布能力收敛成三层：`.github/workflows/` 只负责编排；`build/scripts/` 作为稳定的 shell 入口负责构建与打包；可测试的版本解析、版本文件改写、changelog 生成逻辑下沉到 `tool/release/` 的 Dart CLI 中，并通过 `flutter test` 做夹具验证。Debian 10 依赖和构建工具链放进独立 Dockerfile，`ci.yml` 默认只跑 `amd64`，`release.yml` 再跑 `amd64 + arm64` 并在 ARM 原生失败后自动退回 QEMU 一次。

**Tech Stack:** GitHub Actions, Docker, Debian 10, Flutter, Dart, Bash, flutter_test

---

### Task 1: 建立可跟踪的发布目录与版本/日志测试基线

**Files:**
- Modify: `.gitignore`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `tool/release/release_version.dart`
- Create: `tool/release/update_version_files.dart`
- Create: `tool/release/generate_changelog.dart`
- Create: `test/unit/tool/release/release_version_test.dart`
- Create: `test/unit/tool/release/update_version_files_test.dart`
- Create: `test/unit/tool/release/generate_changelog_test.dart`
- Create: `test/fixtures/release/sample_pubspec.yaml`
- Create: `test/fixtures/release/sample_linux_pubspec.yaml`
- Create: `test/fixtures/release/sample_app_config.dart`
- Create: `test/fixtures/release/sample_app_constants.dart`

- [ ] **Step 1: 调整 `.gitignore`，允许提交发布基础设施目录**

```gitignore
build/*
!build/docker/
!build/docker/**
!build/scripts/
!build/scripts/**
!build/packaging/
!build/packaging/**
build/**/ephemeral/
build/**/bundle/
build/linux/
build/flutter_assets/
build/native_assets/
```

- [ ] **Step 2: 先写失败测试，锁定版本解析规则**

```dart
expect(resolveReleaseVersion(tags: ['v3.0.9', 'v3.0.10'], manualVersion: null), '3.0.11');
expect(resolveReleaseVersion(tags: const [], manualVersion: null), '3.0.0');
expect(() => resolveReleaseVersion(tags: ['v3.0.10'], manualVersion: '3.0.2'), throwsArgumentError);
```

- [ ] **Step 3: 写失败测试，锁定版本文件映射规则**

```dart
expect(updatedPubspec, contains('version: 3.0.7+1'));
expect(updatedLinuxPubspec, contains('version: 3.0.7+1'));
expect(updatedAppConfig, contains("static const String appVersion = '3.0.7';"));
```

- [ ] **Step 4: 写失败测试，锁定 changelog 边界规则**

```dart
expect(firstReleaseBody, contains('首个 GitHub Release'));
expect(changelogBody, isNot(contains('chore: release 3.0.7')));
expect(changelogBody, contains('## feat'));
```

- [ ] **Step 5: 运行新测试并确认失败**

Run: `flutter test test/unit/tool/release/`
Expected: FAIL，原因是 `tool/release/` 下的 CLI 与解析逻辑尚未实现。

- [ ] **Step 6: 为版本解析补齐 semver 依赖**

```yaml
dev_dependencies:
  pub_semver: ^2.1.5
```

- [ ] **Step 7: 运行依赖解析，更新锁文件**

Run: `flutter pub get`
Expected: `pubspec.lock` 包含 `pub_semver`，且工作区中不再有依赖解析缺失。

- [ ] **Step 8: 提交测试与目录基线**

```bash
git add .gitignore pubspec.yaml pubspec.lock tool/release test/unit/tool/release test/fixtures/release
git commit -m "test: 补充发布脚本版本与日志测试基线"
```

### Task 2: 实现可测试的版本解析、版本文件更新与 changelog CLI

**Files:**
- Modify: `tool/release/release_version.dart`
- Modify: `tool/release/update_version_files.dart`
- Modify: `tool/release/generate_changelog.dart`
- Test: `test/unit/tool/release/release_version_test.dart`
- Test: `test/unit/tool/release/update_version_files_test.dart`
- Test: `test/unit/tool/release/generate_changelog_test.dart`
- Create: `build/scripts/resolve-release-version.sh`
- Create: `build/scripts/update-version-files.sh`
- Create: `build/scripts/generate-changelog.sh`

- [ ] **Step 1: 在 `release_version.dart` 实现 semver-max 与手动版本校验**

```dart
String resolveReleaseVersion({
  required List<String> tags,
  required String? manualVersion,
}) {
  final normalized = tags
      .where((tag) => RegExp(r'^v3\.0\.\d+$').hasMatch(tag))
      .map((tag) => Version.parse(tag.substring(1)))
      .toList()
    ..sort();

  if (manualVersion != null && manualVersion.isNotEmpty) {
    final manual = Version.parse(manualVersion);
    if (normalized.isNotEmpty && manual <= normalized.last) {
      throw ArgumentError('manual version must be greater than latest release');
    }
    return manual.toString();
  }

  if (normalized.isEmpty) return '3.0.0';
  return '3.0.${normalized.last.patch + 1}';
}
```

- [ ] **Step 2: 在 `update_version_files.dart` 实现四个版本源的原子改写**

```dart
writeVersionLine(pubspecPath, 'version: $version+1');
writeVersionLine(linuxPubspecPath, 'version: $version+1');
replaceSingleQuotedConstant(appConfigPath, 'appVersion', version);
replaceSingleQuotedConstant(appConstantsPath, 'appVersion', version);
```

- [ ] **Step 3: 在 `generate_changelog.dart` 明确首版固定文案与 `other` 分组**

```dart
if (previousTag == null) {
  return '## Release Notes\n\n首个 GitHub Release，后续版本将从上一版 tag 自动生成变更日志。\n';
}
```

- [ ] **Step 4: 提供 shell 包装脚本，固定 workflow 调用入口**

```bash
dart run tool/release/release_version.dart "$@"
dart run tool/release/update_version_files.dart "$@"
dart run tool/release/generate_changelog.dart "$@"
```

- [ ] **Step 5: 重新运行单测确认通过**

Run: `flutter test test/unit/tool/release/`
Expected: PASS

- [ ] **Step 6: 提交发布元数据 CLI**

```bash
git add tool/release build/scripts/resolve-release-version.sh build/scripts/update-version-files.sh build/scripts/generate-changelog.sh test/unit/tool/release test/fixtures/release
git commit -m "feat: 实现发布版本与日志脚本"
```

### Task 3: 落地 Debian 10 工具链、打包模板与本地 smoke 测试

**Files:**
- Create: `build/docker/debian10-release.Dockerfile`
- Create: `build/scripts/configure-debian10-apt.sh`
- Create: `build/scripts/build-linux-bundle.sh`
- Create: `build/scripts/package-bundle.sh`
- Create: `build/scripts/package-deb.sh`
- Create: `build/scripts/package-rpm.sh`
- Create: `build/scripts/package-appimage.sh`
- Create: `build/scripts/render-packaging-templates.sh`
- Create: `build/scripts/package-smoke-test.sh`
- Create: `build/scripts/run-in-release-container.sh`
- Create: `build/packaging/linux/linglong-store.desktop.in`
- Create: `build/packaging/linux/deb/control.in`
- Create: `build/packaging/linux/rpm/linglong-store.spec.in`
- Create: `build/packaging/linux/appimage/AppRun`
- Create: `build/packaging/linux/appimage/linglong-store.appdata.xml`

- [ ] **Step 1: 先写 smoke test，锁定四类产物命名与输出目录**

```bash
test -f "$OUT_DIR/linglong-store-3.0.7-linux-amd64.tar.gz"
test -f "$OUT_DIR/linglong-store_3.0.7_amd64.deb"
test -f "$OUT_DIR/linglong-store-3.0.7-1.x86_64.rpm"
test -f "$OUT_DIR/linglong-store-3.0.7-amd64.AppImage"
```

- [ ] **Step 2: 运行 smoke test 并确认失败**

Run: `bash build/scripts/package-smoke-test.sh`
Expected: FAIL，原因是 Dockerfile、模板与打包脚本尚未实现。

- [ ] **Step 3: 在 Dockerfile 中固定 Debian 10 工具链**

```dockerfile
FROM debian:buster
COPY build/scripts/configure-debian10-apt.sh /tmp/configure-debian10-apt.sh
RUN bash /tmp/configure-debian10-apt.sh && \
    apt-get update && \
    apt-get install -y curl git unzip xz-utils zip clang cmake ninja-build pkg-config \
      libgtk-3-dev libblkid-dev liblzma-dev libstdc++-8-dev rpm patchelf desktop-file-utils \
      squashfs-tools file zsync wget librsvg2-bin && \
    git clone https://github.com/flutter/flutter.git /opt/flutter --branch stable --depth 1 && \
    wget -O /usr/local/bin/linuxdeploy https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage && \
    wget -O /usr/local/bin/appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage && \
    chmod +x /usr/local/bin/linuxdeploy /usr/local/bin/appimagetool

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
```

- [ ] **Step 4: 实现容器运行入口，所有构建与打包都强制在 Debian 10 内执行**

```bash
docker run --rm \
  --platform "$DOCKER_PLATFORM" \
  -v "$PWD:/workspace" \
  -w /workspace \
  -e TARGET_ARCH="$TARGET_ARCH" \
  linglong-release \
  bash "$@"
```

- [ ] **Step 5: 实现 `build-linux-bundle.sh`，统一根据架构生成 Flutter release bundle**

```bash
flutter build linux --release
cp -r "build/linux/${FLUTTER_ARCH}/release/bundle" "$STAGING_DIR/bundle"
```

- [ ] **Step 6: 先实现模板渲染脚本，把 `.in` 文件转成可消费元数据**

```bash
envsubst < build/packaging/linux/deb/control.in > "$WORK_DIR/deb/DEBIAN/control"
envsubst < build/packaging/linux/rpm/linglong-store.spec.in > "$WORK_DIR/rpm/SPECS/linglong-store.spec"
envsubst < build/packaging/linux/linglong-store.desktop.in > "$WORK_DIR/appdir/usr/share/applications/linglong-store.desktop"
```

- [ ] **Step 7: 实现 `.deb`、`.rpm`、`.AppImage` 与 `tar.gz` 打包脚本**

```bash
bash build/scripts/render-packaging-templates.sh
dpkg-deb --build "$PKG_ROOT" "$OUT_DIR/linglong-store_${VERSION}_${DEB_ARCH}.deb"
rpmbuild --define "_topdir $RPM_ROOT" -bb "$RPM_ROOT/SPECS/linglong-store.spec"
linuxdeploy --appdir "$APPDIR" --output appimage
tar -C "$STAGING_PARENT" -czf "$OUT_DIR/linglong-store-${VERSION}-linux-${ARCH}.tar.gz" bundle
```

- [ ] **Step 8: 让 smoke test 通过容器入口执行完整链路**

```bash
bash build/scripts/run-in-release-container.sh build/scripts/build-linux-bundle.sh
bash build/scripts/run-in-release-container.sh build/scripts/package-bundle.sh
bash build/scripts/run-in-release-container.sh build/scripts/package-deb.sh
bash build/scripts/run-in-release-container.sh build/scripts/package-rpm.sh
bash build/scripts/run-in-release-container.sh build/scripts/package-appimage.sh
```

- [ ] **Step 9: 重新运行本地 smoke test**

Run: `bash build/scripts/package-smoke-test.sh`
Expected: PASS，能在临时目录中生成四类资产。

- [ ] **Step 10: 提交工具链与打包基础设施**

```bash
git add build/docker build/scripts build/packaging/linux
git commit -m "feat: 增加 Debian 10 发布打包脚本"
```

### Task 4: 为 GitHub Actions 工作流补齐失败用例与 CI 编排

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/release.yml`
- Create: `build/scripts/validate-release-workflow.sh`

- [ ] **Step 1: 先写 workflow 校验脚本，锁定关键字段**

```bash
grep -q "workflow_dispatch" .github/workflows/release.yml
grep -q "contents: write" .github/workflows/release.yml
grep -q "ubuntu-24.04-arm" .github/workflows/release.yml
grep -q "pull_request" .github/workflows/ci.yml
grep -q "amd64" .github/workflows/ci.yml
```

- [ ] **Step 2: 运行校验脚本并确认失败**

Run: `bash build/scripts/validate-release-workflow.sh`
Expected: FAIL，原因是 workflow 文件尚未创建。

- [ ] **Step 3: 实现 `ci.yml`，只跑 `amd64` 校验**

```yaml
on:
  push:
  pull_request:

jobs:
  validate-amd64:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test
      - run: docker build -f build/docker/debian10-release.Dockerfile -t linglong-release .
      - run: bash build/scripts/package-smoke-test.sh
```

- [ ] **Step 4: 实现 `release.yml` 的 prepare job**

```yaml
on:
  workflow_dispatch:
    inputs:
      version:
        required: false
        type: string

permissions:
  contents: write

jobs:
  prepare-release:
    if: ${{ github.ref_name == github.event.repository.default_branch }}
    outputs:
      version: ${{ steps.version.outputs.version }}
      tag: ${{ steps.version.outputs.tag }}
      prerelease_sha: ${{ steps.prerelease-sha.outputs.sha }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - id: prerelease-sha
        run: echo "sha=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"
      - id: version
        run: |
          version="$(bash build/scripts/resolve-release-version.sh "${{ inputs.version }}")"
          echo "version=$version" >> "$GITHUB_OUTPUT"
          echo "tag=v$version" >> "$GITHUB_OUTPUT"
      - run: git config user.name "github-actions[bot]"
      - run: git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
      - run: bash build/scripts/update-version-files.sh "${{ steps.version.outputs.version }}"
      - run: git commit -am "chore: release ${{ steps.version.outputs.version }}"
      - run: git push origin "HEAD:${{ github.event.repository.default_branch }}"
      - run: git tag "v${{ steps.version.outputs.version }}"
      - run: git push origin "v${{ steps.version.outputs.version }}"
```

- [ ] **Step 5: 在 prepare job 内生成完整 Release body**

```yaml
      - run: bash build/scripts/generate-changelog.sh > release-notes.md
        env:
          RELEASE_VERSION: ${{ steps.version.outputs.version }}
          RELEASE_TAG: ${{ steps.version.outputs.tag }}
          CHANGELOG_HEAD_SHA: ${{ steps.prerelease-sha.outputs.sha }}
      - run: |
          cat <<'EOF' >> release-notes.md

          ## Download
          - amd64: bundle / deb / rpm / AppImage
          - arm64: bundle / deb / rpm / AppImage

          ## Requirements
          - Linux
          - GTK 3
          - 玲珑运行环境
          EOF
      - uses: actions/upload-artifact@v4
        with:
          name: release-notes
          path: release-notes.md
```

- [ ] **Step 6: 实现 `release.yml` 的双架构构建与 ARM fallback**

```yaml
  build-amd64:
    needs: prepare-release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -f build/docker/debian10-release.Dockerfile -t linglong-release .
      - run: bash build/scripts/run-in-release-container.sh build/scripts/build-linux-bundle.sh
      - run: bash build/scripts/run-in-release-container.sh build/scripts/package-bundle.sh
      - run: bash build/scripts/run-in-release-container.sh build/scripts/package-deb.sh
      - run: bash build/scripts/run-in-release-container.sh build/scripts/package-rpm.sh
      - run: bash build/scripts/run-in-release-container.sh build/scripts/package-appimage.sh
      - uses: actions/upload-artifact@v4
        with:
          name: release-assets-amd64
          path: dist/release/*

  build-arm64:
    needs: prepare-release
    runs-on: ubuntu-24.04-arm
    steps:
      - uses: actions/checkout@v4
      - run: docker build -f build/docker/debian10-release.Dockerfile -t linglong-release .
      - run: bash build/scripts/run-in-release-container.sh build/scripts/build-linux-bundle.sh
      - run: bash build/scripts/run-in-release-container.sh build/scripts/package-bundle.sh
      - run: bash build/scripts/run-in-release-container.sh build/scripts/package-deb.sh
      - run: bash build/scripts/run-in-release-container.sh build/scripts/package-rpm.sh
      - run: bash build/scripts/run-in-release-container.sh build/scripts/package-appimage.sh
      - uses: actions/upload-artifact@v4
        with:
          name: release-assets-arm64
          path: dist/release/*

  build-arm64-qemu:
    needs: [prepare-release, build-arm64]
    if: ${{ always() && (needs.build-arm64.result == 'failure' || needs.build-arm64.result == 'cancelled') }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-qemu-action@v3
        with:
          platforms: arm64
      - run: docker buildx build --load --platform linux/arm64 -f build/docker/debian10-release.Dockerfile -t linglong-release .
      - run: DOCKER_PLATFORM=linux/arm64 bash build/scripts/run-in-release-container.sh build/scripts/build-linux-bundle.sh
      - run: DOCKER_PLATFORM=linux/arm64 bash build/scripts/run-in-release-container.sh build/scripts/package-bundle.sh
      - run: DOCKER_PLATFORM=linux/arm64 bash build/scripts/run-in-release-container.sh build/scripts/package-deb.sh
      - run: DOCKER_PLATFORM=linux/arm64 bash build/scripts/run-in-release-container.sh build/scripts/package-rpm.sh
      - run: DOCKER_PLATFORM=linux/arm64 bash build/scripts/run-in-release-container.sh build/scripts/package-appimage.sh
      - uses: actions/upload-artifact@v4
        with:
          name: release-assets-arm64
          path: dist/release/*
```

- [ ] **Step 7: 实现发布 job，下载 Release body 与资产并创建 GitHub Release**

```yaml
  publish-release:
    needs: [prepare-release, build-amd64, build-arm64, build-arm64-qemu]
    if: ${{ needs.build-amd64.result == 'success' && (needs.build-arm64.result == 'success' || needs.build-arm64-qemu.result == 'success') }}
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: release-notes
          path: release
      - uses: actions/download-artifact@v4
        with:
          path: artifacts
      - uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ needs.prepare-release.outputs.tag }}
          name: 玲珑应用商店社区版 ${{ needs.prepare-release.outputs.tag }}
          body_path: release/release-notes.md
          files: |
            artifacts/**/*.tar.gz
            artifacts/**/*.deb
            artifacts/**/*.rpm
            artifacts/**/*.AppImage
```

- [ ] **Step 8: 重新运行 workflow 校验脚本**

Run: `bash build/scripts/validate-release-workflow.sh`
Expected: PASS

- [ ] **Step 9: 提交 workflow 编排**

```bash
git add .github/workflows build/scripts/validate-release-workflow.sh
git commit -m "feat: 增加 GitHub Actions 发布工作流"
```

### Task 5: 修正 workflow 细节并补充资产上传链路的本地验证

**Files:**
- Modify: `.github/workflows/release.yml`
- Modify: `build/scripts/package-smoke-test.sh`
- Modify: `build/scripts/build-linux-bundle.sh`
- Modify: `build/scripts/package-bundle.sh`
- Modify: `build/scripts/package-deb.sh`
- Modify: `build/scripts/package-rpm.sh`
- Modify: `build/scripts/package-appimage.sh`

- [ ] **Step 1: 增加版本冲突、空 changelog、资产缺失的失败保护**

```bash
git rev-parse "refs/tags/v$VERSION" >/dev/null 2>&1 && {
  echo "tag already exists" >&2
  exit 1
}
git log --grep="^chore: release $VERSION$" --oneline | grep -q . && {
  echo "release commit already exists" >&2
  exit 1
}
```

- [ ] **Step 2: 确保 release body 永远有内容**

```bash
if [[ ! -s "$CHANGELOG_FILE" ]]; then
  printf '## Release Notes\n\n本次版本无符合 Conventional Commits 的提交。\n' > "$CHANGELOG_FILE"
fi
```

- [ ] **Step 3: 增加本地验证，检查四类资产完整性**

```bash
for expected in "$BUNDLE" "$DEB" "$RPM" "$APPIMAGE"; do
  [[ -f "$expected" ]] || exit 1
done
```

- [ ] **Step 4: 运行脚本测试与最小工作流验证**

Run: `bash build/scripts/package-smoke-test.sh`
Expected: PASS

Run: `bash build/scripts/validate-release-workflow.sh`
Expected: PASS

- [ ] **Step 5: 提交发布保护逻辑**

```bash
git add .github/workflows/release.yml build/scripts
git commit -m "fix: 收紧发布工作流保护逻辑"
```

### Task 6: 补充发布文档与仓库约定

**Files:**
- Create: `docs/12-github-actions-release-workflow.md`
- Modify: `BUILD.md`
- Modify: `docs/02-flutter-architecture.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 新增独立发布文档，记录触发方式与版本规则**

```md
- `release.yml` 只允许 `workflow_dispatch`
- `version` 留空时自动递增 `3.0.x`
- 首个 Release 使用固定引导文案，不回溯历史提交
```

- [ ] **Step 2: 更新构建指南，补充 Debian 10 容器与 GitHub Actions 入口**

```md
- 日常校验：GitHub Actions `ci.yml`
- 正式发版：GitHub Actions `release.yml`
- 打包脚本入口：`build/scripts/package-*.sh`
```

- [ ] **Step 3: 在架构文档中补充“workflow 只编排、脚本才是稳定入口”的约束**

```md
- GitHub Actions 不允许内联大量业务脚本；版本解析、打包与 changelog 必须收敛到仓库脚本。
```

- [ ] **Step 4: 在 `AGENTS.md` 记录新的发布维护经验**

```md
- GitHub Release 统一通过 `release.yml` 触发；版本号必须同步 `pubspec.yaml`、`linux/pubspec.yaml`、`AppConfig.appVersion`、`AppConstants.appVersion`。
```

- [ ] **Step 5: 提交文档**

```bash
git add docs/12-github-actions-release-workflow.md BUILD.md docs/02-flutter-architecture.md AGENTS.md
git commit -m "docs: 补充 GitHub Actions 发布说明"
```

### Task 7: 最终验证与交付检查

**Files:**
- Modify: 仅在修复验证问题时涉及

- [ ] **Step 1: 运行发布相关单测**

Run: `flutter test test/unit/tool/release/`
Expected: PASS

- [ ] **Step 2: 运行本地打包 smoke test**

Run: `bash build/scripts/package-smoke-test.sh`
Expected: PASS

- [ ] **Step 3: 运行 workflow 结构校验**

Run: `bash build/scripts/validate-release-workflow.sh`
Expected: PASS

- [ ] **Step 4: 运行最小静态分析**

Run: `flutter analyze tool/release test/unit/tool/release`
Expected: 0 issues found

- [ ] **Step 5: 检查最终改动范围**

Run: `git diff --stat HEAD~7..HEAD`
Expected: 仅包含 `.github/workflows/`、`build/`、`tool/release/`、`docs/`、`AGENTS.md` 和必要的版本源脚本相关改动。

- [ ] **Step 6: 如验证中发现问题，做最小修复后重复上述命令**

- [ ] **Step 7: 准备执行方式选择**

执行前确认使用以下之一：
- `superpowers:subagent-driven-development`（推荐）
- `superpowers:executing-plans`
