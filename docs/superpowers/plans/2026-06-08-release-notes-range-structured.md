# Release Notes 范围驱动结构化生成 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 GitHub Release Notes 从显式范围生成用户可读条目，并由脚本统一渲染编号。

**Architecture:** `generate-changelog.sh` 负责解析 release notes 起点并保持 deterministic fallback；`claude-code-release-changelog.sh` 负责生成小上下文、调用 Claude、解析 JSON 条目并渲染 Markdown；release/nightly workflow 只注入可选起点变量。AI 不再直接输出 Markdown 编号。

**Tech Stack:** Bash, GitHub Actions, Claude Code CLI, jq, existing release smoke tests.

---

### Task 1: 文档约定

**Files:**
- Create: `docs/superpowers/specs/2026-06-08-release-notes-range-structured-design.md`
- Create: `docs/superpowers/plans/2026-06-08-release-notes-range-structured.md`

- [x] **Step 1: 记录设计**

写明 start ref 输入、JSON 输出、脚本编号、fallback 和测试要求。

- [x] **Step 2: 提交文档**

Run:

```bash
git add docs/superpowers/specs/2026-06-08-release-notes-range-structured-design.md docs/superpowers/plans/2026-06-08-release-notes-range-structured.md
git commit -m "docs: 记录 release notes 结构化生成方案"
```

### Task 2: 先写失败测试

**Files:**
- Modify: `build/scripts/release-cli-smoke-test.sh`
- Modify: `build/scripts/nightly-cli-smoke-test.sh`

- [ ] **Step 1: release smoke test 改为 fake Claude JSON 成功输出**

把 fake Claude 成功输出改为：

```json
{"items":[{"kind":"新增","text":"支持从网页商店拉起客户端并加入安装队列。"}]}
```

断言最终 Markdown 包含：

```text
1、支持从网页商店拉起客户端并加入安装队列。
```

- [ ] **Step 2: release smoke test 增加非法 `0、` 输出**

fake Claude 输出 Markdown：

```markdown
## Release Notes

0、新增：错误编号不应进入最终发布说明。
```

断言最终结果不包含 `0、`，并回退到 deterministic 输出。

- [ ] **Step 3: release smoke test 增加 start ref 环境变量断言**

用 `LINGLONG_RELEASE_NOTES_START_REF=v3.1.0` 调用 `generate-changelog.sh 3.1.1`，断言 fake Claude prompt/context 中出现 `当前基线引用：v3.1.0`。

- [ ] **Step 4: nightly smoke test 改为 fake Claude JSON 成功输出**

断言 JSON 渲染后的 changelog 存在，并且 `Nightly source commit` / `Nightly source date` / `Nightly version label` 不变。

- [ ] **Step 5: 运行测试并确认失败**

Run:

```bash
bash build/scripts/release-cli-smoke-test.sh
bash build/scripts/nightly-cli-smoke-test.sh
```

Expected: FAIL，原因是脚本尚不支持 JSON 条目和 start ref 环境变量。

### Task 3: 实现范围解析与结构化渲染

**Files:**
- Modify: `build/scripts/generate-changelog.sh`
- Modify: `build/scripts/generate-nightly-release-notes.sh`
- Modify: `build/scripts/claude-code-release-changelog.sh`
- Modify: `build/scripts/ai-release-notes-system-prompt.md`

- [ ] **Step 1: `generate-changelog.sh` 支持 `LINGLONG_RELEASE_NOTES_START_REF`**

解析优先级：第二个参数 > 环境变量 > 自动 stable tag。传给 Dart fallback 和 Claude wrapper 的 baseline 必须一致。

- [ ] **Step 2: `generate-nightly-release-notes.sh` 支持 start ref 覆盖**

当 `LINGLONG_RELEASE_NOTES_START_REF` 存在时，用它替代上一版 nightly source commit 调用 `generate-changelog.sh`。

- [ ] **Step 3: `claude-code-release-changelog.sh` 改为生成精简上下文**

上下文只包含范围、候选提交、变更文件和少量 docs 摘录。

- [ ] **Step 4: `claude-code-release-changelog.sh` 改为解析 JSON**

新增 JSON 校验与 Markdown 渲染函数；AI 输出非法时退出非零，让上层 fallback。

- [ ] **Step 5: 清理 prompt**

删除“特殊用户要求”，改为严格 JSON 输出说明；明确禁止 AI 修改文件、提交或输出编号。

- [ ] **Step 6: 运行 smoke tests 并确认通过**

Run:

```bash
bash build/scripts/release-cli-smoke-test.sh
bash build/scripts/nightly-cli-smoke-test.sh
```

- [ ] **Step 7: 提交脚本与测试**

Run:

```bash
git add build/scripts/ai-release-notes-system-prompt.md build/scripts/claude-code-release-changelog.sh build/scripts/generate-changelog.sh build/scripts/generate-nightly-release-notes.sh build/scripts/release-cli-smoke-test.sh build/scripts/nightly-cli-smoke-test.sh
git commit -m "fix: 结构化生成 release notes"
```

### Task 4: Workflow 与维护文档

**Files:**
- Modify: `.github/workflows/release.yml`
- Modify: `.github/workflows/nightly.yml`
- Modify: `docs/12-github-workflow-maintenance.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: workflow 注入可选起点变量**

在 release 和 nightly 生成 notes 的 step 中增加：

```yaml
LINGLONG_RELEASE_NOTES_START_REF: ${{ vars.LINGLONG_RELEASE_NOTES_START_REF }}
```

- [ ] **Step 2: 维护文档记录约定**

记录 start ref、JSON 输出、脚本编号和禁止 prompt 临时要求。

- [ ] **Step 3: 验证 workflow 约束与 smoke tests**

Run:

```bash
bash build/scripts/validate-release-workflow.sh
bash build/scripts/release-cli-smoke-test.sh
bash build/scripts/nightly-cli-smoke-test.sh
```

- [ ] **Step 4: 提交 workflow 与文档**

Run:

```bash
git add .github/workflows/release.yml .github/workflows/nightly.yml docs/12-github-workflow-maintenance.md AGENTS.md
git commit -m "docs: 补充 release notes 生成约定"
```

### Task 5: 最终验证

- [ ] **Step 1: 运行 release 相关验证**

Run:

```bash
bash build/scripts/validate-release-workflow.sh
bash build/scripts/release-cli-smoke-test.sh
bash build/scripts/nightly-cli-smoke-test.sh
```

- [ ] **Step 2: 运行 Flutter 静态分析**

Run:

```bash
/home/han/flutter/bin/flutter analyze
```

- [ ] **Step 3: 检查 git 状态**

Run:

```bash
git status --short
```
