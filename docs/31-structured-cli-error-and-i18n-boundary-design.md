# 结构化 CLI 错误与国际化边界设计

## 1. 文档定位

本文描述架构治理第四阶段的实施边界，覆盖安装/更新进度、持久化任务失败、
普通 `ll-cli` 查询和命令结果。目标不是替换所有界面文案，而是先消除 Data 层生成
本地化字符串、失败被空结果吞掉、Journal 固化旧语言这三类基础问题。

本阶段拆成两个可独立验证和回滚的提交：

1. 统一应用操作的结构化事件、失败类型和当前语言格式化；
2. 收敛普通 CLI 查询/命令的成功值与失败契约。

## 2. 当前问题

### 2.1 Data 层持有 locale

`LinglongCliRepositoryImpl` 构造时接收 `InstallMessages`，并在解析
`ll-cli --json` 输出时直接生成“准备安装”“安装完成”“安装失败”等展示文案。
这导致：

- Data 依赖 Flutter locale 和 `AppLocalizations`；
- 同一个 Repository 实例的语言可能与用户后来切换的语言不一致；
- 队列把 `message/errorMessage` 写入 XDG Journal 后，重启或切换语言仍展示旧文案；
- 测试命令协议时必须构造无关的国际化对象。

### 2.2 一个字符串承担多种语义

`InstallProgress.message/error/rawMessage/errorDetail` 和
`InstallTask.message/errorMessage/errorDetail` 同时承担：

- 状态分类；
- 用户展示；
- 原始诊断；
- 后端错误解决方案匹配；
- 旧快照兼容。

调用方无法仅从字段判断它拿到的是稳定业务状态、已翻译文案还是原始 CLI 输出，
也无法在不破坏诊断原文的情况下重新格式化。

### 2.3 空列表会吞掉失败

`getInstalledApps()` 和 `searchVersions()` 在命令退出失败、命令不存在、超时或
解析异常时返回空列表。上层无法区分：

- 命令成功且确实没有应用；
- `ll-cli` 执行失败；
- JSON 不符合约定；
- 进程或系统异常。

这会让启动检查、安装结果确认和页面空状态把真实故障误判为正常空数据。

### 2.4 字符串结果被反向解析

`killApp()`、`createDesktopShortcut()`、`pruneApps()` 和版本查询部分路径返回
自然语言字符串表达成功与失败。Application 甚至通过判断字符串是否包含
“失败/异常”决定操作是否成功。该协议对语言切换和文案修改都不稳定。

## 3. 方案比较

### 3.1 继续保存文案，并在切换语言时批量改写

改动看似较小，但旧文案无法可靠反向映射到业务状态，原始诊断和展示文案也已经
混合。每增加语言都要扩充反向识别规则，维护成本会持续上升。

### 3.2 所有 Repository 返回通用 `Result<T, String>`

能够显式表示失败，但字符串仍然没有稳定类别；调用方会继续解析错误文本。
通用 Result 还会让 Dart 的异常传播、调用栈和现有 Provider 错误处理重复一套。

### 3.3 保存结构化事实，预期失败使用稳定类型

安装流使用结构化事件和失败对象；普通查询成功时直接返回业务值，失败时抛出
Domain 定义的稳定 CLI 异常。空列表只代表命令成功后的真实空结果。Presentation
在当前 locale 下格式化任务状态，Application 只决定状态迁移和重试。

**选择方案 3。** 它保留 Dart 原生异常传播，不引入泛型 Result 容器，同时让
调用方能够通过异常类型和失败类别做稳定决策。

## 4. 应用操作结构化协议

### 4.1 状态消息代码

Domain 新增稳定的 `AppOperationMessageCode`，仅描述可本地化的语义：

- `preparing`
- `starting`
- `installingApplication`
- `installingRuntime`
- `installingBase`
- `downloadingMetadata`
- `downloadingFiles`
- `postProcessing`
- `processing`
- `completed`

Data 根据结构化 JSON 的 `message` 识别代码，但不产生任何本地化字符串。无法识别
时保留 `rawMessage`，Presentation 可以逐字展示原始消息；识别成功时优先使用
当前语言对应文案。

### 4.2 失败类型

Domain 新增 `AppOperationFailure`，至少保存：

- `kind`：`cli`、`timeout`、`resultUnconfirmed`、
  `streamEndedWithoutTerminal`、`execution`、`interrupted`；
- `cliCode`：ll-cli JSON 错误码；
- `diagnostic`：未经本地化的原始诊断；
- `guidanceScenario`：需要发行版特殊提示时保存稳定场景，而不是拼接提示文案。

`diagnostic` 是错误解决方案查询和日志诊断的事实来源。格式化器不得修改它。

### 4.3 分层职责

