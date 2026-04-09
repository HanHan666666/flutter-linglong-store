# Shell KeepAlive Simplification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 按任务逐项执行。步骤使用 `- [ ]` 复选框语法。

**Goal:** 用 Flutter 内置能力替换当前自定义 KeepAlive/可见性系统，在不抬高内存占用的前提下，显著降低路由与页面生命周期代码复杂度。

**Architecture:** 保留现有 `ShellRoute + AppShell + Sidebar` 结构，但把“主侧边栏页面的保活”收敛到 `AppShell` 内部的懒加载 `IndexedStack`。主页面只保留 4 个固定根页面（推荐 / 全部 / 排行 / 我的应用）常驻；搜索、设置、更新、详情、自定义分类继续走普通路由，不参与保活。页面副作用暂停/恢复不再依赖全局注册表，而改为一个很小的“当前主页面是否激活”作用域。

**Tech Stack:** Flutter, go_router 14.6.x, Riverpod, Widget Test, Integration Test, Flutter DevTools（内存验证）

---

## 先给结论

### 1. 当前 KeepAlive 可以换成 Flutter 内置方案吗？

**可以，而且应该换。**

但这次建议的“内置方案”不是继续造一套复杂路由缓存系统，也不是优先选 `StatefulShellRoute`。

这次推荐的目标方案是：

- 用 **Flutter 内置 `IndexedStack`** 承载 4 个固定主页面
- 用 **懒加载缓存集合** 控制只在用户首次访问某个主页面时才真正创建该页面
- 用 **普通 `GoRoute`** 承载搜索 / 设置 / 更新 / 详情 / 自定义分类等二级页面
- 用一个 **极小的主页面激活作用域** 替代当前 `KeepAlivePageRegistry + PageVisibilityManager + KeepAliveVisibilitySync + VisibilityAwareMixin` 这一整套体系

### 2. 为什么这次不把方案主轴定成 `StatefulShellRoute.indexedStack`？

`StatefulShellRoute` 本身没问题，但**不适合作为这次整改的第一选择**，原因不是它差，而是当前项目的页面结构更适合更简单的方案。

当前项目不是只有 4 个侧边栏根页面，还存在这些“共享同一壳层、但不该常驻”的页面：

- `/search_list`
- `/setting`
- `/update_apps`
- `/custom_category/:code`
- `/app/:id`

如果以 `StatefulShellRoute` 为核心，要么：

1. 把这些页面塞进分支导航栈里，带来分支路由和页面驻留的额外复杂度；
2. 要么把它们放到外层，再想办法保证主分支切换状态不丢，这很容易重新长回一套“糊屎型”粘合代码。

而 `AppShell` 内部懒加载 `IndexedStack` 的方案，对当前产品模型更贴合：

- 主侧边栏就是 4 个固定根页面
- 二级页面不是主导航的一部分
- 需要保活的对象很稳定，数量固定
- 内存上限容易推导，不需要 LRU

一句话：**这次不是为了追求“更高级的路由 API”，而是为了把问题收缩到最简单的固定边界里。**

---

## 这次整改的边界

### 纳入本次方案的内容

#### A. KeepAlive 主重构（必须做）

- 删除自定义 KeepAlive 页面注册 / 通知 / 管理体系
- 删除全局页面可见性状态机
- 用 `AppShell` 内部懒加载 `IndexedStack` 取代当前主页面保活逻辑
- 用一个很小的主页面激活作用域驱动副作用暂停 / 恢复
- 仅保活 4 个固定主页面

#### B. 与 KeepAlive 强相关的收尾（同批做）

- 删除 `KeepAlivePaintGate`、`KeepAliveVisibilitySync` 等旧基础设施
- 删除旧测试并新增新测试
- 去掉 4 个主页面上的 `AutomaticKeepAliveClientMixin`
- 去掉 4 个主页面对旧 `VisibilityAwareMixin` 的依赖
- 非主页面取消不必要的“伪可见性逻辑”

#### C. 低风险附带优化（建议同一个整改包的后半段做）

- 删除遗留死代码 `ProcessManager`
- 统一 `sidebar.dart` 中重复的 hover 交互壳

### 不纳入同一批的内容

这些不是不做，而是**不应该和 KeepAlive 主重构捆成一个 PR**：

- `GlobalApp` 大 Provider 的彻底拆分
- 安装文案本地化边界上移（`InstallMessages` 收敛）
- 主题系统进一步去重
- 安装状态机改写成 Freezed union

原因很简单：

- 它们和 KeepAlive 不是一个问题域
- 捆在一起会让回归面扩大
- 更便宜的 AI 一次处理太多概念，失败率会明显上升

这几项会单独放在后面的补充文档里，按“第二波 / 第三波”执行。

---

## 改造完成后的目标架构

## 结构目标

```text
GoRouter
└── ShellRoute
    └── AppShell
        ├── TitleBar
        ├── Sidebar
        └── ContentArea
            ├── PrimaryStackHost (懒加载 IndexedStack)
            │   ├── RecommendPage
            │   ├── AllAppsPage
            │   ├── RankingPage
            │   └── MyAppsPage
            └── SecondaryRouteOverlay (普通 GoRoute child)
                ├── SearchListPage
                ├── SettingPage
                ├── UpdateAppPage
                ├── CustomCategoryPage
                └── AppDetailPage
```

## 生命周期目标

### 主页面

- 首次访问时创建
- 之后常驻在 `IndexedStack`
- 不再依赖路由切换时的显式 show/hide 注册表
- 非激活时：
  - 不绘制
  - 不接收点击
  - 不参与焦点
  - 不跑 ticker
  - 页面内部副作用主动暂停

### 二级页面

- 按现有普通 `GoRoute` 构建
- 离开即释放
- 不参与主页面保活
- 不把自己塞进新的 KeepAlive 体系

