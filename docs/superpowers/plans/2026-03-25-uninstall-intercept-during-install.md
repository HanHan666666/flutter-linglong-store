# Uninstall Intercept During Active Install Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When any uninstall entry is clicked while an install/update task is active, block the uninstall flow and show an explanatory dialog with `我知道了` and `查看下载管理`, instead of entering the uninstall confirmation flow.

**Architecture:** Keep uninstall interception centralized in `AppUninstallService`, because current uninstall entry points already converge there. Add one dedicated dialog helper for the new interaction, wire the install queue snapshot into the service through `appUninstallServiceProvider`, and reuse the existing `showDownloadManagerDialog(context)` entry for the secondary action.

**Tech Stack:** Flutter, Riverpod, existing install queue provider, shared dialog widgets, Flutter widget tests, ARB-based localization.

---

## File Map

**Create:**
- `lib/presentation/widgets/uninstall_blocked_dialog.dart`
- `test/widget/presentation/widgets/uninstall_blocked_dialog_test.dart`

**Modify:**
- `lib/application/services/app_uninstall_service.dart`
- `lib/application/providers/app_uninstall_provider.dart`
- `lib/core/i18n/l10n/app_zh.arb`
- `lib/core/i18n/l10n/app_en.arb`
- `lib/core/i18n/l10n/app_localizations.dart`
- `lib/core/i18n/l10n/app_localizations_zh.dart`
- `lib/core/i18n/l10n/app_localizations_en.dart`
- `docs/07-runtime-sequence-and-state-diagrams.md`
- `AGENTS.md`

**Existing entry points that should stay thin and unchanged except for verification:**
- `lib/presentation/pages/my_apps/my_apps_page.dart`
- `lib/presentation/pages/app_detail/app_detail_page.dart`

**Test files to run:**
- `test/widget/application/services/app_uninstall_service_test.dart`
- `test/widget/presentation/widgets/uninstall_blocked_dialog_test.dart`
- `test/widget/presentation/widgets/download_manager_dialog_test.dart`

## Current Behavior Summary

- Current Flutter uninstall entry points already converge to `appUninstallServiceProvider`.
- `AppUninstallService.uninstall()` currently checks running processes first, then shows uninstall confirmation, then calls the CLI uninstall.
- Install/update state is available from `installQueueProvider.currentTask`.
- The app already has a reusable download manager dialog entry: `showDownloadManagerDialog(context)`.
- The upstream `ll-cli`/`ll-package-manager` task model is single-queue serial execution, so this feature is an explicit UI guard for a real upstream constraint, not a fake frontend-only restriction.

## Scope Rules

- Do **not** add a new uninstall queue.
- Do **not** auto-cancel install/update and then continue uninstall.
- Do **not** duplicate “active install guard” logic inside `MyAppsPage` or `AppDetailPage`.
- Do **not** add snackbars for this path; the interaction must be modal and explanatory.
- Do **not** change install queue semantics; only consume `currentTask` / active task state.

## Interaction Contract

- Trigger condition: there is an active install or update task when uninstall is requested.
- Block behavior: do not show the normal uninstall confirm dialog.
- Modal copy:
  - Title: `暂时无法卸载`
  - Message: `当前正在安装/更新「{activeTaskName}」。玲珑暂不支持同时执行安装和卸载。请等待当前任务完成，或先取消当前任务后再卸载。`
- Buttons:
  - Secondary: `我知道了`
  - Primary: `查看下载管理`
- `我知道了`: close dialog and end the uninstall flow with `false`.
- `查看下载管理`: close dialog first, then open `showDownloadManagerDialog(context)`, then end the uninstall flow with `false`.

## Assumptions For The Worker

- Use the active task’s `appName` when available; fall back to `appId` if the name is empty.
- Use the same copy for both install and update, with the operation fragment resolved from `InstallTaskKind`.
- Open download manager only after the intercept dialog is dismissed; do not stack two dialogs on top of each other in one `showDialog` frame.
- Treat queued-but-not-yet-started tasks as **not** blocking for this feature. Only the active task (`currentTask`) should trigger the intercept dialog.

### Task 0: Create Isolated Worktree And Capture Baseline

**Files:**
- Modify: none
- Test: none

- [ ] **Step 1: Create a dedicated worktree and branch**

Run:

```bash
git worktree add .worktrees/uninstall-intercept -b feat/uninstall-intercept-dialog
```

Expected: new worktree created at `.worktrees/uninstall-intercept`

- [ ] **Step 2: Switch all implementation commands to the worktree**

Run:

```bash
cd /home/han/linglong-store/flutter-linglong-store/.worktrees/uninstall-intercept
git status --short
```

Expected: clean or intentionally dirty status understood before edits

- [ ] **Step 3: Read the shared uninstall and download manager entry points before changing anything**

Check:

