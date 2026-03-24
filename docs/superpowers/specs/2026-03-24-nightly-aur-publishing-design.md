# Nightly AUR Publishing Design

## Goal

在现有 nightly GitHub prerelease 发布链基础上，新增一个自动发布到 AUR 社区的 nightly 通道，包名为 `linglong-store-nightly-bin`，并保持改动最小。

## Background

当前仓库已经具备两条相关能力：

- `nightly.yml` 已能每天生成并签名 `amd64` nightly GitHub prerelease。
- `release.yml` 已能把正式版本通过 `build/scripts/publish-aur.sh` 发布到 AUR，包名为 `linglong-store-bin`。

这次需求不是重新设计一条独立 AUR 链路，而是在复用现有正式版 AUR 模板、校验脚本和推送脚本的基础上，为 nightly 增加一个最小替换型通道。

## Confirmed Decisions

- AUR nightly 包名使用 `linglong-store-nightly-bin`。
- nightly AUR 与稳定版不并存，使用 `conflicts=('linglong-store-bin')`。
- nightly AUR 仅发布 `x86_64`。
- 安装路径与实际二进制入口继续复用稳定版路径，不做并存隔离。
- 只修改用户可见元数据，不改真实运行时布局：
  - 桌面名称显示 `Nightly`
  - `.desktop` 文件名改为 `linglong-store-nightly.desktop`
  - metainfo / AppStream 名称显示 `Nightly`
  - nightly 的 `deb` / `rpm` / `AppImage` 也统一显示 `Nightly`
- nightly AUR 的 `pkgver` 需要从 nightly label 归一化为 Arch 可接受格式。

## Constraints

### Packaging Constraints

- 现有 nightly workflow 只构建 `amd64`，不能为 AUR nightly 平白引入 `arm64` 逻辑。
- 现有正式版 AUR 发布链已经稳定运行，nightly 方案必须尽量复用：
  - `build/scripts/publish-aur.sh`
  - `build/scripts/validate-aur-package.sh`
  - `build/scripts/render-packaging-templates.sh`
  - `build/packaging/linux/aur/PKGBUILD.in`
- 不能让 nightly 逻辑污染正式版 `release.yml` 的行为语义。

### AUR Constraints

- `pkgver` 不能直接使用 `3.0.2-nightly.20260324+8190b89` 这类原始 nightly label。
- nightly 包名必须与稳定版不同，但由于安装路径与命令名复用，需要显式声明冲突关系。

## Chosen Approach

采用“最小替换方案”：

1. 保持 nightly GitHub prerelease 作为真实二进制来源。
2. 对 nightly 新增一条 AUR 发布 job，不复用 `release.yml`，而是在 `nightly.yml` 里新增 `publish-aur-nightly`。
3. 将现有正式版 AUR 模板渲染链参数化，使它能够同时渲染：
   - 稳定版 `linglong-store-bin`
   - 夜版 `linglong-store-nightly-bin`
4. 对 nightly 渲染模式临时覆写用户可见元数据：
   - desktop 名称
   - desktop 文件名
   - metainfo 名称
   - AUR 包名 / 冲突关系 / 下载 URL / `pkgver`
5. 实际安装路径、launcher 实际命令、bundle 内文件布局不做 nightly 专属隔离。

## Version Mapping

### Source Version

nightly workflow 当前产出的对外标签格式：

```text
<base_version>-nightly.<YYYYMMDD>+<short_sha>
```

示例：

```text
3.0.2-nightly.20260324+8190b89
```

### AUR Version Mapping

nightly AUR `pkgver` 采用归一化映射：

```text
3.0.2-nightly.20260324+8190b89
=> 3.0.2_nightly.20260324.8190b89
```

规则：

- 将 `-nightly.` 替换为 `_nightly.`
- 将 `+` 替换为 `.`
- 保留基础 semver、日期和短 SHA 的可读性

这个映射仅用于 AUR 元数据，不回写 GitHub prerelease 文件名，也不改 nightly release notes 中的原始 nightly label。

## Metadata Behavior

### Stable Channel

正式版保持当前行为不变：

- desktop 文件名：`linglong-store.desktop`
- desktop 显示名：`玲珑应用商店社区版`
- metainfo 名称：稳定版文案
- AUR 包名：`linglong-store-bin`

### Nightly Channel

nightly 渲染模式覆写为：

- desktop 文件名：`linglong-store-nightly.desktop`
- desktop 显示名：`玲珑应用商店社区版 Nightly`
- metainfo 名称：Nightly 文案
- AUR 包名：`linglong-store-nightly-bin`
- `conflicts=('linglong-store-bin')`
- `provides=('linglong-store')`