### 内存规则

- **常驻页面固定 4 个**：推荐 / 全部 / 排行 / 我的应用
- 不再对所有 Shell 页面做“看起来像 KeepAlive 的统一包装”
- 不保活详情页、搜索页、设置页、更新页、自定义分类页
- 不引入额外 LRU 缓存层

这意味着这次整改之后，内存边界是**稳定且可预测**的：

- 常驻部分：4 个主页面
- 浮动部分：当前二级页面 1 个
- 不会再出现“壳层逻辑以为页面被隐藏了，实际上树里还挂着一串东西”的情况

---

## 要删除的旧文件 / 旧概念

以下内容是这次 KeepAlive 重构的主要清理目标。

### 必删文件

- `lib/core/config/keepalive_visibility_sync.dart`
- `lib/core/config/page_visibility.dart`
- `lib/core/config/visibility_aware_mixin.dart`
- `lib/core/config/keepalive_paint_gate.dart`

### 必删类型 / 概念

- `KeepAlivePageRegistry`
- `KeepAliveVisibilityBinding`
- `KeepAliveVisibilitySync`
- `ShellRouteVisibilityScope`
- `PageVisibilityManager`
- `PageVisibilityStatus`
- `PageVisibilityEvent`
- `VisibilityInherited`
- `KeepAlivePageWrapper`
- `KeepAlivePageWrapperState`
- `PageCacheManager`
- `NavigationBranch`
- `navigationIndexProvider`
- `NavigationIndexNotifier`
- `keepAliveRoutes`
- `maxCachedPages`

### 必删测试

- `test/widget/core/config/keepalive_paint_gate_test.dart`
- `test/widget/core/config/keepalive_visibility_sync_test.dart`

---

## 本次新增的核心文件

### 新文件（KeepAlive 主重构）

- `lib/core/config/shell_primary_route.dart`
  - 负责定义 4 个主页面枚举和路径映射
- `lib/core/config/shell_branch_visibility.dart`
  - 负责提供主页面是否激活的极小作用域与 mixin
- `test/widget/core/config/shell_branch_visibility_test.dart`
  - 验证新可见性作用域与 mixin 行为
- `test/widget/presentation/widgets/app_shell_primary_stack_test.dart`
  - 验证 `AppShell` 的懒加载 `IndexedStack` 保活逻辑

### 后续附带清理新增文件

- `lib/presentation/widgets/sidebar_interaction_surface.dart`
  - 抽取侧边栏通用 hover / active / tap 交互壳

---

## 需要修改的核心文件

### KeepAlive 主线

- `lib/core/config/routes.dart`
- `lib/presentation/widgets/app_shell.dart`
- `lib/presentation/pages/recommend/recommend_page.dart`
- `lib/presentation/pages/all_apps/all_apps_page.dart`
- `lib/presentation/pages/ranking/ranking_page.dart`
- `lib/presentation/pages/my_apps/my_apps_page.dart`
- `lib/presentation/pages/custom_category/custom_category_page.dart`

### 同批验证相关

- `test/widget/presentation/widgets/sidebar_test.dart`
- `integration_test/app_test.dart`（如果当前已有导航级验证入口）

### 第二波附带优化

- `lib/core/platform/process_manager.dart`（删除）
- `lib/presentation/widgets/sidebar.dart`

---

## 文档阅读顺序

把这套文档交给执行方时，按这个顺序读：

1. `00-overview.md` —— 先理解边界与目标
2. `01-core-router-and-shell.md` —— 先改壳层与路由
3. `02-page-migration.md` —— 再迁移各页面
4. `03-secondary-cleanups.md` —— 最后做附带优化
5. `04-validation-rollout.md` —— 跑验证、拆 commit、做回滚预案

---

## 推荐的 PR / commit 切分

### PR 1：KeepAlive 主重构

目标：只完成主页面保活架构替换。

包含：

- `routes.dart`
- `app_shell.dart`
- `shell_primary_route.dart`
- `shell_branch_visibility.dart`
- 4 个主页面迁移
- `custom_category_page.dart` 清理
- 旧 KeepAlive 文件删除
- 新旧测试替换

### PR 2：导航侧边栏附带清理

包含：

- 删除 `ProcessManager`
- 抽侧边栏 hover 交互壳
- `sidebar.dart` 去重复

### PR 3：状态 / 边界后续清理

包含：

- `GlobalApp` 拆分
- `InstallMessages` 边界整改

不要把 3 个 PR 混成 1 个，否则廉价 AI 很容易在回归时把锅背满。

---

## 这次最重要的执行原则

### 原则 1：不要在新方案里偷偷长回第二套可见性状态机

允许新增的只有：

- 主页面枚举
- 当前激活主页面作用域
- 一个极小的激活变化 mixin

**不允许**重新出现：

- 全局注册表
- 路由路径到 state 的手工同步表
- 页面显式 mount/unmount 状态机
- “缓存页列表 + 手工 show/hide 回调”这种老毛病

### 原则 2：主页面数固定，拒绝 LRU

当前主导航只有 4 个固定页面。

因此：

- 不要重新引入 `PageCacheManager`
- 不要为“未来可能有更多页面”提前设计淘汰机制
- 不要把所有壳层页面都塞进同一套缓存策略

### 原则 3：二级页面不是主页面

以下页面一律视为二级页面，不参与保活：

- 搜索
- 设置
- 更新
- 自定义分类
- 应用详情

后续如果有人提议“顺手也把这些保活一下”，默认拒绝，除非先有内存与体验证据。

---

## 执行入口

具体实施步骤见：

- `01-core-router-and-shell.md`
- `02-page-migration.md`
- `03-secondary-cleanups.md`
- `04-validation-rollout.md`
