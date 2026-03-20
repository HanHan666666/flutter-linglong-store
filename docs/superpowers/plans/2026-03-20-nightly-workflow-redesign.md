# GitHub Nightly Workflow Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有 GitHub Actions 调整为 `pull_request` 轻量校验 + `nightly` 单架构预发布 + `workflow_dispatch` 正式双架构发布三层结构，并把 packaging smoke test 迁移到 nightly。

**Architecture:** 保持正式 `release.yml` 的版本与 tag 逻辑不变，新增独立 `nightly.yml` 负责默认分支 nightly 预发布。nightly 不修改仓库版本源，内部构建继续使用现有 semver 打包脚本，对外通过独立的 nightly 元数据与资产重命名层暴露带日期和短 SHA 的 nightly 标签。

**Tech Stack:** GitHub Actions YAML、Bash、现有 Debian 10 容器打包脚本、GitHub Release API / `softprops/action-gh-release`

---

### Task 1: 收敛 nightly 元数据与资产命名辅助脚本

**Files:**
- Create: `build/scripts/resolve-nightly-metadata.sh`
- Create: `build/scripts/prepare-nightly-assets.sh`
- Create: `build/scripts/nightly-cli-smoke-test.sh`
- Test: `build/scripts/nightly-cli-smoke-test.sh`

- [ ] **Step 1: 写 failing 级别的 CLI smoke test 设计**

明确 `nightly-cli-smoke-test.sh` 需要覆盖的行为：

- `resolve-nightly-metadata.sh` 能输出：
  - `base_version`
  - `nightly_date`
  - `short_sha`
  - `nightly_label`
- `prepare-nightly-assets.sh` 能把 semver 产物复制成带 nightly 标签的新文件名

- [ ] **Step 2: 创建 `build/scripts/resolve-nightly-metadata.sh`**

实现要求：

- 从 `pubspec.yaml` 读取 semver 基础版本
- 使用 `TZ=Asia/Shanghai date` 生成 `YYYYMMDD`
- 读取当前 `HEAD` 的短 SHA
- 输出 shell 可 `source` 的键值对
- 对参数与 git 状态异常做明确报错

- [ ] **Step 3: 创建 `build/scripts/prepare-nightly-assets.sh`**

实现要求：

- 输入：
  - `--base-version`
  - `--nightly-label`
  - `--arch`
  - `--source-dir`
  - `--output-dir`
- 从 `build/out/linux/<base_version>/<arch>` 复制以下产物到 nightly 目录：
  - `tar.gz`
  - `.deb`
  - `.rpm`
  - `.AppImage`
- 输出统一的 nightly 文件名：
  - `linglong-store-<nightly_label>-linux-amd64.tar.gz`
  - `linglong-store-<nightly_label>-amd64.deb`
  - `linglong-store-<nightly_label>-x86_64.rpm`
  - `linglong-store-<nightly_label>-amd64.AppImage`
- 仅重命名对外展示文件，不修改内部包元数据版本

- [ ] **Step 4: 创建 `build/scripts/nightly-cli-smoke-test.sh`**

实现要求：

- 调用 `resolve-nightly-metadata.sh`
- 校验 `nightly_label` 满足 `<semver>-nightly.<YYYYMMDD>+<sha>` 结构
- 在临时目录构造四个伪产物，调用 `prepare-nightly-assets.sh`
- 校验四个 nightly 文件名均已生成

- [ ] **Step 5: 运行 nightly CLI smoke test**

Run: `bash build/scripts/nightly-cli-smoke-test.sh`  
Expected: PASS，输出 nightly metadata 与 assets staging 成功信息

- [ ] **Step 6: 提交**

```bash
git add build/scripts/resolve-nightly-metadata.sh build/scripts/prepare-nightly-assets.sh build/scripts/nightly-cli-smoke-test.sh
git commit -m "feat: 增加 nightly 构建元数据与资产脚本"
```

### Task 2: 重构 `ci.yml` 为 PR 轻量校验

