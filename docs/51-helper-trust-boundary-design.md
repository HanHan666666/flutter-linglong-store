# 51 - 特权 helper 信任边界收敛（仅系统包形态）与直连回退设计

> 状态：**已实施**（2026-09-10；自动化门禁通过，真机回归列入发版清单）
>
> 日期：2026-09-10
>
> 关联文档：docs/47（helper 引入与"已接受风险"的原始记录）、docs/23（取消链路历史结论）、
> docs/50（失败链 / 队列门闩 / 免密直连路径）

---

## 1. 背景与威胁

docs/47 引入的 pkexec root helper（首次任务授权一次、会话内复用、空闲五分钟退出）
此前在所有运行形态启用，包括 helper 文件可被当前用户替换的形态。pkexec 在认证
**完成后**才按路径执行目标程序（polkit 123 `pkexec.c`：认证前仅 `realpath` +
`access(F_OK)`，认证后 `execv(path)`，无 fd 固定、无内容复验），因此存在如下
TOCTOU 窗口：

```text
t0  GUI 解析 helper 路径（FUSE 形态先暂存到 $XDG_RUNTIME_DIR 用户属主目录）
t1  GUI 启动 pkexec，弹出授权对话框
t2  用户输入密码（窗口最长可达客户端 readyTimeout = 5 分钟；
    FUSE 形态的暂存副本必须保留到 helper 发出 ready 之后才删除）
t3  同 UID 恶意进程在窗口内替换该路径上的文件（属主为当前用户，
    0700/0500 只能隔离其他用户，挡不住同 UID 的 chmod/unlink+重建）
t4  认证通过，pkexec 执行被替换的载荷 → 以 root 运行
```

docs/47 §5.2.2 与 §11 曾将该窗口记录为"产品已接受的剩余风险"（AppImage 暂存
副本、用户解压 bundle、开发构建）。本次决策不再接受：**所有存在该风险的形态
全部处理**，以消除"商店可能诱导用户为攻击者载荷输入管理员密码"的本地提权面。

## 2. 决策

### 2.1 唯一信任条件

只有能证明**当前运行 bundle 由系统包管理器安装**时才启用特权 helper：

- 判定输入：`Platform.resolvedExecutable`（当前实际运行的可执行文件）；
- 判定方式：`dpkg-query` / `rpm` / `pacman` 归属查询任一命中即可信；全部不命中
  即不可信（命令绝对路径与数据库目录已固定，见 §4.1）；
- 可信等价于"路径位于 root 属主的包管理器安装树内，同 UID 进程无法替换"；
- 不需要维护包名白名单：恶意同 UID 进程无法让 root 级包管理器为其落盘任何文件，
  而白名单会随包名（`-bin`、nightly、未来改名）漂移。

### 2.2 形态矩阵（新行为）

| 运行形态 | helper 路径归属 | 新行为 |
|---|---|---|
| DEB / RPM / Copr（`/opt/linglong-store`，root 属主） | 包管理器 | **保留 helper**（授权复用体验不变） |
| AUR `linglong-store-bin` / `linglong-store-nightly-bin`（`/opt/linglong-store`，root 属主） | 包管理器（pacman） | **保留 helper** |
| AppImage FUSE 挂载运行 | 用户属主暂存副本 | **直连 ll-cli**（不再暂存、不再 pkexec） |
| AppImage extract-and-run | 用户属主提取目录 | **直连 ll-cli** |
| 用户解压的 release bundle | 用户属主解压目录 | **直连 ll-cli** |
| `flutter run` / 开发构建 | 用户属主构建目录 | **直连 ll-cli** |
| 其他无法证明包管理器归属的形态 | — | **直连 ll-cli** |

直连形态的行为（复用 docs/50 免密路径已实现的机制）：

- 普通用户执行 `ll-cli install/upgrade --json ...`，由上游 daemon 的 polkit 检查
  弹出系统授权框：**每个任务一次**（每个 ll-cli 进程都是新的 polkit subject，
  `auth_admin_keep` 缓存随进程退出失效）；
- 取消只向本进程自己启动的 ll-cli 发 SIGTERM（触发上游 `aboutToQuit →
  cancelCurrentTask → D-Bus Task.Cancel` 协作取消），**不再有第二次授权弹窗**；
