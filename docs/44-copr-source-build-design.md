# Fedora Copr 源码构建设计文档

## 1. 文档定位

本文记录「玲珑应用商店社区版」面向 Fedora Copr 的源码构建支持的设计决策、
产物流水线、维护者操作指南与已知限制。适用对象：

- **Copr 维护者**（第三方贡献者）：希望在自己的 Copr 项目上从源码构建本
  应用并分发给 Fedora 用户；
- **上游维护者**（本仓库开发者）：负责发版流水线、Flutter SDK 版本锚点
  与源码归档质量。

## 2. 需求背景

社区用户提出：「源码添加 rpmspec，以便于我从 Fedora Copr 构建」。

此前仓库已有一份 RPM spec（`build/packaging/linux/rpm/linglong-store.spec.in`），
但它是**二进制重打包模板**：`%build` 段为空，仅把官方 CI 已编译产物复制进
`%{buildroot}`。Copr 的 mock chroot 是干净的 Fedora 环境（无 Flutter SDK、
无预编译产物），要求 spec 从 `Source0` 源码出发在 `%prep`/`%build` 内完成
全部编译，因此旧模板无法满足需求，需要新增一条**从源码独立构建**的 spec
链路。

### 2.1 版本号维护模式选择（模式 B）

Copr 构建入口是「一个 spec + Source0 源码包」，spec 内 `Version:` 是写死
的数字，上游每次发版都需要 Copr 侧跟进重建。存在两种模式：

| 模式 | 做法 | Copr 维护者成本 | 上游成本 |
|------|------|----------------|----------|
| A：自行 fork spec | 维护者复制 spec 到自己空间，发版后手动改 Version | 高（每次手改） | 零 |
| **B：发版渲染 spec（已采用）** | 上游发版时渲染好带版本号与 Source0 的 spec，作为 release 附件 `linglong-store-<version>.copr.spec` 发布 | 低（发版后提交新附件 URL 即可） | 渲染一步（复用现有模板机制） |

选择模式 B：项目已有 `.in` 模板 + `render-packaging-templates.sh` 渲染
机制，边际成本低，且 Copr 维护者完全不需要理解版本号规则。

## 3. 关键设计决策

### D1：RPM 打包双轨并存

| 轨道 | 模板 | 用途 |
|------|------|------|
| 二进制重打包 | `build/packaging/linux/rpm/linglong-store.spec.in` | 官方 CI 已编译产物的快速重打包（Debian 10 容器链路，产出低 glibc 门槛的官方 RPM） |
| 源码构建 | `build/packaging/linux/copr/linglong-store.spec.in` | Copr / mock 环境内从源码完整编译 |

两轨的 `%files` 布局完全一致（`/opt/linglong-store` + `/usr/bin` wrapper +
桌面入口 + 图标 + AppStream 元数据），用户侧安装结果等价。禁止把重打包
模板的「空 `%build` + `@PAYLOAD_DIR@`」模式带入 Copr 轨道，反之亦然。

### D2：Flutter SDK 双路引导（按架构分流）

Flutter 官方 stable 归档（releases_linux.json）**只发布 x86_64 的 Linux
SDK tarball**，不存在 linux-arm64 stable 归档。因此 spec 内按 `%ifarch`
分流，两个架构通过不同机制锁定**同一版本**：

| 架构 | 引导方式 | 一致性保障 |
|------|----------|-----------|
| x86_64 | `Source1` 声明官方归档 URL（rpmbuild 制作 srpm 时自动下载），`%prep` 内 sha256 校验后解压 | `%global flutter_sha256`（来自 releases_linux.json） |
| aarch64 | shallow clone `flutter/flutter` 的版本 tag，首次执行 `bin/flutter` 时按宿主架构自行下载 dart-sdk | `%global flutter_commit`（releases_linux.json 中该版本对应的 commit），`git rev-parse` 比对防 tag 漂移 |

