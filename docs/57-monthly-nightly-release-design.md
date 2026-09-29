# 月度 Nightly Release 设计

## 目标与边界

Nightly 仍在北京时间每天 03:00 检查默认分支。`master` 的每次 push 不再触发 CI；PR 继续运行轻量校验。GitHub Release 从本方案生效起采用每月一个可更新的 prerelease；已发布的日版 Release 和 tag 原样保留，不做历史迁移或清理。

## 版本身份

- `nightly_date` 使用 `Asia/Shanghai` 的 `YYYYMMDD`。
- GitHub tag 使用 `nightly-YYYYMM`。同月所有成功构建共用它，跨月创建新 tag。
- 展示标签及资产文件名仍使用 `<base_version>-nightly.<YYYYMMDD>+<short_sha>`，保证下载文件及 AUR `pkgver` 能区分源码版本。
- `build/scripts/lib/nightly-release-tag.sh` 是 GitHub 元数据、AUR 渲染和校验的 tag 规则入口。手动恢复已有日版 AUR 时，`LINGLONG_NIGHTLY_RELEASE_TAG` 只允许指定与版本标签同一天的日 tag，或同一个月的月 tag。

## 每日状态转换

| 当前月 Release | 源码状态 | 行为 |
| --- | --- | --- |
| 不存在 | 任意，包括与上月相同 | 构建、签名并创建本月 Release |
| 存在 | `Nightly source commit` 与当前 HEAD 相同 | 首次执行跳过；重跑或手动请求可以复用资产补发 AUR |
| 存在 | HEAD 已更新 | 构建、签名、更新同一 Release |
| 存在 | 较旧的运行晚于较新的运行结束 | 拒绝旧运行覆盖当月已发布的新源码 |

Nightly 说明总是从当前源码可达的最近正式版 tag 累计到当次提交，不以昨天的 Nightly 为起点。每次发布保留 `Nightly source commit`、`Nightly source date` 与 `Nightly version label` 元数据，供同月跳过判断与 Loong64 补传校验。

## 发布事务与失败边界

`amd64` 和 `arm64` 构建、签名成功后生成说明及最终 SHA256，再上传到当月 Release。上传成功之后，按这次资产目录的文件名清理同一 Release 中旧日期的资产，最后将月 tag 移到当次源码。构建或生成说明失败时不清理旧资产；上传、清理和 tag 推进阶段的错误使工作流失败，重跑可以继续恢复。GitHub Release API 没有跨 body、资产和 tag 的原子事务，因此发布步骤之间可能短暂显示两次构建的混合状态；只有工作流完整成功才视为该月最新快照。

`nightly-loong64.yml` 在主工作流结束后异步构建。主发布和补传共用串行组；Loong64 上传前再次检查 Release 的源码 SHA，若同月已被新构建替换就跳过旧补传。自动补传只扫描新月度版，不改动已存在的日版；显式指定历史日版 tag 的手动恢复仍可使用。

## AUR 与历史兼容

Nightly AUR 每次成功发布后更新 checksum、签名 URL 和 `pkgver`；URL 的 tag 来自当次月度 Release。手动 `aur_release_tag` 可复用现有日版资产，AUR 渲染、离线校验和发布必须共享这一显式 tag。未显式指定历史 tag 时，不能因为同一 SHA 出现在旧日版或上月快照而误复用旧资产。

## 验证

- `build/scripts/nightly-cli-smoke-test.sh` 验证月 tag、日版手动覆盖、跨月错误覆盖、AUR URL 与最近正式版起点。
- `build/scripts/validate-release-workflow.sh` 验证 CI 触发、主发布步骤及异步补传的关键契约。
- 真实 GitHub Actions 首次运行时，检查当月仅创建 `nightly-YYYYMM`、下载区不残留旧日期资产、Loong64 哈希与 body 对应同一源码、AUR 指向月 tag。首次运行不修改现有日版 Release。