- 用户在授权框取消/拒绝 → ll-cli 输出 `{"code":9,"message":"not authorized"}`
  → 复用既有 `authorizationDenied` 稳定失败类型 + 队列授权门闩（暂停自动消费，
  等待用户明确重试）+ 既有文案 `installErrorAuthorizationDenied`，**不新增文案**；
- 开启免密开关（docs/50）时走既有 `passwordFreeCli` 路径，无任何弹窗。

### 2.3 删除 FUSE 暂存机制

`PrivilegedHelperBinary` 的"FUSE 检测 + 暂存副本 + 清扫 + 幂等清理"整体删除：

1. **新规则下不可达**：包管理器安装的 bundle 永远位于普通文件系统的 root 属主
   目录（`/opt/linglong-store`），不可能在 FUSE 挂载点上；
2. **它本身就是漏洞路径**：暂存的语义是"把 helper 复制到当前用户可写目录、再
   让 pkexec 以 root 执行该副本"——保留它等于保留一条"探测漏判时静默可用"的
   提权链；
3. **fail closed 更正确**：删除后，万一未来路由把非信任形态接回 helper，会在
   执行阶段直接失败（不可用错误），而不是悄悄执行用户可替换副本。

### 2.4 兼容性

- helper 的协议、能力白名单与生命周期不变（docs/47 §6~§9 仍然有效）；
- 失败类型、门闩、文案、`_taskTransports` 按任务绑定取消路由的语义不变（docs/50 §7）；
- pkexec 仍然存在，但只执行包管理器安装路径（root 属主、包管理器保护）。

## 3. 上游事实核实（证据索引）

| 事实 | 证据 |
|---|---|
| pkexec 认证后按路径 `execv`（TOCTOU 窗口成立） | polkit `src/programs/pkexec.c`（本机 `pkexec version 123`）：认证前仅 `realpath`/`access`，认证后 `execv(path, ...)`，无 fd 固定、无内容复验 |
| ll-cli 不再自行 pkexec 提权（旧结论已过期） | 上游 `9937c545`（2026-05-27）改为 daemon 侧 polkit 校验；本机 linglong-bin 1.14.0 的 `/usr/bin/ll-cli` 二进制无 `pkexec` 字符串 |
| 直连安装的授权由 daemon polkit 触发，每任务一次 | `libs/linglong/src/linglong/package_manager/package_manager.cpp` `Install()` → `checkPolkitAuthorizationAsync(action, msg.service())`；`polkit_authority.h` `userInteraction` 默认 `true`；Qt 源码 `qdbusmessage.cpp`：接收消息的 `service()` 即发送方 unique name（每个 ll-cli 进程都是新 subject） |
| 直连取消只需 SIGTERM | `libs/linglong/src/linglong/common/global/initialize.cpp` `catchUnixSignals({SIGTERM, SIGQUIT, SIGINT, SIGHUP})` → `QCoreApplication::quit()` → `aboutToQuit` → `Cli::cancelCurrentTask()` → D-Bus `Task1.Cancel`；ll-cli 为普通用户属主 |
| 授权拒绝输出契约 | daemon 回复 `AccessDenied` + `"not authorized"`；ll-cli `printErr` 输出 `{"code":9,"message":"not authorized"}`（Qt `AccessDenied` 枚举 = 9；消息非本地化） |
| 直连路径的归类/门闩/文案已存在 | `lib/data/repositories/linglong_cli_repository_impl.dart` `_failureKindForCliError`（匹配 `not authorized` → `authorizationDenied`）；`lib/application/providers/install_queue_provider.dart` 授权门闩；10 语言 `installErrorAuthorizationDenied` |
| 系统包安装路径（root 属主） | DEB：`build/scripts/package-deb.sh`（`/opt/linglong-store`）；AUR：`build/packaging/linux/aur/PKGBUILD.in`（`/opt/linglong-store`）；RPM/Copr 同布局 |
| 旧暂存窗口存在 | `lib/core/platform/privileged_helper/privileged_helper_binary.dart`（暂存创建/清理，已删除）；`privileged_helper_client.dart` 曾在收到 `ready` 后才删除暂存副本 |

## 4. 设计

### 4.1 探测：bundle 包管理器归属

`LinuxAppInstallationProbe`（`lib/platform/self_update/linux_app_installation_probe.dart`）
新增 `isManagedBySystemPackageManager()`，对 `Platform.resolvedExecutable` 依次
查询（全部固定绝对路径并显式指定包数据库目录）：

