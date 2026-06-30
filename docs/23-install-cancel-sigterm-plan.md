# 23 - 安装取消方案：用 SIGTERM 复现 Ctrl+C（替代 pkexec killall）

> 状态：**已实现并真机回归通过（2026-06-30 21:30）**。源码研究 + 受控实测 + GUI 实测 + 编码回归四重验证通过。
> ⚠️ **重要修正**：初版假设"GUI 会话 ll-cli 以当前用户身份运行，SIGTERM 可免授权"——**已被 GUI 实测证伪**。本文档已据实修正为新方案：`pkexec kill -15 <精确PID>`。
> 创建：2026-06-30

## 一、背景与问题

### 1.1 命令行 Ctrl+C 的真实语义

用户在终端执行 `ll-cli install com.eastmoney.linyaps` 时按 Ctrl+C，看到：

```
Installing main:com.eastmoney.linyaps/2.8.0.2780/x86_64/binary [33.07MB/s] 50.05%^C
Quit the application by signal(2).
```

`signal(2)` 是 **SIGINT 的编号 2**。Ctrl+C 的完整链路（linyaps 源码）：

| 步骤 | 源码位置 |
|---|---|
| SIGINT 命中 ll-cli 进程 | `libs/linglong/src/linglong/common/global/initialize.cpp:122` 注册 handler |
| handler 打印日志 + `QCoreApplication::quit()` | `initialize.cpp:31-35` |
| **关键：SIGINT/SIGTERM/SIGQUIT/SIGHUP 共用同一个 handler** | `initialize.cpp:122` `catchUnixSignals({ SIGTERM, SIGQUIT, SIGINT, SIGHUP })` |
| `aboutToQuit` 信号 → `Cli::cancelCurrentTask()` | `apps/ll-cli/src/main.cpp:783-790` |
| `cancelCurrentTask()` → `this->task->Cancel()`（D-Bus 调用） | `libs/linglong/src/linglong/cli/cli.cpp:1112-1118` |
| daemon `PackageTask::Cancel()` → `g_cancellable_cancel()` | `libs/linglong/src/linglong/package_manager/package_task.cpp:73-88` |
| cancellable 已传入 `ostree_repo_pull_with_options`，中断 OSTree 下载 | `libs/linglong/src/linglong/repo/ostree_repo.cpp:1469` |

**核心结论**：Ctrl+C 本质是"通过 D-Bus 让 daemon 协作取消任务"，而非"杀进程"。由于 **SIGTERM 与 SIGINT 共用同一 handler**（`initialize.cpp:122`），**对 ll-cli 发 SIGTERM 等价于 Ctrl+C**。

### 1.2 当前商店的实现（问题所在）

取消逻辑收敛在 `lib/core/platform/cli_executor.dart` 的 `cancelWithSystemKill()`（line 419-475），主手段是：

```dart
final args = ['killall', '-15', 'll-cli', 'll-package-manager'];
final result = await Process.run('pkexec', args);  // line 442
```

问题：
1. **`pkexec killall` 全局杀所有同名进程**，会误杀系统上其他 ll 操作。代码里其实记录了 PID（`_activeProcessPids`，line 66；`_activeProcesses`，cli_executor.dart:105），但取消时没使用。
2. **连常驻 daemon `ll-package-manager` 一起杀**，daemon 被 systemd 重启，副作用大。
3. **必须弹 pkexec 授权框**，体验差。
4. 优雅取消路径 `cancel()`（cli_executor.dart:379，`process.kill(sigterm)`）和 `_cancelSignals` 监听（line 331）**已经实现**，却被 pkexec killall 完全覆盖，退化成"补刀"。

## 二、实测铁证（dingtalk 对照实验）

实验对象：`com.alibabainc.dingtalk`（453MB，首次下载零缓存）。完整记录了 SIGTERM 与 SIGKILL 的行为差异。

### 2.1 SIGTERM —— 成功取消

