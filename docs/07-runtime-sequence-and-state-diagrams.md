# 运行逻辑时序图与状态机图

> 文档版本: 1.0 | 创建日期: 2026-03-15  
> 目的：把迁移中最关键、最容易做错的运行逻辑，用可视化方式固定下来，避免多人开发时对真实行为理解不一致。

---

## 一、为什么这份文档必须存在

当前迁移文档已经有：
- 迁移方案
- Flutter 架构
- UI 设计规范
- 路线图
- 多人任务编排
- 测试与性能规范

但如果缺少**时序图**和**状态机图**，多人开发时仍然容易在以下地方“各写各的”：

1. 启动流程谁先谁后
2. 安装队列的状态流转
3. KeepAlive 页面的可见/隐藏行为
4. 搜索与分页的请求废弃策略
5. 更新检查与菜单红点刷新联动
6. 环境检测与自动安装逻辑

所以这份图文档不是“锦上添花”，而是**防止迁移走样的硬约束文档**。

---

## 二、启动流程时序图

> 启动链路的设计说明、首帧主题/语言恢复策略、启动关键路径与延后策略，
> 见：[`11-startup-flow-and-first-frame-restore.md`](./11-startup-flow-and-first-frame-restore.md)。

### 2.1 冷启动主流程

```mermaid
sequenceDiagram
    autonumber
    participant User as 用户
    participant App as Flutter App
    participant Main as main.dart
    participant Window as WindowManager
    participant Store as Local Storage
    participant Providers as Riverpod Providers
    participant Launch as LaunchPage / LaunchSequence
    participant CLI as LinglongCliRepository
    participant HTTP as AppRepository
    participant Home as RecommendPage

    User->>App: 启动应用
    App->>Main: 执行 main()
    Main->>Main: WidgetsFlutterBinding.ensureInitialized()
    Main->>Main: AppLogger.init()
    Main->>Main: SingleInstance.ensure()
    Main->>Window: 初始化窗口参数
    Main->>Store: 初始化 Preferences / Hive
    Main->>Main: ApiClient.init()
    Main->>Providers: 初始化全局 Provider 容器
    Main->>App: runApp()
    App->>Providers: build 阶段同步恢复 locale/theme/settings/installQueue
    App->>Launch: 进入 LaunchPage
    Launch->>CLI: checkLinglongEnv()
    CLI-->>Launch: env result

    alt 环境缺失或异常
        Launch->>App: 打开 LinglongEnvDialog
    else 环境正常
        Launch->>CLI: getInstalledApps()
        CLI-->>Launch: installed apps
        Launch->>Providers: 更新 installedAppsProvider
        Launch->>HTTP: checkUpdates(appIds)
        HTTP-->>Launch: updates
        Launch->>Providers: 更新 updatesProvider
        Launch->>Providers: 恢复 installQueue 状态
        Launch->>Home: 跳转 RecommendPage
    end
```

### 2.2 启动阶段约束

启动流程必须满足：
- 首帧只允许出现一个正式 `LaunchPage`
- 首帧主题和语言必须与用户上次保存的值一致
- `MaterialApp` 依赖的主题、语言、基础设置必须在 Provider `build()` 阶段同步恢复
- 已安装列表先于更新检查
- 更新检查先于菜单红点展示
- install queue 恢复必须在首页交互前完成
- 安装队列本地快照可在 Provider `build()` 恢复，但业务级纠偏仍必须在 `queueRecovery` 完成
- 设置页缓存大小等非关键路径逻辑不得阻塞启动
- 任何一步失败都要可诊断，不能静默吞掉

---

## 三、环境检测与自动安装时序图

```mermaid
sequenceDiagram
    autonumber
    participant Launch as LaunchPage
    participant Env as LinglongEnvProvider
    participant HTTP as AppRepository
    participant CLI as LinglongCliRepository
    participant Dialog as LinglongEnvDialog

    Launch->>Env: checkLinglongEnv()
    Env->>CLI: checkLinglongEnv()
    CLI-->>Env: ok / not_ok + detail
    Env-->>Launch: state

    alt env ok
        Launch->>Launch: 继续启动流程
    else env not ok
        Launch->>Dialog: show()
        alt 用户点击“重新检测”
            Dialog->>Env: recheck()
            Env->>CLI: checkLinglongEnv()
        else 用户点击“手动安装”
            Dialog->>HTTP: get install script url / docs link
        else 用户点击“自动安装”
            Dialog->>HTTP: 获取安装脚本
            HTTP-->>Dialog: script
            Dialog->>CLI: installLinglongEnv(script)
            CLI-->>Dialog: install result
            Dialog->>Env: recheck()
        else 用户点击“退出商店”
            Dialog->>Launch: quitApp()
        end
    end
```