```text
ll-cli JSON line
      │
      ▼
Data: 解析 event / messageCode / failure / raw diagnostic
      │
      ▼
Application: 校验 taskId、决定状态迁移、补充恢复和超时 failure
      │
      ▼
Domain / XDG Journal: 保存 status / messageCode / failure / raw output
      │
      ▼
Presentation: 当前 locale + 当前发行版能力 → 用户文案
```

Data 禁止依赖 `InstallMessages`、`AppLocalizations`、Riverpod 或 Widget context。
Application 禁止把展示文案写入新任务快照。

### 4.4 当前语言格式化

`InstallMessages` 保留为 Presentation 可使用的集中格式化器，但不再注入 Data。
它根据以下结构生成文案：

- `InstallTask.kind`
- `InstallTask.status`
- `InstallTask.messageCode`
- `InstallTask.failure`
- 当前 `LinuxDistribution`

下载管理、详情页状态条和其他任务消费者统一调用同一个格式化入口。切换语言后，
Provider/Widget 重建即可生成新文案，无需改写 Journal。

### 4.5 Journal 兼容

新增字段使用可空值，现有 JSON schema 继续兼容读取：

- 旧快照没有 `messageCode/failure` 时继续读取 `message/errorMessage/errorDetail`；
- 新运行任务只写结构化字段，旧字符串字段保留在模型中作为只读迁移兼容；
- UI 格式化优先级固定为“结构化字段 → 旧字段 → 状态默认文案”；
- `diagnosticMessage` 优先读取 `failure.diagnostic`，再回退旧
  `errorDetail/rawMessage/errorMessage`；
- 不批量重写用户现有 Journal，任务下一次自然变更时按当前 schema 保存。

这样无需提升 Journal 外层版本，也不会让升级中的任务因字段缺失无法恢复。

## 5. 普通 CLI 查询与命令契约

### 5.1 稳定异常

Domain 新增 `LinglongCliFailure` 和 `LinglongCliException`：

- `commandNotFound`
- `timeout`
- `permissionDenied`
- `commandFailed`
- `invalidOutput`
- `filesystem`
- `unexpected`

失败对象保存命令标签、退出码和原始诊断。它不包含用户文案。

### 5.2 查询方法

以下方法继续返回直接业务值，但不得吞异常：

- `getInstalledApps()`：成功可返回空列表；命令失败或 JSON 不合法时抛稳定异常；
- `getRunningApps()`：同上；
- `searchVersions()`：同上；
- `getLlCliVersion()`：只返回真实版本；不可用时抛稳定异常。

Parser 必须区分合法空 JSON 与无法解析的输出。Repository 在 Parser 无法证明输出
有效时抛 `invalidOutput`，不能用空列表兜底。

### 5.3 命令方法

自然语言字符串结果改为明确类型：

- `uninstallApp()`、`killApp()`、`pruneApps()` 成功返回 `void`，失败抛稳定异常；
- `createDesktopShortcut()` 返回包含目标路径和“新建/已存在”状态的结构化结果；
- `runApp()` 保持 `void`；
- `cancelOperation()` 的布尔值已有稳定业务含义，保持不变。

Application 只根据返回类型或异常决定成功失败，不再搜索字符串内容。
Presentation 使用 l10n 生成最终提示。

## 6. 性能与并发

- 结构化枚举和小对象替代重复长文案，不增加 UI isolate 的重计算；
- 任务格式化只在可见 Widget 构建时执行，不进入 CLI 高频解析或 Journal 写入；
- `commandOutput` 仍是复制日志的唯一来源，本阶段不截断、不外置；
- Repository 不缓存 locale，切换语言不需要重建正在执行的 CLI 流；
- 安装流仍由 taskId 隔离，结构化字段不得改变串行队列和持久化屏障。

## 7. 验证范围

不为覆盖率新增无业务价值测试，只保护协议边界：

- Data 在中英文 locale 无关条件下产生相同结构化事件；
- 失败原始 message 逐字保留，错误解决方案查询来源不变；
- 旧任务 JSON 仍可读取，结构化任务可往返 Journal；
- 同一任务在语言切换后得到对应的新文案；
- 已安装列表真实空结果与命令失败、解析失败可区分；
- `killApp()` 不再通过自然语言字符串判断成功；
- 现有安装、取消、恢复、批次和真实 API 测试继续通过。

每个提交执行 `dart format`、相关测试、`flutter analyze`；阶段完成后执行 Linux
调试构建。Freezed/JSON 生成物由项目统一生成命令更新，不手工编辑。

## 8. 非目标

- 不在本阶段重写网络 API 的错误体系；
- 不改变后端错误解决方案接口和原始 message 契约；
- 不调整下载管理、详情页或环境管理界面的视觉布局；
- 不把所有日志都包装成面向用户的错误；
- 不引入发行版分支或 Shell 文案探测。
