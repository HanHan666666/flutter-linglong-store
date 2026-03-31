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
- `build/scripts/nightly-cli-smoke-test.sh`

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
- 如果默认分支 `HEAD` 与某个已存在 nightly prerelease 的 `Nightly source commit` 相同，则首轮执行跳过 prerelease；只有 `run_attempt > 1` 或手动 `force_aur_publish=true` 时，才允许复用那次 prerelease 资产补发 AUR
- 手动补发时可额外传 `aur_release_tag`，显式指定要复用的历史 nightly tag；这种恢复路径以该 tag 对应的 prerelease 为准，不要求它的 `Nightly source commit` 仍等于当前 `HEAD`
- 如果手动补发未传 `aur_release_tag`，workflow 会回退到按 `Nightly source commit` 扫描现有 nightly prerelease
- 无论补发的是当前还是历史 prerelease，`publish-aur-nightly` 都必须继续使用触发本次 workflow 的当前代码版本执行渲染、校验与发布脚本；只允许资产下载 URL 与版本标签指向历史 prerelease
- nightly 只构建 `amd64`
- nightly Release notes 必须通过 `build/scripts/generate-nightly-release-notes.sh` 生成，禁止再把 changelog / 下载说明 / metadata 直接内联写回 workflow heredoc
- nightly changelog 的范围固定为“最近一次 nightly prerelease 的 `Nightly source commit` → 当前 `source_commit`”；如果没有上一版 nightly，则必须输出明确的首版兜底文案
- nightly 发布前必须基于最终签名后的发布资产追加 `SHA256 Hashes of the release artifacts` 段落，并同时产出 `hashes.sha256`；禁止在 prepare/build 阶段对未签名产物提前固化哈希

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

发布时序：

- `prepare-release` 只负责解析版本、生成版本化文件产物与 release notes，禁止在这里直接 `git push` 默认分支或创建正式 tag
- build/sign job 必须统一消费同一份 `release-version-files` 中间产物，保证构建内容与最终 release commit 完全一致
- 只有在正式构建与签名成功后，才允许进入独立的 `finalize-release-state` job 推送 release commit 并创建正式 tag
- `publish-release` 必须依赖 `finalize-release-state`，不要在 tag 尚未落库时抢先创建 GitHub Release
- release notes 的 `SHA256 Hashes of the release artifacts` 段落只能在 `publish-release` 下载最终签名资产后追加，并与同一份 `hashes.sha256` 一起发布，避免展示未签名产物的旧哈希

工具链约束：

- release workflow 不允许再通过 `/home/han/flutter` 之类维护者本机路径兜底 Flutter/Dart
- release CLI 统一优先走显式环境变量，其次走 runner `PATH` 或容器内标准路径

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

## 签名规则

所有 nightly 和 release 构建的产物必须进行签名验证。

### 各格式签名机制

| 格式 | 签名方式 | 说明 |
|------|----------|------|
| **tar.gz** | 外部 `.asc` 文件 | tarball 本身无签名机制，必须通过独立的 PGP 签名文件验证 |
| **deb** | APT 仓库级签名 | 标准做法是签名仓库元数据（`Release`/`InRelease`），而非单个 `.deb` 文件 |
| **rpm** | 内嵌签名 | RPM 支持在包内嵌入 GPG 签名，用 `rpm -K` 验证 |

### tar.gz 签名

- 使用 GPG 生成 detached ASCII armor 签名
- 签名文件命名：`<file>.tar.gz` → `<file>.tar.gz.asc`
- 验证命令：`gpg --verify <file>.tar.gz.asc <file>.tar.gz`

### RPM 内嵌签名

RPM 包必须在构建后使用 `rpmsign` 添加内嵌 GPG 签名：

```bash
# 配置 ~/.rpmmacros
%_signature gpg
%_gpg_name <GPG_KEY_ID>
%_gpg_path $HOME/.gnupg
%__gpg /usr/bin/gpg
%_gpg_digest_algo sha256
%__gpg_sign_cmd %{__gpg} \
  --batch --no-verbose --no-armor --no-secmem-warning \
  --pinentry-mode loopback --passphrase-file %{_gpg_path}/rpm-gpg-passphrase \
  %{?_gpg_digest_algo:--digest-algo %{_gpg_digest_algo}} \
  --local-user "%{_gpg_name}" \
  --detach-sign --sign --output %{__signature_filename} %{__plaintext_filename}

# CI 无 TTY 时，先准备 passphrase 文件
printf '%s' "$GPG_PASSPHRASE" > ~/.gnupg/rpm-gpg-passphrase
chmod 600 ~/.gnupg/rpm-gpg-passphrase

# 签名前先确认 secret key 已导入
gpg --batch --list-secret-keys --keyid-format LONG "$GPG_KEY_ID"

# rpm -K 依赖 rpmdb keyring，还要额外导入公钥
gpg --batch --armor --export "$GPG_KEY_ID" > /tmp/rpm-signing-public-key.asc
rpm --import /tmp/rpm-signing-public-key.asc

# 签名
rpmsign --addsign package.rpm

# 验证
rpm -K package.rpm
```

