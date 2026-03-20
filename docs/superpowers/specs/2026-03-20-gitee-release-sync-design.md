# Gitee Mirror And Release Sync Design

**Date:** 2026-03-20

## Background

当前 Flutter 仓库已经具备 GitHub Release 工作流和正式资产命名规则，但还没有：

- 对应的 Gitee 镜像仓库同步流程
- 将 GitHub Release 同步到 Gitee Release 的稳定脚本
- 面向当前仓库的 Gitee 发布文档与环境变量规范

旧版 Rust 商店仓库里已经有一套 `tools/github2gitee/` 脚本，能力包括：

- 读取 GitHub Release 列表
- 对比 Gitee Release 是否需要更新
- 下载 GitHub Release 资产并重新上传到 Gitee
- 同步标题、正文、预发布标记

本次需求要求：

- 将当前 Flutter 仓库同步到 Gitee 仓库 `hanplus/flutter-linglong-store`
- 将当前 GitHub 已存在的 Release 同步到 Gitee Release
- 将旧版 Rust 仓库里的 Release 同步能力适配到当前 Flutter 仓库，便于后续重复执行
- 所有关键业务约束写入 `docs/`

## Confirmed Requirements

- Gitee 用户名固定为 `hanplus`
- 目标仓库名固定为 `flutter-linglong-store`
- 本次需要同时完成：
  - Git 仓库镜像同步
  - 现有 GitHub Release 到 Gitee Release 的一次性同步
  - 当前仓库内的脚本适配与文档落地
- 同步脚本必须兼容 `/home/han/linglong-repo.sh` 一类现有环境变量来源
- 现有 GitHub Release 资产命名与正文内容必须原样保留，不能擅自改名或重写
- 先推送 tag，再创建 Gitee Release；缺少 tag 时必须失败并给出明确信息

## Current Constraints

### Gitee Repo Identifier Is Not Stable

现有 `/home/han/linglong-repo.sh` 中的 `GITEE_REPO` 不是旧脚本预期的 `owner/repo`，而是完整 URL。当前仓库如果直接复用 Rust 版脚本，会在 Gitee API 请求阶段直接出现 404。

因此新方案必须在入口层统一规范化仓库标识，至少支持：

- `hanplus/flutter-linglong-store`
- `https://gitee.com/hanplus/flutter-linglong-store`
- `https://gitee.com/hanplus/flutter-linglong-store.git`

### Current Repo Does Not Depend On Node

Flutter 仓库当前没有 `package.json`，发布工具链已经收敛在：

- `build/scripts/`
- `tool/release/`

如果直接搬运 Rust 仓库里的 Node 脚本，会给当前仓库新增一个不必要的运行时要求，并打破现有发布工具入口风格。

### Release Source Of Truth

当前正式发布源头是 GitHub 仓库 `HanHan666666/flutter-linglong-store`。Gitee 只承担镜像和分发职责，不重新生成资产，因此同步顺序必须固定为：

1. Git refs 同步到 Gitee
2. 确认目标 tag 已存在于 Gitee
3. 再同步对应 GitHub Release 和资产

## Approaches

### Option A: 直接复用 Rust 仓库 Node 脚本

**Pros**

- 一次性接入最快
- 旧脚本已有完整的下载与上传逻辑

**Cons**

- 当前仓库新增 Node 运行时依赖
- 与现有 `build/scripts/` / `tool/release/` 结构不一致
- 不能解决 `GITEE_REPO` 输入格式不稳定的问题，仍需额外补丁

### Option B: 保留 Bash 入口，核心同步逻辑下沉到 Python CLI

**Pros**

- 当前开发环境天然具备 Python 3
- 适合处理 HTTP 请求、文件下载和 multipart 上传
- 不需要引入 Node 或额外 Dart HTTP 依赖
- 可以通过 `build/scripts/` 提供稳定入口，和现有发布工具链保持一致

**Cons**

- 需要为当前仓库重新整理同步逻辑
- 要补齐最小的脚本测试与文档

### Option C: 全量改写为 Dart CLI

**Pros**

- 语言栈最统一
- 能完全对齐 `tool/release/` 目录风格