```
19:48:51 进度 1.22%，立即发 SIGTERM 到 ll-cli
19:48:51 ll-cli 在 1 秒内退出
daemon journal: task 86553... has been canceled by user   ← 取消送达
8 秒后：输出文件未增长、未 success、未安装               ← 下载真的停了
```

### 2.2 SIGKILL —— 无法取消，daemon 后台偷装完

```
19:49:23 进度 4.63%，发 SIGKILL
ll-cli 立即退出，但 daemon journal 持续报 libostree HTTP error...（仍在下载）
19:51:31 libostree pull complete  transfer: 129s, 453.3 MB   ← daemon 继续下了 129 秒
19:54:00 action Install ... success                          ← 后台偷偷装完了
```

### 2.3 对照结论

| | SIGTERM | SIGKILL |
|---|---|---|
| ll-cli 退出后 daemon 行为 | 立即 `canceled by user`，停止下载 | **继续下载 129 秒（453MB）** |
| 最终结果 | 任务取消，未安装 | **后台偷偷装完了** |
| 与 Ctrl+C | **等价**（同一 handler） | 不等价，daemon 无感知 |

**这正是当前商店 `killall -15`（SIGTERM）能取消成功的根本原因**——它发的恰是 SIGTERM。但用 `pkexec killall` 的方式杀鸡用牛刀，带来了上述 4 个问题。

## 三、GUI 实测结论：ll-cli 进程属主是 root（免授权假设证伪）

### 3.1 GUI 实测结果（2026-06-30 20:42）

在真实玲珑商店 GUI 里触发安装 `uos-youku-app.linyaps`，捕获到的进程：

```
PID 9307  PPID 7860  USER=root  pkexec ll-cli install --json uos-youku-app.linyaps
```

**结论：GUI 商店安装时，ll-cli 进程属主是 root，且确实走了 pkexec。**

### 3.2 为什么是 root（源码解释）

`ll-cli install` 内部流程（`cli.cpp:1191-1261`）：

1. `Process.start('ll-cli', ['--json','install',appId])`（cli_executor.dart:262）以当前用户 `han` 启动 ll-cli
2. ll-cli 调 `ensureAuthorized()` → `authorization()` → D-Bus 调 daemon 的 `Permissions()`
3. daemon 触发 polkit `checkAuthentication`（`allow_active=auth_admin_keep`），用户授权通过后 daemon 返回成功
4. **但**：当 `Permissions()` 返回 `AccessDenied`（在某些 polkit 配置/场景下），ll-cli 走 `runningAsRoot()`（`cli.cpp:2167-2168`）
5. `runningAsRoot()` 用 `execvp("pkexec", ["ll-cli", ...])`（`cli.cpp:2204`）**替换当前进程映像**
6. **关键**：`execvp` 不 fork，PID 不变，但进程映像变成 `pkexec ll-cli`，**属主变为 root**

### 3.3 关键事实：进程引用的 PID 仍然有效

由于 `execvp` 保持 PID 不变，商店在 `onProcessCreated` 回调里记录的 `_activeProcessPids[processId] = process.pid`（`linglong_cli_repository_impl.dart:172`）和 `_activeProcesses[processId]`（`cli_executor.dart:273`）——**这个 PID 就是 root 的 ll-cli 进程的正确 PID**。

### 3.4 授权机制确认

- `pkexec.exec`（org.freedesktop.policykit.exec）：`allow_active=auth_admin` —— **每次 pkexec 都需要授权**
- `linglong checkAuthentication`：`allow_active=auth_admin_keep` —— 认证一次后保持一段时间
- **无任何规则让 linglong checkAuthentication 或 pkexec.exec 免密**（已检查 `/usr/share/polkit-1/rules.d/` 和 `/etc/polkit-1/rules.d/`）

**含义**：
- 安装时弹 1 次授权框（checkAuthentication）
- 当前取消时用 `pkexec killall`，会**再弹 1 次授权框**（pkexec.exec 独立 action）
- **普通用户 han 无法对 root ll-cli 进程发信号**（内核安全基线：非 CAP_KILL 用户不能 kill root 进程）

