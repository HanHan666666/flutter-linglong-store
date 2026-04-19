# CLI 命令日志规范

## 背景

Flutter 商店对 `ll-cli` 的调用已经统一收敛到 `CliExecutor`。此前失败日志只稳定打印 `exitCode`，业务层又普遍优先读取 `stderr`，导致出现“命令是什么不清楚、CLI 实际输出丢失、卸载失败文案为空”的排障断层。

## 目标

- 所有经过 `CliExecutor` 的命令都必须打印完整命令行。
- `stdout` 与 `stderr` 都必须按行实时写入日志。
- 不再额外打印执行结束摘要，只保留过程日志与退出码日志。
- 业务侧读取 CLI 失败文案时，必须优先 `stderr`，为空时回退到 `stdout`。

## 统一约定

### 1. 命令启动日志

`CliExecutor` 在命令启动时统一输出：

- 普通执行：`[CLI] 启动命令: ll-cli ...`
- 流式执行：`[CLI] 启动命令(流式): ll-cli ...`

这条日志必须包含完整参数，禁止只打印操作名或只打印 `exitCode`。

### 2. 输出流日志

`CliExecutor` 必须对两个输出流逐行记录：

- `stdout`：`[CLI stdout] ll-cli ... | <line>`
- `stderr`：`[CLI stderr] ll-cli ... | <line>`

流式命令追加 `(流式)` 标记以区分安装/更新这类长任务。

### 3. 退出日志

命令退出时统一输出：

- 成功：`info`
- 非零退出：`warning`

日志内容必须同时包含完整命令与 `exitCode`，例如：

`[CLI] 命令退出: ll-cli uninstall xxx (exitCode=255)`

### 4. 失败文案回退规则

`CliOutput` 统一提供失败文案解析规则：

1. 优先使用 `stderr.trim()`
2. 若为空，则回退到 `stdout.trim()`
3. 两者都为空时，调用方再补业务兜底文案

适用场景：

- `executeOrThrow()`
- 卸载、停止应用、创建桌面快捷方式、清理废弃服务等直接消费 `CliOutput` 的业务逻辑

## 实施说明

- `CliExecutor.executeWithProcess()` 与 `executeWithProgressAndProcess()` 共用同一套日志格式。
- 卸载链路已按该规则修复，`stderr` 为空时不再丢失 `stdout` 中的实际错误内容。
- 后续若新增 CLI 调用入口，必须复用 `CliExecutor`，不要在业务层重新手写一套日志采集。