```bash
sed -n '1,220p' lib/application/services/app_uninstall_service.dart
sed -n '640,690p' lib/presentation/widgets/download_manager_dialog.dart
sed -n '1,220p' lib/application/providers/app_uninstall_provider.dart
```

Expected: confirm shared uninstall entry and reusable download manager helper

### Task 1: Add A Dedicated Intercept Dialog With Tests First

**Files:**
- Create: `lib/presentation/widgets/uninstall_blocked_dialog.dart`
- Create: `test/widget/presentation/widgets/uninstall_blocked_dialog_test.dart`
- Modify: `lib/core/i18n/l10n/app_zh.arb`
- Modify: `lib/core/i18n/l10n/app_en.arb`
- Modify: `lib/core/i18n/l10n/app_localizations.dart`
- Modify: `lib/core/i18n/l10n/app_localizations_zh.dart`
- Modify: `lib/core/i18n/l10n/app_localizations_en.dart`

- [ ] **Step 1: Write the failing widget test for the intercept dialog**

Test cases to add in `test/widget/presentation/widgets/uninstall_blocked_dialog_test.dart`:

```dart
testWidgets('shows active task name and both actions', ...)
testWidgets('returns acknowledge when tapping 我知道了', ...)
testWidgets('returns openDownloadManager when tapping 查看下载管理', ...)
```

Assertions:
- dialog title is shown
- active task app name is interpolated
- both actions are present
- returned decision matches the tapped action

- [ ] **Step 2: Run the new test to verify it fails**

Run:

```bash
flutter test test/widget/presentation/widgets/uninstall_blocked_dialog_test.dart
```

Expected: FAIL because dialog/helper does not exist yet

- [ ] **Step 3: Add localized strings for the intercept dialog**

Add ARB entries for:
- title
- message prefix / full message with placeholders
- `我知道了`
- `查看下载管理`
- `安装`
- `更新` reuse existing labels where possible, do not duplicate if already present

Then regenerate localization outputs:

```bash
flutter gen-l10n
```

Expected: generated localization files updated

- [ ] **Step 4: Implement the dialog helper**

Implement `lib/presentation/widgets/uninstall_blocked_dialog.dart` with:
- a small enum for dialog result, for example `UninstallBlockedAction`
- one public helper like `showUninstallBlockedDialog(...)`
- explicit title/message/button labels from `AppLocalizations`
- dialog closes before returning the enum

Implementation constraints:
- use a dedicated helper instead of overloading the existing bool-only `ConfirmDialog`
- keep the file focused on this one interaction

- [ ] **Step 5: Re-run the dialog test**

Run:

```bash
flutter test test/widget/presentation/widgets/uninstall_blocked_dialog_test.dart
```

Expected: PASS

- [ ] **Step 6: Commit the dialog + l10n slice**

Run:

```bash
git add lib/presentation/widgets/uninstall_blocked_dialog.dart test/widget/presentation/widgets/uninstall_blocked_dialog_test.dart lib/core/i18n/l10n/app_zh.arb lib/core/i18n/l10n/app_en.arb lib/core/i18n/l10n/app_localizations.dart lib/core/i18n/l10n/app_localizations_zh.dart lib/core/i18n/l10n/app_localizations_en.dart
git commit -m "feat: 增加安装中卸载拦截弹窗"
```

### Task 2: Wire The Active Install Guard Into The Shared Uninstall Service

**Files:**
- Modify: `lib/application/services/app_uninstall_service.dart`
- Modify: `lib/application/providers/app_uninstall_provider.dart`
- Modify: `test/widget/application/services/app_uninstall_service_test.dart`

- [ ] **Step 1: Write failing service tests for the guarded path**

Add test coverage in `test/widget/application/services/app_uninstall_service_test.dart` for:

```dart
testWidgets('blocks uninstall when an active install task exists', ...)
testWidgets('opens download manager when user chooses 查看下载管理', ...)
testWidgets('continues normal uninstall flow when there is no active task', ...)
```

Assertions for the blocked path:
- uninstall executor is not called
- remove/sync/report are not called
- normal uninstall confirm is not shown
- intercept dialog is shown first

Assertions for the download manager choice:
- intercept dialog action is captured
- download manager opener callback is invoked exactly once

- [ ] **Step 2: Run the focused service test to verify it fails**

Run:

```bash
flutter test test/widget/application/services/app_uninstall_service_test.dart
```

Expected: FAIL because service has no active-install guard yet

- [ ] **Step 3: Extend the service contract minimally**

Update `AppUninstallService` to accept:
- a reader for the active install task, or the minimal current-task snapshot it needs
- a dialog callback for the intercept dialog
- a callback that opens the download manager

Recommended shape:
- keep this guard near the start of `uninstall()`
- if there is an active task, show intercept dialog and return `false`
- only after passing the guard continue to the existing running-app check and uninstall confirmation logic

- [ ] **Step 4: Update the provider wiring**

Update `appUninstallServiceProvider` so it passes:
- `installQueueProvider.currentTask`
- the new dialog helper
- `showDownloadManagerDialog(context)` through a callback wrapper