## 四、修正后的改造方案

### 4.1 核心思路（修正版）

免授权的纯 SIGTERM 方案**不成立**（ll-cli 是 root 进程，han 发不出信号）。但 SIGTERM 协作取消本身仍然成立——**只是必须通过 pkexec 提权来发信号**。

新方案：把 `pkexec killall -15 ll-cli ll-package-manager`（全局杀 + 杀 daemon），改为 `pkexec kill -15 <精确PID>`（只对 root ll-cli 进程发 SIGTERM）。

- **仍然需要授权框**（pkexec.exec 性质决定，无法避免，除非加 polkit 免密规则）
- 但**消除了全局 killall 的误杀风险**（精确到 PID）
- **不再杀 daemon**（daemon 由 ll-cli 的 SIGTERM → D-Bus Cancel 协作停止）
- **获得 SIGTERM 的协作取消语义**（daemon `canceled by user`，状态干净）

### 4.2 为什么 SIGTERM 对 root ll-cli 仍能触发协作取消

- root ll-cli 与用户 ll-cli 是**同一个二进制**，`applicationInitialize()` 注册的 signal handler 完全相同（`initialize.cpp:122`）
- 已实测：sudo root 跑 dingtalk 时，SIGTERM 触发 daemon `task ... has been canceled by user`（第二节铁证）
- root 身份不改变 signal handler 行为，SIGTERM 同样走 `aboutToQuit → cancelCurrentTask → D-Bus Cancel`

### 4.3 改动面（精确到行）

改动集中在 `lib/core/platform/cli_executor.dart` 的 `cancelWithSystemKill()`（line 419-475）：

1. **主路径**：用记录的 PID（`_activeProcessPids` 经 repository 传入，或新增参数）执行 `pkexec kill -15 <PID>`，而非 `pkexec killall -15 ll-cli ll-package-manager`。
2. **不再杀 daemon**：移除 `ll-package-manager` 目标，`killPackageMananger` 默认 `false`。
3. **判定成功**：`pkexec kill -15 <PID>` 退出码 0（成功发信号）即视为成功；随后等待进度流出现 `cancelled` 状态（现有 `_handleCancelledProgress` 机制）。
4. **兜底**：若 PID 缺失或 `kill -15` 后超时未退出，回退到 `pkexec kill -9 <PID>`（SIGKILL 兜底，接受 daemon 可能后台续传的风险）。

配套小改：
- `lib/data/repositories/linglong_cli_repository_impl.dart:688-692`：`cancelOperation` 把 `_activeProcessPids[processId]` 传给 `cancelWithSystemKill`。
- 函数类型 `CliCancelWithSystemKillFn`（line 35-40）：新增 `int? pid` 参数。

**不改动**：UI 三处入口、`install_queue_provider.dart` 状态机、`Process.start` 启动方式。

### 4.4 收益（修正版）

| 维度 | 现状（pkexec killall） | 改造后（pkexec kill -15 PID） |
|---|---|---|
| 授权框 | 弹 1 次 | 弹 1 次（无法消除） |
| 误杀风险 | **全局 killall 所有 ll-cli** | **无**（精确 PID） |
| daemon 命运 | **被强杀后 systemd 重启** | **协作取消，daemon 存活** |
| 取消语义 | SIGTERM 但作用范围过广 | SIGTERM，精确到任务进程 |
| daemon 状态 | 被 kill 后状态可能脏 | `canceled by user`，状态干净 |

### 4.5 取消竞态窗口

- **现象**：Firefox 实测中，SIGTERM 在 93.78% 发出时，daemon 在 `Cancel()` 送达前已下完（`PackageTask::Cancel()` 的 `isTaskDone()` 检查直接 return，`package_task.cpp:75`），后台 success。
- **定性**：这是**任何取消机制（含 Ctrl+C）都存在的固有边界**，非方案缺陷。但 UI/状态机需正确处理"取消发出但任务已接近完成"的竞态（避免取消按钮点了却显示成功）。

