# 应用操作队列职责拆分设计

## 1. 文档定位

本文细化 `docs/27-architecture-remediation-roadmap.md` 的第三阶段，目标是在不改变
安装、更新、取消、恢复和一键更新通知语义的前提下，拆分
`lib/application/providers/install_queue_provider.dart`。

本阶段是结构重构，不改变用户界面、不修改 `ll-cli` 命令、不升级 Journal schema，
也不调整结构化错误格式。错误国际化边界将在下一阶段单独处理，避免两类变化互相
掩盖。

## 2. 当前问题

`InstallQueue` 当前约 1385 行，同时承担六类独立职责：

1. 从 XDG Journal 恢复状态，并迁移旧 SharedPreferences 队列；
2. 管理 Riverpod 状态发布和 latest-wins 持久化屏障；
3. 创建任务、批次和任务 ID；
4. 执行单个 `ll-cli` 流，维护超时状态机和取消标志；
5. 把进度、终态、批次和 Outbox 事件归并为完整状态；
6. 根据本机安装实例判断崩溃恢复结果。

这些职责的变化原因不同，却共享大量可变字段和私有方法。修改恢复规则时必须进入
执行器大类，修改批次通知时也可能碰到取消和重试逻辑；测试只能通过构造完整
Riverpod 容器验证本来可以是纯函数的规则。

## 3. 不变协议

拆分后必须保持以下协议：

- 同时只允许一个任务进入 `ll-cli`；
- 当前任务进入 `installing` 且成功落盘后，才允许启动命令；
- 任务唯一身份仍是 `taskId`，`appId` 兼容入口只能影响第一条匹配任务；
- 更新命令不携带版本号；
- 一键更新批次只按自己的 `taskIds` 判断完成；
- 成功任务、批次完成和 Outbox 必须在同一个 Journal 快照中提交；
- 恢复更新任务必须唯一匹配 arch/channel/module/repoName，并精确命中
  `expectedVersion`；
- 无法证明成功的恢复任务必须进入 `interrupted`，禁止乐观标记成功；
- Journal schema、XDG 路径和 latest-wins 保存语义不变；
- `InstallQueue` 的现有公开方法和 Riverpod Provider 名称保持兼容。

## 4. 方案比较

### 4.1 只拆成多个 Dart `part`

该方案可以缩短单文件，但所有代码仍能直接访问 Notifier 的可变字段，职责和依赖
没有真正隔离，只是把大文件切成多个片段。

### 4.2 把所有逻辑放进一个新的 QueueService

这会把 God Object 从 Provider 移到 Service，文件名变化但维护问题仍然存在。
Notifier 与 Service 之间还会出现双份可变状态，增加同步风险。

### 4.3 按变化原因提取小型 Application 服务

把无状态规则提成纯服务，把有生命周期的 `ll-cli` 执行提成单任务执行器，把
Riverpod Notifier 保留为唯一状态所有者和用例编排入口。每个服务只接受完成职责
所需的最小依赖。

**选择方案 4.3。** 它保留单一状态源，同时让恢复、批次、持久化和执行边界可以
独立推理，不引入第二套队列框架。

## 5. 目标组件

### 5.1 `AppOperationStateStore`

职责：

- 从 `AppOperationJournalRepository` 同步读取完整快照；
- Journal 不存在时读取旧 SharedPreferences 的 current/queue；
- 首次迁移成功落盘后删除旧 key；
- 保存完整 `InstallQueueState` 快照。

它不持有 Riverpod `Ref`，不发布 UI 状态，也不决定何时越过持久化屏障。正式依赖
仍由组合根 Provider 提供，Notifier 只负责创建这个 Application 服务。

### 5.2 `AppOperationTaskExecutor`

职责：

- 根据任务类型选择 `installApp` 或 `updateApp`；
- 消费单个任务的 `InstallProgress` 流；
- 维护该任务的 `InstallStateMachine` 和超时检查；
- 把进度、超时、流异常和“无终态结束”报告给编排方；
- 通过 Repository 的精确取消入口取消当前任务；
- 释放计时器和状态机资源。

执行器不读取或写入 `InstallQueueState`，也不生成用户文案。回调携带 `taskId`，
Notifier 在提交前再次核对当前任务，旧流和取消竞态不能覆盖新任务。

同一时间只创建一个活动执行器；任务结束、取消或 Provider 销毁时必须 dispose。

### 5.3 `AppOperationQueueReducer`

职责：

- 把等待任务提升为当前任务；
- 更新当前任务进度；
- 提交任务终态并维护有界历史；
- 移除等待任务、历史任务和清空队列；
- 在任务终态时调用批次推导器。

