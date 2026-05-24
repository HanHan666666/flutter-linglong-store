# Loong64 GitHub Workflow Design

**Date:** 2026-05-24

## Background

当前仓库的 Linux 发布链路已经稳定支持 `amd64` 与 `arm64`，并且底层脚本已经具备一部分 `loong64/linux-loong64` 能力：

- `build/scripts/linux-arch-utils.sh` 已能把 `loong64` 映射到 `flutter_target_platform=linux-loong64`
- `build/scripts/build-linux-bundle.sh` 与 `build/scripts/package-bundle.sh` 已接受 `loong64|loongarch64`
- `build/scripts/package-deb.sh` 已接受 `loong64|loongarch64`

但上层发布链仍然是严格的 `amd64 + arm64` 世界观：

- `nightly.yml` 与 `release.yml` 只编排 `amd64/arm64`
- release notes 下载区与 smoke test 夹具都只覆盖双架构
- AUR / UOS 发布链路也只认现有双架构
- AppImage / linuxdeploy 上游当前只提供 `x86_64` 与 `aarch64` 工具资产，不提供 `loong64`

用户目标是：

1. 新增 **Loong64 nightly 独立构建链路**
2. nightly Loong64 **不要和现有 nightly 主流程绑死**，构建完成后**补传到当前 nightly release**
3. 正式 `release.yml` 中 **并入 Loong64 构建**
4. Loong64 使用外部 `Flutter-Dart-loong64/flutter-loong64-releases` 提供的 Flutter SDK
5. 如果支持异步，就让 nightly Loong64 走异步补传

## Confirmed Constraints

- 不使用 git worktree
- 必须复用现有脚本与 release 资产规范，避免引入第二套命名体系
- 当前最稳妥的 Loong64 范围应收敛为 **`bundle + deb`**
- `AUR` 与 `UOS Store` 本次继续保持现有双架构逻辑，不被 Loong64 额外资产打断
- nightly Loong64 应该异步运行，避免拖慢现有 nightly 主链
- Release 需要在同一条正式 workflow 中统一完成现有双架构 + Loong64 资产发布

## External Findings

### Loong64 Flutter SDK

外部仓库 `Flutter-Dart-loong64/flutter-loong64-releases` 明确支持：

- `flutter config --enable-loong64`
- `flutter build linux --release --target-platform linux-loong64`
- 产物目录位于 `build/linux/loong64/release/bundle/`

该仓库 README 与 BUILDING 文档还明确说明：

- QEMU 适合自动化补位
- 原生 LoongArch64 仍然是最推荐的生产构建方式
- 构建时需要 `linux/loong64` 容器平台
- Flutter cache 中需要完整的 `linux-loong64-release` engine artifacts

### QEMU Workflow Reference

外部仓库提供了 `Dart Tag QEMU Loong64 Release` workflow，核心形态是：

- `docker/setup-qemu-action@v3`
- `docker run --platform linux/loong64 ...`
- 在 Loong64 Debian 容器里执行脚本

这证明 **nightly Loong64 独立异步 workflow** 是可行的，并且技术路线应优先选择：

- GitHub runner: `ubuntu-latest`
- QEMU platform: `linux/loong64`
- 容器内下载并使用 Loong64 Flutter SDK

### AppImage Tooling Limitation

已确认：

- `AppImage/appimagetool` 只有 `x86_64` / `aarch64`
- `linuxdeploy/linuxdeploy` 只有 `x86_64` / `aarch64`

因此本次 **不追求 Loong64 AppImage parity**。

## Approaches

### Option A: Loong64 全量 parity（bundle/deb/rpm/AppImage/AUR）

**Pros**
- 架构表面上最对齐

**Cons**
- 与当前上游工具链事实不匹配
- AppImage 工具链缺少 Loong64 资产
- AUR / UOS / rpm / smoke tests 需要大面积扩容
- 高风险，极易把本次任务拖成大重构

### Option B: Loong64 `bundle + deb + rpm`

**Pros**
- 比全量 parity 收敛一些
- 仍保留部分包管理器覆盖

**Cons**
- `package-rpm.sh` 还未接通 `loong64`
- 仍会扩大 smoke test 与签名验证范围
- 对本次“先跑通主链”目标帮助有限

### Option C: Loong64 先做 `bundle + deb`（推荐）

**Pros**
- 与当前脚本基础能力对齐
- 可以最快打通 nightly/release 主发布链
- 不会被 AppImage/AUR 当前的架构限制卡死
- 变更面最小、验证最直接

**Cons**
- Loong64 暂时不是全格式分发

## Recommended Design

选择 **Option C**。

### Nightly Design

新增独立 workflow：`.github/workflows/nightly-loong64.yml`