1. `/usr/bin/dpkg-query --admindir /var/lib/dpkg -S <path>`：退出码 0 且输出行
   最后一个 `: ` 之后的字段与该路径精确相等 → 由 dpkg 管理；
2. `/usr/bin/rpm --dbpath /var/lib/rpm -qf <path>`：退出码 0 → 由 rpm 管理；
3. `/usr/bin/pacman --dbpath /var/lib/pacman -Qo <path>`：退出码 0 → 由 pacman 管理。

- 任一步命中即返回 true；命令或数据库目录不存在（非对应发行版）按未命中处理，
  继续下一项；全部未命中、探测异常或超时返回 false（**fail closed**）；
- **不校验包名**：只证明"由系统包管理器落盘"；
- **安全约束（复核加固）**：命令固定绝对路径、数据库目录显式传参，防止同 UID
  进程用 PATH 垫片（如 `~/.local/bin/dpkg-query`）或 `DPKG_ADMINDIR`、rpm 宏等
  环境重定向把探测指向伪造数据库；找不到命令时按未命中处理，失败方向是
  回退直连（安全方向）；
- `detect()`（自更新身份语义）的查询命令同步改为绝对路径与显式数据库目录，
  行为语义不变（原为裸命令名，存在同类环境依赖，一并收敛）。

### 4.2 信任 resolver 与组合根注入

- 新增 `PrivilegedHelperTrustResolver = Future<bool> Function()`（异步，探测
  需要启动子进程）；
- Application 层新增 `privilegedHelperTrustResolverProvider`（占位默认
  `_missingDependency`）；生产组合根覆盖为
  `buildMemoizedHelperTrustResolver(probe)`（`lib/bootstrap/production_dependency_overrides.dart`，
  可单测）：**单次解析 + 会话内缓存**，解析异常在构造器内就保守返回 false 并
  随缓存复用；
- **未注入解析器时按不可信处理（fail closed）**：漏注入只会让所有形态退化为
  每任务系统授权，不得静默恢复"对不可验证来源使用特权 helper"的旧行为；
- Data 层不反向依赖 Application：resolver 由组合根注入 Repository；Data 层对
  任何解析异常还有第二道兜底捕获（同样回退不可信）。

### 4.3 传输选择与取消路由

`LinglongCliRepositoryImpl`（`_runInstallLikeOperation`）任务启动时绑定传输：

```text
免密开启                          → passwordFreeCli（既有）
未注入 helper（测试）              → legacyDirectCli（既有）
helper 注入 && 可信                → privilegedHelper（既有）
helper 注入 && 不可信/未注入解析器  → directCliFallback（本次新增）
```

- 新增 `_CliTaskTransport.directCliFallback`：直连普通用户 ll-cli，取消走
  `_cancelProcess`（SIGTERM），与 `passwordFreeCli` 同一取消分支；禁止复用
  `pkexec kill`；
- 判定在任务启动时执行一次并记录到 `_taskTransports`，取消严格按绑定路由
  （docs/50 §7.2 语义不变）；
- **生产组合根必须注入解析器**，系统包形态才会使用 helper。

### 4.4 helper 定位入口简化

`PrivilegedHelperBinary` 收敛为"bundle 内固定路径解析 + 缺失即不可用"：

- 删除：FUSE 检测（mountinfo 解析）、暂存创建、清扫、`PreparedHelperPath`
  的 `staged`/`release()` 语义、`_chmod`/随机目录等全部辅助设施；
- `prepare()`（同步）返回可直接交给 pkexec 的绝对路径（bundle 内
  `libexec/linglong_store_helper`）；文件缺失时抛
  `PrivilegedHelperUnavailableException`（结论不变）；
- `PrivilegedHelperClient` 删除 `release()` 调用与 `staged` 日志。

### 4.5 诊断

- 探测结果记录命中的包管理器（dpkg/rpm/pacman/未命中）与判定耗时（首个安装
  任务会同步等待该判定，耗时日志用于定位首次任务延迟）；
- 传输绑定时记录 `transport` 与信任判定结果，便于真机诊断
  （例如用户报告"AppImage 每任务弹窗"时可直接确认走的是直连回退）。

## 5. 测试与验收

### 5.1 自动化