**Files:**
- Modify: `.github/workflows/ci.yml`
- Test: `build/scripts/validate-release-workflow.sh`

- [ ] **Step 1: 修改 `ci.yml` 触发条件**

实现要求：

- 删除 `push`
- 仅保留 `pull_request`

- [ ] **Step 2: 精简 `ci.yml` 步骤**

保留：

- checkout
- Flutter 安装
- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test`
- `bash build/scripts/release-cli-smoke-test.sh`

删除：

- smoke-test version 解析
- Docker Buildx
- Debian 10 release image 构建
- `package-smoke-test.sh`

- [ ] **Step 3: 为轻量校验添加必要注释**

仅在触发或职责边界不够自解释的位置增加简短注释，说明：

- PR workflow 不承担完整打包职责
- packaging smoke test 已迁移到 nightly

- [ ] **Step 4: 运行工作流约束校验**

Run: `bash build/scripts/validate-release-workflow.sh`  
Expected: 先失败，提示旧断言与新设计不匹配；为下一任务提供校验基线

- [ ] **Step 5: 提交**

```bash
git add .github/workflows/ci.yml
git commit -m "refactor: 精简 PR 校验工作流"
```

### Task 3: 新增 nightly workflow

**Files:**
- Create: `.github/workflows/nightly.yml`
- Test: `build/scripts/nightly-cli-smoke-test.sh`

- [ ] **Step 1: 搭建 workflow 入口**

实现要求：

- `name: Nightly`
- `on.schedule.cron: '0 19 * * *'`
- 保留 `workflow_dispatch`
- 添加顶层 `run-name`：
  - 定时触发显示 `Nightly build (scheduled)`
  - 手动触发显示 `Nightly build (manual)`
- `permissions: contents: write`

- [ ] **Step 2: 实现 `prepare-nightly` job**

实现要求：

- 仅默认分支允许继续
- checkout 默认分支 `HEAD`
- 调用 `resolve-nightly-metadata.sh`
- 查询现有 `nightly` prerelease
- 从 release body 提取上次发布 SHA
- 输出：
  - `should_publish`
  - `base_version`
  - `nightly_label`
  - `short_sha`
  - `nightly_date`
- job 名称带 `nightly_label`

- [ ] **Step 3: 实现 `build-nightly-amd64` job**

实现要求：

- 仅在 `should_publish == true` 时执行
- 复用现有 Debian 10 容器构建链
- 使用 `base_version` 运行：
  - `package-smoke-test.sh`
- 调用 `prepare-nightly-assets.sh` 生成对外 nightly 文件名
- 上传 nightly assets artifact
- job 名称带 `nightly_label`

- [ ] **Step 4: 实现 `publish-nightly` job**

实现要求：

- 下载 staged nightly assets
- 生成 nightly release notes，正文至少包含：
  - nightly 标签
  - source commit
  - source date
  - 下载说明
  - requirements
- 更新固定 tag `nightly`
- 更新固定 prerelease：
  - 标题 `Nightly Build <nightly_label>`
  - `prerelease: true`
  - `latest: false`
- 覆盖旧 assets
- job 名称带 `nightly_label`

- [ ] **Step 5: 显式处理 skip 路径**

实现要求：

- 当 `should_publish == false` 时，workflow 输出清晰 skip 信息
- 不构建、不上传、不覆盖 prerelease

- [ ] **Step 6: 本地跑 nightly 辅助 smoke test**

Run: `bash build/scripts/nightly-cli-smoke-test.sh`  
Expected: PASS，nightly 辅助脚本满足 workflow 依赖

- [ ] **Step 7: 提交**

```bash
git add .github/workflows/nightly.yml
git commit -m "feat: 增加 nightly 预发布工作流"
```

### Task 4: 为正式 release workflow 补版本可见性而不引入 nightly 污染

**Files:**
- Modify: `.github/workflows/release.yml`
- Test: `build/scripts/validate-release-workflow.sh`
- Test: `build/scripts/release-cli-smoke-test.sh`

- [ ] **Step 1: 更新 `release.yml` 顶层显示信息**

实现要求：

- 增加合适的顶层 `run-name`
- 让 `workflow_dispatch` 触发在 Actions 页面具备版本辨识信息

- [ ] **Step 2: 更新关键 job 名称**

实现要求：

- `prepare-release`
- `build-amd64`
- `build-arm64`
- `build-arm64-qemu`
- `publish-release`

这些 job 在不破坏 `needs` / `if` 的前提下，名称中包含版本信息或明确的版本上下文

- [ ] **Step 3: 保持正式 release 逻辑边界**

实现要求：

- 不引入 nightly tag、nightly metadata、nightly skip 逻辑
- 不改变现有双架构成功判定规则

- [ ] **Step 4: 运行 release CLI smoke test**

Run: `bash build/scripts/release-cli-smoke-test.sh`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add .github/workflows/release.yml
git commit -m "refactor: 增强正式发布工作流版本展示"
```