---

## 四、安装队列状态机

### 4.1 全局安装状态机

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Waiting: enqueue(task)
    Waiting --> Installing: dequeue and start
    Installing --> Succeeded: install complete
    Installing --> Failed: install error
    Installing --> Cancelled: user cancel / process killed
    Succeeded --> Waiting: queue not empty
    Failed --> Waiting: queue not empty
    Cancelled --> Waiting: queue not empty
    Succeeded --> Idle: queue empty
    Failed --> Idle: queue empty
    Cancelled --> Idle: queue empty
```

### 4.2 单任务状态机

```mermaid
stateDiagram-v2
    [*] --> Queued
    Queued --> Preparing: becomes currentTask
    Preparing --> Downloading: first progress event
    Downloading --> Installing: package download finished
    Installing --> Finalizing: success callback pending
    Finalizing --> Success: store synced
    Downloading --> Failed: parse error / network error / cli error
    Installing --> Failed: cli error
    Preparing --> Cancelled: user cancel
    Downloading --> Cancelled: user cancel
    Installing --> Cancelled: user cancel
    Failed --> [*]
    Success --> [*]
    Cancelled --> [*]
```

### 4.3 关键实现约束

- 同一时刻只允许 **1 个 currentTask**
- 队列推进必须由统一控制器负责，禁止页面各自改状态
- UI 只能读取 install queue，不允许页面直接驱动任务切换
- `Cancelled` 与 `Failed` 必须区分，不能混成一个“失败”

---

## 五、安装流程时序图

```mermaid
sequenceDiagram
    autonumber
    participant User as 用户
    participant Card as ApplicationCard/AppDetailPage
    participant Install as AppInstallController
    participant Queue as InstallQueueProvider
    participant CLI as LinglongCliRepository
    participant Progress as InstallProgressProvider
    participant Stores as installedApps/updates/cache

    User->>Card: 点击“安装/更新”
    Card->>Install: handleInstall(appId, version)
    Install->>Queue: enqueueInstall(task)
    Queue->>Queue: if idle then processQueue()
    Queue->>CLI: installApp(appId, version)

    loop 流式进度
        CLI-->>Progress: InstallProgress event
        Progress-->>Queue: updateProgress()
        Queue-->>Card: UI progress refresh
    end

    alt success
        CLI-->>Queue: completed
        Queue->>Stores: refresh installed apps
        Queue->>Stores: refresh updates
        Queue->>Stores: invalidate list caches
        Queue-->>Card: button => 打开/已安装
    else failed
        CLI-->>Queue: failed(code, message)
        Queue-->>Card: error state / toast
    else cancelled
        User->>Queue: cancel(task)
        Queue->>CLI: cancelInstall(appId)
        CLI-->>Queue: cancelled
    end
```

---

## 五-A、取消安装流程时序图

> 本节记录取消安装功能的设计，迁移自 Rust 版本的 `InstallSlot` 模式。

### 5-A.1 取消安装时序图

```mermaid
sequenceDiagram
    autonumber
    participant User as 用户
    participant UI as 安装进度UI
    participant Queue as InstallQueueProvider
    participant Repo as LinglongCliRepository
    participant CLI as CliExecutor
    participant System as pkexec/killall
    participant Process as ll-cli/ll-package-manager

    User->>UI: 点击"取消安装"
    UI->>Queue: cancelInstall(appId)
    Queue->>Repo: cancelInstall(appId)
    Repo->>Repo: 设置取消标志 _cancelFlags[processId] = true

    Note over Repo,CLI: 第一阶段：内部进程终止

    Repo->>CLI: cancelWithSystemKill(processId)
    CLI->>CLI: 查找 _activeProcesses[processId]
    CLI->>CLI: 发送取消信号 _cancelSignals[processId].complete()
    CLI->>Process: process.kill(SIGTERM)

    Note over CLI,System: 第二阶段：系统级进程终止

    CLI->>System: pkexec killall -15 ll-cli ll-package-manager
    System->>Process: SIGTERM 优雅终止
    Process-->>CLI: 进程退出
    CLI-->>Repo: cancelWithSystemKill 完成

    Repo->>Repo: 清理 PID 记录 _activeProcessPids.remove(processId)
    Repo-->>Queue: 取消完成
    Queue->>UI: 状态更新为 Cancelled
    UI->>User: 显示"安装已取消"
