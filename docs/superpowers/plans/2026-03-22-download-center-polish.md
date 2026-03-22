# Download Center Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the download manager dialog into a stable, polished operations modal and unify install progress rendering so the dialog progress bar finally works correctly.

**Architecture:** Keep `DownloadManagerDialog` as the single presentation entry point fed by `installQueueProvider` and `networkSpeedProvider`, but restructure it into a fixed-height shell with a highlighted active task section and compact secondary rows. Introduce shared progress normalization helpers on install-task UI data so download manager, app card, and install button render the same progress contract.

**Tech Stack:** Flutter desktop, Material dialogs, Riverpod, existing app theme tokens, widget tests

---

### Task 1: Document The Approved Design

**Files:**
- Create: `docs/superpowers/specs/2026-03-22-download-center-polish-design.md`
- Create: `docs/superpowers/plans/2026-03-22-download-center-polish.md`

- [ ] **Step 1: Write the approved design spec**

Capture the stable-height modal shell, active/waiting/history hierarchy, and shared progress-formatting rules.

- [ ] **Step 2: Write the implementation plan**

Break work into progress-contract tests, dialog UI rebuild, and verification.

- [ ] **Step 3: Commit the docs**

Run:

```bash
git add docs/superpowers/specs/2026-03-22-download-center-polish-design.md docs/superpowers/plans/2026-03-22-download-center-polish.md
git commit -m "docs: 补充下载中心改版方案"
```

### Task 2: Add Red Tests For Progress Rendering And Dialog Shell

**Files:**
- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`
- Modify or create: `test/widget/widgets/install_button_test.dart`

- [ ] **Step 1: Add dialog expectations for active progress display**

Cover:

- active task renders a `LinearProgressIndicator`
- progress percentage and download speed text appear together
- short-list dialog shell keeps the intended minimum height

- [ ] **Step 2: Add progress-format expectations for install surfaces**

Add a focused test that verifies ratio-style progress values (for example `0.74`) render as `74%`, not `1%` or `0%`.

- [ ] **Step 3: Run focused widget tests to verify RED**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart
/home/han/flutter/bin/flutter test test/widget/widgets/install_button_test.dart
```

Expected: download manager progress-display assertions fail before implementation; if generator files are missing, run code generation first and then re-run.

- [ ] **Step 4: Commit the tests after RED/GREEN cycle**

```bash
git add test/widget/presentation/widgets/download_manager_dialog_test.dart test/widget/widgets/install_button_test.dart
git commit -m "test: 补充下载中心进度展示测试"
```

### Task 3: Unify Install Progress Presentation

**Files:**
- Modify: `lib/domain/models/install_task.dart`
- Modify: `lib/presentation/widgets/install_button.dart`
- Modify: `lib/presentation/widgets/app_card.dart`
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`

- [ ] **Step 1: Add shared progress helpers on install-task presentation data**

Implement helpers that:

- normalize legacy `0..100` values into a ratio safely
- expose a single rounded percentage label
- avoid UI widgets duplicating normalization math

- [ ] **Step 2: Switch install button and app card to the shared helpers**

Remove local math like `progress * 100` where shared helpers should be used instead.

- [ ] **Step 3: Update the download manager progress bar to the same helpers**

Make sure the progress indicator consumes a normalized ratio and the text consumes the shared percent label.

- [ ] **Step 4: Run focused widget tests to verify GREEN**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart
/home/han/flutter/bin/flutter test test/widget/widgets/install_button_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit the progress-contract fix**

```bash
git add lib/domain/models/install_task.dart lib/presentation/widgets/install_button.dart lib/presentation/widgets/app_card.dart lib/presentation/widgets/download_manager_dialog.dart test/widget/presentation/widgets/download_manager_dialog_test.dart test/widget/widgets/install_button_test.dart
git commit -m "fix: 统一安装进度展示协议"
```

### Task 4: Rebuild The Download Manager UI

**Files:**
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`
- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`

- [ ] **Step 1: Rebuild the dialog shell with stable desktop sizing**

Keep width near the current 400px baseline, but enforce a stable content height and move scrolling into the list region only.

- [ ] **Step 2: Introduce stronger section hierarchy**

Render:

- one highlighted active task card
- compact waiting queue rows
- compact recent history rows
- anchored footer metadata such as real-time network speed

- [ ] **Step 3: Preserve existing task actions**

Cancel, retry, open, remove, and clear-history flows must keep calling the same queue/repository entry points.

- [ ] **Step 4: Run focused verification**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit the UI rebuild**

```bash
git add lib/presentation/widgets/download_manager_dialog.dart test/widget/presentation/widgets/download_manager_dialog_test.dart
git commit -m "feat: 美化下载中心弹窗"
```

### Task 5: Final Verification

**Files:**
- Review all changed files above

- [ ] **Step 1: Regenerate generated files if needed**

Run:

```bash
/home/han/flutter/bin/dart run build_runner build --delete-conflicting-outputs
```

Expected: generated files updated when annotations or stale generated artifacts block tests.

- [ ] **Step 2: Run final focused checks**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart test/widget/widgets/install_button_test.dart
/home/han/flutter/bin/flutter analyze lib/domain/models/install_task.dart lib/presentation/widgets/download_manager_dialog.dart lib/presentation/widgets/install_button.dart lib/presentation/widgets/app_card.dart
```

- [ ] **Step 3: Review acceptance criteria against the spec**

Confirm:

- dialog height remains stable for short lists
- active task is visually dominant
- progress text and bar agree across widgets
- existing queue actions remain wired correctly

- [ ] **Step 4: Prepare handoff summary**

Report code changes, verification evidence, and any residual risks.