签名后的 RPM 包可在任意支持 RPM 的系统上通过 `rpm -K` 验证完整性，无需额外下载签名文件。

注意：

- GitHub Actions / 容器里 `rpmsign` 没有可交互 TTY，禁止继续依赖 `echo "$GPG_PASSPHRASE" | rpmsign --addsign ...`
- 必须通过 `%__gpg_sign_cmd` 显式切到 `gpg --batch --pinentry-mode loopback --passphrase-file ...`

### 签名 Secrets

| Secret | 用途 |
|--------|------|
| `GPG_PRIVATE_KEY` | GPG 私钥（ASCII armor 格式） |
| `GPG_PASSPHRASE` | GPG 密码 |
| `GPG_KEY_ID` | 用于 RPM 宏配置和 AUR 发布 |

### 签名产物清单

**Nightly 构建：**
```
linglong-store-<label>-linux-amd64.tar.gz
linglong-store-<label>-linux-amd64.tar.gz.asc  ← PGP 签名
linglong-store-<label>-amd64.deb
linglong-store-<label>-x86_64.rpm              ← 内嵌签名
linglong-store-<label>-amd64.AppImage
hashes.sha256                                  ← GitHub Release 页面附带的 SHA256 汇总文件
```

**Release 构建：**
```
linglong-store-<version>-linux-amd64.tar.gz + .asc
linglong-store-<version>-linux-arm64.tar.gz + .asc
linglong-store-<version>-amd64.deb
linglong-store-<version>-arm64.deb
linglong-store-<version>-x86_64.rpm            ← 内嵌签名
linglong-store-<version>-aarch64.rpm           ← 内嵌签名
linglong-store-<version>-amd64.AppImage
linglong-store-<version>-arm64.AppImage
hashes.sha256                                  ← GitHub Release 页面附带的 SHA256 汇总文件
```

## Nightly Release 规则

nightly 当前按日期维护 prerelease：

- tag: `nightly-<YYYYMMDD>`
- prerelease title 前缀: `Nightly Build`
- `prerelease: true`
- `latest: false`

同一天内重跑可以覆盖同一个 nightly tag 的 assets / body；不要再额外引入第二套固定 `nightly` tag 规则，以免 AUR 恢复与 changelog 基线判断出现歧义。

nightly release body 必须保留以下元数据行，供下次执行判断是否需要发布：

```text
Nightly source commit: <full_sha>
Nightly source date: <YYYYMMDD>
Nightly version label: <nightly_label>
```

如果这些元数据缺失，nightly 应按“无法确认已发布 SHA”处理，重新构建并重写 body，而不是静默跳过。

## Nightly AUR 规则

nightly 在 GitHub prerelease 发布成功后，必须继续执行 AUR 发布，当前目标仓库固定为 `linglong-store-nightly-bin`。

约束如下：

- `linglong-store-nightly-bin` 只发布 `x86_64`
- `linglong-store-nightly-bin` 必须声明 `conflicts=('linglong-store' 'linglong-store-bin')`，因为它复用稳定版安装路径，既要拦住稳定包名，也要拦住共享虚拟包名
- nightly AUR `pkgver` 必须把 `<base_version>-nightly.<YYYYMMDD>+<short_sha>` 归一成 `<base_version>_nightly.<YYYYMMDD>.<short_sha>`
- nightly 桌面与 metainfo 命名必须显式带 nightly 变体：
  - desktop 文件：`linglong-store-nightly.desktop`
  - AppStream launchable：`linglong-store-nightly.desktop`
  - 用户可见名称必须带 `Nightly`
- `nightly.yml` 当前发布顺序固定为：生成并签名 nightly 资产 → 发布 GitHub prerelease → 发布 nightly AUR；不要把 AUR 发布提前到 prerelease 之前
- `publish-aur.sh` 在宿主机没有 `makepkg` 时，必须通过临时 Arch 容器生成 `.SRCINFO`，不要假定 Ubuntu runner 自带 Arch 打包工具
- 容器兜底只允许在容器内部临时工作目录生成 `.SRCINFO` 后再拷回结果，禁止对挂载进来的宿主 AUR 仓库执行递归 `chown`

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