```

### 5-A.2 为什么需要系统级终止

Flutter 通过 `Process.start` 启动的子进程存在以下问题：

1. **进程树隔离**：`ll-cli` 会启动 `ll-package-manager` 作为子进程，Dart 的 `process.kill()` 只能终止直接子进程，无法终止孙子进程
2. **权限问题**：`ll-package-manager` 可能需要 root 权限运行，普通用户无法直接终止
3. **僵尸进程风险**：如果只终止 Dart 层面的进程引用，系统进程可能继续运行，导致资源泄露

**解决方案**（参考 Rust 版本）：
- 使用 `pkexec` 获取管理员权限
- 通过 `killall -15` 同时终止 `ll-cli` 和 `ll-package-manager`
- SIGTERM（信号 15）允许进程优雅退出，而非强制终止

### 5-A.3 取消状态管理

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> CancelRequested: 用户点击取消
    CancelRequested --> InternalCancel: 设置取消标志
    InternalCancel --> SystemKill: pkexec killall
    SystemKill --> CleaningUp: 进程已终止
    CleaningUp --> Cancelled: 清理 PID/标志
    Cancelled --> [*]

    note right of CancelRequested: _cancelFlags[processId] = true
    note right of SystemKill: pkexec killall -15 ll-cli ll-package-manager
```

### 5-A.4 关键实现约束

1. **PID 记录时机**：必须在 `onProcessCreated` 回调中记录 PID，而非事后获取
   ```dart
   await for (final event in CliExecutor.executeWithProgressAndProcess(
     args,
     processId: processId,
     onProcessCreated: (process) {
       _activeProcessPids[processId] = process.pid;
     },
   )) { ... }
   ```

2. **双重取消机制**：
   - **标志位检查**：在流式处理循环中检查 `_cancelFlags[processId]`，实现快速响应
   - **系统级终止**：通过 `pkexec killall` 确保所有相关进程被终止

3. **取消与失败的区分**：
   - `InstallStatus.cancelled`：用户主动取消
   - `InstallStatus.failed`：安装过程出错
   - 两者不可混淆，UI 需要展示不同的提示信息

4. **资源清理顺序**：
   ```dart
   // 1. 设置取消标志
   _cancelFlags[processId] = true;
   // 2. 系统级终止
   await CliExecutor.cancelWithSystemKill(processId, ...);
   // 3. 清理 PID 记录
   _activeProcessPids.remove(processId);
   ```

### 5-A.5 从 Rust 迁移的设计要点

| Rust 设计 | Flutter 实现 | 说明 |
|-----------|-------------|------|
| `InstallSlot` 全局单例 | `CliExecutor._activeProcesses` 静态 Map | 管理活跃安装进程 |
| `is_cancelled` 标志 | `_cancelFlags` Map + `_isUserCancelled` | 区分取消与失败 |
| `pkexec killall -15` | `CliExecutor.cancelWithSystemKill()` | 系统级进程终止 |
| PID 记录 | `onProcessCreated` 回调 | 确保可靠获取进程 ID |
| `emit_cancelled()` 事件 | `_handleCancelledProgress()` | 处理取消状态传播 |

### 5-A.6 取消流程的关键实现细节

**1. 取消标志的双重同步**

为确保取消状态正确传播，Flutter 版本维护了两层取消标志：

```dart
// LinglongCliRepositoryImpl 中
final Map<String, bool> _cancelFlags = {}; // 进程级取消标志

// InstallQueue 中
bool _isUserCancelled = false; // 用户取消标志
```

当用户点击取消时：
1. `InstallQueue.cancelTask()` 调用 `markUserCancelled()` 设置用户取消标志
2. `LinglongCliRepositoryImpl.cancelInstall()` 设置 `_cancelFlags[processId] = true`
3. 安装流检测到 `_cancelFlags[processId] == true`，发送 `cancelled` 状态
4. `_handleProgress()` 检测到 `cancelled` 状态，调用 `_handleCancelledProgress()`

