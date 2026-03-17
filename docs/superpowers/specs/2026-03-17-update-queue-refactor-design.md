# 一键更新队列重构设计

## 背景

Flutter 商店当前的一键更新链路存在三个核心问题：

1. 更新页直接循环调用安装队列，批量更新没有统一入口，导致单次点击产生多次状态写入与多次调度。
2. 安装队列内部只有“安装”语义，更新行为只是“带版本号的安装”，业务含义不清晰。
3. 安装成功后的 installed apps / updates 同步虽然已经集中处理，但实现仍依赖 Widget build 期监听，时序脆弱。

本次重构目标是在保持用户可见行为与 Rust 旧版一致的前提下，显式引入 `install` / `update` 任务类型，收敛批量更新入口，稳定 UI 状态流。

## Rust 旧版对照

Rust 商店的一键更新链路为：

1. 更新页筛选未在队列中的可更新应用。
2. 使用 `enqueueBatch` 批量入队。
3. 队列内部仍创建统一 install task。
4. 后端调用 `install_app(appId, version, force)`。
5. 全局进度监听成功后调用 `syncAfterAppChange()`，统一刷新 installed apps 和 updates。

旧版没有显式 `update` 任务类型，也没有独立的 update IPC。本次重构属于在保持外部行为不变的前提下，优化 Flutter 内部架构。

## 设计目标

1. 一键更新必须通过统一批量入口入队，避免页面自行循环操作队列。
2. 队列任务显式区分 `InstallTaskKind.install` 与 `InstallTaskKind.update`。
3. 队列处理、取消、成功文案与收尾同步都要感知任务类型。
4. 页面和卡片不再直接拼装队列写入逻辑，只负责声明业务动作。
5. 安装成功后的刷新链路继续集中，不允许页面在各自的交互代码里手动 refresh。

## 非目标

1. 不改动用户可见的串行执行规则。
2. 不引入并行下载或多任务并发。
3. 不改动 ll-cli 的外部调用契约，只在 Flutter 端区分 install/update 两类任务。

## 架构方案

### 1. 任务模型

在 `InstallTask` 中新增 `InstallTaskKind`：

- `install`
- `update`=

任务模型继续由安装队列统一管理，但状态文案与操作路由根据 `kind` 派生。

### 2. 统一入口

新增 application 层的 operation dispatcher，提供两个入口：

- `enqueueAppOperation()`
- `enqueueBatchOperations()`

Presentation 层只声明“我要安装”或“我要更新”，不再直接调用安装队列底层方法。

### 3. 队列执行

安装队列保留统一状态机，但处理单个任务时根据 `kind` 选择：

- `install` -> `LinglongCliRepository.installApp()`
- `update` -> `LinglongCliRepository.updateApp()`

取消逻辑同样按任务类型路由，避免 update 任务继续复用 install 专用取消标识。

### 4. 成功后的统一同步

收尾同步仍然保留“集中式”设计，但从 Widget build 期监听中抽离，封装为 application 层同步服务：

- 刷新 installed apps
- 重新检查 updates

Widget 只负责注册监听，不直接写分散的 refresh 业务。

### 5. UI 层调整

更新页需要同步收敛以下行为：

1. “全部更新”使用批量 operation 入口。
2. 按钮在队列活跃时 disabled，并显示“正在更新...”。
3. 更新列表项补稳定 key，避免批量状态切换时 element 复用污染语义树。

## 数据流

1. 用户点击更新页“全部更新”。
2. 更新页把可更新应用映射为 `update` 类型 operation。
3. dispatcher 调用安装队列批量入队。
4. 队列串行消费任务。
5. 队列根据 `kind` 路由到 `installApp()` 或 `updateApp()`。
6. 任务成功后，集中同步服务刷新 installed apps 与 updates。
7. 更新页基于新的 provider 状态自动收敛 UI。

## 错误处理

1. 批量入口需要先过滤已在队列中的应用，避免重复入队。
2. 队列失败不能阻塞后续任务，继续保持失败隔离。
3. update 任务取消后，UI 文案必须显示“更新已取消”，不能复用“安装已取消”。
4. build 期副作用需要移除，避免在大批量 provider 变化时造成渲染时序问题。

## 测试计划

1. 单元测试：验证队列会根据 task kind 调用正确的 repository 方法。
2. 单元测试：验证批量 operation 入口会生成 update 类型任务。
3. Widget/行为测试：验证更新页“全部更新”按钮在活跃任务期间被禁用。
4. 静态分析：`flutter analyze` 必须为 0 error / 0 warning。

## 风险与取舍

### 风险

1. `InstallTask` 增加字段后需要同步更新生成代码和持久化兼容。
2. 取消逻辑从 install-only 变为 operation-aware，需要确保 update 流也能被正确终止。
3. 部分旧调用可能仍直接依赖 `enqueueInstall()`，需要保留兼容包装或统一迁移。

### 取舍

本次不直接把 IPC 层改造成独立 update 命令，而是在 repository 层通过现有 `updateApp()` 流封装更新语义。这样能显著提升 Flutter 侧可维护性，同时把风险控制在当前仓库内。
