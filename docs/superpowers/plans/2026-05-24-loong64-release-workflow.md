# Loong64 Release Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为仓库新增 Loong64 GitHub Actions 发布能力：nightly 走独立异步补传到现有 nightly release，正式 release workflow 并入 Loong64 `bundle + deb` 构建。

**Architecture:** 不改现有 `amd64/arm64` 主链语义，把 Loong64 收敛成单独的 QEMU + `linux/loong64` 容器构建路径。nightly 通过独立 workflow 在现有 Nightly 发布完成后追加资产；正式 release 在 `release.yml` 中新增 Loong64 job 并复用既有签名、资产归档、发布逻辑。AUR/UOS 继续保持现有双架构边界。

**Tech Stack:** GitHub Actions, Bash, QEMU, Docker, Loong64 Flutter SDK, existing release scripts

---

### Task 1: 为 Loong64 build 准备脚本与夜构 notes/hash 替换能力

**Files:**
- Modify: `build/scripts/append-release-asset-hashes.sh`
- Modify: `build/scripts/generate-nightly-release-notes.sh`
- Create or Modify: `build/scripts/prepare-nightly-assets.sh`（按实现方式）
- Create: `build/scripts/build-loong64-in-container.sh`
- Create: `build/scripts/install-loong64-build-deps.sh`
- Test: `build/scripts/nightly-cli-smoke-test.sh`
- Test: `build/scripts/release-cli-smoke-test.sh`

- [ ] 写 failing smoke 断言，要求 nightly/release notes 都能包含 `loong64` 下载项。
- [ ] 写 failing smoke 断言，要求 hash 脚本支持“替换已有哈希段”而不是只能追加一次。
- [ ] 实现 `build-loong64-in-container.sh`：在 Loong64 容器内下载外部 Flutter SDK、开启 `--enable-loong64`、执行 `package-bundle.sh --inner` 与 `package-deb.sh --inner`。
- [ ] 增加 `install-loong64-build-deps.sh`，集中安装容器内 Loong64 构建依赖。
- [ ] 让 nightly 资产 staging 支持 `loong64` 的 tar.gz 与 deb 命名。
- [ ] 运行 `bash build/scripts/nightly-cli-smoke-test.sh`，确认先 RED 再 GREEN。

### Task 2: 新增独立异步 nightly Loong64 workflow

**Files:**
- Create: `.github/workflows/nightly-loong64.yml`
- Modify: `build/scripts/validate-release-workflow.sh`
- Test: `build/scripts/validate-release-workflow.sh`

- [ ] 新建 `nightly-loong64.yml`，触发源为 `workflow_run`（Nightly completed）+ `workflow_dispatch`。
- [ ] 增加 job：解析 nightly tag、查找匹配 `Nightly source commit` 的 prerelease、检查 Loong64 资产是否已存在。
- [ ] 增加 QEMU + `linux/loong64` 容器构建 job，上传 Loong64 staging artifact。
- [ ] 增加 publish job：下载现有 nightly release 资产与 notes，合并 Loong64 资产，刷新 `hashes.sha256`，覆盖 release body 与 files。
- [ ] 更新 workflow 校验脚本，加入 `nightly-loong64.yml` 断言。
- [ ] 跑 `bash build/scripts/validate-release-workflow.sh` 验证新 workflow 结构。

### Task 3: 把 Loong64 并入正式 release workflow

**Files:**
- Modify: `.github/workflows/release.yml`
- Test: `build/scripts/release-cli-smoke-test.sh`

- [ ] 为 release notes 下载区新增 `loong64: bundle / deb`。
- [ ] 新增 `build-loong64` job，使用 QEMU + `linux/loong64` 容器构建 Loong64 `bundle + deb`。
- [ ] 让 `sign-release` 依赖并下载 Loong64 assets（tar.gz 自动签名，deb 保持现状）。
- [ ] 保持 `publish-release` 不区分架构，继续统一发布规整后的 `release-assets/*`。
- [ ] 调整 `update-uos-store`，显式只收集 `amd64/arm64` deb，避免因 Loong64 deb 导致数量断言失败。
- [ ] 保持 `publish-aur` 只消费 `amd64/arm64`，不引入 Loong64 AUR 逻辑。
- [ ] 跑 `bash build/scripts/release-cli-smoke-test.sh` 验证 notes 与 asset fixture。

### Task 4: 补齐 smoke tests、维护文档与仓库约定

**Files:**
- Modify: `docs/12-github-workflow-maintenance.md`
- Modify: `AGENTS.md`
- Test: `build/scripts/nightly-cli-smoke-test.sh`
- Test: `build/scripts/release-cli-smoke-test.sh`
- Test: `build/scripts/validate-release-workflow.sh`

- [ ] 在维护文档中补充 `nightly-loong64.yml` 的异步补传职责与限制。
- [ ] 记录 Loong64 当前只支持 `bundle + deb`，并注明 AppImage 工具链缺少上游 Loong64 资产。
- [ ] 在 `AGENTS.md` 追加 Loong64 发布经验，防止后续把 AUR/UOS 错误扩到三架构。
- [ ] 运行三个脚本：
  - `bash build/scripts/nightly-cli-smoke-test.sh`
  - `bash build/scripts/release-cli-smoke-test.sh`
  - `bash build/scripts/validate-release-workflow.sh`

### Task 5: 提交、触发 GitHub Actions，并核对真实 Release 结果

**Files:**
- Modify: 无（除非修复实跑问题）

- [ ] 检查 `git status --short`，确认只包含本次任务文件。
- [ ] 提交变更，使用 Conventional Commit。
- [ ] 推送到 `master`。
- [ ] 手动触发 `nightly-loong64.yml` 或必要的 `Nightly` / `Release` workflow 做真实验证。
- [ ] 用 GitHub CLI 检查：
  - nightly release 是否出现 Loong64 tar.gz 与 deb
  - nightly release body 与 `hashes.sha256` 是否已刷新
  - 正式 release 是否出现 Loong64 tar.gz 与 deb
  - UOS/AUR 相关 job 是否保持成功
- [ ] 若 workflow 实跑失败，按失败日志做最小修复并重跑。

### Task 6: 完成前最终验证

**Files:**
- Modify: 仅在修复验证问题时涉及

- [ ] 运行 `bash build/scripts/nightly-cli-smoke-test.sh`
- [ ] 运行 `bash build/scripts/release-cli-smoke-test.sh`
- [ ] 运行 `bash build/scripts/validate-release-workflow.sh`
- [ ] 运行相关 `git diff --stat` / `git status --short` 检查变更边界
- [ ] 再核对 GitHub Release 页面与 workflow 运行结果，确认 Loong64 资产已经真实落库