**2. 系统级终止的返回值处理**

`cancelWithSystemKill()` 返回值的判断逻辑：

```dart
// killall 返回码含义：
// 0 - 成功找到并终止进程
// 1 - 没有找到匹配的进程（进程可能已结束）
// 其他 - 权限问题或其他错误
if (result.exitCode == 0 || result.exitCode == 1) {
  systemKillSuccess = true;
}
```

**3. 取消与失败的区分**

- `InstallStatus.cancelled`：用户主动取消，由 `markUserCancelled()` 标记
- `InstallStatus.failed`：安装过程出错，由 `markFailed()` 处理
- 在 `markFailed()` 中检查 `isUserCancelled()` 决定最终状态

---

## 六、卸载流程时序图

```mermaid
sequenceDiagram
    autonumber
    participant User as 用户
    participant UI as AppDetail/MyApps
    participant Uninstall as AppUninstallService
    participant Queue as InstallQueueProvider
    participant Process as RunningProcessProvider
    participant DL as DownloadManagerDialog
    participant CLI as LinglongCliRepository
    participant Stores as installedApps/updates/cache

    User->>UI: 点击"卸载"
    UI->>Uninstall: uninstall(appInfo, context)

    %% 新增：安装中拦截前置检查
    Uninstall->>Queue: readActiveInstallTask()
    Queue-->>Uninstall: currentTask (或 null)

    alt 有正在执行的安装/更新任务 (isProcessing=true)
        Uninstall->>UI: showUninstallBlockedDialog(activeTaskName)
        UI-->>User: 弹出拦截弹窗（暂时无法卸载）
        User-->>UI: 选择"我知道了" 或 "查看下载管理"
        alt 用户点击"查看下载管理"
            UI->>DL: showDownloadManagerDialog(context)
        end
        Uninstall-->>UI: return false（不继续卸载）
    else 无活跃安装任务
        Uninstall->>Process: 检查应用是否正在运行

        alt 正在运行
            Uninstall->>UI: 弹出确认 / 先停止应用
        end

        Uninstall->>CLI: uninstallApp(appId, version)
        CLI-->>Uninstall: result

        alt success
            Uninstall->>Stores: remove installed app（乐观更新）
            Uninstall->>Stores: refresh updates
            Uninstall->>Stores: invalidate caches
            Uninstall->>UI: button => 安装
        else failed
            Uninstall->>UI: error toast / dialog
        end
    end
```

---

## 七、列表分页状态机

### 7.1 通用分页状态机

```mermaid
stateDiagram-v2
    [*] --> InitialLoading
    InitialLoading --> Ready: first page success
    InitialLoading --> Error: first page failed
    Ready --> LoadingMore: scroll to bottom / auto load
    LoadingMore --> Ready: next page success
    LoadingMore --> Error: next page failed
    Ready --> Refreshing: visible again / manual refresh
    Refreshing --> Ready: refresh success
    Refreshing --> Error: refresh failed
    Error --> InitialLoading: retry with reset
```

### 7.2 请求代次控制时序

```mermaid
sequenceDiagram
    autonumber
    participant Page as PaginatedPage
    participant Notifier as PaginatedListNotifier
    participant API as AppRepository

    Page->>Notifier: loadPage(1, reset=true)
    Notifier->>Notifier: generation = generation + 1
    Notifier->>API: request(generation=3)

    Page->>Notifier: loadPage(1, reset=true) again
    Notifier->>Notifier: generation = generation + 1
    Notifier->>API: request(generation=4)

    API-->>Notifier: response(generation=3)
    Notifier->>Notifier: discard stale response

    API-->>Notifier: response(generation=4)
    Notifier->>Page: apply latest result
```

### 7.3 自动补页时序

```mermaid
sequenceDiagram
    participant View as PaginatedGridView
    participant Ctrl as ScrollController
    participant Notifier as PaginatedListNotifier

    View->>Ctrl: first frame rendered
    Ctrl->>View: maxScrollExtent <= viewportHeight?
    alt 内容未撑满
        View->>Notifier: loadNextPage()
    else 内容已撑满
        View->>View: wait for user scroll
    end
```

---

## 八、KeepAlive 可见性状态机

