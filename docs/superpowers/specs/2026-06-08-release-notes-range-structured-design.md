# Release Notes 范围驱动结构化生成设计

**日期:** 2026-06-08

## 背景

`nightly-20260607` 的 GitHub Release body 曾出现 `0、新增：...`，并且内容直接复述 commit 标题，例如把 `og` 协议注册、解析、单实例转发和安装入队拆成多条工程实现说明。用户期望 release notes 面向普通用户：说明实际能感知到的功能和修复，而不是展示提交记录。

当前链路是：

- `release.yml` 调用 `build/scripts/generate-changelog.sh` 生成 `## Release Notes`。
- `nightly.yml` 调用 `build/scripts/generate-nightly-release-notes.sh`，内部复用 `generate-changelog.sh`。
- `generate-changelog.sh` 先生成 deterministic changelog，再在 `CLAUDE_CODE_SETTINGS_JSON` 存在时调用 `claude-code-release-changelog.sh`。
- Claude 失败时回退 deterministic changelog。

问题在于 deterministic changelog 仍以 commit subject 为主体；Claude 分支让模型直接输出 Markdown 编号，编号权在模型手里；prompt 中还残留一次性“特殊用户要求”，把“从哪里开始总结”藏进自然语言指令，容易污染长期 CI 行为。

## 目标

1. 让 changelog 起点由脚本参数或环境变量显式决定，而不是写在 prompt 里。
2. 让 AI 只输出结构化条目，不输出 Markdown 编号。
3. 由脚本统一渲染 `1、2、3` 编号，从机制上杜绝 `0、`。
4. AI 输入只保留范围、候选提交、变更文件和相关文档摘录，避免把大段上下文直接塞给模型。
5. AI 不可用或输出非法时，回退内容也必须过滤文档、CI、工具链、注释规范等维护项。
6. 删除 prompt 中的临时特殊要求，禁止 CI 里的 release notes 任务尝试改文件或提交。

## 非目标

- 不引入新的 AI 服务。
- 不改变 release/nightly 发布资产、哈希追加、签名和 UOS/AUR 发布流程。
- 不让 AI 写入仓库文件，也不让 AI 决定下载说明、Requirements 或 Nightly metadata。
- 不把 release notes 扩展成完整变更文章；仍保持最多 5 条。

## 方案

### 范围输入

新增可选环境变量：

- `LINGLONG_RELEASE_NOTES_START_REF`

含义：显式指定 release notes 的左边界，最终范围为 `LINGLONG_RELEASE_NOTES_START_REF..HEAD`。优先级为：

1. `generate-changelog.sh <version> <start-ref>` 的第二个参数。
2. `LINGLONG_RELEASE_NOTES_START_REF`。
3. stable release 自动解析最近 stable tag。
4. nightly 使用上一版 nightly source commit。

如果显式传入的 start ref 不存在，应直接失败并输出明确错误；如果 nightly 历史 release body 里的上一版 source commit 不可用，继续沿用现有首版兜底文案。

### AI 输入

`claude-code-release-changelog.sh` 不再把完整 README、workflow 维护文档和 deterministic changelog 一起塞给 Claude。上下文包改为小而明确：

- 目标版本、构建类型、start ref、end ref。
- `git log --reverse <start-ref>..HEAD` 的 commit hash 与 subject。
- 每个候选 commit 的变更文件列表。
- 范围内改动过的 `docs/*.md` 前若干行摘录，最多保留少量文档，作为业务语义证据。
- 明确声明：不要复述 commit subject，要合并同一用户功能链路。

### AI 输出

Claude 必须输出严格 JSON：

```json
{
  "items": [
    {
      "kind": "新增",
      "text": "支持从网页商店拉起客户端并加入安装队列。"
    }
  ]
}
```

约束：

- `kind` 只能是 `新增` 或 `修复`。
- `text` 是不含编号、不含 `新增：`/`修复：` 前缀的一句话中文。
- 最多 5 条。
- 没有用户可见变化时输出 `{"items":[]}`。

脚本负责把 JSON 渲染为：

```markdown
## Release Notes

1、新增：支持从网页商店拉起客户端并加入安装队列。
```

### 校验与回退

脚本校验：

- JSON 结构合法。
- 条目数量为 0 到 5。
- 每条包含合法 `kind` 和非空 `text`。
- `text` 不得包含换行、Markdown 标题、编号前缀、AI/prompt/commit/CI/workflow/AUR/UOS/文档/测试/重构等维护性词汇。

如果 AI 输出非法或 Claude 失败，回退 deterministic changelog。deterministic 过滤规则同步增强，避免把 `AGENTS.md` / `CLAUDE.md` 注释规范、技术栈模板、发布脚本和 workflow 改动写给普通用户。

## 测试

- release smoke test 覆盖 JSON 成功路径，确认最终 Markdown 从 `1、` 开始。
- release smoke test 覆盖 AI 输出 `0、` Markdown 的非法路径，确认不会进入最终 notes。
- release smoke test 覆盖 `LINGLONG_RELEASE_NOTES_START_REF` 能作为范围左边界传给 prompt/context。
- nightly smoke test 覆盖 JSON 成功路径，并确认 Nightly metadata 仍保留。
- prompt smoke test 覆盖不再包含“特殊用户要求”和 git commit 指令。

## 文档约定

完成后同步 `docs/12-github-workflow-maintenance.md` 和 `AGENTS.md`：

- release notes 起点必须通过脚本参数或 `LINGLONG_RELEASE_NOTES_START_REF` 指定。
- AI 只能产出结构化条目，Markdown 编号统一由脚本渲染。
- prompt 中禁止保留一次性临时业务指令。
