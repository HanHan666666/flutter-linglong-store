# Header Search Single Entry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将搜索入口统一收敛到标题栏真实搜索框，用户在 header 输入并提交后进入搜索结果页，搜索页不再渲染第二个搜索框。

**Architecture:** 维持现有 `go_router + SearchListPage + searchProvider` 链路，只把“输入职责”从 `SearchListPage` 收敛到 `CustomTitleBar`。标题栏负责 query 输入与导航，搜索页负责 query 消费与结果渲染，路由继续通过 `q` 参数衔接。

**Tech Stack:** Flutter, Riverpod, go_router, flutter_test

---

### Task 1: 先锁定单一搜索入口行为

**Files:**
- Create: `test/widget/presentation/widgets/title_bar_search_test.dart`
- Create: `test/widget/presentation/pages/search_list_page_test.dart`

- [ ] **Step 1: 写标题栏搜索提交跳转的失败测试**
- [ ] **Step 2: 运行测试，确认旧实现下无法输入或无法提交 query**
- [ ] **Step 3: 写搜索页不再出现本地输入框的失败测试**
- [ ] **Step 4: 运行测试，确认旧搜索页仍存在重复搜索框**

### Task 2: 改造标题栏搜索为真实入口

**Files:**
- Modify: `lib/presentation/widgets/title_bar.dart`
- Modify: `lib/presentation/widgets/app_shell.dart`
- Modify: `lib/core/config/routes.dart`

- [ ] **Step 1: 将标题栏搜索框改为真实 `TextField`，支持回车与图标提交**
- [ ] **Step 2: 让标题栏搜索框显示当前路由 query，并统一复用 `goToSearch()`**
- [ ] **Step 3: 收敛标题栏拖拽区域，避免输入框误触发窗口拖拽**
- [ ] **Step 4: 为搜索页路由加上基于 query 的 key，明确 query 切换生命周期**

### Task 3: 把搜索页降为纯结果页

**Files:**
- Modify: `lib/presentation/pages/search_list/search_list_page.dart`

- [ ] **Step 1: 移除页内搜索框和搜索按钮**
- [ ] **Step 2: 根据 `initialQuery` 直接触发搜索或展示顶部搜索引导态**
- [ ] **Step 3: 保留结果头部、分页加载、错误态和空态**
- [ ] **Step 4: 调整无 query 文案，明确提示用户使用顶部搜索框**

### Task 4: 同步文档与项目约定

**Files:**
- Modify: `docs/03d-ui-pages.md`
- Modify: `docs/07-runtime-sequence-and-state-diagrams.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 同步搜索页交互说明为“标题栏输入后进入结果页”**
- [ ] **Step 2: 修正搜索流程时序图中的 query 参数描述**
- [ ] **Step 3: 在项目约定中记录“标题栏为唯一搜索入口”的规则**

### Task 5: 验证与提交

**Files:**
- Modify: `git index`

- [ ] **Step 1: 运行新增 widget 测试并确认 red-green**
- [ ] **Step 2: 运行相关搜索测试与 `flutter analyze`**
- [ ] **Step 3: 仅提交本次搜索入口收敛相关文件**
- [ ] **Step 4: 使用 Conventional Commit 提交**
