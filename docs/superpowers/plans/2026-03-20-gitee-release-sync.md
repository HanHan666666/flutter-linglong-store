# Gitee Mirror And Release Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 Flutter 仓库建立 `hanplus/flutter-linglong-store` 的 Gitee 镜像，并提供一个仓库内可复用的 GitHub Release 同步脚本，用于把 GitHub Release 与资产同步到 Gitee Release。

**Architecture:** Git refs 同步与 Release API 同步分层处理。Git 镜像通过 `git remote` 完成；Release 同步能力收敛在 `tool/release/` 下的 Python CLI，由 `build/scripts/sync-gitee-release.sh` 提供统一入口，并在文档中固化环境变量和执行顺序。这样可以保持当前仓库的发布入口一致，同时避免引入 Node 运行时。

**Tech Stack:** Git, Bash, Python 3, GitHub REST API, Gitee REST API

---

### Task 1: 记录设计与建立隔离工作区基线

**Files:**
- Create: `docs/superpowers/specs/2026-03-20-gitee-release-sync-design.md`
- Create: `docs/superpowers/plans/2026-03-20-gitee-release-sync.md`

- [ ] **Step 1: 写入设计文档**

```markdown
- 目标仓库: hanplus/flutter-linglong-store
- 同步顺序: git refs -> tags -> release
- GITEE_REPO 需要支持 URL 和 owner/repo 两种输入
```

- [ ] **Step 2: 写入实施计划**

```markdown
- 远端建仓
- git mirror 同步
- release 同步脚本迁移
- 文档补充
```

- [ ] **Step 3: 运行现有发布 smoke test 验证基线**

Run: `bash build/scripts/release-cli-smoke-test.sh && bash build/scripts/validate-release-workflow.sh`
Expected: PASS

- [ ] **Step 4: 提交设计与计划文档**

```bash
git add docs/superpowers/specs/2026-03-20-gitee-release-sync-design.md docs/superpowers/plans/2026-03-20-gitee-release-sync.md
git commit -m "docs: 补充 Gitee 同步方案与计划"
```

### Task 2: 创建 Gitee 仓库并同步当前 Git refs

**Files:**
- Modify: `.git/config` 或仓库 remote 配置（运行时变更，不提交）

- [ ] **Step 1: 使用 Gitee API 创建空仓库**

Run:

```bash
curl -X POST "https://gitee.com/api/v5/user/repos" \
  -d "access_token=$GITEE_TOKEN" \
  -d "name=flutter-linglong-store" \
  -d "private=true"
```

Expected: 返回仓库元数据，`full_name` 为 `hanplus/flutter-linglong-store`

- [ ] **Step 2: 配置 `gitee` remote**

Run:

```bash
git remote add gitee "https://hanplus:${GITEE_TOKEN}@gitee.com/hanplus/flutter-linglong-store.git"
```

Expected: `git remote -v` 中出现 `gitee`

- [ ] **Step 3: 推送默认分支与 tags**

Run:

```bash
git push gitee master
git push gitee --tags
```

Expected: `master` 和现有 `v3.0.x` tags 全部存在于 Gitee

- [ ] **Step 4: 验证目标 tag 已存在**

Run:

```bash
git ls-remote gitee HEAD refs/tags/v3.0.2
```

Expected: 至少返回 `HEAD` 和 `refs/tags/v3.0.2`

### Task 3: 迁移 Release 同步脚本到当前仓库

**Files:**
- Create: `tool/release/sync_github_release_to_gitee.py`
- Create: `build/scripts/sync-gitee-release.sh`

- [ ] **Step 1: 先写脚本帮助输出与参数校验**

```python
if not github_token or not gitee_token:
    raise SystemExit("Missing GITHUB_TOKEN or GITEE_TOKEN")
```

- [ ] **Step 2: 实现仓库标识规范化**

```python
normalize_gitee_repo("hanplus/flutter-linglong-store") == "hanplus/flutter-linglong-store"
normalize_gitee_repo("https://gitee.com/hanplus/flutter-linglong-store.git") == "hanplus/flutter-linglong-store"
```

- [ ] **Step 3: 迁移旧版同步逻辑并收敛配置**

```python
CONFIG = {
    "github_repo": os.environ.get("GITHUB_REPO", "HanHan666666/flutter-linglong-store"),
    "gitee_repo": normalize_gitee_repo(os.environ.get("GITEE_REPO", "hanplus/flutter-linglong-store")),
}
```

- [ ] **Step 4: 为 Bash 入口补齐环境变量加载**

```bash
if [[ -f "${LINGLONG_RELEASE_ENV_FILE:-/home/han/linglong-repo.sh}" ]]; then
  source "${LINGLONG_RELEASE_ENV_FILE:-/home/han/linglong-repo.sh}"
fi
```

- [ ] **Step 5: 运行帮助与缺参冒烟**

Run:

```bash
bash build/scripts/sync-gitee-release.sh --help
env -i bash build/scripts/sync-gitee-release.sh
```

Expected:
- `--help` 正常输出使用说明
- 缺少 token 时返回非 0，并打印缺失项

- [ ] **Step 6: 提交同步脚本**

```bash
git add tool/release/sync_github_release_to_gitee.py build/scripts/sync-gitee-release.sh
git commit -m "feat: 增加 Gitee Release 同步脚本"
```

### Task 4: 首次同步现有 GitHub Release 到 Gitee

**Files:**
- Runtime only: Gitee 远端 Release 元数据

- [ ] **Step 1: 执行首次同步**

Run:

```bash
bash build/scripts/sync-gitee-release.sh
```

Expected: 至少同步 `v3.0.2`，并上传 8 个资产

- [ ] **Step 2: 再执行一次确认幂等**

Run:

```bash
bash build/scripts/sync-gitee-release.sh
```

Expected: 输出 `v3.0.2 无需更新` 或等价提示，不重复上传资产

### Task 5: 补正式文档并记录仓库约定

**Files:**
- Create: `docs/08-gitee-release-sync.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 写 Gitee 同步操作文档**

```markdown
- 建仓命令
- gitee remote 配置
- 同步 tags 命令
- sync-gitee-release.sh 用法
```

- [ ] **Step 2: 在仓库指南追加约定**

```markdown
- Gitee Release 同步统一走 build/scripts/sync-gitee-release.sh
- GITEE_REPO 允许写 URL，但脚本内部统一归一到 owner/repo
```

- [ ] **Step 3: 运行最终验证**

Run:

```bash
bash build/scripts/release-cli-smoke-test.sh
bash build/scripts/validate-release-workflow.sh
bash build/scripts/sync-gitee-release.sh --help
```

Expected: 全部 PASS

- [ ] **Step 4: 提交文档收尾**

```bash
git add docs/08-gitee-release-sync.md AGENTS.md
git commit -m "docs: 补充 Gitee 发布同步说明"
```