nightly 的 `deb/rpm/AppImage` 也要从模板层显示为 Nightly，以便用户安装后能在桌面环境里看到明确区分。

## Workflow Design

### Existing Nightly Flow

当前 nightly 链路：

1. `prepare-nightly`
2. `build-nightly-amd64`
3. `sign-nightly`
4. `publish-nightly`

### New Nightly AUR Flow

在 `publish-nightly` 成功后新增：

5. `publish-aur-nightly`

该 job 负责：

- 下载 nightly 已签名资产
- 计算 `amd64` tarball 与 `.asc` 的 SHA256
- 将 nightly label 映射为 AUR `pkgver`
- 以 nightly 模式运行 AUR 校验脚本
- 以 nightly 模式运行 AUR 发布脚本

不做的事：

- 不回头修改 `publish-nightly`
- 不把 nightly AUR 逻辑塞进 `release.yml`
- 不额外引入 arm64 AUR 校验

## Script Changes

### `build/scripts/render-packaging-templates.sh`

新增 channel / variant 参数，用于控制：

- 包名
- desktop 文件名
- desktop 显示名
- metainfo 名称
- AUR 冲突关系
- 下载 URL 对应的 tag / 文件名

保持 stable 为默认行为，避免影响现有正式版链路。

### `build/scripts/publish-aur.sh`

参数化以下内容：

- AUR 仓库 URL
- 包名
- channel
- version / pkgver
- 目标架构集合

nightly 模式下：

- repo 使用 `linglong-store-nightly-bin.git`
- 仅渲染 `x86_64`
- 使用 nightly 版本映射后的 `pkgver`

### `build/scripts/validate-aur-package.sh`

新增 nightly 模式校验，确保：

- `pkgname=linglong-store-nightly-bin`
- `arch=('x86_64')`
- `conflicts=('linglong-store-bin')`
- desktop / metainfo / changelog 均按 nightly 渲染
- `pkgver` 为归一化后的合法格式

## File-Level Design

### Files To Modify

- `.github/workflows/nightly.yml`
- `build/scripts/publish-aur.sh`
- `build/scripts/validate-aur-package.sh`
- `build/scripts/render-packaging-templates.sh`
- `build/packaging/linux/aur/PKGBUILD.in`
- `build/packaging/linux/aur/linglong-store-bin.changelog.in`
- `build/packaging/linux/linglong-store.desktop.in`
- `build/packaging/linux/appimage/linglong-store.appdata.xml`
- `docs/12-github-workflow-maintenance.md`
- `AGENTS.md`

### Files Likely To Add

- 一个 nightly AUR 版本归一化辅助脚本，或将该逻辑直接放入现有 AUR 发布脚本中
- 如果模板分支复杂度过高，则新增 nightly 专属 changelog 模板

## Risks

### Risk 1: Stable/Nightly Template Drift

如果单独复制一套 nightly AUR 模板，后续稳定版和 nightly 容易漂移。

Mitigation:

- 优先参数化现有模板，而不是复制两套大模板。

### Risk 2: Nightly User-Facing Metadata Incomplete

如果只改 AUR 包名，不改 desktop/metainfo，用户安装后无法明显区分 nightly。

Mitigation:

- Nightly 名称统一在模板层注入，而不是在单个打包脚本里零散覆盖。

### Risk 3: AUR `pkgver` 不合法

nightly label 原样使用会触发 AUR / makepkg 版本规范问题。

Mitigation:

- 统一使用映射函数生成 nightly `pkgver`
- 在 `validate-aur-package.sh` 中加显式断言

## Testing Strategy

### Local Validation

- 继续运行现有：
  - `bash build/scripts/validate-release-workflow.sh`
  - `bash build/scripts/release-cli-smoke-test.sh`
  - `bash build/scripts/nightly-cli-smoke-test.sh`
- 新增或扩展 AUR 校验：
  - stable 模式校验继续通过
  - nightly 模式校验通过

### Workflow Validation

- 手动触发 `nightly.yml`
- 确认：
  - GitHub prerelease 正常发布
  - `publish-aur-nightly` 成功
  - AUR 仓库被推送到 `linglong-store-nightly-bin`

## Out of Scope

- 夜版与稳定版并存安装
- 夜版独立安装路径
- 夜版独立真实二进制命令名
- 为 nightly AUR 增加 `arm64`
- 重写现有 release AUR 发布链

## Recommendation

按本设计直接在现有正式版 AUR 发布链上做参数化扩展，这是满足需求且改动最小的方案。它保留了 nightly 与正式版 workflow 的职责边界，同时把风险限制在模板渲染、AUR 校验和 nightly job 增量范围内。
