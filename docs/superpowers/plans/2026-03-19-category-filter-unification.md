# Category Filter Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 收敛推荐页与全部应用页的分类筛选栏页面接线与骨架屏，并移除展开态内部滚动条。

**Architecture:** 保留 `CategoryFilterHeaderDelegate` 作为固定高度顶部栏；新增 `CategoryFilterSection` 统一 sliver 接线，并在展开时追加独立 sliver 面板，让页面主滚动容器承担滚动。分类骨架屏抽为共享展示组件。

**Tech Stack:** Flutter, Riverpod, Widget Test

---

### Task 1: 写回归测试

**Files:**
- Create: `test/widget/presentation/widgets/category_filter_section_test.dart`
- Modify: `lib/presentation/widgets/widgets.dart`

- [ ] **Step 1: 写一个失败测试，约束展开态不再依赖内部滚动容器**
- [ ] **Step 2: 运行该测试，确认先失败**
- [ ] **Step 3: 写一个失败测试，约束公共组件能渲染固定头部与展开面板**
- [ ] **Step 4: 运行测试，确认失败原因正确**

### Task 2: 实现共享分类栏封装

**Files:**
- Modify: `lib/presentation/widgets/category_filter_header.dart`
- Create: `lib/presentation/widgets/category_filter_section.dart`
- Modify: `lib/presentation/widgets/widgets.dart`

- [ ] **Step 1: 保留 `CategoryFilterHeaderDelegate`，移除其内部展开滚动实现**
- [ ] **Step 2: 新增 `CategoryFilterSection`，统一 sliver 接线**
- [ ] **Step 3: 新增 `CategoryFilterSkeleton`，抽离公共骨架屏**
- [ ] **Step 4: 运行新增测试，确认通过**

### Task 3: 页面接入共享组件

**Files:**
- Modify: `lib/presentation/pages/recommend/recommend_page.dart`
- Modify: `lib/presentation/pages/all_apps/all_apps_page.dart`

- [ ] **Step 1: 推荐页切换到共享分类栏封装**
- [ ] **Step 2: 全部应用页切换到共享分类栏封装**
- [ ] **Step 3: 使用共享分类骨架屏替换页面内重复实现**
- [ ] **Step 4: 运行相关 widget test / analyze，确认没有回归**
