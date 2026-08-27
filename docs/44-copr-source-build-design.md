# Fedora Copr 源码构建设计

## 1. 概述

本仓库为 Fedora Copr 提供从源码构建 RPM 的完整支持。每次 stable 发版随
Release 附件发布两个文件：

- `linglong-store-<version>.tar.gz` —— 自包含源码归档；
- `linglong-store-<version>.copr.spec` —— 已填好版本号与 `Source0` 的
  构建配方。

Copr 维护者在自己的 Copr 项目中提交该 spec 的附件链接即可构建，产物为
`x86_64` / `aarch64` 架构、面向当前活跃 Fedora 版本的 RPM，安装布局与
官方发行的 RPM 完全一致。

## 2. 与官方 RPM 的关系

仓库维护两条独立的 RPM spec：

| 轨道 | 模板 | 说明 |
|------|------|------|
| 官方二进制 RPM | `build/packaging/linux/rpm/linglong-store.spec.in` | 重打包官方 CI 已编译产物，覆盖低 glibc 系统等官方发行目标 |
| Copr 源码 RPM | `build/packaging/linux/copr/linglong-store.spec.in` | 在 mock/Copr 环境内完成 SDK 引导与编译，覆盖活跃 Fedora 版本 |

两条轨道的 `%files` 安装布局相同（`/opt/linglong-store` + `/usr/bin`
wrapper + 桌面入口 + 图标 + AppStream 元数据），用户侧安装结果等价。

## 3. spec 构建流程

### 3.1 Flutter SDK 引导（按架构分流）

Flutter 官方 stable 归档仅发布 x86_64 的 Linux SDK，spec 内按 `%ifarch`
分流，两个架构锁定同一版本：

| 架构 | 引导方式 | 一致性保障 |
|------|----------|-----------|
| x86_64 | `Source1` 声明官方归档 URL，rpmbuild 制作 srpm 时自动下载，`%prep` 内 sha256 校验 | `%global flutter_sha256` |
| aarch64 | shallow clone `flutter/flutter` 版本 tag，首次执行 `bin/flutter` 时按宿主架构下载 dart-sdk | `%global flutter_commit`，`git rev-parse` 比对 |

`Source1` 仅在 x86_64 声明，aarch64 构建不会下载无法使用的 x86_64 归档。

### 3.2 编译与安装

- 编译参数与官方发行一致：`flutter build linux --release --obfuscate
  --split-debug-info=...`（调试符号不入包）；
- 不执行 build_runner：生成源码（`*.g.dart` 等）与 `pubspec.lock` 均已
  入库，依赖解析是确定性的；
- 桌面入口、图标、AppStream 元数据直接安装归档内 `packaging-dist/` 的
  预渲染产物，构建端不需要 dart 脚本或 SVG 工具；
- `AutoReqProv: no` + 手写 `Requires`（与官方 RPM 一致，避免对 `/opt`
  捆绑库自动生成噪声依赖）；禁用 debuginfo 子包。

## 4. 源码归档

由 `build/scripts/package-source-archive.sh` 在发版时制作，组成为
`git archive HEAD` 树 + 发版版本文件覆盖（pubspec.yaml、
linux/pubspec.yaml、app_config.dart）+ 预渲染的 `packaging-dist/`：

```
linglong-store-<version>/
  （完整源码树，不含 .git）
  packaging-dist/
    com.dongpl.linglong-store.v2.desktop   # 主桌面入口（多语言）
    compat/linglong-store.desktop          # 兼容桌面入口
    metainfo/linglong-store.appdata.xml    # AppStream 元数据（多语言）
    icons/linglong-store-256.png           # 256px 图标
    linglong-store.spec                    # 内嵌本次发版的 Copr spec
```

打包使用归一化参数（`--sort=name`、统一 mtime 为提交时间、固定属主、
`gzip -n`）：同一提交产出字节一致。PNG 图标依赖渲染工具版本，跨机器可能
不同，完整性以 Release 附件的 `hashes.sha256` 为准（源码归档与 spec 均已
纳入该清单）。

