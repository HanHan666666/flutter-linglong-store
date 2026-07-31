# 40. 应用自更新设计

> 状态：已确认并实现
>
> 支持范围：DEB、RPM、AppImage
>
> 完成行为：安装新版后由用户手动关闭并重新打开应用

## 1. 目标与边界

设置页检测到商店自身存在新版本后，用户可以直接下载并安装与当前运行身份匹配的发布资产。

本功能只负责：

1. 识别当前进程实际来自 DEB、RPM、AppImage 还是其它手动安装；
2. 从 Release 资产中选择当前架构对应的安装包；
3. 下载安装包与同一 Release 的 `hashes.sha256`；
4. 本地计算安装包 SHA256，完全一致后才调用安装器；
5. 安装成功后提示用户手动关闭并重新打开应用。

明确不做：

- 不自动退出或重启应用；
- 不创建等待旧 PID 退出的重启协调器；
- 不创建签名更新清单，不使用 Ed25519，不新增发布私钥或 GitHub Secret；
- 不支持 tar.gz、源码构建、Arch/AUR 或其它手动安装方式的自动覆盖；
- 不在系统包管理器开始工作后强行取消事务。

这里选择 SHA256 的目标是发现下载损坏或资产内容不一致。`hashes.sha256` 与安装包来自同一 HTTPS Release，它不是独立的供应链签名；如以后需要更强的来源真实性保证，应单独提出需求并重新评审密钥生命周期，不能顺手塞进当前流程。

## 2. 总体架构

依赖方向保持为：

```text
Presentation
  AppUpdateFlowDialog（只观察状态和发送事件）
        ↓
Application
  AppSelfUpdateController（唯一状态源、单飞约束）
        ↓
  AppSelfUpdateService（业务顺序编排）
        ↓
Domain ports
  Probe / WorkspaceFactory / Installer
        ↑
Platform
  LinuxAppInstallationProbe
  XdgAppUpdateWorkspaceFactory
  Dpkg / Rpm / AppImage installers
```

生产实现只在 `lib/bootstrap/production_dependency_overrides.dart` 组装。Application 和 Presentation 不创建 Dio、文件系统或 Shell 具体实现。

## 3. Release 资产契约

### 3.1 资产来源

`VersionCheckService` 从 Gitee、GitHub 的 latest Release API 读取：

- `tag_name`；
- Release 页面 URL；
- 全部 `assets` 的文件名、下载 URL 和可选大小。

若镜像报告新版本但没有 `hashes.sha256`，服务继续尝试下一发布源；如果所有源都缺少哈希文件，仍然报告“存在新版本”，让用户可以打开下载页，但自动安装会明确失败为“校验信息缺失”。

### 3.2 安装包选择

客户端不绑定完整版本文件名，只按当前运行身份和架构后缀选择唯一资产：

| 当前身份 | amd64 | arm64 | loong64 |
|---|---|---|---|
| DEB | `*amd64.deb` | `*arm64.deb` | `*loong64.deb` |
| RPM | `*x86_64.rpm` | `*aarch64.rpm` | 不支持 |
| AppImage | `*-amd64.AppImage` | `*-arm64.AppImage` | 不支持 |

规则同时兼容 stable 和 nightly 的分隔符差异。匹配不到时返回“不支持当前架构”；同一目标匹配到多个文件时拒绝安装，避免随意选择。

### 3.3 SHA256 校验

发布流程已有 `build/scripts/append-release-asset-hashes.sh`，它为发布资产生成标准格式：

```text
<64 位 SHA256>  <完整资产文件名>
```

客户端使用完整文件名精确匹配，不做 `contains` 或相似文件名匹配。缺少目标摘要、重复摘要、摘要不一致都必须在进入安装器之前失败。

## 4. 当前运行身份探测

`LinuxAppInstallationProbe` 判断的是当前进程来源，不是“系统安装过什么”：

1. `APPIMAGE` 非空且文件存在时，当前进程直接识别为 AppImage；该证据优先级最高；
2. 否则用 `Platform.resolvedExecutable` 查询 `dpkg-query -S <executable>`；
3. dpkg 未命中时查询 `rpm -qf --qf '%{NAME}\n' <executable>`；
4. 只有归属包名精确为 `linglong-store` 才识别为 DEB/RPM；
5. 其它情况统一为 manual，只允许用户前往下载页手动安装。

因此，机器上残留一个 DEB 包不会把当前运行的 AppImage 误判为 DEB；也不需要把 Debian、Ubuntu、Deepin、Fedora、RHEL、openSUSE 等发行版名称维护到业务模型中。

## 5. 应用级任务生命周期

`AppSelfUpdateController` 是唯一任务所有者：

- 保存本次 `VersionCheckResultUpdateAvailable` 快照；
- 同一时间最多运行一个任务，重复 `start` 保持幂等；
- 保存阶段、进度、错误和取消信号；
- 处理开始、重试、取消、重置事件；
- 弹窗关闭、重建或语言切换不能创建第二个任务。

