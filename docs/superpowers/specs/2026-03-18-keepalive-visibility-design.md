# KeepAlive 页面显式可见性驱动设计

## 背景

当前 Flutter 商店希望对 KeepAlive 页面统一执行“显示时恢复副作用，隐藏时立即暂停副作用”的策略，`玲珑进程` 页的 3 秒轮询也是建立在这个前提上。

但现有实现把可见性变化主要绑定在 `KeepAlivePageWrapper.activate()/deactivate()` 上，这对 ShellRoute 下的页面切换并不可靠。实际结果是：

1. `我的应用 / 玲珑进程` 切到其他页面后，旧页面仍可能保持 `mountedVisible` 状态。
2. `runningProcessProvider` 继续认为“页面可见 && 进程 Tab 激活”，定时器每 3 秒执行一次。
3. `ll-cli ps` 与补齐详情用的 `ll-cli list --json --type=all` 会持续打印日志，违反“隐藏页必须暂停副作用”的约束。

## 目标

1. 路由切换时必须显式驱动 KeepAlive 页面 `visible/hidden` 状态，不再依赖 `activate()/deactivate()` 猜生命周期。
2. 保持 `runningProcessProvider` 现有职责不变，仍由“进程 Tab 激活 && 页面可见”控制轮询。
3. 修复方案应对整个 KeepAlive 页面体系生效，而不是只对 `玲珑进程` 做局部补丁。

## 非目标

1. 不改动 `runningProcessProvider` 的轮询间隔、失败退避和数据来源。
2. 不移除 `我的应用` 页或其他首页分支的 KeepAlive 策略。
3. 不引入新的页面轮询机制或额外的全局 Timer。

## 根因分析

### 现状链路

1. `AppShell` 会根据 `GoRouterState.of(context).matchedLocation` 知道当前激活路由。
2. KeepAlive 页面通过 `KeepAlivePageWrapper` 包装，并在内部持有 `_isVisible`。
3. `VisibilityAwareMixin` 通过 `VisibilityInherited` 感知 `_isVisible` 变化，再调用页面自己的 `onVisibilityChanged()`。

### 问题点

`KeepAlivePageWrapper` 虽然提供了 `setAsVisible()` / `setAsHidden()`，但当前项目里没有任何地方在路由切换时调用它们，导致包装器并未真正收到“当前路由变了”的显式通知。

## 方案

### 1. 引入 KeepAlive 页面注册表

在路由配置层维护一个轻量的全局注册表：

- `register(routePath, state)`
- `unregister(routePath, state)`
- `syncVisibleRoute(currentPath)`

注册表只负责保存当前仍挂载的 `KeepAlivePageWrapperState`，并在路由变化时把当前页面设为 visible，其余已注册页面设为 hidden。

### 2. AppShell 显式同步当前可见路由

`AppShell` 已经天然持有 `currentPath`，因此它应该在：

1. 首次挂载后
2. `currentPath` 变化后

主动调用注册表的 `syncVisibleRoute(currentPath)`。

这样当前路由就是唯一事实来源，页面可见性不再依赖 Flutter 对 keep-alive route 生命周期的隐式行为。

### 3. KeepAlivePageWrapper 负责状态落地

`KeepAlivePageWrapperState` 在 `initState()` 时注册，在 `dispose()` 时注销；`setAsVisible()` / `setAsHidden()` 继续复用现有 `_updateVisibility()` 逻辑，保持：

- `VisibilityInherited` 的依赖更新
- `PageVisibilityManager` 的状态同步
- 子树 `VisibilityAwareMixin` 的通知分发

### 4. 业务层保持不变

`MyAppsPage` 和 `runningProcessProvider` 不改业务判断：

- 进入 `玲珑进程` Tab 仍然 `setProcessTabActive(true)`
- 切离 tab 或页面隐藏仍然停止轮询

本次修复只解决“页面隐藏事件没有被可靠触发”的基础设施问题。

## 测试策略

1. Widget 测试：验证注册表在显式切换可见路由时，会把旧页面从 visible 切到 hidden，把新页面切到 visible。
2. Widget 测试：验证 `AppShell` 在 `currentPath` 变化时会调用显式同步，从而让路由切换真正驱动隐藏事件。
3. 最小回归验证：运行 `running_process_provider` 相关测试与可见性测试，确保不破坏现有状态机。

## 风险与取舍

### 风险

1. 全局注册表如果不在 `dispose()` 正确注销，可能留下悬空 state。
2. `AppShell` 若在 build 中直接同步而不做去重，可能产生重复 post-frame 调度。

### 取舍

相比仅给 `玲珑进程` 页面单独打补丁，统一修复可见性框架能让推荐页、列表页等所有 KeepAlive 页面都站在同一条可靠机制上，后续副作用暂停逻辑也不会继续漂移。