Implementation constraints:
- provider remains the only assembly point
- pages continue calling `appUninstallServiceProvider.uninstall(context, app)` without new branching

- [ ] **Step 5: Re-run the focused service tests**

Run:

```bash
flutter test test/widget/application/services/app_uninstall_service_test.dart
```

Expected: PASS

- [ ] **Step 6: Commit the shared service wiring**

Run:

```bash
git add lib/application/services/app_uninstall_service.dart lib/application/providers/app_uninstall_provider.dart test/widget/application/services/app_uninstall_service_test.dart
git commit -m "feat: 统一卸载入口拦截安装中的操作"
```

### Task 3: Verify The Real Entry Points And Avoid Page-Level Drift

**Files:**
- Modify: no production page change expected unless a test reveals a missing shared entry
- Test: `test/widget/presentation/widgets/download_manager_dialog_test.dart`

- [ ] **Step 1: Verify current uninstall entry points still route through the shared service**

Check:

```bash
rg -n "appUninstallServiceProvider" lib/presentation/pages lib/presentation/widgets -S
```

Expected:
- `my_apps_page.dart` uses the shared uninstall service
- `app_detail_page.dart` uses the shared uninstall service

- [ ] **Step 2: Add or adjust one regression test around the download manager dialog if needed**

Goal:
- ensure the dialog helper remains openable in the same modal stack used by the service callback

If existing coverage is sufficient, document that no production change is needed here.

- [ ] **Step 3: Run the entry-point related widget tests**

Run:

```bash
flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart
flutter test test/widget/presentation/widgets/app_detail_secondary_actions_test.dart
```

Expected: PASS

- [ ] **Step 4: Commit any test-only follow-up**

Run only if files changed:

```bash
git add test/widget/presentation/widgets/download_manager_dialog_test.dart test/widget/presentation/widgets/app_detail_secondary_actions_test.dart
git commit -m "test: 补充卸载拦截相关交互验证"
```

### Task 4: Update Docs And Repository Conventions

**Files:**
- Modify: `docs/07-runtime-sequence-and-state-diagrams.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Update runtime flow documentation**

In `docs/07-runtime-sequence-and-state-diagrams.md`, add the uninstall pre-check:
- active install/update task check
- intercept dialog branch
- optional jump to download manager
- only no-active-task path enters uninstall confirmation

- [ ] **Step 2: Update AGENTS guidance with the new rule**

Add a short rule under change log / conventions:
- uninstall entry points must go through `AppUninstallService`
- when `installQueueProvider.currentTask` exists, uninstall must show the intercept dialog instead of proceeding
- `查看下载管理` must reuse `showDownloadManagerDialog(context)` rather than creating a second download manager surface

- [ ] **Step 3: Commit the docs**

Run:

```bash
git add docs/07-runtime-sequence-and-state-diagrams.md AGENTS.md
git commit -m "docs: 补充安装中卸载拦截约定"
```

### Task 5: Final Verification

**Files:**
- Modify: none
- Test: all files touched above

- [ ] **Step 1: Run targeted tests together**

Run:

```bash
flutter test test/widget/presentation/widgets/uninstall_blocked_dialog_test.dart test/widget/application/services/app_uninstall_service_test.dart test/widget/presentation/widgets/download_manager_dialog_test.dart test/widget/presentation/widgets/app_detail_secondary_actions_test.dart
```

Expected: all PASS

- [ ] **Step 2: Run targeted analysis**

Run:

```bash
flutter analyze lib/application/services/app_uninstall_service.dart lib/application/providers/app_uninstall_provider.dart lib/presentation/widgets/uninstall_blocked_dialog.dart lib/presentation/widgets/download_manager_dialog.dart lib/core/i18n/l10n/app_localizations.dart
```

Expected: 0 errors, 0 warnings

- [ ] **Step 3: Review the final diff**

Run:

```bash
git status --short
git diff --stat HEAD~3..HEAD
```

Expected: only the planned files are changed

- [ ] **Step 4: Prepare handoff note**

Include in the handoff:
- current Flutter only has shared uninstall entry points in `MyApps` and `AppDetail`
- queued tasks are intentionally not blocked; only `currentTask` blocks uninstall
- no auto-cancel behavior was introduced

## Worker Notes

- Keep comments concise and only where the control-flow branch is non-obvious.
- Prefer injecting callbacks into `AppUninstallService` rather than making the service read providers directly.
- Do not introduce a page-level `if (installing)` guard in multiple places; shared service interception is the main architectural goal.
- If the worker discovers a third uninstall entry point that bypasses `AppUninstallService`, stop and route it through the shared service before adding local guards.

## Open Question For Human Review

- Button emphasis is planned as: left secondary `我知道了`, right primary `查看下载管理`. If product wants the reverse visual emphasis, confirm before implementation; behavior stays the same either way.
