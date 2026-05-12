# AI Release Notes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 release/nightly 发布链路中接入 Claude Code 生成 changelog，保留现有脚本作为 fallback，并把 GitHub Secret 中的完整 Claude `settings.json` 原文写回 CI 的 `~/.claude/settings.json`。

**Architecture:** 维持现有 `generate-changelog.sh` 与 `generate-nightly-release-notes.sh` 的发布入口不变，把 AI 能力收敛为一个 shell wrapper。wrapper 负责安装 Claude Code CLI、写入用户级 settings、准备上下文包、生成结构化 changelog；现有 deterministic Dart/shell 脚本继续负责基线和失败回退。

**Tech Stack:** GitHub Actions, Bash, Dart release tooling, Claude Code CLI, jq

---

### Task 1: 实现 Claude Code CLI wrapper 与安装脚本

**Files:**
- Create: `build/scripts/install-claude-code.sh`
- Create: `build/scripts/claude-code-release-changelog.sh`

- [ ] 写安装脚本，支持显式版本与自定义可执行文件覆盖。
- [ ] 写 settings 写回逻辑：从 `CLAUDE_CODE_SETTINGS_JSON` 写到 `~/.claude/settings.json`，校验 JSON，收紧权限。
- [ ] 写上下文包生成逻辑：收集 deterministic changelog、git log、README 摘要、workflow 约束摘要。
- [ ] 用 `claude -p --bare --setting-sources user --tools "" --max-turns 1 --json-schema ...` 生成结构化 Markdown。
- [ ] 当 Secret 缺失、Claude 失败或输出校验失败时回退到 deterministic changelog。

### Task 2: 把 AI 增强接入 stable/nightly notes 入口

**Files:**
- Modify: `build/scripts/generate-changelog.sh`
- Modify: `build/scripts/generate-nightly-release-notes.sh`
- Modify: `.github/workflows/release.yml`
- Modify: `.github/workflows/nightly.yml`

- [ ] 修改 `generate-changelog.sh`：先产出 deterministic changelog，再尝试 Claude 增强。
- [ ] 修改 `generate-nightly-release-notes.sh`：把 direct Dart 调用改成复用增强后的 `generate-changelog.sh`。
- [ ] 在 `release.yml` 的 notes 生成步骤注入 `CLAUDE_CODE_SETTINGS_JSON` secret。
- [ ] 在 `nightly.yml` 的 notes 生成步骤注入 `CLAUDE_CODE_SETTINGS_JSON` secret。
- [ ] 保持 nightly 元数据与 hash 追加时序不变。

### Task 3: 扩展 smoke test 覆盖 AI 成功/失败分支

**Files:**
- Modify: `build/scripts/release-cli-smoke-test.sh`
- Modify: `build/scripts/nightly-cli-smoke-test.sh`

- [ ] 为 release smoke test 增加 fake Claude executable，覆盖成功生成与失败回退两条路径。
- [ ] 校验 fake Claude 模式下 `~/.claude/settings.json` 被正确写入。
- [ ] 校验 AI 结果只替换 `## Release Notes` 段落，不提前写入哈希段。
- [ ] 为 nightly smoke test 增加 fake Claude 成功路径，确认 `Nightly source commit` 等元数据不变。

### Task 4: 更新文档并执行验证

**Files:**
- Modify: `docs/12-github-workflow-maintenance.md`

- [ ] 在 workflow 维护文档中补充 AI changelog 的入口、Secret 约定、fallback 策略。
- [ ] 运行 `bash build/scripts/release-cli-smoke-test.sh`。
- [ ] 运行 `bash build/scripts/nightly-cli-smoke-test.sh`。
- [ ] 运行 `bash build/scripts/validate-release-workflow.sh`。