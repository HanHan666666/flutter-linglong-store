# Custom Category Family Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix custom category switching by converting the state layer to a `code`-keyed provider family, restore real app counts from the API response, and align custom category page size with the Rust implementation.

**Architecture:** Replace the singleton custom category notifier with a Riverpod family so each route code owns isolated query state and lifecycle. Keep the menu configuration entry point on `sidebarConfigProvider` in local mode for now, but continue fetching category app data from `/app/sidebar/apps`, using the response `total` as the displayed count and `30` as the page size.

**Tech Stack:** Flutter, Riverpod codegen, Freezed, flutter_test

---

### Task 1: Add Failing Regression Coverage

**Files:**
- Create: `test/unit/application/providers/custom_category_provider_test.dart`
- Create: `test/widget/presentation/pages/custom_category_page_test.dart`

- [ ] **Step 1: Write the failing provider tests**

Cover these behaviors:
- `customCategoryProvider('office')` and `customCategoryProvider('system')` can hold different results
- first page request sends `pageSize: 30`
- `CategoryInfo.appCount` equals API `total`

- [ ] **Step 2: Write the failing widget test**

Mount `CustomCategoryPage(code: 'office')`, then rebuild with `code: 'system'` and assert the header switches to the new localized label without throwing.

- [ ] **Step 3: Run the focused tests to verify RED**

Run:

```bash
/home/han/flutter/bin/flutter test test/unit/application/providers/custom_category_provider_test.dart
/home/han/flutter/bin/flutter test test/widget/presentation/pages/custom_category_page_test.dart
```

Expected: FAIL because the current singleton provider and page lifecycle cannot satisfy the new assertions.

- [ ] **Step 4: Commit after GREEN in Task 3**

```bash
git add test/unit/application/providers/custom_category_provider_test.dart \
  test/widget/presentation/pages/custom_category_page_test.dart
git commit -m "test: 补充自定义分类切换回归断言"
```

### Task 2: Refactor Custom Category State To A Provider Family

**Files:**
- Modify: `lib/application/providers/custom_category_provider.dart`
- Modify: `lib/presentation/pages/custom_category/custom_category_page.dart`
- Modify: `lib/application/providers/global_provider.dart`
- Modify: `lib/application/providers/setting_provider.dart`
- Modify: `lib/application/providers/custom_category_provider.g.dart`

- [ ] **Step 1: Convert the provider to a family**

Change the provider shape so `build(String code)` owns:
- active category code
- menu lookup from `sidebarConfigProvider`
- initial data load
- per-category paging state

- [ ] **Step 2: Replace fake count and page size**

Use the sidebar apps response to build:

```dart
CategoryInfo(
  code: code,
  name: resolvedName,
  appCount: apps.total,
)
```

and send `pageSize: 30` for both initial load and `loadMore`.

- [ ] **Step 3: Update page wiring**

Make `CustomCategoryPage` read/watch `customCategoryProvider(widget.code)` and remove the direct `initCategory()` lifecycle mutation. Keep pull-to-refresh and load-more routed to the family notifier for the current `code`.

- [ ] **Step 4: Fix invalidation strategy**

Remove direct invalidation of the non-family provider from global/setting locale refresh logic, and instead invalidate upstream dependencies that the family instance already reads.

- [ ] **Step 5: Regenerate Riverpod output**

Run:

```bash
/home/han/flutter/bin/dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Run focused tests to verify GREEN**

Run:

```bash
/home/han/flutter/bin/flutter test test/unit/application/providers/custom_category_provider_test.dart
/home/han/flutter/bin/flutter test test/widget/presentation/pages/custom_category_page_test.dart
```

- [ ] **Step 7: Commit the refactor**

```bash
git add lib/application/providers/custom_category_provider.dart \
  lib/presentation/pages/custom_category/custom_category_page.dart \
  lib/application/providers/global_provider.dart \
  lib/application/providers/setting_provider.dart \
  lib/application/providers/custom_category_provider.g.dart
git commit -m "fix: 重构自定义分类状态为按 code 分片"
```

### Task 3: Verify Integration And Sync Documentation

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/superpowers/specs/2026-03-22-custom-category-family-fix-design.md`

- [ ] **Step 1: Run targeted static analysis**

```bash
/home/han/flutter/bin/dart analyze \
  lib/application/providers/custom_category_provider.dart \
  lib/presentation/pages/custom_category/custom_category_page.dart \
  lib/application/providers/global_provider.dart \
  lib/application/providers/setting_provider.dart \
  test/unit/application/providers/custom_category_provider_test.dart \
  test/widget/presentation/pages/custom_category_page_test.dart
```

- [ ] **Step 2: Record the new contract**

Update `AGENTS.md` to capture:
- custom category data is keyed by `code`
- page size follows Rust parity at `30`
- header count must come from `/app/sidebar/apps` `total`

- [ ] **Step 3: Commit docs separately**

```bash
git add AGENTS.md \
  docs/superpowers/specs/2026-03-22-custom-category-family-fix-design.md \
  docs/superpowers/plans/2026-03-22-custom-category-family-fix.md
git commit -m "docs: 同步自定义分类 family 化约定"
```
