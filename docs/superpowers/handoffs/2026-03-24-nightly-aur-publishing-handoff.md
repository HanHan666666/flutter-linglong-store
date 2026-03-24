# Nightly AUR Publishing Handoff

## 1. 任务背景

本轮需求是在现有 nightly GitHub prerelease 链路基础上，新增自动发布到 AUR 社区的 nightly 通道，包名为 `linglong-store-nightly-bin`。

用户最终确认的业务约束如下：

- AUR 夜版包名固定为 `linglong-store-nightly-bin`
- 与稳定版不并存，走“最小替换方案”
- nightly AUR 只发布 `x86_64`
- 安装路径和实际二进制入口继续复用稳定版，不做并存隔离
- 只修改用户可见元数据
  - 桌面名称带 `Nightly`
  - `.desktop` 文件名改为 `linglong-store-nightly.desktop`
  - metainfo / AppStream 名称带 `Nightly`
  - nightly 的 `deb/rpm/AppImage` 也统一渲染为 Nightly 名称
- nightly AUR `pkgver` 需要归一化
  - 例如：`3.0.2-nightly.20260324+8190b89`
  - 映射为：`3.0.2_nightly.20260324.8190b89`

前置文档已经存在：

- 设计文档：`docs/superpowers/specs/2026-03-24-nightly-aur-publishing-design.md`
- 实施计划：`docs/superpowers/plans/2026-03-24-nightly-aur-publishing.md`

## 2. 当前工作区和分支状态

- 仓库根目录：`/home/han/linglong-store/flutter-linglong-store`
- 功能 worktree：`/home/han/linglong-store/flutter-linglong-store/.worktrees/nightly-aur-publishing`
- 当前分支：`feat/nightly-aur-publishing`
- 当前 HEAD：`8e2ab4002f3ac1af07ca538b5375af3a1842493a`
- 当前 worktree 是干净的：`git status --short` 无输出

最近的提交从新到旧如下：

```text
8e2ab40 fix: 修复 nightly 打包渠道与 AUR 幂等发布
c915430 docs: 记录 nightly AUR 发布约定
abc065a fix: 收紧 nightly AUR 发布工件校验
e150b6e feat: 增加 nightly AUR 自动发布流程
e3a439b fix: 区分 AUR 在线与离线校验模式
7ebcad3 fix: 让 AUR 校验脱离在线源校验
cc5d725 feat: 参数化 AUR 发布与校验脚本
ada3ff8 fix: 收紧 AUR 模板渲染前置校验
a30e437 fix: 修复 AUR 模板渲染占位符泄漏
d3297c1 feat: 支持 nightly AUR 版本与模板渲染
495b8dc fix: 让打包流程消费渲染后的桌面文件名
9909654 fix: 补充 nightly 渲染断言和 AUR 校验路径
```

## 3. 这轮已经完成了什么

### 3.1 Nightly 渲染模式已经打通

核心入口是：

- `build/scripts/render-packaging-templates.sh`

已完成内容：

- 增加 `--channel stable|nightly`，默认 `stable`
- nightly 模式下覆盖用户可见元数据：
  - `display_name="玲珑应用商店社区版 Nightly"`
  - `summary_text="Linglong Store Community Edition Nightly"`
  - `desktop_filename="linglong-store-nightly.desktop"`
  - `launchable_desktop_id="linglong-store-nightly.desktop"`
- stable 默认行为保持不变
- desktop / appdata / AUR 模板都改成走统一变量渲染，而不是硬编码稳定版名字

相关文件：

- `build/scripts/render-packaging-templates.sh`
- `build/packaging/linux/linglong-store.desktop.in`
- `build/packaging/linux/appimage/linglong-store.appdata.xml`

### 3.2 打包脚本已经消费渲染后的 desktop 文件名

已完成内容：

- `build/scripts/package-deb.sh`
- `build/scripts/package-rpm.sh`
- `build/scripts/package-appimage.sh`

现在都不会再假定 desktop 文件名永远是 `linglong-store.desktop`，而是先从 render 输出目录里找唯一的 `.desktop` 文件再复制。

