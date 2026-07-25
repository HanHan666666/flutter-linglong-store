# 跨发行版玲珑安装（OBS 社区源）问题解决

> 文档版本：1.0
> 更新日期：2026-07-25
> 适用范围：在 Deepin/UOS 之外的发行版（Ubuntu / Debian / Fedora / Arch 等）上，玲珑应用商店或 `ll-cli` 无法下载、安装应用的故障排查与修复。

## 背景与问题现象

在非 Deepin/UOS 的发行版上自行安装玲珑后，常出现应用列表能拉取，但点下载/安装直接失败的现象。典型表现：

- 命令行：`ll-cli install --json <appId>` 返回
  `{"code":-1,"message":"Failed to connect signal: RequestInteraction"}`。
- GUI：玲珑商店点击安装无响应或弹错。

原始问题来自 Zorin OS 18.1（基于 Ubuntu 24.04 LTS）环境，报错即如上。

## 根本原因

非 Deepin 发行版自带的 `linglong` 包（或用户随手 `apt install linglong` 装到的版本）并不是上游维护的稳定运行时，在跨发行版环境下玲珑的安装交互信号（`RequestInteraction`）无法正常连接，导致下载/安装链路中断。

## 解决方案：换装社区 OBS 源的玲珑 1.12.2

社区维护者在 OpenBuildService 上为各主流发行版单独编译并签名了玲珑 1.12.2 稳定版，经过跨发行版 SIG 测试确认可用。**正确做法是先加这个源，再安装 `linglong-bin` 与 `linglong-box` 这两个包**（不是发行版自带那个 `linglong`）。

### Ubuntu 24.04（含 Zorin OS 18.1、Linux Mint 22 等基于 24.04 的衍生版）

```bash
sudo apt install curl -y && sudo install -d -m 0755 /usr/share/keyrings

curl -fsSL https://obs-ci.odata.cc/obs-mirror/xUbuntu_24.04/Release.key \
  | gpg --dearmor | sudo tee /usr/share/keyrings/obs-ubuntu2404.gpg >/dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/obs-ubuntu2404.gpg] https://obs-ci.odata.cc/obs-mirror/xUbuntu_24.04/ ./" \
  | sudo tee /etc/apt/sources.list.d/obs-ubuntu2404.list

sudo apt update
sudo apt install linglong-bin linglong-box -y
```

装完之后，应用商店或 `ll-cli install` 的下载/安装交互即可恢复正常。

### 其他 Debian/Ubuntu 版本

把上面命令里的镜像路径、GPG key 名、源文件名按版本替换即可：

| 发行版 | 镜像路径片段 |
| --- | --- |
| Debian 12 | `Debian_12` |
| Debian 13 | `Debian_13` |
| Debian Testing | `Debian_Testing` |
| Debian Sid | `Debian_Unstable` |
| Ubuntu 22.04 | `xUbuntu_22.04` |
| Ubuntu 24.04 | `xUbuntu_24.04` |
| Ubuntu 25.04 | `xUbuntu_25.04` |
| Ubuntu 25.10 | `Ubuntu_25.10_standard` |
| Ubuntu 26.04 | `xUbuntu_26.04` |

派生发行版直接用其上游：例如 Linux Mint 22 基于 Ubuntu 24.04，就用 24.04 的包；MX Linux / LinuxMINT 同理。

### Fedora / EPEL（RPM 系）

```bash
sudo dnf copr enable mozixun/OpenAtom-Linyaps
sudo dnf install linglong linglong-bin linglong-builder linglong-pica linyaps-web-store-installer -y
```

OpenEuler 因其 `dnf` 砍掉了 `copr enable` 支持，需直接下载 repo 文件：
<https://copr.fedorainfracloud.org/coprs/mozixun/OpenAtom-Linyaps/repo/openeuler-24.03/mozixun-OpenAtom-Linyaps-openeuler-24.03.repo>

### Arch Linux

玲珑包已进入 Extra 仓库，自行加源获取即可。

## 注意事项

1. **务必使用本源 `obs-ci.odata.cc`，不要用 `ci.deepin.com/repo/obs/linglong`**，后者会出现 404 或依赖不全。
2. **源要带签名**：若出现 `Release 没有 Release 文件 / 默认禁用该源`，说明没下到签名 key，按上面命令正确导入 GPG key；或临时在 deb 行前缀加 `[trusted]`。
3. **Ubuntu 22.04 及更老版本有硬限制**：系统 `liblzma` 过旧，无法用 `ll-builder` 构建时 `-z` 强制 lzma 压缩，也不能装本地 lzma 压缩的 layer 包。24.04 及更新不受影响。
4. **太新的版本可能有坑**：如 Kubuntu 26.04 反馈过“能下载但安装失败”。Ubuntu 24.04 是被官方测试覆盖的、相对最稳的版本。
5. 银河麒麟 v10 关闭相关系统保护后，解压对应架构包执行 `install.sh` 即可。

## 与本项目的关系

本项目（Flutter 版玲珑应用商店）运行在 Deepin 25 上，玲珑运行时由系统提供，**不涉及本文档的跨发行版安装问题**。本文档仅作为外部知识参考：当商店用户在非 Deepin 发行版上遇到玲珑环境本身不可用时，可指引其先按本文档把玲珑运行时装对，再使用商店。

Deepin/UOS 环境下玲珑运行时的诊断与修复，见 `docs/21-linglong-environment-management.md`。

## 参考来源

- 问题帖：[玲珑商店无法下载](https://bbs.deepin.org.cn/post/300089)
- 社区 OBS 源安装教程（版主 mozixun）：[【日常更新】玲珑 1.12.2 各发行版更新](https://bbs.deepin.org.cn/zh/post/289061)
