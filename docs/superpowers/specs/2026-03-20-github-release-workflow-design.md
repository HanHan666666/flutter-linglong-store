# GitHub Workflow Design

**Date:** 2026-03-20

## Background

当前仓库已经具备正式 Release 所需的核心脚本与 GitHub Actions 基础链路，但新的发布节奏要求与最初设计发生了变化：

- `push` 不再需要自动跑 GitHub Actions
- `pull_request` 只保留轻量校验，尽量缩短反馈时间
- 真正昂贵的 Linux 打包与冒烟测试统一收敛到每日构建
- 每日构建只需要 `amd64`
- 每日构建要维护一个固定的 GitHub prerelease，而不是每天创建一个新的 Release
- 只有默认分支相对上一次 nightly 有新提交时，才重新发布 nightly
- 工作流在 GitHub Actions 页面上的名称需要体现版本信息，至少不能让 nightly / release 的执行记录失去版本辨识度

这意味着现有“CI 校验 + 正式 Release”二分结构需要升级为“三段式职责分离”：

1. `pull_request` 轻量校验
2. nightly prerelease 构建与发布
3. 手动正式 Release

## Confirmed Requirements

- `ci.yml` 只响应 `pull_request`
- `ci.yml` 只保留轻量校验：
  - `flutter pub get`
  - `dart run build_runner build --delete-conflicting-outputs`
  - `flutter analyze`
  - `flutter test`
- `push` 不再触发日常 GitHub Actions
- 新增 `nightly.yml`
  - 触发：`schedule` + `workflow_dispatch`
  - 定时：每天 `UTC+8 03:00`
  - GitHub Actions cron 使用 UTC，因此实际写为 `0 19 * * *`
  - 只在默认分支执行
  - 只构建 `amd64`
- nightly 复用现有 Debian 10 容器化打包链
- nightly 必须包含现有 packaging smoke test
- nightly 只在默认分支 `HEAD` 相对上一次 nightly 有变化时才真正发布
- nightly 维护固定 prerelease 与固定滚动 tag，而不是每天新建 release
- 正式 `release.yml` 继续只允许 `workflow_dispatch`
- 正式 Release 继续生成 `amd64` + `arm64` 双架构资产
- `Action` 名称必须有版本辨识信息
- 所有关键约束必须写入项目 `docs/`

## Current Project Constraints

### Existing Packaging Baseline

当前 Flutter Linux 构建稳定依赖两段式流程：

1. Flutter 先产出 Linux `bundle`
2. 自定义脚本从 `bundle` 派生：
   - `tar.gz`
   - `.deb`
   - `.rpm`
   - `.AppImage`

核心脚本已经存在：

- `build/scripts/build-linux-bundle.sh`
- `build/scripts/package-bundle.sh`
- `build/scripts/package-deb.sh`
- `build/scripts/package-rpm.sh`
- `build/scripts/package-appimage.sh`
- `build/scripts/package-smoke-test.sh`

因此 nightly 不应该再创建一套平行打包逻辑，而应直接复用这条链路。

### Existing Release Strategy

当前正式 Release 设计已经明确：

- `release.yml` 只负责正式发版
- `workflow_dispatch` 解析正式版本号
- 正式版本需要更新版本源、提交 release commit、打正式 tag
- 正式 Release 页面上传双架构四类资产

新的 nightly 需求不能污染这条正式发版链，否则：

- 版本号规则会混乱
- prerelease 与正式 release 的边界会被打散
- 权限与失败语义会明显复杂化

### GitHub Actions Naming Limitation

GitHub Actions 顶层 `run-name` 在 workflow 启动时就会求值，不能引用后续 job 的运行时输出。这意味着：

- 正式 `release.yml` 可以在 `workflow_dispatch` 时直接把输入版本写进 `run-name`
- nightly 的真实版本标签通常需要先 checkout 仓库、解析 `pubspec.yaml`、拼接日期与提交 SHA 后才能得到
- 因此 nightly 无法把“运行时解析后的完整版本号”百分之百放进顶层 workflow run title

本设计对“Action 名称要有版本号”的落实方式是：

- 正式 Release：顶层 `run-name` 直接体现版本
- nightly：
  - 顶层 `run-name` 体现 nightly channel 与触发方式
  - 关键 job 名称体现 nightly 版本标签
  - GitHub prerelease 标题体现 nightly 版本标签
  - 资产文件名体现 nightly 版本标签