## 五、推荐落地路径

1. ~~先验证疑点一~~（**已完成**：GUI 实测确认 ll-cli 属主 root，见第三节）。
2. 按 4.3 实现 `pkexec kill -15 <PID>` 精确取消 + SIGKILL 兜底。
3. 补单元测试：模拟 PID 存在/缺失、kill -15 成功/超时、兜底 SIGKILL 触发等分支。
4. ~~真机回归：在商店里实测取消一个正在下载的大应用~~（**已完成**：见附录 A.2，daemon `canceled by user`、daemon 未被杀、任务未装完）。
5. 可选优化（单独议题）：评估是否新增 polkit 免密规则让 `pkexec kill` 免授权，进一步改善体验（需权衡安全）。
6. 完成后更新本文档"状态"为已实现，并同步关键约定到 `AGENTS.md` 变更记录。

## 附录 A：已完成验证的记录

### A.1 GUI 会话 ll-cli 进程属主（2026-06-30 20:42，已完成）

在真实玲珑商店 GUI 触发安装 `uos-youku-app.linyaps`，结果：
```
PID 9307  USER=root  pkexec ll-cli install --json uos-youku-app.linyaps
```
**结论：ll-cli 走 pkexec，属主 root。免授权 SIGTERM 方案不成立，改为 pkexec kill -15 PID 精确取消。**

### A.2 GUI 实测：精确 PID + SIGTERM 协作取消（2026-06-30 20:59-21:01，铁证）

在真实玲珑商店 GUI 点击安装 `com.popcap.plantsvszombies.deepin`（植物大战僵尸），用记录的 PID 发 SIGTERM，完整验证了精确 PID 取消方案：

**进程关系（证明 PID 精确绑定到单次任务）：**
```
PID 11118  PPID 7860  USER=root  comm=pkexec
  args=pkexec ll-cli install --json com.popcap.plantsvszombies.deepin
PPID 7860 = /opt/linglong-store/linglong_store   ← 商店主进程
```
root ll-cli 进程的 PPID 正是商店主进程，证明商店 `Process.start('ll-cli')` 记录的 PID（经 `execvp pkexec → execv ll-cli`，PID 连续）精确绑定到这一次安装任务，不会误杀别的 ll 操作。

**SIGTERM 协作取消（daemon journal）：**
```
20:59:56  task 221142171507064771214819416116623516023293 has been canceled by user
20:59:59  action Install unknown:com.popcap.plantsvszombies.deepin/unknown/unknown failed:
          ostree_repo_pull_with_options [code 19]: 操作被取消
```

**三重验证全部通过：**
1. **PID 精确性**：root 进程 PPID 指向商店，PID 精确到任务 ✓
2. **SIGTERM 协作取消**：daemon 打印 `canceled by user` + `操作被取消`（`cancelCurrentTask → D-Bus Cancel → g_cancellable_cancel` 链路），daemon 未被强杀 ✓
3. **真实结果**：植物大战僵尸**未被安装**（任务失败：操作被取消），无后台偷装完 ✓

**结论：`pkexec kill -15 <精确PID>` 方案在真实 GUI 场景完全成立，可以进入编码。**

### A.3 编码后真机回归：autoDispose 根因与修复（2026-06-30 21:30）

编码后首次真机回归发现 BUG：取消安装时取不到 PID（`_activeProcessPids={}`），pkexec 弹窗不出现。

**根因定位（诊断日志铁证）**：
- `linglongCliRepositoryProvider` 是 `@riverpod`（非 keepAlive，`isAutoDispose: true`）
- 安装时 `ref.read` 拿到实例 A，PID 写入实例 A 的 `_activeProcessPids`
- 但 `await for` 循环持有的是 stream 引用，不维持 provider 的 listener 关系
- **autoDispose 在没有活跃 listener 时销毁 provider → 实例 A 销毁 → `_activeProcessPids` 随之消失**
- 取消时 `ref.read` 重新 build → 创建实例 B（空 map）→ PID 缺失 → 取消失败