触发方式：

- `workflow_run`：当 `Nightly` workflow 成功完成后异步触发
- `workflow_dispatch`：用于手动补传 / 失败恢复

职责：

1. 定位当前 nightly prerelease
2. 判断当前 release 是否已经包含 Loong64 nightly 资产
3. 若未包含，则使用 QEMU + `linux/loong64` 容器构建 Loong64 `bundle + deb`
4. 生成 Loong64 tarball detached signature
5. 追加上传到当前 nightly prerelease
6. 重新生成并替换 `hashes.sha256`
7. 更新 nightly release notes 中的下载区与哈希区，使其包含 Loong64

关键点：

- 该 workflow 不参与 AUR 发布
- 该 workflow 不修改现有 nightly 主链的 `amd64/arm64` 逻辑
- 该 workflow 是补传者，不是 nightly 主发布者

### Release Design

在 `.github/workflows/release.yml` 中新增并入式 Loong64 job：

- 新增 `build-loong64` job
- 与 `build-amd64` / `build-arm64` 并行
- 只产出：
  - `linglong-store-<version>-linux-loong64.tar.gz`
  - `linglong-store_<version>_loong64.deb`
- `sign-release` 继续统一签 `*.tar.gz`
- `publish-release` 继续统一发布所有 `release-assets/*`
- `publish-aur` 保持只处理 `amd64/arm64`
- `update-uos-store` 改为显式只收集 `amd64/arm64` deb，避免因新增 Loong64 deb 误报“Expected exactly 2 Debian packages”

### Loong64 Build Strategy

Loong64 构建不复用 `build/docker/debian10-release.Dockerfile`，原因：

- 当前 Dockerfile 明确只支持 `amd64|arm64`
- Debian 10 不是 Loong64 的自然基线
- Loong64 需要外部 Flutter SDK，而不是标准 Flutter stable 克隆流程

因此采用独立的 QEMU 容器执行方案：

1. 在 `ubuntu-latest` 上启用 QEMU
2. 拉起 `linux/loong64` 容器（默认 `ghcr.io/loong64/debian:trixie`，允许通过 env/vars 覆盖）
3. 在容器内安装：
   - `git curl unzip xz-utils zip`
   - `clang cmake ninja-build pkg-config`
   - `libgtk-3-dev liblzma-dev libstdc++-dev`
   - `fakeroot dpkg-dev librsvg2-bin`
4. 下载并解压 Loong64 Flutter SDK
5. 执行：
   - `flutter config --enable-linux-desktop`
   - `flutter config --enable-loong64`
   - `bash build/scripts/package-bundle.sh --inner --version ... --arch loong64`
   - `bash build/scripts/package-deb.sh --inner --version ... --arch loong64`

## Release Notes Strategy

### Nightly

夜构补传完成后，必须更新：

- `## Nightly Build`
  - Architecture 改为 `amd64, arm64, loong64`
- `## Download`
  - 新增 `loong64: bundle / deb`
- `## SHA256 Hashes of the release artifacts`
  - 重新生成并替换，不允许保留旧的双架构哈希段

### Release

正式 release notes 下载区需要明确：

- `amd64: bundle / deb / rpm / AppImage`
- `arm64: bundle / deb / rpm / AppImage`
- `loong64: bundle / deb`

## Testing Strategy

### Script-level

至少补齐以下脚本验证：

- `build/scripts/validate-release-workflow.sh`
- `build/scripts/nightly-cli-smoke-test.sh`
- `build/scripts/release-cli-smoke-test.sh`

### Workflow-level

至少需要验证：

- `nightly-loong64.yml` 能异步定位并追加上传到现有 nightly release
- `release.yml` 能成功合并 Loong64 bundle/deb 资产
- `update-uos-store` 在新增 Loong64 deb 后仍只提交 amd64/arm64 双 deb
- `publish-aur` 在 release 新增 Loong64 资产后不受影响

## Out of Scope

本次明确不做：

- Loong64 AppImage
- Loong64 AUR
- Loong64 UOS Store 上传
- Loong64 RPM（除非实现过程中验证成本异常低，否则不主动扩）
- 改造现有 nightly 主 workflow 为三架构同步发布

## Expected Outcome

完成后将形成两条 Loong64 路径：

1. **Nightly**：独立异步 workflow，在现有 nightly 发布完成后补传 Loong64 `bundle + deb`
2. **Release**：在正式 release workflow 中直接并入 Loong64 `bundle + deb`

这样可以在不破坏当前 `amd64 + arm64` 稳定链路的前提下，先把 Loong64 主发布链打通，并为后续扩展 RPM / AppImage / AUR 留出空间。