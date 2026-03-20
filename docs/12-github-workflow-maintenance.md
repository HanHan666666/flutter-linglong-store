# 12 GitHub Workflow Maintenance

## 目标

当前 GitHub Actions 采用三层结构：

- `ci.yml`
  - 仅用于 `pull_request` 轻量校验
- `nightly.yml`
  - 仅用于 nightly `amd64` 预发布
- `release.yml`
  - 仅用于手动正式发版

这三条工作流的职责必须保持分离，不要为了“少一个文件”把它们重新揉回一条 workflow。

## 职责边界

### `ci.yml`

用途：

- 快速反馈 PR 里的源码回归

保留内容：

- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test`
- `build/scripts/release-cli-smoke-test.sh`

禁止回加：

- `push` 触发
- Debian 10 打包链
- `package-smoke-test.sh`
- nightly / release 资产上传

### `nightly.yml`

用途：

- 每天固定生成一次最新 nightly `amd64` 预发布
- 接管完整 Linux packaging smoke test

触发：

- `schedule`
- `workflow_dispatch`

调度：

- GitHub Actions 使用 UTC
- 当前 nightly 调度为 `0 19 * * *`
- 这对应 `UTC+8` 每天 `03:00`

运行约束：

- 只允许默认分支真正发布 nightly
- 如果默认分支 `HEAD` 与当前 nightly 已发布 SHA 相同，则直接 skip
- nightly 只构建 `amd64`

### `release.yml`

用途：

- 正式双架构发版

保留内容：

- `workflow_dispatch`
- 版本解析
- 版本文件更新
- release commit
- 正式 tag
- `amd64` / `arm64` 资产发布

禁止混入：

- nightly tag
- nightly body metadata
- nightly skip 判断
- nightly 单架构逻辑

## Nightly 元数据规则

nightly 通过 `build/scripts/resolve-nightly-metadata.sh` 生成：

- `base_version`
- `nightly_date`
- `short_sha`
- `nightly_label`

当前 `nightly_label` 格式：

```text
<base_version>-nightly.<YYYYMMDD>+<short_sha>
```

示例：

```text
3.0.0-nightly.20260320+abc1234
```

`nightly_label` 用于：

- nightly Release 标题
- nightly 资产文件名
- nightly 发布元数据
- nightly 构建 job 名称

## Nightly 资产规则

nightly 的内部打包继续复用正式 semver 产物，然后由 `build/scripts/prepare-nightly-assets.sh` 重命名出对外下载文件。

当前输出命名：

- `linglong-store-<nightly_label>-linux-amd64.tar.gz`
- `linglong-store-<nightly_label>-amd64.deb`
- `linglong-store-<nightly_label>-x86_64.rpm`
- `linglong-store-<nightly_label>-amd64.AppImage`

注意：

- 当前实现只重命名对外下载文件
- 不在 nightly 阶段改写仓库版本源
- 如果后续要让 `.deb` / `.rpm` 内部包版本也具备 nightly 递增语义，需要单独扩展打包模板和版本映射，不要直接把显示标签硬塞进所有包管理器字段

## Nightly Release 规则

nightly 固定维护一个滚动预发布：

- tag: `nightly`
- prerelease title 前缀: `Nightly Build`
- `prerelease: true`
- `latest: false`

不要改成“每天创建一个新 Release”，否则 release 列表会被 nightly 淹没。

nightly release body 必须保留以下元数据行，供下次执行判断是否需要发布：

```text
Nightly source commit: <full_sha>
Nightly source date: <YYYYMMDD>
Nightly version label: <nightly_label>
```

如果这些元数据缺失，nightly 应按“无法确认已发布 SHA”处理，重新构建并重写 body，而不是静默跳过。

## Action 名称与版本展示

GitHub Actions 顶层 `run-name` 无法引用运行时求值得到的 nightly 版本输出，因此当前策略是分层展示：

- 顶层 `run-name`
  - `ci.yml`：固定展示 PR 校验
  - `nightly.yml`：仅区分 scheduled / manual
  - `release.yml`：展示手动输入版本或 `auto`
- job 名称
  - nightly 的 build / publish job 展示真实 `nightly_label`
  - release 的 build / publish job 展示正式版本
- GitHub Release 标题
  - nightly / release 都要带版本标签

后续不要为了追求顶层 run title 的“绝对一致”去绕过 GitHub Actions 的表达式限制，优先保证 Release 页面、job 名称和资产文件名上的版本可见性。

## 本地维护命令

改 GitHub Actions 相关文件后，至少运行：

```bash
bash build/scripts/validate-release-workflow.sh
bash build/scripts/release-cli-smoke-test.sh
bash build/scripts/nightly-cli-smoke-test.sh
```

这三个命令分别保护：

- workflow 结构约束
- 正式 release 版本解析 / changelog CLI
- nightly 元数据与资产重命名辅助脚本

## 常见故障

### `validate-release-workflow.sh` 失败

优先检查：

- `ci.yml` 是否误把 `package-smoke-test.sh` 加回去了
- `nightly.yml` 是否丢了 `schedule` 或 `workflow_dispatch`
- `release.yml` 的 arm64 fallback 条件是否被改坏

### nightly 没有发布新版本

优先检查：

- 是否运行在默认分支
- 当前 `HEAD` 是否和 nightly body 中的 `Nightly source commit` 相同
- workflow 是否只是按预期 skip

### nightly 发布了，但下载文件名没有版本

优先检查：

- `build/scripts/prepare-nightly-assets.sh` 是否被绕过
- `nightly.yml` 上传的是否仍是原始 semver 输出目录

### 正式 release 名称没有版本上下文

优先检查：

- `release.yml` 的顶层 `run-name`
- `prepare-release` / `build-*` / `publish-release` job 名称

## 维护原则

- PR 校验求快，不求完整打包
- nightly 求“最新可安装快照”，不求历史归档
- 正式 release 求稳定、可追溯、双架构完整
- 任何时候都不要把 nightly 逻辑塞回 `release.yml`
