# 54 - 安装队列与 helper 传输终态一致性设计

> 状态：**已确认，待实施**
>
> 日期：2026-09-27
>
> 关联文档：docs/23（取消链路）、docs/47（特权 helper）、docs/50（免密路径）、
> docs/51（helper 信任边界）

---

## 1. 背景

安装与更新队列在 Presentation/Application 层承诺严格串行，特权 helper 也只允许
同时运行一个 `/usr/bin/ll-cli` 子进程。正常情况下，Application 不应触发 helper
的 `busy` 防线。

2026-09-27 在 Omarchy 真机连续执行两个更新任务时，第一项显示成功后第二项立即失败。
本机保留日志中已有同一故障证据：

```text
22:08:01.422  Task completed successfully: cn.com.10jqka
22:08:01.645  Processing task ... for app: org.localsend
22:08:01.865  Task failed: org.localsend,
              kind=helperUnavailable,
              diagnostic=客户端已有活动任务
```

该问题不是发行版授权代理、LinYAPS daemon 或用户队列真的并发，而是商店内部把
ll-cli 输出中的业务成功消息误当成了子进程生命周期终点。

## 2. 根因

当前链路存在两个不同的“终态”，但实现把它们合并处理：

1. **业务终态**：`CliOutputParser` 从输出行识别到 success/failed；
2. **传输终态**：直连 ll-cli 进程真实退出，或 helper 发出 `exited`（已经
   `waitpid` 回收子进程）。

现有 Repository 在读到 success/failed 输出行时立即向上游发布终态。队列收到后：

1. 立即把任务移入历史记录；
2. `dispose` 当前 `AppOperationTaskExecutor`；
3. 100ms 后调度下一任务。

虽然 Repository 内部原本尝试在发布终态后继续消费 helper 流直至 `exited`，但
执行器在终态回调中被队列同步释放，随后会中断 `await for`，因此这段等待实际上被
上层取消。若 ll-cli 从输出成功到进程退出超过下一任务调度窗口，客户端仍保留上一
任务的 `_activeRequestId`，第二个 `startTask` 就会抛出
`PrivilegedHelperBusyException`。

取消链路存在同构问题：`cancelAccepted` 只表示 SIGTERM 已发送，现有队列却立即清除
当前任务并调度下一项，没有等待 `exited(cancelRequested=true)`。

另有一个错误分类问题：Repository 当前把所有 `PrivilegedHelperException` 都归为
`helperUnavailable`。因此内部 busy 竞态会被误报成授权组件不可用，并错误触发授权
门闩，进一步暂停剩余任务。

## 3. 设计目标

1. success/failed/cancelled 只有在传输生命周期结束后才能发布给安装队列；
2. helper 路径以 `PrivilegedHelperTaskExited` 为传输终态；
3. 普通直连路径以 ll-cli 进程真实退出并关闭进度流为传输终态；
4. 取消已接受后保持当前任务占位，直到原任务流结束；
5. 明确成功优先于临界时刻到达的取消请求，避免已落地任务被误记为取消；
6. helper busy 视为内部执行时序错误，不得触发授权门闩；
7. 不增加固定等待时间、轮询或自动重试，不改变 helper 白名单与授权边界。

## 4. 方案比较

### 4.1 方案 A：延长下一任务固定延迟

把 100ms 改为 1 秒或更长可以降低复现概率，但不同机器、包体和 ll-cli 版本的退出
清理耗时没有固定上界。该方案仍然允许并发窗口，且会无条件拖慢正常队列，拒绝采用。

### 4.2 方案 B：客户端遇到 busy 时等待或自动重试

客户端可以等待 `_activeRequestId` 清空后再发送第二个 start，但这会掩盖 Application
违反串行契约的问题；取消、持久化终态和 UI 历史记录仍会提前。自动重试还会让副作用
边界变得不确定，拒绝作为主修复。

### 4.3 方案 C：以 Repository 流结束建立生命周期屏障（采用）

