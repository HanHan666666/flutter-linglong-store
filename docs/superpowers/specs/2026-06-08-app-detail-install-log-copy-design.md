# 详情页复制安装日志设计

**日期:** 2026-06-08
**状态:** 已确认
**范围:** 应用详情页头部安装状态条的复制入口

## 背景

应用详情页头部状态条当前在安装完成、安装中或失败时展示状态文案，并提供“复制”或“复制错误信息”入口。该入口复制的是状态展示文案、失败详情或原始 message。用户期望这里不再复制状态文案，而是复制与下载管理一致的安装日志。

下载管理已经建立日志复制契约：每个下载管理 item 使用 `InstallTask.id` 作为唯一身份，复制按钮只复制该任务自己的 `InstallTask.commandOutput`。`commandOutput` 在安装队列消费 `InstallProgress.outputLine` 时累计，随当前任务和历史记录生命周期保存。

## 目标

- 详情页状态条的复制入口改为“复制日志”。
- 复制内容必须来自下载管理同一任务记录的 `InstallTask.commandOutput`。
- 当匹配任务没有 `commandOutput` 时，详情页隐藏复制入口。
- 状态条展示文案保持不变，继续用于提示当前安装、更新、完成或失败状态。
- 不新增 `ll-cli` 调用，不新增独立日志来源，不从 UI 文案反推日志。

## 非目标

- 不改变安装队列、下载管理、取消、重试、删除和打开应用流程。
- 不新增日志预览、日志导出、批量复制或从磁盘读取日志文件能力。
- 不改变下载管理弹窗中“复制日志”的行为和反馈方式。
- 不重构 `InstallQueueState.getAppInstallStatus()` 的现有匹配顺序。

## 方案

采用页面层解析、头部组件参数化的方案。

`AppDetailPage` 已经读取 `installQueueProvider` 并通过 `getAppInstallStatus(appId)` 得到当前详情页匹配的安装任务。页面层负责从该 `InstallTask` 读取 `commandOutput.trim()`，只有非空时把日志文本传给 `AppDetailHeroHeader`。

`AppDetailHeroHeader` 只负责视觉渲染，不订阅全局 Provider。头部组件新增一个可空的日志复制参数，状态条继续接收 `statusMessage` 控制展示文案。复制按钮的显示条件从“存在状态文案”改为“存在状态文案且日志非空”。按钮文案、语义标签和 Tooltip 统一使用 `l10n.copyLog`。

点击按钮时调用 `Clipboard.setData(ClipboardData(text: logText))`。复制成功不新增全局通知，保持当前详情页状态条的轻量交互模型。

## 数据流

1. 安装或更新任务通过 `InstallQueue` 串行执行。
2. 队列层在 `_handleProgress()` 中把 `InstallProgress.outputLine` 追加进当前任务的 `commandOutput`。
3. 当前任务完成、失败或取消后进入 `InstallQueueState.history`，`commandOutput` 随历史 item 保存。
4. 详情页通过 `getAppInstallStatus(appId)` 匹配当前任务、等待队列或历史记录。
5. 详情页把匹配任务的 `commandOutput.trim()` 传给头部状态条复制入口。

## 边界规则

- `commandOutput.trim().isEmpty`：隐藏复制按钮，不回退复制 `statusMessage`、`rawMessage`、`errorDetail` 或 `errorMessage`。
- 匹配任务不存在：不展示状态条；若状态条因其他逻辑展示，也不展示日志复制入口。
- 同一 appId 存在多条历史记录：沿用当前 `getAppInstallStatus()` 的匹配顺序，选择详情页当前已展示的同一个任务，避免状态文案与复制日志来自不同 item。
- 失败任务：状态文案仍显示失败摘要；复制入口仍只复制 `commandOutput`，不再复制失败详情。

## 测试策略

更新 `test/widget/presentation/pages/app_detail/app_detail_page_test.dart`：

1. 构造安装中任务，设置 `message` 和 `commandOutput`。
2. 验证详情页状态条展示状态文案，并展示“复制日志”按钮。
3. 点击“复制日志”，验证剪贴板写入完整 `commandOutput`。
4. 构造安装中任务但不设置 `commandOutput`。
5. 验证状态条仍展示状态文案，但不展示“复制日志”按钮。

## 验收标准

- 截图中高亮状态条不再展示“复制”或“复制错误信息”入口。
- 有下载管理日志时，详情页状态条展示“复制日志”，复制内容与下载管理 item 的 `commandOutput` 一致。
- 没有日志时，详情页状态条不展示复制入口。
- 相关 widget 测试通过，`flutter analyze` 无新增问题。