`Source1` 以 `%ifarch x86_64` 条件声明：aarch64 构建不会下载无法使用的
x86_64 归档（约 1 GB）。

**版本锚点同步要求**：`flutter_version` / `flutter_commit` /
`flutter_sha256` 三个宏必须与官方发布容器
`build/docker/debian10-release.Dockerfile` 的 `FLUTTER_VERSION` 保持一致，
升级 SDK 时两处同步修改，`flutter_commit`/`flutter_sha256` 从
`https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json`
查询。

### D3：源码归档自包含（预渲染元数据）

Copr 构建端不引入任何项目私有渲染工具（dart 脚本、rsvg）。发版时由
`build/scripts/package-source-archive.sh` 把以下产物预渲染进源码归档的
`packaging-dist/` 目录：

```
packaging-dist/
  com.dongpl.linglong-store.v2.desktop   # 主桌面入口（ARB 多语言渲染）
  compat/linglong-store.desktop          # 兼容桌面入口
  metainfo/linglong-store.appdata.xml    # AppStream 元数据（多语言）
  icons/linglong-store-256.png           # 256px 图标（rsvg 预渲染）
  linglong-store.spec                    # 内嵌渲染好的 Copr spec（自描述）
```

归档组成为 `git archive HEAD` 树 + 发版版本文件覆盖（pubspec.yaml、
linux/pubspec.yaml、app_config.dart）+ 上述 `packaging-dist/`，顶层目录
`linglong-store-<version>/`。发版流水线中版本文件在归档制作前已写入工作区，
因此归档内容与最终发版 tag 树一致。

### D4：跳过 build_runner（依赖入库生成源码）

依据 `docs/36-generated-source-policy.md`（方案 C：稳定生成物全部入库），
Copr 构建不执行 `dart run build_runner`，直接使用归档内已提交的
`*.g.dart` / `*.freezed.dart` / 本地化源码。`package-source-archive.sh`
内置防御检查（pubspec.lock 存在、生成源码数量抽查），策略被破坏时归档
制作直接失败，而不是产出一个在 Copr 端必然构建失败的归档。

### D5：Fedora 版本边界与 glibc 事实

「应用最低要求 Debian 10 的 glibc」**不能**推出「同期及以后的 Fedora 都能
用 Copr 构建」，原因有二：

1. Copr 只提供**活跃维护期内**的 Fedora chroot（EOL 版本不可选）；
2. RPM 内二进制链接的 glibc 版本由**构建 chroot** 决定：在 Fedora N chroot
   构建的包只能保证在 Fedora ≥ N 运行。

因此两条链路的定位互补：

- **Copr 链路**：覆盖当前活跃 Fedora 版本（x86_64 + aarch64），满足 Fedora
  用户从源码构建、社区自维护仓库的需求；
- **Debian 10 官方链路**：继续承担低 glibc 系统（含老发行版）的兼容性。

Copr 维护者建项目时勾选当时活跃的 Fedora chroot 即可，新 Fedora 发布后
Copr 会通知跟进重建。

### D6：依赖与包语义

- `AutoReqProv: no` + 手写 `Requires`（gtk3、xz-libs、libstdc++、
  hicolor-icon-theme）：与官方二进制 RPM 保持一致，避免 rpmbuild 自动依赖
  扫描 /opt 捆绑 `.so` 生成噪声依赖；
- `BuildRequires`：gtk3-devel、clang、cmake、ninja-build、pkgconf-pkg-config、
  git、tar、xz、unzip（前五项为 Flutter Linux 桌面工具链，后四项为 SDK
  引导所需）；
- `%global debug_package %{nil}`：/opt 捆绑二进制的调试符号对 Copr 场景
  无价值，禁用可缩短构建并避免符号提取工具处理 Flutter engine 产物；
