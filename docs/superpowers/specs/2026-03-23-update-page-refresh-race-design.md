# 更新页刷新竞态修复设计

## 背景

Flutter 商店当前的更新页在“一键更新”或单个更新成功后，会通过全局成功监听触发安装集合同步。但现有同步链路存在时序竞态：

1. 安装成功后同时触发 `installedAppsProvider.refresh()` 与 `updateAppsProvider.checkUpdates()`。
2. `updateAppsProvider.checkUpdates()` 会立即同步读取当前 `installedAppsProvider` 的旧值。
3. 如果刚更新完成的应用尚未写回 installed apps，更新检查会继续基于旧版本计算，导致已更新应用仍被保留在“可更新列表”中。
4. 更新页列表项在成功态后会回退为普通“更新”按钮，因此脏数据会直接表现为“更新完仍可继续更新”。

这与用户观察到的现象一致：一键更新完成其中一个应用后，列表刷新仍保留该应用，且按钮可再次点击。

## 目标

1. 安装/更新成功后的 installed apps 与 updates 刷新必须基于一致的数据快照执行。
2. 更新页在队列执行过程中和成功收尾阶段，不能让已完成任务因为脏列表重新进入可点击状态。
3. 为该问题补充稳定的单元/Widget 回归测试，覆盖“成功后残留”和“活跃队列防重复点击”两个用户视角。

## 非目标

1. 不改动安装队列串行执行模型。
2. 不引入新的 ll-cli 调用方式。
3. 不重构更新页整体 UI 结构，只修复与本次缺陷直接相关的状态流。

## 根因分析

### 1. 成功后的同步顺序错误

`AppCollectionSyncService.syncAfterSuccessfulOperation()` 当前采用 fire-and-forget 并发触发：

- `installedAppsProvider.refresh()`
- `updateAppsProvider.checkUpdates()`

而 `checkUpdates()` 只有在 installed apps 为空时才会主动等待刷新，因此在大多数真实场景中都会直接读取旧的 installed apps 版本。

### 2. 更新页缺少队列感知过滤

更新页的一键更新入口直接使用 `updateAppsProvider.apps` 全量映射任务，没有先过滤已经在当前队列中的 app。单项按钮也没有在“存在任意活跃任务且本项已成功完成但列表尚未剔除”时禁止再次点击。

这让竞态带来的脏数据可以进一步升级为重复入队行为。

## 方案

### 方案 A：顺序同步 + 队列感知 UI 防护（推荐）

1. 把 `AppCollectionSyncService.syncAfterSuccessfulOperation()` 改为 `Future<void>`。
2. 先 `await installedAppsProvider.refresh()`，确认 installed apps 状态更新完成。
3. 再 `await updateAppsProvider.checkUpdates()`，让更新列表基于新 installed apps 重新计算。
4. 为 `updateAppsProvider` 增加轻量并发保护，避免页面初始化、手动刷新、成功收尾三者并发时发生“旧响应覆盖新响应”。
5. 更新页渲染时按 `appId` 感知当前活跃队列：
   - 一键更新前先过滤已在队列中的 app。
   - 单项按钮在本项处于队列中时显示 loading。
   - 单项按钮在存在活跃队列且本项刚成功但尚未从更新列表移除时，不允许再次点击。

优点：

- 根因修复，数据一致性最强。
- 改动集中在 Application/Presentation 层，符合当前架构。
- 测试边界清晰，可稳定回归。

缺点：

- 成功收尾由并发改为顺序后，更新列表刷新会略晚于 installed apps，但这是可接受且正确的时序。

### 方案 B：仅在 `checkUpdates()` 内等待 installed apps 刷新

保留同步服务调用方式，但给 installed apps provider 增加“刷新中的 Future”，`checkUpdates()` 如果发现 installed apps 正在刷新就先等待。

优点：

- 表面改动范围更小。

缺点：

- provider 间耦合更重。
- 不如方案 A 直接表达业务时序。

### 方案 C：成功后乐观移除更新项

任务成功时直接从 `updateAppsProvider` 删除当前 app，再异步后台刷新。

优点：

- 用户可见症状能很快消失。

缺点：

- 只是掩盖症状，不解决更新检查读取旧 installed apps 的根因。
- 遇到多版本、多架构场景容易删错。

## 选型

采用方案 A。

原因：

1. 直接修复“旧 installed state 驱动新 updates state”这个根因。
2. 改动面可控，不需要引入跨 provider 的复杂等待协议。
3. 可以顺手补齐更新页和 Rust 版一致的队列过滤行为，避免脏数据二次放大。

## 实现要点

1. `AppCollectionSyncService` 改为顺序同步，并保留统一入口职责。
2. `AppShell` 监听安装成功后继续复用该同步服务，但以 `unawaited()` 调用异步方法，不阻塞 UI 线程。
3. `UpdateApps` provider 增加并发保护：
   - 每次 `checkUpdates()` 分配新的 request id。
   - 只有最后一次请求允许写回 state，旧响应直接丢弃。
4. `UpdateAppPage`：
   - `_updateAll()` 只入队未在当前队列中的 app。
   - 列表项根据 `InstallQueueState` 计算是否允许点击。
5. 补测试：
   - 单元测试：成功同步必须先刷新 installed apps，再检查 updates。
   - 单元测试：并发 `checkUpdates()` 不应使用旧 installed apps 结果覆盖。
   - Widget 测试：更新页在活跃队列下不重复入队已在队列中的 app。

## 风险

1. `AppShell` 成功监听中如果直接 `await`，可能让监听回调依赖异步执行；应继续 fire-and-forget，只把服务内部改为顺序。
2. `updateAppsProvider` 增加并发保护后，测试需要覆盖重复调用场景，避免最后一次请求被旧响应回写覆盖。
3. 更新页按钮状态需要避免影响正常的单项更新交互，禁用条件必须只针对“本项已在队列中”或“当前列表仍是脏数据窗口”。

## 验证

1. 失败测试先证明：
   - 顺序错误时，`checkUpdates()` 会读取旧 installed apps。
   - 更新页会对脏列表中的已完成 app 继续触发 `onUpdate`。
2. 修复后运行：
   - `flutter test test/unit/application/providers/update_apps_provider_test.dart`
   - `flutter test test/unit/application/providers/app_collection_sync_provider_test.dart`
   - `flutter test test/widget/presentation/pages/update_app/update_app_page_test.dart`
   - 必要时运行相关现有测试文件，防止下载管理和安装按钮回归。