Reducer 是无状态纯函数，不读取 locale、Repository、时间或 Riverpod。当前时间、
已格式化的任务和最大历史条数均由调用方显式传入。

### 5.4 `AppOperationBatchReducer`

职责：

- 在成功任务终态中幂等创建 `taskSucceeded` 事件；
- 只根据目标批次的 `taskIds` 推导批次完成；
- 幂等创建 `updateBatchCompleted` 事件；
- 记录 Outbox attempt；
- 原子确认 Outbox，并同步写入批次通知状态。

这组规则必须保持纯函数，便于直接审阅“任务事实 → 批次事实 → 副作用事件”的关系。

### 5.5 `AppOperationRecoveryService`

职责：

- 按 `appId + arch + channel + module + repoName` 精确匹配安装实例；
- 区分安装任务和更新任务的成功证明；
- 返回结构化恢复结论及匹配实例。

它不生成“任务被中断”等本地化文案；Notifier 根据结论和当前 locale 构造最终
任务，下一阶段再把旧的展示字段迁移为结构化错误。

### 5.6 `InstallQueue`

拆分后只保留：

- Riverpod 生命周期和状态发布；
- 公开用例入口；
- ID、当前 locale 和发行版上下文；
- 调用 Store、Executor、Reducer 和 RecoveryService；
- 在关键边界等待 `AppOperationPersistenceBarrier`；
- 调度下一条任务。

## 6. 依赖与数据流

```text
Presentation / LifecycleCoordinator
                 │
                 ▼
          InstallQueue Notifier
          │       │         │
          │       │         └── AppOperationRecoveryService
          │       └──────────── AppOperationQueueReducer
          │                          └── AppOperationBatchReducer
          ├── AppOperationStateStore ── AppOperationJournalRepository
          └── AppOperationTaskExecutor ─ LinglongCliRepository
```

唯一可变的业务状态仍位于 `InstallQueue.state`。Store 只负责持久化副本，Executor
只负责当前外部进程，Reducer 和 RecoveryService 均不持有状态。

## 7. 执行时序

1. 入队命令通过 Notifier 创建任务，并由 Reducer 追加到 queue；
2. Notifier 发布状态并排队保存完整 Journal；
3. 调度器等待 latest persistence barrier；
4. Reducer 把队首提升为 currentTask；
5. Notifier 再次等待 currentTask 快照落盘；
6. 创建单任务 Executor，开始消费 `ll-cli` 流；
7. 每条进度由 Executor 回调 Notifier，Reducer 更新当前任务；
8. 终态由 Reducer 一次性写入历史、批次和 Outbox；
9. 终态保存进入屏障后，Notifier 才调度下一任务；
10. LifecycleCoordinator 继续按既有 durable Outbox 协议消费副作用。

## 8. 竞态与失败边界

### 8.1 取消与终态同时到达

取消请求返回前，进度流可能已经提交终态。Notifier 必须用 `taskId` 再次核对：

- 当前任务仍相同：提交取消终态；
- 当前任务已经清空或替换：视为流已完成处理，不重复提交。

### 8.2 旧执行流延迟回调

Executor 的所有事件携带启动时的 `taskId`。Notifier 只接受与当前任务 ID 相同的
事件，避免上一任务的延迟输出污染下一任务。

### 8.3 currentTask 持久化失败

命令不得启动；Notifier 只在当前任务仍是刚提升的任务时恢复到提升前的内存状态，
不得覆盖等待期间的新状态。

### 8.4 Provider 释放

Notifier 通过 `ref.onDispose` 释放活动 Executor 和调度 Timer。任何延迟调度在
访问状态前检查 `ref.mounted`。

### 8.5 Journal 迁移失败

保留旧 SharedPreferences key，并把失败纳入同一个 persistence barrier；下一次
启动仍可重试迁移。

## 9. 验证范围

本阶段不为了拆文件制造大量单元测试。验证聚焦已有高风险行为：

- 单任务严格串行及 currentTask 先落盘再启动；
- `ll-cli` success/failed/cancelled/无终态流；
- 精确 PID 取消失败时保持当前任务；
- 恢复更新的实例与版本核验；
- 批次完成和 Outbox 幂等；
- Journal 迁移及 latest persistence barrier；
- 全量 `flutter analyze`、现有相关测试和 Linux debug 构建。

如果纯 Reducer 在迁移过程中暴露现有测试未覆盖的幂等边界，只补该真实风险的最小
测试，不为文件拆分本身增加样板测试。

## 10. 提交边界

本阶段代码、必要测试调整和项目约定作为一个可回滚功能点提交：

```text
refactor: 拆分应用操作队列职责
```

设计文档先单独提交，确保实现过程始终有稳定边界可对照。
