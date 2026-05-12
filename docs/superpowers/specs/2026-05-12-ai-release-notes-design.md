# AI Release Notes Design

**Date:** 2026-05-12

## Background

当前仓库的 GitHub Release 说明生成链路已经稳定运行：

- 正式发版在 `.github/workflows/release.yml` 的 `prepare-release` 中先调用 `build/scripts/generate-changelog.sh` 生成 `## Release Notes` 段落，再在 workflow 里追加固定的下载说明与运行环境说明。
- nightly 在 `.github/workflows/nightly.yml` 的 `publish-nightly` 中调用 `build/scripts/generate-nightly-release-notes.sh` 生成完整说明，其中 `Nightly source commit` 同时作为下一次 nightly 的范围基线。
- 正式版和 nightly 都会在发布前通过 `build/scripts/append-release-asset-hashes.sh` 追加 `SHA256 Hashes of the release artifacts` 段落，因此 changelog 生成阶段不能提前写入该段。

本需求是在 release/nightly 发布时引入 Claude Code，让它基于仓库上下文生成更可读的 changelog，并写入 GitHub Release body。

## Confirmed Requirements

- 使用 Claude Code，而不是额外引入其他 AI 服务实现。
- 在构建脚本里安装并启动 Claude Code，不把安装细节散落到 workflow YAML。
- GitHub Secret 中保存的是完整 `settings.json` 原文，CI 必须原样写回 `~/.claude/settings.json`，用于自定义 Claude Code 后端地址与认证环境。
- Claude 生成 changelog 前必须拿到足够的项目上下文，而不是只看几条 commit subject。
- 现有 deterministic 脚本仍然保留，作为 AI 不可用或生成失败时的回退路径。
- nightly 必须继续保留 `Nightly source commit` / `Nightly source date` / `Nightly version label` 这些固定元数据行。
- `SHA256 Hashes of the release artifacts` 仍然只允许在签名资产下载完成后追加。

## Current Constraints

### Release Notes Contract

- `build/scripts/generate-changelog.sh` 仍然是 stable release notes 的唯一入口，最终输出必须统一为 `## Release Notes` + `1、2、3` 编号列表，最多 `5` 条。
- changelog 只保留用户可感知的功能新增与缺陷修复；文档、CI、workflow、打包、发布流程、AUR/UOS 发布、测试、重构和其他维护性改动即使落在 `feat/fix` 提交里，也应在最终输出中忽略。
- `build/scripts/generate-nightly-release-notes.sh` 会在 changelog 后追加 nightly 固定元数据。
- 当本次范围内没有需要对外说明的功能新增或问题修复时，changelog 统一回退为单条编号文案：`1、本次版本暂无需要特别说明的功能新增或问题修复。`
- release workflow 中提交到 UOS Store 的 `note` 必须直接复用同一份 release notes 中的编号列表摘要，禁止继续手写与 GitHub Release 脱节的固定说明。
- `build/scripts/release-cli-smoke-test.sh` 与 `build/scripts/nightly-cli-smoke-test.sh` 都对 Markdown 结构有显式断言。
- `build/scripts/validate-release-workflow.sh` 目前要求 `release.yml` 继续调用 `generate-changelog.sh`，要求 `nightly.yml` 继续调用 `generate-nightly-release-notes.sh`。

### Claude Code Configuration Precedence

- Claude Code 的配置优先级是 `command line > local > project > user`。
- 仓库已经存在项目级 `.claude/settings.json` 和根级 `CLAUDE.md`。
- 如果 CI 直接以默认模式启动 Claude Code，用户级 `~/.claude/settings.json` 里的后端地址配置可能被项目级配置干扰，仓库内的交互式开发规范也可能被错误带入自动 changelog 任务。

## Approaches

### Option A: 直接使用 `anthropics/claude-code-action@v1`

- 在 workflow 中新增官方 Action step。
- 通过 Action 的 `settings` 输入直接注入 Secret。
- 让 Action 读取仓库上下文并输出结构化 changelog。

**Pros**

- 接入最快。
- 官方维护安装和执行细节。
- 原生支持结构化输出。

**Cons**

- 不符合“在构建脚本里安装并启动 Claude Code”的要求。
- Action 默认会带入更多 Claude 项目上下文，行为面更大。
- 对现有 shell script 体系的复用较弱。

### Option B: 在 shell 脚本里直接安装 Claude Code CLI，并让旧脚本做 fallback

- `generate-changelog.sh` 先运行现有 Dart 生成器拿到 deterministic changelog。
- 当 `CLAUDE_CODE_SETTINGS_JSON` 存在时，脚本把 Secret 写入 `~/.claude/settings.json`，安装 Claude Code CLI，并用一份受控的上下文包让 Claude 重写 `## Release Notes` 段落。
- 生成失败则自动回退到 deterministic 结果。
- nightly 继续通过 `generate-nightly-release-notes.sh` 组装完整 release body，但内部改为复用增强后的 `generate-changelog.sh`。

**Pros**

- 最符合用户要求。
- release/nightly 可以共用同一条 AI changelog 增强链路。
- 行为边界清晰，AI 只负责 changelog 段落，不碰哈希段与 nightly 固定元数据。
- 本地 smoke test 可通过 fake Claude executable 覆盖成功/失败两种路径。