日志铁证：`记录安装进程 PID: 16102` 成功，但取消时 `_activeProcessPids={}`，且全程无 finally 日志（实例是被整体销毁，不是被 remove）。

**修复（commit d759710）**：进程状态归 `CliExecutor` 静态管理，与 provider 生命周期解耦。
1. 新增 `CliExecutor.getProcessPid(processId)` 静态方法，从 `_activeProcesses[processId]?.pid` 读取
2. **关键**：`_activeProcesses` 的清理从 stream-finally 移到 `process.exitCode` 回调——进程引用生命周期绑定到「进程真实退出」，而非「stream subscription 被 cancel」。即使 autoDispose 级联 cancel stream，只要 root ll-cli 进程还在跑，PID 始终可查
3. `cancelOperation` 改用 `CliExecutor.getProcessPid`，不再依赖 repository 实例字段

**修复后真机回归（com.qq.music）**：
```
开始安装: ll-cli install --json com.qq.music
开始取消安装: com.qq.music
开始精确 PID 取消: install_com.qq.music (pid=18954)    ← PID 成功取到
精确 PID 取消完成: (结果: true)                         ← pkexec kill -15 成功
取消安装成功: com.qq.music
命令退出: exitCode=255                                  ← ll-cli 被 SIGTERM 终止
```

**经验教训**：跨方法、跨调用需要持续存在的进程状态，不能放在 autoDispose 的 provider 实例字段里。进程状态应集中到 `CliExecutor` 静态管理，且其清理时机必须绑定进程真实退出（`exitCode`），而非 stream 生命周期。

## 附录 C：经验教训（踩坑全过程复盘）

本方案从研究到落地经历了多次"假设被实测推翻"，每一步都验证了"先验证再下结论"的纪律。以下复盘供后续维护者参考，避免重蹈。

### C.1 不要相信未经验证的"项目已有能力"

- **踩坑**：初版方案误称"项目有 `lib/rust/` Rust FFI，可用 zbus 实现 D-Bus Cancel"。实际项目里**根本不存在** `lib/rust`，无任何 `.rs` 文件。
- **教训**：涉及"复用现有能力"的判断，必须先 `find`/`ls` 实际确认，不能凭印象。`lib/rust` 这个错误直接导致"D-Bus Cancel"方案被高估可行性。

### C.2 信号机制要从源码读，不能靠语义猜测

- **踩坑**：起初以为 Ctrl+C = "杀进程"，后来想当然认为"GUI 会话 ll-cli 是当前用户进程，SIGTERM 可免授权"。
- **源码真相**：
  - Ctrl+C（SIGINT）本质是 ll-cli 的 signal handler 调 `QCoreApplication::quit()` → `aboutToQuit` → `cancelCurrentTask()` → **D-Bus Cancel**，daemon 协作中断下载，**不是杀进程**。
  - `initialize.cpp:122` 的 `catchUnixSignals({SIGTERM, SIGQUIT, SIGINT, SIGHUP})` 证明 **SIGTERM 与 SIGINT 共用同一个 handler**，所以 SIGTERM 等价于 Ctrl+C。
  - GUI 实测推翻"免授权"假设：ll-cli `ensureAuthorized()` 失败后 `execvp("pkexec")` 替换自身，**属主变 root**。
- **教训**：信号行为必须从目标程序的源码 signal handler 读起，不能凭信号名猜语义；进程属主、是否提权必须在**真实运行环境实测**，不能从 polkit 规则推导（规则与实际行为之间有条件分支）。

### C.3 SIGTERM vs SIGKILL 必须用对照实测区分

- **铁证**（dingtalk 453MB 首次下载对照）：
  - SIGTERM → daemon 日志 `canceled by user`，下载停止，未安装。
  - SIGKILL → daemon **后台继续下载 129 秒（453MB），偷偷装完了**。