- `Release: 1%{?dist}`：遵循 Fedora 惯例，便于同仓库多发行版并存；
- `ExclusiveArch: x86_64 aarch64`：loong64 由官方发布链路单独覆盖，不进
  Copr；
- 编译参数与官方 `build-linux-bundle.sh` 对齐（`--release --obfuscate
  --split-debug-info`），产物与官方发行等价（符号不入包）。

### D7：归档可复现性

`package-source-archive.sh` 打包时统一 `--sort=name`、`--mtime=@<提交时间>`、
`--owner=0 --group=0 --numeric-owner` 并配合 `gzip -n`：同一提交两次产出
字节一致（已验证）。例外：`packaging-dist/icons/linglong-store-256.png`
由渲染工具（rsvg-convert 优先、ImageMagick 兜底）生成，跨机器可能不同；
完整性以 release 附件的 `hashes.sha256` 为最终口径（`.copr.spec` 与源码
归档均纳入哈希清单）。

### D8：范围排除

- **nightly 渠道不支持**：nightly 版本号含 `-nightly.<date>+<sha>`，RPM
  `Version` 语义不兼容且 Source0 指向 nightly tag 结构，渲染器在 nightly
  渠道直接跳过 Copr spec，`package-source-archive.sh` 拒绝含连字符的版本；
- **loong64 不支持**：见 D6。

## 4. 发版流水线接入点

```
prepare-release job
  ├─ update-version-files.sh（版本文件写入工作区）
  ├─ Stage versioned release files（原有步骤）
  ├─ package-source-archive.sh --version <v>          ← 新增
  │    └─ build/out/linux/<v>/source/
  │         ├─ linglong-store-<v>.tar.gz
  │         └─ linglong-store-<v>.copr.spec
  └─ upload-artifact: release-assets-source           ← 新增

sign-release job
  ├─ download-artifact: pattern release-assets-*（自动收编源码归档）
  ├─ Sign release tarballs（源码 tar.gz 同样获得 .asc 签名）
  └─ upload: signed-release-assets（*.copr.spec 仅透传，不签名）

publish-release job
  ├─ normalize-release-assets.sh（白名单含 *.copr.spec）
  ├─ append-release-asset-hashes.sh（spec 与源码归档进 hashes.sha256）
  └─ GitHub Release 附件
```

`.copr.spec` 不做 GPG 签名：它是提交给 Copr 的输入而非安装产物，完整性由
`hashes.sha256` 中的哈希覆盖。

## 5. Copr 维护者操作指南

### 5.1 一次性准备

1. 注册 Fedora 账号（FAS），登录 <https://copr.fedorainfracloud.org>；
2. 新建 Copr 项目（如 `<你的用户名>/linglong-store`）：
   - **Chroots**：勾选当前活跃 Fedora 版本的 `x86_64` 与 `aarch64`
     （按需取舍，两者使用同一份 spec）；
   - 其余选项保持默认（Copr 构建默认允许联网，spec 需要下载 Flutter SDK
     与 pub 依赖）。

### 5.2 提交构建

1. 打开本仓库任意 stable Release 页面，下载（或复制链接）
   `linglong-store-<version>.copr.spec`；
2. Copr 项目页 → **New Build** → **ByUrl**，粘贴该 spec 的附件直链；
3. Copr 会自动：下载 spec → 解析 `Source0`（源码归档）与 `Source1`
   （x86_64 的 Flutter SDK 归档）→ 制作 srpm → 在所选 chroot 内执行
   `%prep`/`%build`/`%install`；
4. 构建时长预期：SDK 引导 + `pub get` + Release 编译，每 chroot 约
   15–45 分钟（aarch64 构建机队列与速度通常更慢）。

### 5.3 用户安装

```bash
dnf copr enable <你的用户名>/linglong-store
dnf install linglong-store
```

### 5.4 版本跟进（上游发版后）

上游每次 stable 发版都会附带新的 `linglong-store-<version>.copr.spec`
（版本号与 Source0 已渲染好）。你只需：

