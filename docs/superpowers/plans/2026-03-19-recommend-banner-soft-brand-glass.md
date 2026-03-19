# Recommend Banner Soft Brand Glass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把推荐页轮播替换为已确认的 `Soft Brand Glass` 视觉方案，并将背景层抽离为可替换组件，支持后续图片背景与风格扩展。

**Architecture:** 保持推荐页现有三段结构与自动轮播/分页逻辑不变，只重构轮播表现层。轮播项拆分为“背景组件”和“前景内容组件”两层，背景组件负责品牌色、图标风格化背景和主题适配，前景层负责文案、按钮、点击行为和指示器。

**Tech Stack:** Flutter, Material 3, Riverpod, widget tests

---

### Task 1: 更新推荐页设计文档

**Files:**
- Modify: `docs/superpowers/specs/2026-03-19-recommend-page-rust-parity-design.md`
- Create: `docs/superpowers/plans/2026-03-19-recommend-banner-soft-brand-glass.md`

- [ ] **Step 1: 补充设计文档中的轮播视觉结论**

记录 `Soft Brand Glass` 方案、品牌色背景、轻量材质、深浅色适配和背景组件抽象边界。

- [ ] **Step 2: 保存实施计划**

记录测试优先、组件拆分、文件边界、验证命令和提交粒度。

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-03-19-recommend-page-rust-parity-design.md docs/superpowers/plans/2026-03-19-recommend-banner-soft-brand-glass.md
git commit -m "docs: 明确推荐页轮播 Soft Brand Glass 方案"
```

### Task 2: 用测试锁定新轮播结构

**Files:**
- Modify: `test/widget/presentation/pages/recommend_page_test.dart`
- Test: `test/widget/presentation/pages/recommend_page_test.dart`

- [ ] **Step 1: 写失败的 widget 测试**

覆盖以下行为：

- 推荐页轮播渲染标题、简介和详情按钮；
- 推荐页轮播渲染独立背景组件；
- 深色主题下轮播仍能正常渲染。

- [ ] **Step 2: 运行测试验证失败**

Run: `flutter test test/widget/presentation/pages/recommend_page_test.dart`

Expected: FAIL，原因是新背景组件与新轮播结构尚未实现。

- [ ] **Step 3: Commit**

```bash
git add test/widget/presentation/pages/recommend_page_test.dart
git commit -m "test: 补充推荐页轮播新视觉测试"
```

### Task 3: 抽离可替换背景组件

**Files:**
- Create: `lib/presentation/pages/recommend/widgets/recommend_banner_background.dart`
- Modify: `lib/presentation/pages/recommend/recommend_page.dart`

- [ ] **Step 1: 实现背景组件最小版本**

提供单一职责组件，入参只包含 banner 基础信息和当前主题语义：

- `title`
- `imageUrl`
- `child`

组件负责：

- 品牌色背景与轻量层次；
- 基于 icon 的风格化背景元素；
- 主色优先从 logo / icon 提取并生成同色系调色板，不能继续依赖标题 hash 直接挑色；
- 浅色/深色主题分支；
- 未来可替换实现的明确边界。

- [ ] **Step 2: 在推荐页轮播项中接入背景组件**

轮播项只保留：

- 左下信息区布局；
- 跳转按钮；
- 文案截断与可读性控制。

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/recommend/widgets/recommend_banner_background.dart lib/presentation/pages/recommend/recommend_page.dart
git commit -m "feat: 抽离推荐页轮播背景组件"
```

### Task 4: 落地 Soft Brand Glass 视觉样式

**Files:**
- Modify: `lib/presentation/pages/recommend/recommend_page.dart`
- Modify: `lib/presentation/pages/recommend/widgets/recommend_banner_background.dart`

- [ ] **Step 1: 实现 A 方案视觉结构**

包括：

- 品牌色主背景；
- 轻量光影与薄玻璃信息底座；
- logo/图标左下锚点；
- 大标题、单行简介与详情按钮；
- 指示器对比度调整。

- [ ] **Step 2: 保持与现有行为兼容**

确保不改变：

- 自动轮播暂停/恢复逻辑；
- 点击进入详情或外链逻辑；
- 推荐页整体 KeepAlive 行为。

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/recommend/recommend_page.dart lib/presentation/pages/recommend/widgets/recommend_banner_background.dart
git commit -m "feat: 应用推荐页 Soft Brand Glass 轮播样式"
```

### Task 5: 验证并清理

**Files:**
- Modify: 仅在修复验证问题时涉及

- [ ] **Step 1: 运行 widget 测试**

Run: `flutter test test/widget/presentation/pages/recommend_page_test.dart`

Expected: PASS

- [ ] **Step 2: 运行推荐页相关单测**

Run: `flutter test test/unit/application/providers/recommend_provider_test.dart`

Expected: PASS

- [ ] **Step 3: 运行静态分析**

Run: `flutter analyze`

Expected: 0 error，0 warning

- [ ] **Step 4: 如有问题则最小修复并再次验证**

- [ ] **Step 5: Commit**

```bash
git add <fixed-files>
git commit -m "fix: 修正推荐页轮播回归问题"
```
