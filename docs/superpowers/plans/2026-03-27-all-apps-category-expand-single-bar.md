# All Apps Category Expand Single Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让全部应用页分类条在展开时直接复用顶部同一容器展示多行分类，不再出现下方第二块重复分类面板。

**Architecture:** 保留 `AllAppsPage` 的展开状态入口，但把展开态的 UI 收敛到 `CategoryFilterHeaderDelegate` 内部。`CategoryFilterSection` 继续作为页面 sliver 接线层，不过不再在展开时追加独立 `SliverToBoxAdapter` 面板。通过 widget test 约束展开后只保留一个分类容器和一个展开入口。

**Tech Stack:** Flutter, SliverPersistentHeader, Widget Test

---

### Task 1: 写展开态回归测试

**Files:**
- Modify: `test/widget/presentation/widgets/category_filter_section_test.dart`

- [ ] **Step 1: 写失败测试，约束展开态不再渲染下方独立面板**
- [ ] **Step 2: 运行 `flutter test test/widget/presentation/widgets/category_filter_section_test.dart`，确认先失败**
- [ ] **Step 3: 写失败测试，约束展开态仍能展示所有分类项且只存在一个分类容器**
- [ ] **Step 4: 再次运行同一测试文件，确认失败原因与预期一致**

### Task 2: 收敛分类条展开结构

**Files:**
- Modify: `lib/presentation/widgets/category_filter_header.dart`
- Modify: `lib/presentation/widgets/category_filter_section.dart`

- [ ] **Step 1: 在 `CategoryFilterHeaderDelegate` 中根据展开态切换单行横向列表和多行 `Wrap`**
- [ ] **Step 2: 让 header 高度根据展开内容自适应，并保留同一套外层容器样式和展开按钮**
- [ ] **Step 3: 移除 `CategoryFilterSection` 中展开态追加的独立面板接线**
- [ ] **Step 4: 运行 `flutter test test/widget/presentation/widgets/category_filter_section_test.dart`，确认通过**

### Task 3: 文档与验证

**Files:**
- Modify: `docs/08-pending-requirements.md`

- [ ] **Step 1: 补充分类栏展开行为说明，明确“展开后复用顶部同一容器”**
- [ ] **Step 2: 运行 `flutter analyze lib/presentation/widgets/category_filter_header.dart lib/presentation/widgets/category_filter_section.dart lib/presentation/pages/all_apps/all_apps_page.dart test/widget/presentation/widgets/category_filter_section_test.dart`**
- [ ] **Step 3: 提交本次改动，提交信息使用 `fix: 修复全部应用分类展开重复显示`**
