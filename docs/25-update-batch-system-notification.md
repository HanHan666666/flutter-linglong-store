# 一键更新批次与跨桌面系统通知设计

> 状态：已实施
> 日期：2026-07-29  
> 适用范围：Linux 桌面版玲珑应用商店社区版  
> 相关规范：
> [Desktop Notifications Specification 1.3](https://specifications.freedesktop.org/notification/latest-single/)、
> [XDG Desktop Portal Notification](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Notification.html)、
> [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/)、
> [Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry/latest-single/)、
> [GNotification](https://docs.gtk.org/gio/class.Notification.html)

## 1. 背景

当前更新页支持“一键更新”，会把当时可更新且未处于活跃队列中的应用批量加入串行操作队列。现有实现只返回一组任务 ID，并没有保存“一次点击产生的一组任务”这一业务概念，因此不能可靠判断某次一键更新何时结束，也无法在应用重启后继续追踪该批次。

现有链路还存在以下架构问题：

1. `InstallTask` 和 `InstallQueue` 已经同时承担安装与更新职责，但命名和部分字段仍然只有安装语义。
2. 批量入口只返回 `List<String>`，任务之间没有持久化的批次关系。
3. 安装成功后的列表同步、更新列表移除和自动运行由 `AppShell` 监听队列状态完成，业务副作用泄漏到了 Presentation 层。
4. 崩溃恢复只使用 appId 判断任务是否成功。更新任务执行前应用本来就已经安装，因此应用存在不能证明更新成功。
5. 队列和当前任务分别写入 SharedPreferences，不具备单快照原子性，也不能与批次、待处理副作用保持一致。
6. 项目已有 `enableNotifications` 用户偏好，但设置页没有对应入口，也没有实际系统通知能力。
7. Linux `GApplication` ID 为 `com.dongpl.linglong-store.v2`，打包后的 desktop 文件名却是 `linglong-store.desktop`，不符合 `GNotification` 对应用身份匹配的要求。

本功能不是在队列结束处增加一次平台调用，而是建立可复用的应用操作批次、生命周期协调和系统通知边界。

## 2. 目标

1. 一键更新创建一个可持久化、可恢复、可独立判断终态的更新批次。
2. 批次中的所有任务进入终态后，只产生一次批次完成事件。
3. 通过 Linux 通用桌面标准发送系统通知，不依赖 DDE、发行版名称或桌面环境名称。
4. 普通宿主发行版和未来沙箱打包共享同一上层通知接口。
5. 通知失败不得改变更新任务结果，不得阻塞后续任务，也不得产生递归错误提示。
6. 应用重启后能够恢复任务、批次和待投递事件，并避免把中断更新误判为成功。
7. 把安装/更新完成后的全局副作用从 Widget 中移到 Application 层。
8. 本地持久状态遵循 XDG Base Directory Specification。
9. 对批次恢复、Outbox 幂等和通知偏好等高风险业务边界提供自动验证；平台边界通过 runner 编译和真实桌面验收。

## 3. 非目标

1. 不改变当前“同一时间只执行一个安装或更新任务”的串行规则。
2. 不增加 ll-cli 调用，不改变 `ll-cli upgrade <appId> --json` 的命令契约。
3. 不为单个安装或单个更新发送系统通知；首期只通知用户主动触发的“一键更新”批次。
4. 不增加通知按钮、点击打开下载中心或 D-Bus Activation。后续若需要动作通知，必须单独设计应用激活契约。
5. 不绕过系统通知策略，不尝试强制显示、强制声音或强制常驻。
6. 不把系统通知当作应用内通知中心或完整任务历史的替代品。
7. 不修改后端接口。

## 4. 核心设计原则

### 4.1 不按发行版或桌面环境分支

Debian、Ubuntu、Fedora、Deepin 等是发行版，GNOME、KDE Plasma、DDE、Xfce、Cinnamon 等是桌面环境。通知能力取决于当前图形会话提供的标准服务，而不是发行版名称。

实现禁止读取发行版信息来选择通知方案，也禁止增加 DDE、GNOME 或 KDE 私有通知 API。平台层统一使用 GTK/GIO 提供的 `GNotification`：

- 普通宿主桌面由 GIO 使用 Freedesktop Notifications 后端。
- Flatpak 等沙箱环境由 GIO 使用 XDG Desktop Portal Notification 后端。
- 通知服务不存在、被用户禁用或拒绝请求时，记录诊断信息并结束，不执行 Shell 回退。

### 4.2 批次终态不等于全局队列为空

一次一键更新只关心本次点击成功入队的任务。以下任务不得影响该批次终态：

- 点击前已经在队列中的任务。
- 点击后新增的单个安装或更新任务。
- 批次执行期间重新检查更新后发现的新版本。
- 原批次失败后由用户手动触发的重试任务。

只有批次记录的全部 taskId 进入终态，批次才进入终态。禁止通过“全局队列为空”或“当前任务为空”推断批次完成。

### 4.3 UI 只表达用户意图

更新页只负责调用 `UpdateAllController.start()` 并处理纯 UI 效果，例如下载中心脉冲动画。应用筛选、目标快照、批次创建、入队和业务错误由 Application 层统一处理。

Presentation 层禁止：

- 直接创建批次或写持久化文件。
- 监听队列并执行列表同步、统计、自动运行或系统通知。
- 直接调用 MethodChannel 或 GTK/GIO。
- 复制批次完成判定和通知文案规则。

### 4.4 平台投递与业务结果分离

更新任务成功只由 ll-cli 结构化终态或经过精确核验的恢复结果决定。通知投递是批次完成后的附加副作用：

- 通知失败不得把成功任务改成失败。
- 通知成功不得掩盖失败或中断任务。
- 通知偏好关闭时记录为 `suppressed`，不是错误。
- 系统 API 通常只能证明请求已经提交，不能证明用户实际看到了通知。

## 5. 目标架构

```text
Presentation
└── UpdateAppPage
    └── UpdateAllController.start()

Application
├── AppOperationQueueController
├── AppOperationLifecycleCoordinator
├── UpdateBatchNotificationPolicy
└── AppCollectionSyncService

Domain
├── AppOperationTask
├── AppOperationTargetSnapshot
├── AppOperationBatch
├── AppOperationBatchSummary
├── AppOperationEffect
├── SystemNotificationMessage
└── SystemNotificationGateway

Data / Platform
├── AppOperationJournalRepository
│   └── XDG_STATE_HOME versioned JSON snapshot
├── LinglongCliRepository
└── LinuxSystemNotificationGateway
    └── MethodChannel
        └── GNotification
```

依赖方向保持：

```text
Presentation → Application → Domain ← Data / Platform
```

Domain 和 Application 层不得 import Flutter Widget、MethodChannel、GTK/GIO 或 Presentation 文件。

## 6. 领域模型

### 6.1 AppOperationKind

```text
install
update
```

领域语义统一称为 `AppOperationKind`。当前代码为兼容既有 Provider、Freezed
序列化和下载中心 API，持久化类型名继续使用 `InstallTaskKind`；它已经同时
表达 install/update，禁止再把该名称理解为“只支持安装”。只有在单独执行完整
API 迁移时才做机械重命名，避免本功能同时维护两套任务模型。

### 6.2 AppOperationStatus

```text
pending
downloading
running
success
failed
cancelled
interrupted
```

`interrupted` 表示应用或进程异常退出后无法证明任务成功。它是终态，但不得归类为普通 ll-cli 执行失败。

代码中的兼容类型名为 `InstallStatus`，其业务语义与本节完全一致。

### 6.3 AppOperationTargetSnapshot

任务入队时保存不可变目标快照：

| 字段 | 用途 |
|---|---|
| `appId` | 应用主身份 |
| `displayName` | 通知和历史记录使用的点击时名称 |
| `icon` | UI 展示 |
| `arch` | 多实例身份和恢复核验 |
| `channel` | 多实例身份和恢复核验 |
| `module` | 多实例身份和恢复核验 |
| `repoName` | 多实例身份和恢复核验 |
| `installedVersion` | 更新前版本 |
| `expectedVersion` | 更新后的预期版本 |
| `requestedInstallVersion` | 仅显式版本安装传给 ll-cli |

`expectedVersion` 是业务核验字段，禁止因为 `ll-cli upgrade` 不接受版本参数就丢弃。`requestedInstallVersion` 与 `expectedVersion` 必须分离，避免一个 `version` 字段同时承担命令参数、统计版本和恢复判断三种含义。

### 6.4 AppOperationTask

任务至少包含：

```text
id
batchId?
kind
target
force
status
progress
message/rawMessage
commandOutput
error
createdAt/startedAt/finishedAt
```

`batchId` 可空。单个安装、单个更新和人工重试默认没有批次；一键更新任务必须携带同一个 batchId。

代码中的持久化类型名暂时保留为 `InstallTask`。本功能直接扩展该唯一模型，
没有新建平行 `AppOperationTask` 数据结构，避免队列、下载中心和恢复流程之间
出现双向转换与状态漂移。

### 6.5 AppOperationBatch

首期仅支持：

```text
kind = updateAll
```

批次至少包含：

```text
id
kind
taskIds
targets
createdAt
finishedAt?
status
notificationState
```

批次目标快照和顺序在创建时固定。Provider 后续刷新、应用改名或更新列表变化不得改变已创建批次的通知内容。

批次状态：

```text
active
completed
```

批次结果从任务终态派生，不保存第二套可漂移的成功/失败计数。

### 6.6 AppOperationBatchSummary

由批次和任务快照纯计算得到：

```text
successfulTargets
failedTargets
cancelledTargets
interruptedTargets
totalCount
finishedAt
```

该类型是通知策略和后续批次历史 UI 的稳定输入。通知格式化不得直接遍历全局队列历史。

### 6.7 AppOperationEffect

持久化副作用采用轻量 Outbox：

```text
id
type
aggregateId
createdAt
attemptCount
lastAttemptAt?
```

首期事件类型：

```text
taskSucceeded
updateBatchCompleted
```

队列在任务或批次进入终态时，把领域状态和对应 effect 写入同一个快照。生命周期协调器只消费 Outbox，不通过比较两个 Provider 状态猜测“刚才发生了什么”。

effect 处理规则：

1. 处理成功后从 Outbox 删除或移动到有界审计记录。
2. 通知偏好关闭属于成功消费，通知状态为 `suppressed`。
3. 永久不支持、无图形会话或服务不存在属于已尝试消费，记录日志后结束。
4. 进程在投递和确认之间退出时可能再次尝试。稳定 batchId 作为系统通知 ID，以 Portal 的替换语义降低重复概率。
5. Freedesktop Notifications 不提供跨进程的绝对 exactly-once 保证，因此文档和日志不得声称绝对不重复。

## 7. 一键更新流程

1. 用户点击“全部更新”。
2. `UpdateAllController` 读取最新可更新列表和活跃任务快照。
3. 按 appId 排除已经存在活跃任务的应用。
4. 若没有可入队应用，直接返回 `noTasksEnqueued`，不创建空批次，也不发送通知。
5. 为每个应用创建包含当前版本、目标版本和完整本机身份的 `AppOperationTargetSnapshot`。
6. 创建 batchId，并在一次队列状态变更中创建批次与所有任务。
7. 队列继续按原规则严格串行执行。
8. 每个任务进入终态时，队列更新任务记录，并重新计算对应批次是否全部终态。
9. 批次第一次进入 `completed` 时写入一个 `updateBatchCompleted` effect。
10. `AppOperationLifecycleCoordinator` 消费 effect：
    - 同步已安装应用和更新列表。
    - 根据用户偏好和批次摘要生成系统通知。
    - 调用 `SystemNotificationGateway`。
11. 通知结果写入诊断日志并确认消费 effect。

同一个批次只能产生一个 `updateBatchCompleted` effect。重复的任务终态消息、Provider 重建或启动恢复不得再次创建完成事件。

## 8. 任务执行与恢复

### 8.1 正常执行

正常执行继续以 `ll-cli --json` JSON line 为唯一状态来源：

- 收到结构化 `success` 后标记成功。
- 收到结构化 `failed` 后标记失败。
- 用户协作取消成功后标记取消。
- 流正常结束但没有终态时标记失败，禁止乐观推断成功。

### 8.2 应用重启恢复

启动恢复必须接收完整的 `List<InstalledApp>`，禁止只接收 appId 集合。

安装任务恢复：

- 根据 appId 和可用的 arch/channel/module/repoName 找到目标实例。
- 显式版本安装需要核验已安装版本。
- 无法唯一定位或无法证明成功时标记 `interrupted`。

更新任务恢复：

- 找不到目标实例：`interrupted`。
- `expectedVersion` 缺失：`interrupted`，兼容旧记录时不得按 appId 乐观成功。
- 精确目标实例版本等于 `expectedVersion`：`success`。
- 版本仍等于 `installedVersion`：`interrupted`。
- 版本既不等于旧版本也不等于预期版本：`interrupted`，记录实际版本供诊断。

恢复只负责确认本地事实，不重新调用 ll-cli，也不自动重试。

### 8.3 人工重试

失败、中断任务由用户点击重试时创建新的 taskId。原任务和原批次结果保持不可变：

- 原批次按第一次执行结果结束并通知。
- 重试任务默认作为单任务运行，不重新打开已经完成的批次。
- 如果未来需要“重试整个批次”，必须创建新批次。

## 9. 持久化与 XDG

### 9.1 路径

为 `AppXdgPaths` 增加 `$XDG_STATE_HOME` 解析：

```text
$XDG_STATE_HOME/com.dongpl.linglong-store.v2/
```

未设置时使用规范默认值：

```text
$HOME/.local/state/com.dongpl.linglong-store.v2/
```

应用操作快照：

```text
$XDG_STATE_HOME/com.dongpl.linglong-store.v2/operations/queue-v2.json
```

该文件属于跨重启状态和操作历史，禁止放入 cache 或 runtime 目录。

### 9.2 快照

单文件版本化结构：

```json
{
  "schemaVersion": 2,
  "pendingTasks": [],
  "currentTask": null,
  "history": [],
  "batches": [],
  "outbox": []
}
```

写入要求：

1. 只允许 `AppOperationJournalRepository` 读写。
2. 先在同目录创建临时文件，写入并刷新后再原子替换正式文件。
3. 目录权限按 XDG 建议创建为仅当前用户可访问。
4. 写入失败必须记录错误；内存状态可以继续运行，但不得伪装成已经持久化。
5. 文件损坏时先保留带时间戳的损坏副本，再回退到空状态，方便诊断。
6. 历史记录继续保持有界，活跃批次和 Outbox 不得被历史上限淘汰。

### 9.3 迁移

由 `InstallQueue` 在首次读取新 Journal 时执行一次惰性迁移：

1. 读取旧 SharedPreferences 的 current task 和 queue。
2. 把旧任务转换为 `AppOperationTask`。
3. 旧任务没有批次和可靠 expectedVersion，不创建伪批次。
4. 当前执行中的旧 update 任务在恢复时按 `interrupted` 处理，禁止只按 appId 标记成功。
5. 新快照成功落盘后再删除旧 key。
6. 迁移失败保持旧 key，不得写入半成品。

`build/scripts/clear-local-data.sh` 和 smoke test 必须同步覆盖新的 XDG state 目录；`--keep-preferences` 不保留操作队列和历史。

## 10. 生命周期协调器

`AppOperationLifecycleCoordinator` 是 app-wide keepAlive Application 服务，启动序列完成本地状态恢复后显式启动。

职责：

1. 按顺序消费 `AppOperationEffect`。
2. 成功任务完成后调用 `AppCollectionSyncService.syncAfterSuccessfulOperation()`。
3. 仅 install 成功且用户启用“安装后自动运行”时启动应用。
4. 触发既有统计上报。
5. 批次完成时调用 `UpdateBatchNotificationPolicy`。

非职责：

- 不执行 ll-cli。
- 不直接修改页面局部状态。
- 不保存 Widget、BuildContext 或路由对象。
- 不拼装 GTK/GIO 参数。

列表同步失败不回滚已经成功的任务，也不阻止批次通知。通知正文使用批次自己的目标快照，不依赖同步成功后的更新列表。

## 11. 通知领域接口

### 11.1 SystemNotificationMessage

```text
id
title
body
priority
category?
iconName?
```

首期约束：

- `id` 使用稳定的 `update-batch-<batchId>`。
- `priority` 使用 normal。
- `category` 使用 `transfer.complete`；旧 GLib 不支持设置 category 时允许忽略。
- `iconName` 使用主题图标名 `linglong-store`。
- title 和 body 使用纯文本，不发送 markup。
- 不携带动作按钮。

### 11.2 SystemNotificationGateway

```text
Future<SystemNotificationSubmission> submit(
  SystemNotificationMessage message,
)
```

返回状态：

```text
submitted
unsupported
unavailable
rejected
failed
```

`submitted` 只表示平台调用已接受，不表示通知实际显示或用户已看到。

Domain 只定义接口和数据类型。Linux MethodChannel、GTK/GIO 和异常映射位于 Platform 层。

## 12. Linux 平台实现

### 12.1 Dart 侧

新增 `LinuxSystemNotificationGateway`：

- 使用单一、固定名称的 MethodChannel。
- 对输入做空标题、长度和平台检查。
- 非 Linux 平台返回 `unsupported`。
- 捕获 `MissingPluginException`、`PlatformException` 和超时，映射为 typed result。
- 禁止直接记录完整异常堆栈到用户界面。

通道负载仅包含可序列化基础类型。由于 API 很小且只有一个方法，首期使用显式封装的 MethodChannel；若后续加入撤回、动作和能力查询，再迁移到 Pigeon。

### 12.2 C++ 侧

Linux runner 新增独立的通知通道实现文件，禁止继续把所有逻辑堆入 `my_application.cc`。

处理步骤：

1. 校验 method 名称和参数类型。
2. 创建 `GNotification`。
3. 设置 title、body、普通优先级和主题图标。
4. 构建环境支持时设置 category。
5. 使用 `g_application_send_notification()` 发送。
6. 立即返回“已提交”，不等待用户可见性。

通知调用必须运行在 GTK 主线程。参数错误返回明确的 `FlMethodErrorResponse`，不得崩溃或触发未定义行为。

### 12.3 不允许的回退

禁止调用：

```text
notify-send
zenity
kdialog
dde-notify
Shell / Process.run
```

这些回退会引入额外进程、桌面私有分支、沙箱不一致和不可控超时。系统没有通知服务时，功能静默降级并保留日志即可。

## 13. Desktop Entry 与应用身份

`GApplication` ID 保持：

```text
com.dongpl.linglong-store.v2
```

主 desktop 文件改为：

```text
com.dongpl.linglong-store.v2.desktop
```

同步修改：

- Deb/RPM/AppImage/AUR 安装路径。
- AppStream `<launchable type="desktop-id">`。
- 打包 smoke test。
- 通知 `desktop-entry` 身份。

desktop 文件新增：

```text
X-GNOME-UsesNotifications=true
```

该扩展键只帮助 GNOME 设置识别通知能力，不参与核心通知实现；其他桌面会按 Desktop Entry 规范保留或忽略未知扩展。

### 13.1 og 协议兼容

旧 desktop ID 可能已被用户写入 MIME 默认应用配置。为避免升级后 `og://` 处理失效，至少一个大版本保留：

```text
linglong-store.desktop
```

兼容文件要求：

- `NoDisplay=true`
- 保留 `Exec=linglong-store %u`
- 保留 `MimeType=x-scheme-handler/og;`
- 不作为 AppStream launchable
- 不在菜单显示第二个应用入口

Nightly 与 stable 包当前互相冲突并复用同一运行时 ID，因此主 desktop ID 统一使用 canonical ID；Nightly 的旧 desktop 文件同样只作为过渡兼容入口。

运行时不得调用 `xdg-mime` 强制修改用户默认 handler。

## 14. 通知业务规则

### 14.1 总开关

复用 `UserPreferences.enableNotifications`，默认值保持 true。设置页增加“系统通知”开关和说明：

```text
系统通知
一键更新完成后，在桌面通知中显示更新结果
```

应用开关关闭时不调用平台 API。系统层面的勿扰模式、应用通知权限和显示策略继续由桌面环境控制。

### 14.2 文案

文案必须使用 l10n，不得在策略或平台层硬编码中文/英文。

全部成功：

```text
标题：3 个应用已更新
正文：已更新：应用 A、应用 B、应用 C
```

部分成功：

```text
标题：批量更新已结束
正文：成功 2 个，失败 1 个
      已更新：应用 A、应用 B
```

存在取消或中断时：

```text
标题：批量更新已结束
正文：成功 2 个，失败 1 个，取消 1 个，中断 1 个
      已更新：应用 A、应用 B
```

没有任何成功：

```text
标题：应用更新未完成
正文：失败 2 个，取消 1 个
```

计数为 0 的失败、取消、中断分类不显示。名称顺序保持用户点击时更新列表的顺序。

### 14.3 长列表

系统通知不承担完整历史展示。成功应用：

- 不超过 6 个时全部列出。
- 超过 6 个时列出前 6 个，并追加“等 N 个应用”。
- 单个应用名和总正文需要做 Unicode 安全的长度上限处理，禁止按 UTF-16 半个代理项截断。
- 完整结果保留在下载管理历史和批次摘要中。

### 14.4 发送时机

- 批次所有任务终态后立即排入 Outbox。
- 不要求主窗口隐藏或失焦；用户明确要求任务结束后发送系统通知。
- 应用关闭且批次仍在执行时，任务本身不会继续执行；下次启动完成恢复后处理批次终态和待投递事件。
- 空批次不通知。
- 单个更新不通知。
- 人工重试不补发或改写原批次通知。

## 15. 并发、幂等与性能

1. 队列仍为单消费者，不新增并发 ll-cli。
2. batchId 和 taskId 使用 UUID，禁止使用列表索引作为身份。
3. 批次终态计算只扫描该批次 taskId，避免每次进度更新扫描完整历史。
4. 只有任务进入终态时才重新计算批次完成，不在每个进度百分比事件中计算。
5. Outbox 同一时刻只允许一个消费循环，防止重复通知。
6. 系统通知调用异步执行，禁止阻塞 UI isolate。
7. D-Bus/Portal 服务不可用时快速失败；平台通道设置有限超时。
8. 通知正文使用入队时快照，不触发额外网络请求或 ll-cli。
9. 批次和历史保持有界；活跃批次、当前任务和未消费 Outbox 永远不得被历史裁剪。

## 16. 错误处理与可观测性

日志至少记录：

- batchId、taskId、appId 和任务终态。
- 批次完成摘要，不记录不必要的用户环境变量。
- 通知是否因应用偏好被抑制。
- 平台提交结果和标准化错误类型。
- 重启恢复时的旧版本、预期版本和实际版本。
- journal 迁移、损坏备份和原子写入失败。

日志禁止记录：

- D-Bus session 地址。
- 用户 HOME 完整内容或无关环境变量。
- 通知正文之外的额外应用隐私数据。

用户关闭通知或系统通知服务不存在不属于更新失败，不显示应用内错误。

## 17. 测试策略

测试服务于实际故障风险，不以新增文件数或覆盖率为目标。本功能保留以下关键自动验证：

1. 批次只跟踪自己的任务，并且只生成一次完成事件。
2. XDG State 路径、Journal round-trip、串行原子写入和损坏副本保留。
3. 重启后必须按完整实例和目标版本核验，无法证明成功时标记 `interrupted`。
4. 生命周期协调器只投递一次批次通知；关闭通知偏好时消费事件但不调用平台网关。
5. desktop ID、旧 og handler、Deb/RPM/AppImage/AUR 渲染结果和清理脚本保持一致。
6. Linux runner 必须实际通过 CMake 编译，防止 MethodChannel 或 GLib API 接入错误。

纯 getter、框架生成代码、简单设置控件和 GIO 本身已经保证的行为不追加陪跑单测。平台是否真正显示通知仍需真实图形会话验收，不能由 mock 宣称成功。

### 17.1 自动验证

自动验证：

```text
flutter analyze
/home/han/flutter/bin/flutter test <本功能关键测试>
flutter build linux --release
build/scripts/release-cli-smoke-test.sh
build/scripts/nightly-cli-smoke-test.sh
build/scripts/package-smoke-test.sh
build/scripts/clear-local-data-smoke-test.sh
desktop-file-validate
appstreamcli validate
```

真实会话最小矩阵：

| 发行版/桌面 | 显示协议 | 包形态 |
|---|---|---|
| Debian / Xfce 或 GNOME | X11 | Deb |
| Ubuntu / GNOME | Wayland | Deb 或 AppImage |
| Fedora / GNOME 或 KDE | Wayland | RPM |
| Deepin / DDE | Wayland 或 X11 | Deb |

验收点：

- 通知标题、正文、应用名和图标正确。
- 系统通知设置可以识别应用。
- 勿扰模式和系统禁用通知时应用不报错。
- stable/nightly 打包只显示一个菜单入口。
- 升级后旧 `og://` handler 仍可拉起应用。

## 18. 实施分期与提交边界

### 阶段一：文档

```text
docs: 增加一键更新系统通知设计
```

### 阶段二：XDG 与桌面身份

```text
refactor: 补全 XDG 状态目录
fix: 统一系统通知桌面身份
```

### 阶段三：操作领域与持久化

```text
refactor: 建立可恢复的一键更新批次
```

### 阶段四：生命周期副作用

```text
feat: 完成一键更新结果通知编排
```

### 阶段五：系统通知

```text
feat: 建立跨桌面系统通知通道
feat: 增加系统通知设置入口
fix: 精简批次通知结果文案
```

每个功能点完成针对性验证后使用 Conventional Commit 独立提交。测试优先覆盖状态恢复、幂等消费和平台编译等真实故障边界，不为形式覆盖增加低价值用例。

## 19. 验收标准

1. 用户点击一次“全部更新”只创建一个 batch。
2. 只有该 batch 的全部任务终态后发送一次通知。
3. 通知准确区分成功、失败、取消和中断。
4. 通知列出的成功应用来自批次快照，不受更新列表刷新影响。
5. 应用重启后不会仅凭 appId 把更新任务标记成功。
6. 通知失败、被禁用或服务不存在不影响任务结果。
7. Presentation 层不再监听队列执行全局业务副作用。
8. 业务代码不调用 `notify-send`、桌面私有 API 或发行版判断。
9. 操作状态写入 `$XDG_STATE_HOME`，旧队列可安全迁移。
10. canonical desktop ID 与 GApplication ID 一致，旧 og handler 有过渡兼容。
11. 状态恢复、Outbox 幂等、通知偏好和 runner 编译等关键风险有对应验证。
12. 静态分析、关键测试、Linux 构建和打包元数据验证通过。

## 20. 后续演进边界

以下能力必须建立在本设计的批次、Outbox 和通知网关之上，禁止另建平行实现：

- 单个安装完成通知。
- 点击通知打开下载中心。
- 通知动作按钮。
- 批次历史详情页。
- 整批重试。
- Flatpak、玲珑或其他沙箱打包。

引入通知动作前，必须先统一 GApplication 单实例、D-Bus Activation 和现有 `SingleInstance` URL 转发契约；不能只在某个桌面环境中临时监听通知点击。