**Cons**

- 当前仓库还没有现成的 Dart HTTP 上传封装
- multipart 上传与文件流实现成本更高
- 这次任务目标是尽快完成可用的镜像同步，不适合额外扩展技术面

## Recommended Design

选择 **Option B**。

### Tooling Layout

新增两层结构：

- `tool/release/sync_github_release_to_gitee.py`
  - 负责 GitHub / Gitee API 访问
  - 负责 Release 对比、删除、创建、附件下载与上传
  - 负责规范化 `GITEE_REPO`
- `build/scripts/sync-gitee-release.sh`
  - 负责加载环境变量
  - 负责校验 `GITHUB_TOKEN`、`GITEE_TOKEN`
  - 负责把仓库级命令收敛成一个稳定入口

这样可以保持：

- 业务逻辑集中在 `tool/release/`
- Shell 只做入口和环境准备
- 后续 CI / cron / 手工执行都复用同一个入口

### Git Mirror Strategy

仓库同步使用 `git remote add gitee` + `git push` 完成，不把 Git mirror 逻辑内嵌进 Python 脚本。

原因：

- Git refs 同步和 Release API 调用是两类职责
- Git 本身已经是推送 refs 的唯一可信实现
- 脚本只需要依赖“tag 已存在”，不应该再自己调用 `git push`

本次一次性同步步骤固定为：

1. 在 Gitee 创建空仓库 `hanplus/flutter-linglong-store`
2. 本地新增 `gitee` remote
3. 推送默认分支
4. 推送全部 tags
5. 再运行 Release 同步脚本

### Release Update Rules

同步脚本需要按 tag 对齐 GitHub Release 与 Gitee Release：

- Gitee 不存在同 tag Release：直接创建
- Gitee 已存在同 tag Release，但正文不同：删除并重建
- Gitee 已存在同 tag Release，但附件数量、名称或大小不同：删除并重建
- 完全一致：跳过

删除重建仍沿用 Rust 旧版逻辑，而不是在 Gitee 侧做增量附件修补，原因是：

- Gitee Release API 对附件局部更新支持有限
- 当前版本数量少，重建成本可控
- 行为更确定，便于排查

### Repository Identifier Normalization

同步脚本增加统一的仓库标识规范化函数：

- 输入 URL 时剥离协议头、域名和可选 `.git`
- 最终输出固定的 `owner/repo`
- 非 `gitee.com` URL 或不符合两段路径格式时直接失败

这样可以兼容：

- `GITEE_REPO=hanplus/flutter-linglong-store`
- `GITEE_REPO=https://gitee.com/hanplus/flutter-linglong-store`
- 旧环境变量文件中的 URL 写法

### Documentation Requirements

必须新增一份正式文档，至少覆盖：

- 建仓前提
- 环境变量要求
- 首次同步 Git refs 的命令
- 同步 Release 的命令
- “先推 tag 再同步 Release”的约束
- Gitee 单文件大小限制与失败行为

## Testing Strategy

验证分成三层：

1. 入口验证
   - `build/scripts/sync-gitee-release.sh --help`
   - 缺失 token 时明确失败
2. 规范化与参数单测
   - 针对 `GITEE_REPO` URL / `owner/repo` 两种输入验证输出一致
3. 端到端冒烟
   - 首次创建 Gitee 仓库后推送分支与 tag
   - 同步现有 `v3.0.2` Release
   - 再次运行脚本时应命中“无需更新”分支

## Risks And Mitigations

### Risk: Gitee 仓库不存在

- 症状：API / git 直接 404
- 处理：在正式同步前显式创建仓库，并把建仓步骤写入文档

### Risk: Gitee Token 权限不足

- 症状：Release 创建返回 403
- 处理：脚本保留原始响应体，并在文档中注明需要 `projects` 权限

### Risk: Tag 未推送到 Gitee

- 症状：Release 创建失败
- 处理：脚本打印明确提示，要求先执行 `git push gitee --tags`

### Risk: 同步脚本重复上传大文件

- 症状：同步慢
- 处理：先对比附件名称和大小；一致则直接跳过整个 Release
