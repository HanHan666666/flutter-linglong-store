# Update Page Installed Snapshot Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure update-page refresh actions rebuild the installed-app snapshot from `ll-cli list --json` before recomputing available updates.

**Architecture:** Keep `AppCollectionSyncService` as the single post-change synchronization entry. Route update-page initial load, manual "check update", retry, and pull-to-refresh through that service so `installedAppsProvider.refresh()` always completes before `updateAppsProvider.checkUpdates()`.

**Tech Stack:** Flutter, Riverpod, flutter_test

---

### Task 1: Add Failing Update Page Sync Test

**Files:**
- Modify: `test/widget/presentation/pages/update_app/update_app_page_test.dart`

- [x] **Step 1: Add a widget test that records refresh order**

Add a fake `InstalledApps` notifier and a fake `UpdateApps` notifier. The test should render `UpdateAppPage`, tap the header "检查更新" button, and assert that the recorded events are `installed:refresh` before `updates:check`.

- [x] **Step 2: Run the focused widget test**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/pages/update_app/update_app_page_test.dart --plain-name "manual check refreshes installed apps before recomputing updates"
```

Expected: FAIL because the current page calls `updateAppsProvider.notifier.checkUpdates()` directly.

### Task 2: Route Update Page Refresh Through Sync Service

**Files:**
- Modify: `lib/presentation/pages/update_app/update_app_page.dart`

- [x] **Step 1: Import `app_collection_sync_provider.dart`**

Add the existing sync provider import near the other application provider imports.

- [x] **Step 2: Replace direct update checks**

Replace initial load, manual check, retry, and `RefreshIndicator.onRefresh` calls with a private `_syncUpdates()` method that calls:

```dart
ref.read(appCollectionSyncServiceProvider).syncAfterSuccessfulOperation();
```

The method should return `Future<void>` so pull-to-refresh can await it.

- [x] **Step 3: Keep UI loading semantics unchanged**

Do not change `UpdateAppsState` rendering rules, list layout, or queue-aware update buttons.

### Task 3: Update Documentation

**Files:**
- Modify: `docs/07-runtime-sequence-and-state-diagrams.md`

- [x] **Step 1: Document the update-page refresh contract**

Add a change note stating that update-page manual/initial refresh must use `AppCollectionSyncService` to refresh installed apps before recomputing updates, because `ll-cli list --json` is the installed-version source of truth.

### Task 4: Verify And Commit

**Files:**
- Verify: `test/widget/presentation/pages/update_app/update_app_page_test.dart`
- Verify: `test/unit/application/providers/app_collection_sync_provider_test.dart`
- Verify: `test/unit/application/providers/update_apps_provider_test.dart`
- Analyze: changed Dart files

- [x] **Step 1: Run focused tests**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/pages/update_app/update_app_page_test.dart test/unit/application/providers/app_collection_sync_provider_test.dart test/unit/application/providers/update_apps_provider_test.dart
```

- [x] **Step 2: Run targeted static analysis**

Run:

```bash
/home/han/flutter/bin/flutter analyze lib/presentation/pages/update_app/update_app_page.dart test/widget/presentation/pages/update_app/update_app_page_test.dart
```

- [ ] **Step 3: Commit**

Run:

```bash
git add lib/presentation/pages/update_app/update_app_page.dart test/widget/presentation/pages/update_app/update_app_page_test.dart docs/07-runtime-sequence-and-state-diagrams.md docs/superpowers/plans/2026-07-09-update-page-installed-sync.md
git commit -m "fix: 更新页检查更新前刷新已安装快照"
```