这是中后期修复的关键点之一，因为如果只改模板但打包脚本仍然硬编码稳定版文件名，nightly 包实际内容还是错的。

### 3.3 nightly 的真实打包元数据已经贯通到 smoke test

核心文件：

- `build/scripts/package-smoke-test.sh`
- `.github/workflows/nightly.yml`

已完成内容：

- `package-smoke-test.sh` 新增 `PACKAGE_CHANNEL="${PACKAGE_CHANNEL:-stable}"`
- 包装 `deb/rpm/AppImage` 三个脚本时都会透传 `--channel "$PACKAGE_CHANNEL"`
- nightly workflow 的 smoke step 已显式注入：

```yaml
env:
  PACKAGE_CHANNEL: nightly
```

- nightly 模式下，smoke test 会解包生成出的 `.deb`，并验证：
  - `usr/share/applications/linglong-store-nightly.desktop` 存在
  - desktop `Name=` 含 `Nightly`
  - desktop `Comment=` 含 `Nightly`
  - metainfo `<name>` 含 `Nightly`
  - metainfo `<summary>` 含 `Nightly`
  - metainfo `<launchable>` 指向 `linglong-store-nightly.desktop`

这一步是为了避免“workflow 只是把稳定版产物重命名成 nightly 文件名”的假成功。

### 3.4 AUR 版本归一化已经落地

新增脚本：

- `build/scripts/normalize-nightly-aur-version.sh`

逻辑：

- 将 `-nightly.` 替换为 `_nightly.`
- 将 `+` 替换为 `.`
- 当前要求输入必须满足：

```text
<semver>-nightly.<YYYYMMDD>+<sha>
```

例如：

```text
3.0.2-nightly.20260324+8190b89
-> 3.0.2_nightly.20260324.8190b89
```

### 3.5 AUR 模板已经参数化支持 stable / nightly

核心模板：

- `build/packaging/linux/aur/PKGBUILD.in`
- `build/packaging/linux/aur/linglong-store-bin.changelog.in`

当前已支持参数化：

- `pkgname`
- `pkgver`
- `arch`
- `provides`
- `conflicts`
- changelog 文件名
- source URL / tag root
- `.desktop` 文件名
- GPG key id
- 多架构 source block 的条件展开

nightly 模式当前渲染结果：

- `pkgname=linglong-store-nightly-bin`
- `arch=('x86_64')`
- `provides=('linglong-store')`
- `conflicts=('linglong-store-bin')`
- desktop 文件名 `linglong-store-nightly.desktop`

### 3.6 AUR 校验脚本已经支持 nightly

核心文件：

- `build/scripts/validate-aur-package.sh`

已完成内容：

- 增加参数：
  - `--channel`
  - `--package-name`
  - `--aur-version`
  - `--verify-source|--online`
- 默认离线模式会：
  - 渲染 AUR 元数据
  - 用 synthetic fixture 构造本地 bundle 源
  - 跑 `makepkg`
  - 校验 `.SRCINFO`
  - 校验 `.PKGINFO`
  - 校验安装内容中 desktop 文件和 payload
- nightly 模式会特别断言：
  - `pkgname = linglong-store-nightly-bin`
  - `pkgver = 归一化后的 nightly pkgver`
  - `arch = x86_64`
  - 不再出现 `source_aarch64`
  - desktop 文件为 `linglong-store-nightly.desktop`

### 3.7 AUR 发布脚本已经支持 nightly 且做到幂等

核心文件：

- `build/scripts/publish-aur.sh`

已完成内容：

- 增加参数：
  - `--channel`
  - `--package-name`
  - `--repo-url`
  - `--aur-version`
  - `--arch`
- 支持 stable / nightly 两套默认值
- 渲染 AUR 元数据前会校验 repo 名和 package name 是否一致
- 会清理旧的 `.desktop` / `.changelog` 文件，避免 stable/nightly 文件残留
- 发布前执行 `git add -A`
- 如果 rerun 导致 AUR repo 内容完全一致，则：

```text
AUR repo already up to date for <pkg> <ver>; skipping publish.
```

然后 `exit 0`

这解决了之前“重复运行会在空提交处失败”的问题。