```mermaid
stateDiagram-v2
    [*] --> MountedVisible
    MountedVisible --> MountedHidden: route switched away
    MountedHidden --> MountedVisible: route switched back
    MountedHidden --> Evicted: LRU overflow / memory pressure
    Evicted --> MountedVisible: route reopened and rebuilt
```

### 8.1 隐藏态行为约束

进入 `MountedHidden` 后必须暂停：
- 自动补页
- 滚动监听
- ResizeObserver 等效逻辑
- 轮询任务
- 高频动画
- 后台刷新定时器

恢复到 `MountedVisible` 时：
- 只允许一次轻量 refresh
- 不允许重新显示首屏骨架
- 不允许重置滚动位置（除非被 LRU 淘汰）

---

## 九、更新检查时序图

```mermaid
sequenceDiagram
    autonumber
    participant Launch as LaunchController
    participant Installed as InstalledAppsProvider
    participant Updates as UpdatesProvider
    participant HTTP as AppRepository
    participant Sidebar as Sidebar

    Launch->>Installed: fetchInstalledApps()
    Installed-->>Launch: installedApps
    Launch->>Updates: checkUpdates(installedApps)
    Updates->>HTTP: appCheckUpdate(appIds)
    HTTP-->>Updates: update list
    Updates-->>Sidebar: badge count changed
    Sidebar->>Sidebar: render red dot
```

### 9.1 安装/卸载后的联动

```mermaid
sequenceDiagram
    participant Action as Install/Uninstall Controller
    participant Installed as InstalledAppsProvider
    participant Updates as UpdatesProvider
    participant Menu as Sidebar/MenuBadgeProvider
    participant Cache as AppListCacheService

    Action->>Installed: refresh()
    Action->>Updates: checkUpdates(force=true)
    Action->>Cache: invalidate related cache
    Updates-->>Menu: update count
```

---

## 十、搜索流程时序图

```mermaid
sequenceDiagram
    autonumber
    participant User as 用户
    participant TitleBar as TitleBar SearchBox
    participant Router as GoRouter
    participant Page as SearchListPage
    participant Notifier as SearchListNotifier
    participant API as AppRepository

    User->>TitleBar: 输入关键词
    User->>TitleBar: Enter
    TitleBar->>Router: go(/search_list?q=xxx)
    Router->>Page: build SearchListPage
    Page->>Notifier: search(xxx)
    Notifier->>API: getSearchAppList(xxx)
    API-->>Notifier: search results
    Notifier-->>Page: render cards
```

---

## 十一、运行中进程轮询状态机

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Polling: page visible and active
    Polling --> Success: fetch ok
    Polling --> Backoff: fetch failed
    Success --> Polling: next interval
    Backoff --> Polling: retry after 3s/6s/10s
    Polling --> Idle: page hidden or tab inactive
    Success --> Idle: page hidden or tab inactive
    Backoff --> Idle: page hidden or tab inactive
```

### 11.1 退避规则

- 第一次失败：3s 后重试
- 第二次失败：6s 后重试
- 第三次及以上：10s 后重试
- 页面隐藏时立即暂停轮询

---

## 十二、推荐补充图（后续可继续扩展）

如果你要把这套文档做成“交接即上手”的级别，后续还建议继续补：

1. **目录级依赖图**：core / application / presentation 模块依赖
2. **缓存结构图**：seed / runtime / visible-refresh 三层缓存关系
3. **Provider 依赖图**：哪些 Provider watch 哪些 Provider
4. **错误处理流转图**：用户提示、日志、上报、恢复策略
5. **窗口行为图**：最小化、最大化、关闭、托盘恢复

---

## 十三、结论

是的，**之前的文档确实缺少时序图和状态机图**，尤其对于：
- 安装队列
- KeepAlive
- 启动流程
- 搜索分页
- 更新红点联动
- 环境检测

这些地方如果没有图，多人开发时非常容易“逻辑各自脑补”。

现在这份文档补上之后，迁移资料完整度会明显上一个台阶：
- **方案**告诉你做什么
- **架构**告诉你怎么分层
- **UI 规范**告诉你怎么还原
- **路线图**告诉你怎么推进
- **任务规划**告诉你怎么多人协作
- **测试性能规范**告诉你怎么验收
- **时序图/状态机图**告诉你运行时到底怎么流转

这就比较像一套完整的迁移作战包了，而不是几篇散文。