Repository 是唯一同时理解 CLI 输出和传输生命周期的层，因此由它缓存解析出的业务
终态，继续消费底层传输，待 `exited`/进程退出后再发布 success/failed/cancelled。
Application 继续只消费一个 `InstallProgress` 流，不新增平台细节或第二份全局状态。

该方案同时适用于 helper、免密直连和不可信 helper 的直连回退，不依赖发行版与机器
速度，符合现有分层和单一事实来源约束。

## 5. 详细行为

### 5.1 正常成功或失败

```text
ll-cli output(success/failed)
  → Repository 缓存 pendingTerminal，不向队列发布
  → 继续消费底层流
  → helper exited / direct process exit
  → Repository 发布缓存终态
  → Queue 提交历史记录并调度下一项
```

终态输出后的其他行仍由底层传输完整消费，但不再改变第一次明确的业务终态，避免尾部
日志覆盖成功/失败事实。

### 5.2 无明确业务终态

底层流结束但没有 success/failed 时，继续使用现有安装前后版本快照复验：

- 目标已落地：success；
- 目标未落地：`resultUnconfirmed`。

这次修复不改变既有结果复验规则。

### 5.3 用户取消

取消入口只做两件事：

1. 按任务启动时绑定的传输发送 SIGTERM/cancel request；
2. 记录“用户取消已被底层接受”，保持当前任务和执行器占位。

Repository 在底层流结束后决定最终状态：

- 已收到明确 success，或本机复验证明目标已落地：success；
- 取消已接受且目标未落地：cancelled；
- 未取消且无明确终态、目标也未落地：沿用现有失败规则。

队列只有在收到 Repository 的 cancelled 后才移入历史并调度下一项。这样
`cancelAccepted` 不再被错误当作 `exited`。

### 5.4 helper busy 分类

`PrivilegedHelperBusyException` 单独映射为 `AppOperationFailureKind.execution`：

- 保留原始诊断，便于定位串行契约回归；
- 不归类为 `helperUnavailable`；
- 不触发授权门闩；
- 不自动重试，避免无法证明前一任务状态时重复副作用。

## 6. 改动范围

### Data

- `LinglongCliRepositoryImpl._runInstallLikeOperation`
  - 缓存第一条明确 success/failed；
  - 等底层流结束后发布终态；
  - 取消在传输结束后结合结果复验输出 cancelled/success；
  - busy 单独映射为 execution。

### Application

- `InstallQueue.cancelTask`
  - 取消接受后不再释放执行器、清空 `currentTask` 或调度下一项；
  - 等原执行流发布最终 cancelled/success/failed。

### Core / helper

- 不修改 helper 协议、C++ 子进程管理、白名单、授权方式或信任判定；
- `exited` 继续表示唯一可信的 helper 子进程传输终态。

## 7. 测试设计

新增使用可控 `PrivilegedHelperTransport` 的跨层单元测试：

1. **成功与退出存在间隔**
   - 第一任务输出 `Install success`；
   - 暂不发送 `PrivilegedHelperTaskExited`；
   - 经过原调度窗口后断言第二任务没有启动、第一任务仍占位；
   - 发送 exited 后断言第二任务才启动。

2. **取消接受与退出存在间隔**
   - 第一任务运行时入队第二任务；
   - fake helper 接受 cancel，但暂不发送 exited；
   - 断言第一任务仍占位、第二任务没有启动；
   - 发送 `exited(cancelRequested=true)` 后断言第一任务进入 cancelled 历史，第二任务
     才启动。

3. **busy 分类**
   - helper 主动抛出 `PrivilegedHelperBusyException`；
   - 断言失败类型为 execution，授权门闩不暂停。

保留并运行现有 Repository、队列取消、授权门闩、helper client 与 C++ helper 测试。

## 8. 验收标准

- 连续安装/更新两个应用只产生一次 helper 授权；
- 第二任务的 start 严格晚于第一任务 exited；
- 取消第一任务后，第二任务严格晚于第一任务 exited；
- 日志中不再出现由正常队列触发的“客户端已有活动任务”；
- busy 不再显示为授权组件不可用，也不暂停授权门闩；
- `flutter analyze` 无 error/warning，相关测试与全量测试通过。