### 3.8 nightly workflow 已经新增 nightly AUR job

核心文件：

- `.github/workflows/nightly.yml`

当前新增了 `publish-aur-nightly` job，主要步骤：

1. checkout 到 nightly tag
2. 下载 signed nightly assets
3. 对 nightly tarball 和 `.asc` 计算 SHA256
4. 归一化 nightly AUR version
5. 渲染 nightly AUR 元数据，并用 `grep` 对关键字段做硬断言
6. 执行 `validate-aur-package.sh`
7. 执行 `publish-aur.sh`

目前 job 里的发布目标仓库是：

```text
ssh://aur@aur.archlinux.org/linglong-store-nightly-bin.git
```

### 3.9 文档和仓库约定已经同步

已更新：

- `docs/12-github-workflow-maintenance.md`
- `AGENTS.md`

已记录的约定包括：

- nightly 也有独立的 AUR 发布链路
- nightly 打包元数据必须通过模板渲染，不允许只靠产物重命名

## 4. 实际做法概览

如果下一个 AI 想快速理解实现路径，可以按下面顺序读：

1. 设计：`docs/superpowers/specs/2026-03-24-nightly-aur-publishing-design.md`
2. 计划：`docs/superpowers/plans/2026-03-24-nightly-aur-publishing.md`
3. 模板渲染入口：`build/scripts/render-packaging-templates.sh`
4. 三个打包脚本：
   - `build/scripts/package-deb.sh`
   - `build/scripts/package-rpm.sh`
   - `build/scripts/package-appimage.sh`
5. AUR 校验和发布：
   - `build/scripts/validate-aur-package.sh`
   - `build/scripts/publish-aur.sh`
6. workflow：
   - `.github/workflows/nightly.yml`

整体实现思路是：

- 把 stable/nightly 的差异尽量收敛到模板渲染层
- 打包脚本只消费渲染结果
- workflow 只负责把真实 nightly 资产 checksum 带进去并执行校验/发布

## 5. 已经跑过的验证

以下命令是已经实际跑过并成功的：

```bash
bash build/scripts/validate-release-workflow.sh
bash build/scripts/release-cli-smoke-test.sh
bash build/scripts/nightly-cli-smoke-test.sh
bash -n build/scripts/package-smoke-test.sh build/scripts/publish-aur.sh
PACKAGE_CHANNEL=nightly RELEASE_VERSION=3.0.7 TARGET_ARCH=amd64 bash build/scripts/package-smoke-test.sh
```

最后这条 nightly smoke test 的意义最大，因为它验证了：

- `deb/rpm/AppImage` 都能在 nightly channel 下完成打包
- `.deb` 中实际装入的是 nightly desktop/metainfo，而不是稳定版内容

## 6. 最终 reviewer 发现但尚未修掉的问题

我在最终整体验收阶段拉了 reviewer。一个 reviewer 因配额问题没有返回；另一个 reviewer 返回了 4 个问题。当前这些问题还没修，所以这条 feature 还不能直接合并到 `master`。

### 问题 1：nightly AUR 发布 job 在 GitHub Ubuntu runner 上会缺 `makepkg`

严重级别：High

问题位置：

- `.github/workflows/nightly.yml`
- `build/scripts/publish-aur.sh`

问题描述：

- `publish-aur-nightly` job 运行在 `ubuntu-latest`
- `publish-aur.sh` 内部无条件执行 `makepkg --printsrcinfo`
- 这个 job 没有安装 Arch 的 `makepkg`
- GitHub 官方 Ubuntu runner 并不自带 `makepkg`

结果：

- 发布 job 在真正推送 AUR 前就会因为 `makepkg: command not found` 失败

建议修法：

- 方案 A：不要在 Ubuntu 裸 runner 上执行 `makepkg`，而是在 Arch 容器里生成 `.SRCINFO` 再提交
- 方案 B：把 `publish-aur.sh` 中 `.SRCINFO` 生成逻辑拆成“有 makepkg 就生成，否则报更明确的错误”，并让 workflow 在 Arch 容器里跑这一段
- 方案 C：nightly workflow 里单独增加一个 Arch 容器步骤，只负责生成 `.SRCINFO` 和 validate，再把渲染好的 AUR repo 内容交给 Ubuntu runner push

