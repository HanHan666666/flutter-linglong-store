# Sidebar English Label Width Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent expanded desktop sidebar English labels from wrapping by widening the desktop sidebar and keeping menu labels constrained to a single line.

**Architecture:** Keep the existing sidebar structure and interactions unchanged. Limit the fix to the presentation layer by adjusting the expanded width token and aligning static menu text behavior with the existing dynamic menu single-line fallback.

**Tech Stack:** Flutter, Riverpod, flutter_test

---

### Task 1: Add Regression Coverage For Expanded English Sidebar Labels

**Files:**
- Modify: `test/widget/presentation/widgets/sidebar_test.dart`
- Verify: `test/widget/presentation/widgets/sidebar_test.dart`

- [ ] **Step 1: Write the failing widget assertion**

Add a widget test that renders the expanded sidebar under English locale and verifies:
- the expanded sidebar width is `176`
- the `Recommend` label remains in a single text widget instance

- [ ] **Step 2: Run the targeted widget test to verify RED**

Run: `flutter test test/widget/presentation/widgets/sidebar_test.dart`
Expected: FAIL before production change because expanded width is still `160`

- [ ] **Step 3: Keep test scope minimal**

Reuse the existing sidebar provider override pattern instead of introducing new helpers or mocks.

- [ ] **Step 4: Re-run targeted widget test after the production fix**

Run: `flutter test test/widget/presentation/widgets/sidebar_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/widget/presentation/widgets/sidebar_test.dart
git commit -m "test: 补充侧边栏英文文案布局断言"
```

### Task 2: Adjust Expanded Sidebar Width And Single-Line Fallback

**Files:**
- Modify: `lib/presentation/widgets/sidebar.dart`
- Verify: `test/widget/presentation/widgets/sidebar_test.dart`

- [ ] **Step 1: Implement the minimal sidebar width fix**

Change the expanded desktop sidebar width constant from `160` to `176`.

- [ ] **Step 2: Align static menu labels with dynamic menu labels**

Add `maxLines: 1`, `softWrap: false`, and `overflow: TextOverflow.ellipsis` to the static sidebar text so both static and dynamic menu items share the same single-line fallback behavior.

- [ ] **Step 3: Preserve current behavior**

Do not change collapsed width, selection rules, hover styling, bottom action layout, or routing behavior.

- [ ] **Step 4: Run the targeted verification**

Run: `flutter test test/widget/presentation/widgets/sidebar_test.dart`
Expected: PASS with the new width and the English label test green

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/sidebar.dart test/widget/presentation/widgets/sidebar_test.dart docs/superpowers/plans/2026-03-22-sidebar-english-label-width.md
git commit -m "fix: 修复侧边栏英文菜单换行"
```