状态阶段如下：

```text
detectingInstallation
  → resolvingAsset
  → downloading
  → verifying
  → installing
  → done

任一可失败阶段 → failed
安装前用户取消 → cancelled
```

下载、选择和校验阶段允许协作取消。进入 `installing` 后不再显示取消按钮，因为中断 dpkg/RPM 事务可能留下半安装状态。

`AppUpdateFlowDialog` 只读取 Controller 状态并发送取消、重试、关闭事件。任务运行期间弹窗禁止通过 Escape 或点击遮罩关闭，避免 UI 消失后用户误以为任务停止。

## 6. XDG 下载工作区

每次任务创建隔离目录：

```text
$XDG_CACHE_HOME/<application-id>/self-update/session-*/
```

未设置 `XDG_CACHE_HOME` 时使用 XDG 标准回退：

```text
$HOME/.cache/<application-id>/self-update/session-*/
```

下载先写 `<asset>.part`，完成后在同一目录原子改名。以下所有路径都通过 `finally` 释放整个 session：

- 下载失败或超时；
- 用户取消下载；
- SHA256 文件缺失或无法解析；
- SHA256 不一致；
- 用户取消 pkexec 授权；
- dpkg、RPM 或 AppImage 安装失败；
- 安装成功。

清理失败只记录日志，不能覆盖真实的安装结果。

## 7. 安装适配器

### 7.1 DEB

校验成功后执行：

```text
pkexec dpkg -i <downloaded.deb>
```

### 7.2 RPM

校验成功后执行：

```text
pkexec rpm -Uvh <downloaded.rpm>
```

### 7.3 AppImage

AppImage 使用 Probe 返回的真实 `APPIMAGE` 路径：

1. 把下载文件复制为同目录 `<oldPath>.new`；
2. 设置权限为 `0755`；
3. 同目录 rename 原子替换旧文件；
4. 当前用户无权替换时，清理 staging 文件并回退：

```text
pkexec install -m 755 <downloaded.AppImage> <oldPath>
```

必须显式恢复执行位。普通 `openWrite`、`copy` 或下载文件通常受 umask 影响成为 `0600/0644`，直接替换会导致下一次无法启动。

三个适配器只负责安装，不管理 Controller、不关闭窗口、不拉起进程。

## 8. 安装完成后的行为

`done` 只表示新版已经写入系统包或 AppImage 原路径。当前旧进程继续运行，弹窗显示：

> 更新已安装，请关闭应用后重新打开以使用新版本

用户点击“关闭”只关闭结果弹窗，不强制退出应用。用户之后正常关闭窗口并重新打开即可进入新版本。

这样避免：

- 新旧进程与单实例锁竞争；
- 不同桌面环境和包类型的重启行为差异；
- 安装完成但拉起失败导致结果语义混乱；
- 为一个简单更新功能引入 PID 协调器和额外生命周期状态。

## 9. 错误与用户行为

| 场景 | 结果 |
|---|---|
| 当前身份不是 DEB/RPM/AppImage | 提示手动下载安装 |
| 当前架构没有匹配资产 | 提示当前架构不支持自动安装 |
| 缺少 `hashes.sha256` 或目标摘要 | 中止安装，提示校验信息缺失 |
| 本地 SHA256 不一致 | 中止安装，提示校验失败 |
| 下载失败 | 显示失败，可重试或关闭 |
| 下载/校验阶段取消 | 进入 cancelled，可重试或关闭 |
| pkexec 授权取消或安装命令失败 | 显示失败并清理下载文件 |
| 安装成功 | 提示手动关闭并重新打开 |

## 10. 维护约定

新增包类型时必须新增独立 `AppUpdateInstaller`，并同步扩展资产选择规则；禁止把新分支堆进现有 DEB/RPM/AppImage 适配器。

不得在页面或弹窗中直接下载文件、执行 `pkexec`、识别发行版或保存任务状态。所有任务入口继续收敛到 `AppSelfUpdateController`。

不得把自更新重新绑定到 `LinuxDistribution`。是否可自动更新只取决于当前可执行文件的真实归属。

不得加入自动重启。若未来产品需求变化，必须先重新评审单实例、进程退出、失败恢复和三种安装身份的差异。

不得自行加入签名清单或发布私钥。当前确认方案是 Release 的 `hashes.sha256` 下载后校验。

## 11. 验证边界

自动化验证只覆盖真实风险：

- AppImage 优先级和当前可执行文件归属探测；
- DEB/RPM/AppImage 后缀选择与 SHA256 精确解析；
- Controller 禁止并发；
- 下载、校验、授权失败和取消后的工作区清理；
- XDG cache 路径；
- AppImage 替换后的执行权限；
- UI 成功态的手动重启提示和失败重试。

交付前执行：

```bash
flutter analyze
flutter test <自更新相关测试>
flutter build linux --release
```
