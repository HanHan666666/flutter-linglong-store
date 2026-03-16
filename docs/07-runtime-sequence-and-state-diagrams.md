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

### 2.1 冷启动主流程

```mermaid
sequenceDiagram
    autonumber
    participant User as 用户
    participant App as Flutter App
    participant Main as main.dart
    participant Window as WindowManager
    participant Store as Local Storage
    participant Launch as LaunchController
    participant CLI as LinglongCliRepository
    participant HTTP as AppRepository
    participant Providers as Riverpod Providers
    participant Home as RecommendPage

    User->>App: 启动应用
    App->>Main: 执行 main()
    Main->>Main: WidgetsFlutterBinding.ensureInitialized()
    Main->>Main: SingleInstance.ensure()
    Main->>Main: NvidiaWorkaround.apply()
    Main->>Window: 初始化窗口参数
    Main->>Store: 初始化 Preferences / Cache
    Main->>Providers: 初始化全局 Provider 容器
    Main->>App: runApp()
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
        Launch->>HTTP: sendVisitRecord()
        Launch->>Home: 跳转 RecommendPage
    end
```

### 2.2 启动阶段约束

启动流程必须满足：
- 环境检测先于主内容渲染
- 已安装列表先于更新检查
- 更新检查先于菜单红点展示
- install queue 恢复必须在首页交互前完成
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

## 六、卸载流程时序图

```mermaid
sequenceDiagram
    autonumber
    participant User as 用户
    participant UI as AppDetail/MyApps
    participant Uninstall as AppUninstallController
    participant Process as RunningProcessProvider
    participant CLI as LinglongCliRepository
    participant Stores as installedApps/updates/cache

    User->>UI: 点击“卸载”
    UI->>Uninstall: uninstall(appInfo)
    Uninstall->>Process: 检查应用是否正在运行

    alt 正在运行
        Uninstall->>UI: 弹出确认 / 先停止应用
    end

    Uninstall->>CLI: uninstallApp(appId, version)
    CLI-->>Uninstall: result

    alt success
        Uninstall->>Stores: remove installed app
        Uninstall->>Stores: refresh updates
        Uninstall->>Stores: invalidate caches
        Uninstall->>UI: button => 安装
    else failed
        Uninstall->>UI: error toast / dialog
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
    TitleBar->>Router: go(/search_list?keyword=xxx)
    Router->>Page: build SearchListPage
    Page->>Notifier: reset + loadPage(1)
    Notifier->>API: getSearchAppList(keyword)
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