| 范围 | 内容 |
|---|---|
| probe 单测 | 三管理器命中/未命中/命令缺失/超时/任意包名归属/空可执行路径；命令绝对路径与数据库目录断言 |
| resolver | 单次解析缓存、异常保守为不可信（`buildMemoizedHelperTrustResolver` 单测） |
| 组合根装配 | 信任解析器与安装 Repository 的注入 smoke 测试（端口被覆盖、可构建） |
| Repository 传输矩阵 | 可信→helper；不可信→直连（且不触发 `ensureStarted`）；未注入解析器→直连（fail closed）；免密优先且不探测；更新同规则 |
| 取消路由 | `directCliFallback` → SIGTERM（不触 `pkexec kill`） |
| 失败归类 | `{"code":9,"message":"not authorized"}` → `authorizationDenied` + 门闩 |
| binary 简化 | 路径解析、缺失即不可用（删除暂存用例） |
| 全量 | `flutter analyze` 0 问题 + `flutter test` 全通过 |

### 5.2 真机验收矩阵（发版清单）

| 场景 | 期望 |
|---|---|
| DEB/RPM/AUR：连续安装两个应用 | 一次授权，会话内复用（回归，不受本次影响） |
| AppImage（FUSE 与 extract-and-run）与解压包：安装 | 每任务一次系统授权；无暂存目录产生 |
| AppImage / 解压包：取消任务 | 立即取消，无第二次授权弹窗 |
| AppImage / 解压包：授权框取消/拒绝 | `authorizationDenied` 文案 + 队列门闩（pending 任务不自动消费） |
| 免密开启 + AppImage | 无任何弹窗（既有免密路径） |
| 开发构建（`flutter run`） | 同非信任形态（直连） |

## 6. 残留与边界

- 非包形态的体验代价是"每任务一次系统授权"；消除的是"以 root 执行可替换文件"
  的提权面。用户可用免密开关（docs/50，独立功能、明确风险提示）换取无弹窗；
- helper 对 GUI 的信任边界不变：被利用的 GUI 在会话内只能请求白名单内的在线
  安装/更新，不能执行任意命令（docs/47 §11 仍有效）；
- 非包形态的 bundle 本身仍可被同 UID 篡改，但它不再获得任何特权执行机会
  （ll-cli 为系统安装的普通用户程序；授权由桌面代理向用户如实展示）；
- 探测命令已固定绝对路径与数据库目录；"GUI 进程自身的启动环境可信"仍是产品级
  隐含前提（与既有的 `pkexec`、`ll-cli` PATH 解析一致），如未来要求更强保证，
  需要系统级组件（root 属主启动器 / 发行签名验证锚）而非应用内加固；
- AppImage / 解压包 / AUR 的真机端到端验证依赖打包产物与对应发行版环境，
  已列入发版清单；AUR 探测逻辑以单测覆盖。

## 7. 变更记录

| 位置 | 变更 |
|---|---|
| `lib/platform/self_update/linux_app_installation_probe.dart` | 新增 bundle 包管理器归属探测；命令绝对路径 + 显式数据库目录 + 耗时日志；`detect()` 查询命令同步收敛 |
| `lib/domain/models/privileged_helper_trust.dart` | 新增 `PrivilegedHelperTrustResolver` 端口类型 |
| `lib/application/providers/application_dependency_providers.dart` | 新增信任 resolver provider 占位（fail closed 语义） |
| `lib/bootstrap/production_dependency_overrides.dart` | 注入 `buildMemoizedHelperTrustResolver`（单次解析 + 缓存 + 异常保守 false） |
| `lib/data/repositories/linglong_cli_repository_impl.dart` | 传输矩阵新增 `directCliFallback`（未注入解析器按不可信）；取消路由；注释更新 |
| `lib/core/platform/privileged_helper/privileged_helper_binary.dart` | 删除暂存机制，收敛为路径解析（`prepare()` 同步返回路径） |
| `lib/core/platform/privileged_helper/privileged_helper_client.dart` | 删除 `release()`/`staged` 相关 |
| `docs/47` | 顶部 v3 修订说明；§5.2/§5.2.1/§5.2.2/§6.1/§9.1/§10.3/§17.4 标注被本文档取代；§18 第 5 条补充非包形态直连说明 |
| `CHANGELOG.md` | 2026-09-10 变更记录 |
| 测试 | probe/组合根/传输/取消/失败归类/binary 重写与扩展 |