### Task 5: 更新工作流约束校验脚本

**Files:**
- Modify: `build/scripts/validate-release-workflow.sh`
- Test: `build/scripts/validate-release-workflow.sh`

- [ ] **Step 1: 删除旧断言**

移除以下旧设计假设：

- `ci.yml` 必须包含 `push`
- `ci.yml` 必须包含 `package-smoke-test.sh`

- [ ] **Step 2: 增加新断言**

新增约束：

- `ci.yml` 包含 `pull_request`
- `ci.yml` 包含 `release-cli-smoke-test.sh`
- `nightly.yml` 存在
- `nightly.yml` 包含 `schedule`
- `nightly.yml` 包含 `workflow_dispatch`
- `nightly.yml` 包含 `package-smoke-test.sh`
- `nightly.yml` 包含 `nightly`
- `release.yml` 继续包含：
  - `workflow_dispatch`
  - `contents: write`
  - `ubuntu-24.04-arm`
  - 现有 arm64 fallback 判定

- [ ] **Step 3: 运行校验脚本**

Run: `bash build/scripts/validate-release-workflow.sh`  
Expected: PASS，输出新的 workflow validation 成功信息

- [ ] **Step 4: 提交**

```bash
git add build/scripts/validate-release-workflow.sh
git commit -m "test: 更新工作流约束校验脚本"
```

### Task 6: 补充维护文档并做最终验证

**Files:**
- Create: `docs/10-github-workflow-maintenance.md`
- Modify: `docs/superpowers/specs/2026-03-20-github-release-workflow-design.md`（仅当实现与设计有必要的小幅对齐时）
- Test: `build/scripts/validate-release-workflow.sh`
- Test: `build/scripts/release-cli-smoke-test.sh`
- Test: `build/scripts/nightly-cli-smoke-test.sh`

- [ ] **Step 1: 编写维护文档**

文档至少覆盖：

- `ci.yml` / `nightly.yml` / `release.yml` 三者边界
- nightly 的 `UTC+8 03:00` 调度
- nightly 只在默认分支有新 commit 时发布
- nightly 固定 tag / prerelease 约束
- nightly 资产命名规则
- Action 名称中的版本展示策略
- 常见排障方法

- [ ] **Step 2: 核对 spec 与实现一致性**

若实现中出现比 spec 更合理的细节调整，仅做最小幅度文档同步，禁止在此阶段扩大范围。

- [ ] **Step 3: 运行最终验证**

Run: `bash build/scripts/validate-release-workflow.sh`  
Expected: PASS

Run: `bash build/scripts/release-cli-smoke-test.sh`  
Expected: PASS

Run: `bash build/scripts/nightly-cli-smoke-test.sh`  
Expected: PASS

- [ ] **Step 4: 检查 git 状态**

Run: `git status --short`  
Expected: 仅包含本任务预期的文档与 workflow / script 变更

- [ ] **Step 5: 提交**

```bash
git add docs/10-github-workflow-maintenance.md docs/superpowers/specs/2026-03-20-github-release-workflow-design.md
git commit -m "docs: 补充 GitHub 工作流维护说明"
```
