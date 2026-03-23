# Update Page Refresh Race Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate the update-page stale-entry bug after successful updates and prevent duplicate update actions during queue processing.

**Architecture:** Keep the existing centralized post-success sync entry, but make it execute in a deterministic order: refresh installed apps first, then recompute updates from the refreshed state. Add a small concurrency guard to the updates provider and queue-aware safeguards in the update page so stale entries cannot be re-enqueued during the transition window.

**Tech Stack:** Flutter, Riverpod, Freezed, Mockito, flutter_test

---

### Task 1: Baseline Setup And Test Harness

**Files:**
- Modify: `pubspec.lock` only if dependency resolution changes unexpectedly
- Generate: existing `*.g.dart` / `*.freezed.dart` files as required by the repo
- Test: `test/unit/application/providers/update_apps_provider_test.dart`

- [ ] **Step 1: Generate code required by the clean worktree**

Run: `/home/han/flutter/bin/dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 2: Run existing provider test baseline**

Run: `/home/han/flutter/bin/flutter test test/unit/application/providers/update_apps_provider_test.dart`
Expected: current baseline passes before new regression test is added

- [ ] **Step 3: Commit setup-only changes if generated files changed unexpectedly**

```bash
git status --short
```

### Task 2: Write Failing Sync Regression Tests

**Files:**
- Create: `test/unit/application/providers/app_collection_sync_provider_test.dart`
- Modify: `test/unit/application/providers/update_apps_provider_test.dart`

- [ ] **Step 1: Write failing test for sequential sync contract**

Cover:
- installed apps refresh must complete before update check begins
- update sync must not run from stale installed app state

- [ ] **Step 2: Run the new sync test and verify it fails for the expected reason**

Run: `/home/han/flutter/bin/flutter test test/unit/application/providers/app_collection_sync_provider_test.dart`
Expected: FAIL because sync service currently calls refresh and check concurrently

- [ ] **Step 3: Write failing test for updates provider reentry/race handling**

Cover:
- concurrent `checkUpdates()` calls should not let stale results overwrite fresh state

- [ ] **Step 4: Run the provider test and verify it fails correctly**

Run: `/home/han/flutter/bin/flutter test test/unit/application/providers/update_apps_provider_test.dart`
Expected: FAIL because current implementation lets the older request overwrite the newer result

### Task 3: Write Failing Update Page Widget Regression Test

**Files:**
- Create: `test/widget/presentation/pages/update_app/update_app_page_test.dart`

- [ ] **Step 1: Write failing widget test for queue-aware update actions**

Cover:
- “全部更新” only enqueues apps not already in queue
- stale row with completed history must not trigger duplicate enqueue while queue is active

- [ ] **Step 2: Run the widget test and verify it fails**

Run: `/home/han/flutter/bin/flutter test test/widget/presentation/pages/update_app/update_app_page_test.dart`
Expected: FAIL because the page currently maps all `updateAppsProvider.apps` items directly to update actions

### Task 4: Implement Minimal Production Fix

**Files:**
- Modify: `lib/application/providers/app_collection_sync_provider.dart`
- Modify: `lib/application/providers/update_apps_provider.dart`
- Modify: `lib/presentation/widgets/app_shell.dart`
- Modify: `lib/presentation/pages/update_app/update_app_page.dart`

- [ ] **Step 1: Make app collection sync sequential**

Implementation:
- change sync method to `Future<void>`
- await installed apps refresh
- then await updates refresh

- [ ] **Step 2: Add update-provider latest-request protection**

Implementation:
- assign a request token to each check
- ensure only the latest request writes success or error state

- [ ] **Step 3: Make update page queue-aware**

Implementation:
- filter `_updateAll()` candidates against queue state
- disable duplicate single-item update actions during active queue windows

- [ ] **Step 4: Add concise comments where the race-prevention logic is non-obvious**

### Task 5: Verify, Document, And Commit

**Files:**
- Modify: `docs/superpowers/specs/2026-03-23-update-page-refresh-race-design.md`
- Modify: `docs/superpowers/plans/2026-03-23-update-page-refresh-race-fix.md`

- [ ] **Step 1: Run focused tests**

Run:
- `/home/han/flutter/bin/flutter test test/unit/application/providers/app_collection_sync_provider_test.dart`
- `/home/han/flutter/bin/flutter test test/unit/application/providers/update_apps_provider_test.dart`
- `/home/han/flutter/bin/flutter test test/widget/presentation/pages/update_app/update_app_page_test.dart`

- [ ] **Step 2: Run targeted static analysis**

Run:
- `/home/han/flutter/bin/flutter analyze lib/application/providers/app_collection_sync_provider.dart lib/application/providers/update_apps_provider.dart lib/presentation/widgets/app_shell.dart lib/presentation/pages/update_app/update_app_page.dart test/unit/application/providers/app_collection_sync_provider_test.dart test/unit/application/providers/update_apps_provider_test.dart test/widget/presentation/pages/update_app/update_app_page_test.dart`

- [ ] **Step 3: Reconcile docs with final implementation details**

- [ ] **Step 4: Commit code and docs with conventional commits**

```bash
git add docs/superpowers/specs/2026-03-23-update-page-refresh-race-design.md \
        docs/superpowers/plans/2026-03-23-update-page-refresh-race-fix.md \
        lib/application/providers/app_collection_sync_provider.dart \
        lib/application/providers/update_apps_provider.dart \
        lib/presentation/widgets/app_shell.dart \
        lib/presentation/pages/update_app/update_app_page.dart \
        test/unit/application/providers/app_collection_sync_provider_test.dart \
        test/unit/application/providers/update_apps_provider_test.dart \
        test/widget/presentation/pages/update_app/update_app_page_test.dart
git commit -m "fix: 修复更新页刷新残留与重复更新"
```