## 5. 发版流水线产物

```
prepare-release 阶段
  package-source-archive.sh
    └─ linglong-store-<v>.tar.gz / linglong-store-<v>.copr.spec
       （artifact: release-assets-source）

sign-release 阶段
  源码 tar.gz 获得 .asc 签名；.copr.spec 仅透传，不签名

publish-release 阶段
  两类文件随 GitHub Release 附件发布，并纳入 hashes.sha256
```

## 6. Copr 维护者指南

### 6.1 一次性准备

1. 注册 Fedora 账号（FAS），登录 <https://copr.fedorainfracloud.org>；
2. 新建 Copr 项目，勾选当前活跃 Fedora 版本的 `x86_64` 与 `aarch64`
   chroot。保持默认设置即可——Copr 构建默认允许联网，spec 需要下载
   Flutter SDK 与 pub 依赖。

### 6.2 提交构建

1. 打开本仓库任意 stable Release 页，复制 `linglong-store-<version>.copr.spec`
   附件的下载链接；
2. Copr 项目页 → New Build → ByUrl，粘贴该链接提交；
3. Copr 自动下载 spec、源码归档与 SDK 归档，在所选 chroot 内执行
   `%prep` / `%build` / `%install`。单个 chroot 构建约 15–45 分钟
   （aarch64 通常更慢）。

### 6.3 用户安装

```bash
dnf copr enable <你的用户名>/linglong-store
dnf install linglong-store
```

### 6.4 版本跟进

上游每次 stable 发版都会附带新版本的 `.copr.spec`（版本号与 Source0 已
渲染好）。提交新附件链接重建即可，无需修改任何内容。CLI 方式：

```bash
copr-cli build <项目> <spec 附件 URL>
```

如需深度定制（修改 Release 号、打补丁），可 fork spec 自行维护：spec 的
`Source0` / `Source1` 均为完整 URL，无外部依赖。

### 6.5 构建失败排查

- **SDK 下载/校验失败**：查看 `%prep` 日志中 `sha256sum -c` 或
  `git clone` 段，多为网络问题；
- **`pub get` 失败**：pub.dev 网络问题，重试即可；
- **缺系统库**：`BuildRequires` 由 Copr 自动安装，出现即属于上游 spec
  问题，请向上游反馈。

## 7. 上游维护要点

1. **升级 Flutter SDK** 时同步修改两处：官方发布容器
   `build/docker/debian10-release.Dockerfile` 的 `FLUTTER_VERSION`，以及
   Copr spec 模板的 `flutter_version` / `flutter_commit` /
   `flutter_sha256`（从
   `https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json`
   查询）；
2. **修改桌面元数据**（canonical / compat desktop ID）时，两份 spec 模板
   与 `package-source-archive.sh` 需同步调整；
3. **本地验证源码归档**：

   ```bash
   bash build/scripts/update-version-files.sh <version>
   bash build/scripts/package-source-archive.sh --version <version>
   ```

4. **spec 语法验证**（需 Fedora 环境）：

   ```bash
   rpmspec -P --target x86_64  linglong-store-<v>.copr.spec
   rpmspec -P --target aarch64 linglong-store-<v>.copr.spec
   ```

## 8. 支持范围与限制

- **发行版**：Copr 上的活跃 Fedora 版本。构建产出的 glibc 门槛由构建
  chroot 决定，不向下兼容旧发行版；旧系统的兼容性由官方二进制 RPM 承担；
- **架构**：`x86_64`、`aarch64`（`ExclusiveArch` 声明）；loong64 走官方
  发布链路，不进 Copr；
- **渠道**：仅 stable。nightly 版本号不满足 RPM `Version` 语义，渲染器在
  nightly 渠道跳过 Copr 产物；
- **归档不含 `.git`**：flutter 工具从 `pubspec.yaml` 读取版本号，属官方
  支持路径；
- 完整构建尚未在 mock/Copr 实机验证过，首次构建若失败按 6.5 排查或向上游
  反馈。