- Copr 项目页 → **New Build** → **ByUrl** → 粘贴**新版本** spec 的附件
  直链提交即可，无需修改任何内容；
- 也可以用 CLI 自动化：
  `copr-cli build <项目> <spec 的 URL>`。

若你希望完全脱离上游 spec 自行调整（如改 `Release` 号、打补丁），可 fork
spec 到自己仓库维护——`Source0`/`Source1` 均为完整 URL，spec 本身无外部
依赖。

### 5.5 构建失败排查入口

- **SDK 下载/校验失败**：`%prep` 日志中 `sha256sum -c` 或 `git clone`
  段，多为网络或上游归档变动，确认 spec 内 `flutter_sha256` 与
  releases_linux.json 一致；
- **`pub get` 失败**：pub.dev 网络问题，重试即可；归档内含
  `pubspec.lock`，依赖解析是确定性的；
- **编译期缺系统库**：对照 spec `BuildRequires` 是否被 chroot 环境满足
  （正常情况下 Copr 会自动安装，无需手动处理）。

## 6. 上游维护注意事项

1. **升级 Flutter SDK**：同步修改三处——
   `build/docker/debian10-release.Dockerfile` 的 `FLUTTER_VERSION`、
   Copr spec 模板的 `flutter_version`/`flutter_commit`/`flutter_sha256`
   （查询 releases_linux.json）；
2. **修改桌面元数据**：canonical/compat desktop ID 变更会影响
   `%files`，两份 spec 模板同步调整；
3. **本地验证源码归档**：
   ```bash
   bash build/scripts/update-version-files.sh <version>
   bash build/scripts/package-source-archive.sh --version <version>
   ```
   （发布流水线在 prepare-release 阶段自动执行同两步）；
4. **spec 语法验证**（可选，需 Fedora 环境）：
   ```bash
   rpmspec -P --target x86_64  linglong-store-<v>.copr.spec
   rpmspec -P --target aarch64 linglong-store-<v>.copr.spec
   ```

## 7. 验证记录（2026-08-27）

- 模板渲染：stable 渠道渲染无残留占位符；nightly 渠道正确跳过 Copr 段；
- 源码归档：真实仓库树全量制作成功（约 1065 个条目 / 1.7 MB）；同提交
  两次产出 sha256 一致；版本护栏（pubspec 版本不匹配 / 版本含连字符）
  双向生效；
- 资产链路：`normalize-release-assets.sh` 与
  `append-release-asset-hashes.sh` 对 `.copr.spec` 的收编与哈希覆盖模拟
  通过；
- spec 语法：渲染产物在 Fedora 容器内 `rpmspec -P` 双架构（x86_64 /
  aarch64）宏展开解析通过，`Source1` 架构条件化生效（aarch64 无 Source1）。

## 8. 已知限制与风险

| 项 | 说明 | 缓解 |
|----|------|------|
| 尚未在 mock/Copr 完整实构建 | 本地验证到 `rpmspec -P` 语法与宏展开层 | 首个 Copr 项目首次构建即真实验证；失败按 5.5 排查 |
| 无 `.git` 项目目录 | 源码归档不含 `.git`，flutter 工具从 `pubspec.yaml` 读取版本号（官方支持路径） | 已在官方容器外构建实践中验证可行；若未来 flutter 工具行为变化，再评估嵌入 `.git` 元数据的必要性 |
| PNG 图标跨机器差异 | rsvg/ImageMagick 输出字节可能不同 | 完整性以 `hashes.sha256` 为准（D7） |
| aarch64 SDK 引导较慢 | git clone + 自举下载 dart-sdk | 仅影响构建时长，不影响正确性 |
| Copr 构建机网络依赖 | 需访问 storage.googleapis.com、pub.dev、github.com | Copr 默认开放构建网络；不可达时构建失败并留有日志 |