### 问题 2：workflow 级别不支持“先 prerelease 成功、后 AUR 失败”的 rerun 恢复

严重级别：Medium

问题位置：

- `.github/workflows/nightly.yml`

问题描述：

- `prepare-nightly` 会读取已有 nightly prerelease
- 如果 release body 里记录的 source commit 已经等于当前 `HEAD`，就把 `should_publish=false`
- `publish-aur-nightly` 也依赖这个 `should_publish`

结果：

- 假设某次 nightly 已经成功发布 GitHub prerelease，但 AUR job 失败
- 之后对同一 commit/date 重新手动 rerun
- 因为 prerelease 已存在且记录了相同 commit，workflow 会整体认为“已经发布过”
- AUR job 会被跳过，无法利用当前 `publish-aur.sh` 的幂等能力来恢复

建议修法：

- 将 “是否需要发布 GitHub prerelease” 与 “是否需要发布 AUR” 拆开
- 或者至少给 `workflow_dispatch` 一个显式开关，允许强制重跑 AUR job
- 更直接的做法是：
  - `prepare-nightly` 只控制构建和 GitHub prerelease 是否跳过
  - `publish-aur-nightly` 改为依据“signed asset 是否存在” + “当前 event 是否允许补发”来运行

### 问题 3：nightly AUR 只 conflicts `linglong-store-bin` 可能不够

严重级别：Medium

问题位置：

- `build/scripts/render-packaging-templates.sh`
- `build/packaging/linux/aur/PKGBUILD.in`

问题描述：

- 当前 nightly 仍会安装这些稳定版路径：
  - `/opt/linglong-store`
  - `/usr/bin/linglong-store`
  - 共享 icon
  - 共享 metainfo
- 当前 AUR 元数据只写了：

```bash
conflicts=('linglong-store-bin')
```

reviewer 的担心是：

- 如果用户系统里存在别的 `linglong-store` 包，而不仅仅是 `linglong-store-bin`
- pacman 可能在安装阶段遭遇真实文件冲突，而不是在 metadata 层干净地被 `conflicts` 拦住

这个点还需要业务判断：

- 如果仓库语义上只需要和 `linglong-store-bin` 互斥，那当前实现符合已确认方案
- 如果想更保险，可能需要补更宽的 conflict/provides 组合

建议下一个 AI 接手时先核对当前 AUR 社区里实际相关包名，再决定要不要把 conflict 扩大到 `linglong-store`

### 问题 4：默认“离线”校验模式并不彻底离线

严重级别：Low

问题位置：

- `build/scripts/validate-aur-package.sh`

问题描述：

- 脚本帮助文案写的是默认走 offline structural validation
- 但如果调用方没有显式提供所有 checksum，脚本仍会尝试访问 GitHub release URL 计算缺失的 SHA256

结果：

- 从语义上说，这不是真正的离线
- 对“发布前、尚未真正存在 release 资产”的 nightly label，会造成歧义

当前影响：

- 当前 nightly workflow 已经显式提供 `sha256-amd64` 和 `sha256-sig-amd64`
- 所以实际 workflow 不会踩到这个坑

但是脚本本身的“默认模式说明”和“实际行为”不完全一致，后续最好补齐。

## 7. reviewer 之外，我认为下一个 AI 还要额外注意的点

### 7.1 目前只对 `.deb` 做了产物级拆包验证

当前 smoke test 会拆 `.deb` 检查 nightly metadata。

`rpm` 和 `AppImage` 目前没有做到同级别的“产物内容拆包断言”，而是依赖：

- 模板渲染正确
- 打包脚本消费渲染结果正确
- 打包命令本身执行成功

这并不一定是 bug，但如果后续再动 desktop/metainfo 逻辑，最好补：

- RPM 包内容的 payload 路径断言
- AppImage 中 desktop/metainfo 的存在性断言

### 7.2 publish-aur-nightly 的 checksum 计算只覆盖 tar.gz 和 asc

