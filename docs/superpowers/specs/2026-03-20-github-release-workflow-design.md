# GitHub Release Workflow Design

**Date:** 2026-03-20

## Background

当前 Flutter 仓库还没有正式的 GitHub Actions 发布链路：
- 仓库缺少 `.github/workflows/`
- 当前版本号分散在 `pubspec.yaml`、`linux/pubspec.yaml`、`lib/core/config/app_config.dart`、`lib/core/constants/app_constants.dart`
- 现有构建方式只有 `flutter build linux --release` 产出的 Linux `bundle`
- 文档中提到过 `.deb` / `.rpm` / `.AppImage` 打包，但仓库里还没有实际打包脚本与 Release 流程

用户希望补齐一套正式的 CI / Release 体系，并满足以下目标：
- `push` / `pull_request` 仅做日常构建校验
- 正式发版只允许 `workflow_dispatch`
- Release 默认自动递增 `3.0.x` 的 patch，也支持手动指定版本
- Release body 自动汇总“上一个 Git tag 到当前版本”的 Conventional Commits
- 自动构建并发布 `amd64` 和 `arm64`
- 正式 Release 资产包含 `bundle` 压缩包、`.deb`、`.rpm`、`.AppImage`
- 为最大兼容性，构建和打包统一基于 Debian 10 容器
- 首版暂不把 Arch Linux 资产纳入正式发布

## Confirmed Requirements

- CI 与 Release 必须职责分离：
  - `ci.yml` 负责 `push` / `pull_request` 校验
  - `release.yml` 只负责 `workflow_dispatch` 发版
- 日常 `push` / `pull_request` 默认只跑 `amd64`
- 正式 Release 必须跑 `amd64` 和 `arm64`
- `release.yml` 需要支持两个版本策略：
  - 手动传入版本号时，使用用户指定版本
  - 未传入版本号时，自动从最新 `v3.0.*` tag 递增 patch
- 版本发布前必须同步更新仓库内所有版本源，并生成独立 release commit
- tag、源码版本、Release 名称、资产文件名必须严格一致
- changelog 必须根据上一个 tag 到当前 release commit 的 Conventional Commits 自动生成，不依赖手工维护 `CHANGELOG.md`
- 打包与构建必须以 Debian 10 容器为统一环境，避免直接依赖 GitHub runner 宿主机的软件栈
- `arm64` 构建优先使用原生 ARM GitHub runner；只有当原生 ARM 路径不可用或不稳定时，才退回 QEMU 容器模拟
- 所有业务细节和维护约束都要写入 `docs/`

## Current Project Constraints

### Version Sources

当前仓库的版本信息至少分散在以下文件：
- `pubspec.yaml`
- `linux/pubspec.yaml`
- `lib/core/config/app_config.dart`
- `lib/core/constants/app_constants.dart`

如果只更新其中一部分，会导致 UI 展示版本、Flutter 包版本、打包版本和 Release tag 漂移。

### Packaging Baseline

当前 Flutter Linux 能稳定产出的官方构建物是：
- `build/linux/x64/release/bundle/`

因此本方案不假设 Flutter 直接输出 `.deb` / `.rpm` / `.AppImage`，而是采用两段式流程：
1. Flutter 负责生成 Linux `bundle`
2. 自定义脚本基于 `bundle` 再进行 Debian / RPM / AppImage 打包

### Architecture Strategy

Flutter Linux 桌面首版不依赖“单机交叉编译出另一架构桌面产物”这一路线。正式发布按架构分别构建：
- `amd64`：在 x86 GitHub runner 上运行 Debian 10 容器进行原生构建
- `arm64`：优先在 ARM GitHub runner 上运行 Debian 10 容器进行原生构建
- QEMU 仅作为 ARM 发布链的降级后备方案，不作为首选主路径

## Approaches

### Option A: 单个 Workflow 同时处理 CI 与 Release

- 一个 workflow 同时包含 `push` / `pull_request` / `workflow_dispatch`
- 通过条件判断区分校验与正式发版流程

**Pros**
- 文件数量少
- 入口集中

**Cons**
- 条件分支复杂，后续维护成本高
- 版本号、tag、上传 Release 与普通 CI 混在一起，出错面大
- 很容易在 PR 校验里误触及 release 逻辑

### Option B: CI 与 Release 分离

- `ci.yml` 只负责日常校验
- `release.yml` 只负责手动发版

**Pros**
- 责任边界清晰
- Release 的版本、tag、资产上传逻辑不会污染 PR 流水线
- 后续可以独立调整 CI 与发版策略

**Cons**
- 需要额外维护两个 workflow 和共享脚本