- **教训**：取消类逻辑的正确性不能用"进程退出了"来判断——SIGKILL 也会让 ll-cli 退出，但 daemon 照样在后台把任务做完。必须对照 daemon journal 的 `canceled`/`success` 才能判定取消是否真正生效。

### C.4 autoDispose provider 不能承载跨调用持续状态

这是本次最深的坑，也是最容易复现的架构陷阱：

- **现象**：编码后真机回归，取消安装时取不到 PID（`_activeProcessPids={}`），pkexec 弹窗不出现。
- **根因**：`linglongCliRepositoryProvider` 是 `@riverpod`（`isAutoDispose: true`）。安装时 `ref.read` 拿实例 A 写入 PID，但 `await for` 循环持有的是 stream 引用、不维持 provider listener；autoDispose 在无活跃 listener 时销毁实例 A，`_activeProcessPids` 随之消失；取消时 `ref.read` 重建实例 B（空 map）。
- **诊断方法**：在 cancelOperation 打印 `_activeProcessPids` 完整内容、在 finally 打印移除时机、在 await-for 打印退出时机。日志显示"PID 写入成功 + 取消时 map 全空 + 全程无 finally 日志"，三证据交叉锁定"实例被整体销毁"而非"被 remove"。
- **修复**：进程状态归 `CliExecutor` 静态字段，清理绑定 `process.exitCode`（进程真实退出）而非 stream finally（autoDispose 级联 cancel stream 时会提前清理）。
- **教训**：
  1. 跨方法、跨调用需要持续存在的状态（进程 PID、句柄等），**禁止**放在 autoDispose provider 的实例字段里。
  2. 资源清理时机必须与资源的**真实生命周期**对齐，不能绑定在中间层（stream subscription）的生命周期上——中间层会被上层（provider 销毁）级联影响。
  3. 多组件时序 bug 必须用诊断日志在**每个边界**取证，不能靠静态阅读代码猜——本例静态分析穷尽了所有 `_activeProcessPids.remove` 调用点都找不到原因，直到日志证明是"实例销毁"而非"字段移除"。

### C.5 授权框无法消除，要诚实标注

- `pkexec.exec` 默认 `allow_active=auth_admin`，每次 `pkexec kill` 都弹一次授权框。
- 无 polkit 免密规则（已检查 `/usr/share/polkit-1/rules.d/` 和 `/etc/polkit-1/rules.d/`）。
- 本方案保留授权框（用户确认可接受）。若要消除需新增 polkit 免密规则，属系统级改动，应单独评估安全性。

## 附录 B：证据索引

- linyaps 源码：`/home/han/code/linyaps`
  - signal handler：`libs/linglong/src/linglong/common/global/initialize.cpp:29-50, 120-123`
  - aboutToQuit 连接：`apps/ll-cli/src/main.cpp:783-790`
  - cancelCurrentTask：`libs/linglong/src/linglong/cli/cli.cpp:1112-1118`
  - daemon Cancel：`libs/linglong/src/linglong/package_manager/package_task.cpp:73-88`
  - ostree pull 传 cancellable：`libs/linglong/src/linglong/repo/ostree_repo.cpp:1438-1470`
  - install 流程与授权：`libs/linglong/src/linglong/cli/cli.cpp:1191-1261, 2161-2222`
  - polkit policy：`/usr/share/polkit-1/actions/org.deepin.linglong.PackageManager1.policy`
- 商店源码：`/home/han/code/linglong-store/flutter-linglong-store`
  - CLI 执行器：`lib/core/platform/cli_executor.dart:105, 250-350, 379-403, 419-475`
  - 取消调用：`lib/data/repositories/linglong_cli_repository_impl.dart:35-40, 66, 678-706`
  - 队列状态机：`lib/application/providers/install_queue_provider.dart:785-854`
- 实测记录：见本文档第二节（dingtalk SIGTERM vs SIGKILL 对照，2026-06-30）。