这是符合 AUR binary package 的当前设计的，因为 PKGBUILD 只拉 bundle tarball 和签名。

但如果后续有人误以为 nightly AUR 应该引用 `.deb`/`.rpm`/`.AppImage`，不要照着现在的 checksum 逻辑直接扩展，先确认 AUR 包的 source of truth。

### 7.3 rpm spec 里已经从 `@PACKAGE_NAME@.desktop` 改成 `@DESKTOP_FILENAME@`

这个修复非常关键，不要回退。

如果后续有人再重构 `render-packaging-templates.sh`，一定要确认：

- `render_file()` 里仍然会替换 `@DESKTOP_FILENAME@`
- `build/packaging/linux/rpm/linglong-store.spec.in` 仍然依赖该变量，而不是重新写死稳定版 desktop 名

### 7.4 当前 workflow / 脚本是按“nightly tag -> GitHub release asset -> AUR metadata”串起来的

这个链路的顺序不能随便打乱：

1. 构建 nightly 资产
2. 签名
3. 发布 prerelease
4. 用已发布资产和真实 checksum 渲染 AUR metadata
5. 校验
6. 发布 AUR

如果改成“先渲染 AUR，再发 GitHub prerelease”，AUR source URL 和真实 checksum 的一致性会变差。

## 8. 下一个 AI 建议的接手顺序

建议按下面顺序接手，不要一上来直接改 workflow：

1. 先阅读：
   - `docs/superpowers/specs/2026-03-24-nightly-aur-publishing-design.md`
   - `docs/superpowers/plans/2026-03-24-nightly-aur-publishing.md`
   - 本交接文档
2. 跑一遍当前已通过的本地验证命令，确认环境一致
3. 优先修 reviewer 的问题 1
   - 因为这会直接导致 GitHub 上 nightly AUR job 失败
4. 再修 reviewer 的问题 2
   - 否则 AUR 发布失败后无法优雅重跑
5. 再决定 reviewer 的问题 3 要不要扩大 conflict 范围
6. 最后再处理问题 4 和产物级验证补强

## 9. 我建议的下一步实现方向

如果让我继续做，我会按下面路线收尾：

### 第一步：把 publish-aur-nightly 里的 `makepkg` 相关逻辑迁到 Arch 容器

目标：

- 不依赖 Ubuntu runner 是否自带 `makepkg`
- 保持 `.SRCINFO` 生成和 `validate-aur-package.sh` 的运行环境一致

比较稳的做法：

- 在 nightly workflow 新增一个 Arch Linux 容器步骤
- 容器里执行：
  - 渲染 AUR metadata
  - `makepkg --printsrcinfo`
  - `validate-aur-package.sh`
- 将最终整理好的 AUR repo 文件作为 artifact 或工作目录内容交给发布步骤

### 第二步：拆开 GitHub prerelease 和 AUR 补发条件

目标：

- 即使 nightly prerelease 已存在，也允许补发 AUR

思路：

- `should_publish_release`
- `should_publish_aur`

分两个输出，或给 `workflow_dispatch` 增加 `force_aur_publish` 输入。

### 第三步：核实 AUR 生态里相关包名，再决定是否扩 conflict

不要凭感觉直接加。

先查：

- `linglong-store-bin`
- `linglong-store`
- 是否还有别名或旧包

然后再更新：

- `PKGBUILD`
- `validate-aur-package.sh`
- 设计文档和维护文档

## 10. 交接结论

当前这条 feature 分支已经完成了大部分实现工作，核心脚本和模板层已经成型，nightly 元数据渲染、AUR 模板参数化、AUR 校验、AUR 发布脚本幂等化、nightly workflow 挂接都已经落地。

但它还没有到“可安全合并”的状态，主要还差：

1. 修正 GitHub nightly AUR job 对 `makepkg` 的运行环境依赖
2. 修正 AUR job 在 prerelease 成功但 AUR 失败时无法 rerun 恢复的问题
3. 评估并决定是否扩大 conflict 范围
4. 可选地补强“真正离线校验”语义和 rpm/AppImage 产物级断言

如果下一个 AI 只想抓最关键的 blocker，先修第 1 条。