**Cons**

- 需要维护 CLI 安装与 settings 写回脚本。
- 需要我们自己约束输出格式与上下文输入。

### Option C: 让 workflow 先生成上下文文件，再调用本仓库自定义 wrapper action

- 仓库里新增 composite action 或自定义脚本目录。
- workflow 负责准备 Secret 和 prompt，wrapper 负责调用 Claude。

**Pros**

- 逻辑可复用。
- 比直接写在 workflow 里更整洁。

**Cons**

- 相比 Option B 多一层封装，没有明显收益。
- 当前仓库已有稳定的 `build/scripts/` 入口，不需要再引入 action 封装层。

## Recommended Design

选择 **Option B**。

### Architecture

引入三层脚本职责：

1. `build/scripts/generate-changelog.sh`
   - 继续作为 stable changelog 的统一入口。
   - 默认输出 Dart 生成器产物。
   - 当检测到 `CLAUDE_CODE_SETTINGS_JSON` 时，尝试调用 Claude Code 对 changelog 段落做二次生成。
   - Claude 失败时记录 warning，并回退到 deterministic 产物。

2. `build/scripts/claude-code-release-changelog.sh`
   - 新增 Claude Code wrapper。
   - 负责：写入 `~/.claude/settings.json`、安装 Claude Code、组装上下文包、调用 `claude -p`、校验输出结构。
   - 输入是明确的上下文文件和 deterministic changelog，而不是让 Claude 自由扫描整个仓库。

3. `build/scripts/generate-nightly-release-notes.sh`
   - 保持 nightly full-body 入口不变。
   - 原先直接调用 Dart 生成器的地方，改为调用增强后的 `generate-changelog.sh`。
   - nightly 的固定元数据、下载说明和 requirements 仍由脚本自身追加。

### Claude Execution Model

Claude Code 使用非交互 CLI：

- `claude -p`
- `--bare`
- `--setting-sources user`
- `--max-turns 1`
- `--no-session-persistence`
- `--append-system-prompt-file <prompt.txt>`

这样做的目的：

- 只加载我们刚写入的用户级 `~/.claude/settings.json`。
- 不自动读取项目级 `.claude/`、`.mcp.json`、`CLAUDE.md`。
- 通过预先构造的上下文包让 Claude“理解项目上下文”，同时允许它按当前用户级配置分析代码库与 `docs/` 文档。
- 直接要求 Claude 输出 Markdown，然后在 shell 脚本里做结构校验，避免半截文本或额外解释污染输出文件。

### Context Package

上下文包由脚本显式生成，至少包含：

- deterministic changelog 结果
- release/nightly 类型与版本标识
- 本次 commit 范围的 `git log`（subject + body）
- `docs/12-github-workflow-maintenance.md` 中关于 release/nightly notes 的约束摘要
- 仓库简介（`README.md` 的精简片段）

Claude 的任务不是重新推导元数据，而是把这些信息整理成更可读的 `## Release Notes` 段落。

### Failure Policy

默认采用 best-effort：

- Secret 缺失：直接回退 deterministic changelog
- Claude 安装失败：回退 deterministic changelog
- Claude 输出不符合 schema：回退 deterministic changelog
- Claude 生成成功：仅替换 `## Release Notes` 段落

发布流程不因 AI changelog 失败而阻断。

## File Changes

- Modify: `.github/workflows/release.yml`
- Modify: `.github/workflows/nightly.yml`
- Modify: `build/scripts/generate-changelog.sh`
- Modify: `build/scripts/generate-nightly-release-notes.sh`
- Create: `build/scripts/claude-code-release-changelog.sh`
- Create: `build/scripts/install-claude-code.sh`
- Modify: `build/scripts/release-cli-smoke-test.sh`
- Modify: `build/scripts/nightly-cli-smoke-test.sh`
- Modify: `docs/12-github-workflow-maintenance.md`

## Secrets And Environment

- 新增 GitHub Secret: `CLAUDE_CODE_SETTINGS_JSON`
  - 内容是完整的 `settings.json` 原文。
  - 由脚本原样写入 `~/.claude/settings.json`。
- 可选普通环境变量: `LINGLONG_CLAUDE_CODE_VERSION`
  - 控制 CLI 安装版本。
  - 默认使用脚本内置版本或 `latest`。

## Risks

- GitHub runner 的 npm registry 或网络异常会导致 Claude CLI 安装失败，因此必须保留 fallback。
- Claude 生成的 Markdown 如果误写 `SHA256 Hashes of the release artifacts` 段落，会破坏后续哈希追加脚本，因此 prompt 和输出校验都要显式禁止。
- nightly 的元数据行格式不能改变，否则下次 nightly 无法正确解析上一版 `Nightly source commit`。
- Secret 写入 `~/.claude/settings.json` 时不能打印原文，所有脚本必须避免 `set -x` 和 `cat` 输出该文件内容。

## Verification

- `build/scripts/release-cli-smoke-test.sh` 增加 fake Claude 成功/失败用例。
- `build/scripts/nightly-cli-smoke-test.sh` 增加 fake Claude 成功路径，验证 nightly 元数据仍保留。
- `build/scripts/validate-release-workflow.sh` 保持现有关键约束不变，并继续允许 `release.yml` / `nightly.yml` 使用原有入口脚本。