这样虽然不能让 schedule 入口在最外层 run title 使用运行时输出，但版本辨识信息仍然会稳定暴露在用户实际查看与下载的关键位置。

## Approaches

### Option A: 在现有 `ci.yml` 中同时承载 PR 校验和 nightly 发布

- `ci.yml` 同时处理 `pull_request`、`schedule`、`workflow_dispatch`
- 通过 `if:` 分流轻量校验与 nightly 发布

**Pros**
- 文件数量最少
- 现有 CI 文件可以继续复用

**Cons**
- PR 校验与 nightly 发布共享同一 workflow，职责变脏
- `permissions`、artifact 上传、prerelease 更新条件会变复杂
- 后续排查失败时，很难一眼区分是“校验失败”还是“发布失败”

### Option B: 在 `release.yml` 中增加 nightly 模式

- `release.yml` 同时承载手动正式发版与 nightly prerelease

**Pros**
- 现有打包与发布逻辑复用最多

**Cons**
- 正式 Release 与 nightly prerelease 混在一起，风险最高
- 正式 tag / prerelease tag / 版本更新 / changelog 规则会相互缠绕
- 任何 nightly 逻辑错误都更容易误伤正式发布

### Option C: 拆成三条独立工作流

- `ci.yml`：只做 `pull_request` 轻量校验
- `nightly.yml`：只做 nightly 构建与 prerelease 发布
- `release.yml`：只做手动正式发布

**Pros**
- 职责边界最清晰
- PR 反馈最快
- nightly 与正式 release 的权限、版本、tag、失败语义彻底隔离
- 后续维护与排障成本最低

**Cons**
- 需要维护第三个 workflow 文件
- 需要同步更新工作流校验脚本与文档

## Recommended Design

选择 **Option C**。

### Workflow Split

工作流职责调整为三条独立链路：

- `.github/workflows/ci.yml`
  - 只响应 `pull_request`
  - 只做轻量校验
- `.github/workflows/nightly.yml`
  - 响应 `schedule` 与 `workflow_dispatch`
  - 负责 nightly 打包、冒烟测试、固定 prerelease 更新
- `.github/workflows/release.yml`
  - 继续只响应 `workflow_dispatch`
  - 负责正式双架构 Release

### PR Validation Workflow

`ci.yml` 改为：

- 触发：`pull_request`
- 不再响应 `push`
- 不再执行 Debian 10 packaging smoke test
- 不再上传 nightly / release 资产

保留的校验步骤：

- 安装 Flutter
- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test`

这个 workflow 的目标只有一个：尽快发现 PR 里的源码回归，而不是验证完整 Linux 发布链。

### Nightly Trigger and Branch Rules

`nightly.yml` 的触发规则：

- `schedule`
- `workflow_dispatch`

cron 使用：

```yaml
schedule:
  - cron: '0 19 * * *'