### Option C: 仅保留 Release Workflow，本地脚本辅助校验

- GitHub Actions 只做正式发版
- 日常校验依赖本地命令和零散脚本

**Pros**
- 初期实现最少

**Cons**
- 不满足用户要求的日常 `push` / `pull_request` 自动校验
- 容易在合并后才暴露构建问题

## Recommended Design

选择 **Option B**。

### Workflow Split

新增两条正式工作流：
- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`

其中：
- `ci.yml`
  - 触发：`push`、`pull_request`
  - 目标：静态分析、测试、Debian 10 容器内 `amd64` release 构建与打包 smoke test
  - 不生成版本号、不打 tag、不创建 Release
- `release.yml`
  - 触发：`workflow_dispatch`
  - 目标：解析版本号、更新版本源、生成 changelog、创建 release commit、打 tag、双架构构建、上传 Release 资产

### Versioning and Tagging

`release.yml` 提供一个可选输入：
- `version`

规则如下：
- 如果传入 `version`，直接使用该版本
- 如果未传入 `version`，自动从仓库中筛选所有 `v3.0.*` tag，并按语义化版本取 **semver 最大值** 后递增 patch，而不是按 tag 创建时间取最近一个
- 若仓库不存在任何 `v3.0.*` tag，则自动从 `3.0.0` 开始

版本确定后，统一更新以下文件：
- `pubspec.yaml`
- `linux/pubspec.yaml`
- `lib/core/config/app_config.dart`
- `lib/core/constants/app_constants.dart`

更新完成后创建正式 release commit：
- commit message: `chore: release <version>`

然后基于该 commit 创建并推送 tag：
- `v<version>`

这样可以保证：
- 仓库源码版本和 Release 完全一致
- 后续任何人 checkout 某个 release tag 都能看到匹配的版本源

### Changelog Generation

changelog 生成范围固定为：
- 从上一个 release tag
- 到创建 release commit 之前的当前业务提交 `HEAD`

release commit 本身只承载版本号同步，不应计入本次 release notes，避免 changelog 中出现自引用的 `chore: release <version>` 条目。

changelog 只汇总 Conventional Commits，并按类型分组展示，至少包含：
- `feat`
- `fix`
- `refactor`
- `docs`
- `test`
- `chore`

Release body 直接复用这份自动生成的 changelog，并在底部补充：
- 版本号
- 系统要求
- 各架构资产说明

changelog 不要求同步维护 `CHANGELOG.md`，以避免手工文件与 Release 页面双写漂移。

### Build Environment

正式构建与打包统一放进 Debian 10 容器执行，避免直接依赖 GitHub runner 宿主机环境。

容器层需要统一完成以下工作：
- 配置 Debian 10 可用 APT 源
- 安装 Flutter Linux 构建依赖
- 安装基础打包依赖：
  - `dpkg-deb`
  - `rpmbuild`
  - `patchelf`
  - `desktop-file-utils`
  - `squashfs-tools`
- 安装 AppImage 打包工具：
  - `linuxdeploy`
  - `appimagetool`

Debian 10 的换源逻辑必须独立成共享脚本，由 `ci.yml` 与 `release.yml` 共用，避免两份 workflow 各自内联一套源配置。

### Build Matrix

CI 与 Release 的架构策略不同：

- `ci.yml`
  - 默认只跑 `amd64`
  - 目的是在日常提交中控制耗时，并尽快暴露构建回归

- `release.yml`
  - 固定跑 `amd64` 与 `arm64`
  - `arm64` 首选原生 ARM runner
  - `arm64` 采用固定的两阶段策略：
    1. 先跑原生 ARM runner 构建
    2. 仅当原生 ARM job 进入 `failure` 或 `cancelled` 状态时，自动触发一次 QEMU 容器重试
  - 若原生 ARM 与 QEMU 两条路径都失败，则整个 Release 失败，不发布半套资产

### Packaging Strategy

所有正式资产都从同一份 Flutter Linux `bundle` 派生，保证内容一致。

每个架构都生成四类资产：
- `bundle` 压缩包
- `.deb`
- `.rpm`
- `.AppImage`

推荐命名固定为：
- `linglong-store-<version>-linux-amd64.tar.gz`
- `linglong-store_<version>_amd64.deb`
- `linglong-store-<version>-1.x86_64.rpm`
- `linglong-store-<version>-amd64.AppImage`
- `linglong-store-<version>-linux-arm64.tar.gz`
- `linglong-store_<version>_arm64.deb`
- `linglong-store-<version>-1.aarch64.rpm`
- `linglong-store-<version>-arm64.AppImage`

### Packaging Metadata

打包模板和元数据不应直接散落在 workflow 里，而应独立收敛到 `build/` 目录，至少包括：
- Debian control 模板
- RPM spec 模板
- `.desktop` 模板
- icon / AppDir 组装配置

这样后续修改：
- 应用名
- 图标
- 分类
- `Exec` 路径
- 依赖信息

都不需要直接改 workflow 主体。

### Release Assets

`release.yml` 在两种架构都构建完成后，统一创建 GitHub Release，并上传所有资产。

Release 页面需包含：
- 版本标题
- 自动生成 changelog
- 按架构区分的下载说明
- Linux 运行依赖说明

首版 Release 不包含：
- Arch Linux 正式资产
- 自动同步到其他代码托管平台
- 自动发布 AUR / 软件源仓库

## File Responsibilities

建议新增和修改的文件职责如下：

- `.github/workflows/ci.yml`
  - 日常 `push` / `pull_request` 校验入口
- `.github/workflows/release.yml`
  - 正式 `workflow_dispatch` 发版入口
- `build/scripts/configure-debian10-apt.sh`
  - Debian 10 EOL 源配置与换源逻辑
- `build/scripts/resolve-release-version.sh`
  - 解析手动版本或自动递增 patch
- `build/scripts/update-version-files.sh`
  - 批量更新 Flutter 版本源文件
- `build/scripts/generate-changelog.sh`
  - 基于 Git tag 与 Conventional Commits 生成 Release body
- `build/scripts/build-linux-bundle.sh`
  - 在容器内执行 Flutter bundle 构建
- `build/scripts/package-deb.sh`
  - 基于 bundle 生成 `.deb`
- `build/scripts/package-rpm.sh`
  - 基于 bundle 生成 `.rpm`
- `build/scripts/package-appimage.sh`
  - 基于 bundle 生成 `.AppImage`
- `build/scripts/package-bundle.sh`
  - 生成标准 `tar.gz` bundle 资产
- `build/packaging/linux/`
  - `.desktop`、icon、Debian control、RPM spec、AppImage 资源模板
- `docs/`
  - 发布流程、维护说明、常见故障排查

## Error Handling and Guardrails

- 当手动输入版本号不符合语义化版本时，release workflow 直接失败
- 当自动解析版本号时，若发现最新 tag 不属于 `v3.0.*` 范围，不应错误递增其他主版本
- 当自动解析版本号时，必须按 `v3.0.*` 的 semver 最大值取基线，而不是按 tag 创建时间或 git 遍历顺序取值
- 当版本源文件更新后存在未提交改动，workflow 必须显式 commit，而不是依赖脏工作区继续打 tag
- 当 changelog 为空时，workflow 不自动填充模糊文案，应仍然展示“本次版本无符合 Conventional Commits 的提交”
- 当生成 changelog 时，必须固定基于 release commit 之前的 `HEAD`，不得把 `chore: release <version>` 自身写进 release notes
- 当 `arm64` 原生 runner 构建失败或取消时，只允许自动回退一次 QEMU；若 QEMU 后备也失败，Release 不应发布半套资产
- 任一架构缺少 `.deb` / `.rpm` / `.AppImage` / `bundle` 任一必需产物时，Release 创建必须失败
- Release 一律以完整双架构资产为成功标准，避免出现用户下载页面只存在部分文件的半成品版本

## Testing Strategy

### CI Validation

`ci.yml` 至少覆盖：
- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test`
- Debian 10 容器内 `amd64` release bundle 构建
- `.deb` / `.rpm` / `.AppImage` / `bundle` 的最小打包验证

### Release Validation

`release.yml` 至少验证：
- 目标版本解析正确
- 版本源文件更新正确
- changelog 生成正确
- `amd64` 与 `arm64` 均成功生成四类正式资产
- GitHub Release 上传成功且文件名符合命名约束

## Out of Scope

本次设计明确不包含：
- Arch Linux 包的正式发布资产
- 自动维护 `CHANGELOG.md`
- 自动推送到 Gitee / OBS / AUR
- 额外的 macOS / Windows 发布链路
- 在首版 CI 中默认启用 `arm64` 日常校验

## Expected Outcome

完成后，仓库将具备一套可维护、可追溯、兼容性优先的 Linux 发版体系：
- 日常提交通过 `ci.yml` 获得 Debian 10 `amd64` 校验
- 正式版本通过 `release.yml` 手动触发
- 默认自动递增 `3.0.x` patch，也支持手动指定版本
- Release 页面自动附带 Conventional Commits changelog
- 用户可以直接下载 `amd64` / `arm64` 的 `bundle`、`.deb`、`.rpm`、`.AppImage`
