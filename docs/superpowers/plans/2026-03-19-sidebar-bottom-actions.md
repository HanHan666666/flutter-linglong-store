# Sidebar Bottom Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将侧边栏底部三项改成固定纵向菜单，并把顶部导航收敛为推荐、全部、排行与动态菜单。

**Architecture:** 维持现有 `Sidebar` 的“上部滚动 + 下部固定”结构，只调整静态菜单数据源与底部渲染方式。底部区域复用主菜单的视觉结构，`下载管理` 继续保留动作为弹窗，其余项保持路由高亮。

**Tech Stack:** Flutter, Riverpod, go_router, flutter_test

---

### Task 1: 先锁定侧边栏顺序行为

**Files:**
- Create: `test/widget/presentation/widgets/sidebar_test.dart`

- [x] **Step 1: 写失败测试**
- [x] **Step 2: 运行测试确认因旧侧边栏结构失败**
- [x] **Step 3: 断言顶部菜单、动态菜单和底部菜单顺序**

### Task 2: 调整 Sidebar 结构

**Files:**
- Modify: `lib/presentation/widgets/sidebar.dart`
- Modify: `lib/presentation/widgets/app_shell.dart`

- [x] **Step 1: 收敛顶部静态菜单为推荐/全部/排行**
- [x] **Step 2: 将底部区域改为固定纵向菜单**
- [x] **Step 3: 保留自动折叠与下载管理弹窗行为**
- [x] **Step 4: 移除无用的更新红点订阅，减少侧边栏重建**

### Task 3: 更新回归测试与文档

**Files:**
- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`
- Modify: `docs/03a-ui-design-tokens.md`
- Modify: `docs/03b-ui-layout-components.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 调整受导航文案影响的旧测试断言**
- [ ] **Step 2: 同步 UI 规范中的侧边栏结构说明**
- [ ] **Step 3: 在项目约定中记录新的侧边栏导航规则**

### Task 4: 验证与提交

**Files:**
- Modify: `git index`

- [ ] **Step 1: 运行相关 widget 测试**
- [ ] **Step 2: 运行 `flutter analyze` 做静态校验**
- [ ] **Step 3: 仅提交本次侧边栏相关文件**
- [ ] **Step 4: 使用 Conventional Commit 提交**