```

GitHub Actions 使用 UTC 计时，`0 19 * * *` 对应中国时区 `UTC+8` 的每天 `03:00`。

nightly 还必须加两层保护：

- 只允许默认分支真正执行 nightly 发布逻辑
- 非默认分支手动触发时直接跳过或失败，防止把临时分支误发为 nightly

### Nightly Publication Strategy

nightly 维护一个固定滚动 prerelease：

- 固定 tag：`nightly`
- 固定 Release 标题前缀：`Nightly Build`
- `prerelease: true`
- `latest: false`

nightly 不每天创建新 Release，而是每次覆盖同一个 prerelease。

这样做的原因：

- release 列表不会被 nightly 冲刷
- 用户始终只看到最新一份 nightly
- nightly 天生就是“滚动快照”，不是稳定版本档案

### Nightly Change Detection

“有 commit 才发布”不采用时间窗口判断，而采用“当前默认分支 `HEAD` 是否已被 nightly 覆盖”的判断。

推荐流程：

1. 读取当前默认分支 `HEAD`
2. 查询已有 nightly prerelease
3. 从 release body 的固定元数据字段中提取上一次 nightly 对应的 commit SHA
4. 比较：
   - 如果 SHA 相同：`should_publish=false`，nightly 构建与发布 job 全部跳过
   - 如果 SHA 不同：继续构建、冒烟测试、发布

推荐写入 release body 的元数据：

```text
Nightly source commit: <full_sha>
Nightly source date: <iso8601>
Nightly version label: <nightly_label>
```

这种方式比“过去 24 小时是否有 commit”更稳，因为它判断的是“nightly 是否已经覆盖当前源码状态”，不会因为 GitHub 定时漂移、补跑、人工重跑而重复发布或漏发布。

### Nightly Version Label

nightly 需要一个对人可读、对资产命名稳定、对 GitHub 页面可辨识的版本标签。

推荐生成规则：

- `base_version`：来自当前仓库 `pubspec.yaml` 的语义化版本部分
- `build_date`：使用 `UTC+8` 逻辑日期，格式 `YYYYMMDD`
- `short_sha`：当前默认分支 `HEAD` 的短 SHA

拼接得到：

- `nightly_label = <base_version>-nightly.<YYYYMMDD>+<short_sha>`

示例：

- `3.0.7-nightly.20260321+abc1234`

这个标签用于：

- nightly prerelease 标题
- nightly job 名称
- nightly 资产文件名
- nightly release body 元数据

### Action Naming Strategy

“Action 名称要有版本号”的要求，按工作流类型分开落实。

#### 正式 Release

正式 `release.yml` 可以直接使用顶层 `run-name`，因为版本号来自 `workflow_dispatch` 输入或自动版本解析入口的可预期上下文。

推荐展示效果：

- `Release v3.0.8`
- `Release auto -> v3.0.8`

此外，关键 job 名称也要带版本：

- `Prepare release 3.0.8`
- `Build amd64 3.0.8`
- `Build arm64 3.0.8`
- `Publish release 3.0.8`

#### Nightly

nightly 顶层 `run-name` 无法稳定引用运行时解析出的 `nightly_label`，因此采用分层展示：

- 顶层 `run-name`
  - `Nightly build (scheduled)`
  - `Nightly build (manual)`
- 关键 job 名称包含真实 `nightly_label`
  - `Prepare nightly 3.0.7-nightly.20260321+abc1234`
  - `Build nightly amd64 3.0.7-nightly.20260321+abc1234`
  - `Publish nightly 3.0.7-nightly.20260321+abc1234`
- nightly prerelease 标题包含真实 `nightly_label`
  - `Nightly Build 3.0.7-nightly.20260321+abc1234`

这里的核心原则不是执着于 GitHub Actions 顶层 run title 的单点展示，而是确保用户在“工作流详情、构建 job、Release 页面、下载资产”这些真正会查看的位置，都能稳定看到版本信息。

### Nightly Build and Smoke Test

nightly 继续复用现有 Debian 10 容器化打包链：

- `build/scripts/run-in-release-container.sh`
- `build/docker/debian10-release.Dockerfile`
- `build/scripts/package-smoke-test.sh`

nightly 的职责是完整验证“当前默认分支源码是否还能打出 Linux 发布资产”，因此：

- packaging smoke test 从 `ci.yml` 迁移到 `nightly.yml`
- nightly 至少运行：
  - Debian 10 release image 构建
  - `package-smoke-test.sh`

nightly 只构建 `amd64`，不引入 `arm64`，原因是：

- nightly 目标是高价值、低维护成本的日常回归守门
- `arm64` 构建开销更高，且当前用户明确只需要 `amd64` nightly
- `arm64` 继续留给正式 `release.yml` 负责

### Nightly Asset Naming

nightly 资产必须包含版本标签，避免本地下载后被同名文件覆盖。

推荐命名：

- `linglong-store-<nightly_label>-linux-amd64.tar.gz`
- `linglong-store-<nightly_label>-amd64.deb`
- `linglong-store-<nightly_label>-x86_64.rpm`
- `linglong-store-<nightly_label>-amd64.AppImage`

示例：

- `linglong-store-3.0.7-nightly.20260321+abc1234-linux-amd64.tar.gz`

如果具体包管理器版本字段不适合直接使用完整 `nightly_label`，则实现层需要对“显示标签”和“包管理器内部版本字段”做分离处理，但对外展示的 Release 标题与下载文件名仍然以 `nightly_label` 为准。

### Formal Release Workflow

`release.yml` 继续维持正式 Release 的既有职责：

- 只响应 `workflow_dispatch`
- 默认分支保护不变
- 解析正式版本号
- 更新版本源文件
- 创建 release commit
- 推送正式 tag
- 构建 `amd64` + `arm64`
- 上传正式 Release 资产

nightly 相关逻辑禁止混入 `release.yml`，包括：

- nightly tag 维护
- nightly prerelease body 元数据
- nightly SHA 去重判断
- nightly 单架构打包分支

### Validation Script Updates

现有工作流校验脚本也必须同步调整，否则文档和实现会漂移。

`build/scripts/validate-release-workflow.sh` 需要从旧断言迁移到新断言：

- 删除对 `ci.yml` 中 `push` 的断言
- 删除对 `ci.yml` 中 `package-smoke-test.sh` 的断言
- 保留对 `ci.yml` 中 `pull_request` 的断言
- 新增对 `nightly.yml` 的断言：
  - 存在 `schedule`
  - 存在 `workflow_dispatch`
  - 存在 `package-smoke-test.sh`
  - 存在 `nightly` prerelease 相关逻辑
- 继续保留对 `release.yml` 的正式发版约束断言

### Documentation Requirements

与工作流一起维护的文档至少要覆盖：

- PR 校验、nightly prerelease、正式 Release 三者的边界
- nightly 的 `UTC+8 03:00` 调度说明
- nightly “有新 commit 才发布”的 SHA 判断规则
- nightly 固定 tag / fixed prerelease 的维护约束
- Action 名称中的版本辨识策略
- 常见失败场景：
  - nightly 已存在但 body 元数据缺失
  - nightly tag 指向漂移
  - package smoke test 失败
  - release / nightly 条件判断写错导致误发

## File Responsibilities

建议文件职责调整如下：

- `.github/workflows/ci.yml`
  - `pull_request` 轻量校验入口
- `.github/workflows/nightly.yml`
  - nightly 构建、smoke test、固定 prerelease 发布入口
- `.github/workflows/release.yml`
  - 正式 `workflow_dispatch` 发版入口
- `build/scripts/package-smoke-test.sh`
  - nightly 完整打包回归验证脚本
- `build/scripts/validate-release-workflow.sh`
  - 工作流结构与关键约束的静态校验脚本
- `build/scripts/resolve-release-version.sh`
  - 正式 release 版本解析
- `docs/`
  - 工作流职责、nightly 规则、维护说明、排障文档

## Error Handling and Guardrails

- 非默认分支禁止真正执行 nightly 发布
- nightly 查询不到现有 prerelease 时，应按“首次 nightly 发布”处理，而不是直接失败
- nightly 找到 prerelease 但 body 元数据缺失时，应视为“无法确认已发布 SHA”，继续构建并重写 metadata
- 当前 `HEAD` 与已发布 SHA 相同时，nightly 必须显式输出“skip”结果，避免看起来像异常中断
- packaging smoke test 任一步失败，nightly 不得更新 prerelease
- `release.yml` 不得因为 nightly 引入额外权限或额外条件分支
- 任何一次正式 Release 缺失任一必需资产时，整个 Release 必须失败

## Testing Strategy

### PR Validation

`ci.yml` 至少验证：

- Flutter 依赖可解析
- 代码生成可成功执行
- `flutter analyze`
- `flutter test`

### Nightly Validation

`nightly.yml` 至少验证：

- 默认分支判断正确
- nightly SHA 去重判断正确
- Debian 10 容器镜像可成功构建或复用缓存
- `package-smoke-test.sh` 通过
- `amd64` 四类 nightly 资产可生成
- prerelease 更新成功
- release body 写入新的 nightly metadata

### Formal Release Validation

`release.yml` 至少验证：

- 正式版本解析正确
- 版本源文件更新正确
- changelog 生成正确
- `amd64` 与 `arm64` 双架构正式资产齐全
- 正式 GitHub Release 上传成功

## Out of Scope

本次设计明确不包含：

- `push` 触发的 GitHub Actions 恢复
- `arm64` nightly
- 为 nightly 单独维护长期历史版本列表
- 自动维护 `CHANGELOG.md`
- macOS / Windows 发布链路
- Arch Linux 正式发布资产

## Expected Outcome

完成后，仓库将形成稳定的三层工作流结构：

- `pull_request` 只做快速源码校验
- nightly 每天 `UTC+8 03:00` 只在默认分支有新提交时构建一次 `amd64` prerelease，并附带完整 packaging smoke test
- 正式版本继续通过 `workflow_dispatch` 构建双架构 Release

最终效果是：

- PR 反馈更快
- 昂贵的 Linux 打包回归被收敛到 nightly
- nightly 对用户保持单一最新快照
- 正式 Release 不受 nightly 逻辑污染
- GitHub Actions / Release / 资产下载路径都具备足够清晰的版本辨识信息
