# Screenshot Preview Lightbox Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the screenshot multi-window preview with an in-app lightbox that is faster, theme-adaptive, and Linux-stable.

**Architecture:** The app detail page opens a dedicated `showGeneralDialog` lightbox inside the main window. The lightbox owns preview-only UI state, while the abandoned multi-window startup path, Linux runner hook, and related tests are deleted.

**Tech Stack:** Flutter desktop, Material dialog routing, `InteractiveViewer`, widget tests, Linux runner cleanup

---

### Task 1: Document The Architecture Switch

**Files:**
- Create: `docs/superpowers/specs/2026-03-20-screenshot-preview-lightbox-design.md`
- Create: `docs/superpowers/plans/2026-03-20-screenshot-preview-lightbox.md`

- [ ] **Step 1: Write the updated design spec**

Document the move from a separate desktop window to a main-window lightbox, including UI layout, theme rules, performance rationale, and cleanup scope.

- [ ] **Step 2: Write the implementation plan**

Break implementation into test-first UI extraction, integration changes, and multi-window cleanup.

- [ ] **Step 3: Commit the docs**

Run:

```bash
git add docs/superpowers/specs/2026-03-20-screenshot-preview-lightbox-design.md docs/superpowers/plans/2026-03-20-screenshot-preview-lightbox.md
git commit -m "docs: 设计截图灯箱预览方案"
```

### Task 2: Add Failing Lightbox Widget Tests

**Files:**
- Create: `test/widget/presentation/pages/screenshot_preview_lightbox_test.dart`
- Delete: `test/widget/presentation/pages/screenshot_preview_app_test.dart`
- Delete: `test/unit/presentation/pages/app_detail/screenshot_preview_window_coordinator_test.dart`
- Delete: `test/unit/presentation/pages/app_detail/screenshot_preview_window_payload_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Cover:

- localized title inside dialog
- light theme title bar / thumbnail rail readability
- close button dismisses dialog
- arrow-key or button navigation updates index
- thumbnail rail hidden for a single screenshot

- [ ] **Step 2: Run the new widget test file to verify RED**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/pages/screenshot_preview_lightbox_test.dart
```

Expected: FAIL because the lightbox widget does not exist yet.

- [ ] **Step 3: Commit the test scaffold after RED/GREEN cycle later**

```bash
git add test/widget/presentation/pages/screenshot_preview_lightbox_test.dart
git commit -m "test: 补充截图灯箱预览组件测试"
```

### Task 3: Implement The Lightbox Component

**Files:**
- Create: `lib/presentation/pages/app_detail/screenshot_preview_lightbox.dart`
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`

- [ ] **Step 1: Implement the dedicated lightbox widget**

Add a focused widget that accepts `screenshots` and `initialIndex`, owns page state, and renders theme-adaptive title bar, stage, navigation arrows, and thumbnail rail.

- [ ] **Step 2: Replace the detail-page multi-window open path**

Remove payload/coordinator usage from `AppDetailPage` and switch `_showScreenshotPreview(...)` back to `showGeneralDialog`.

- [ ] **Step 3: Run the widget tests to verify GREEN**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/pages/screenshot_preview_lightbox_test.dart
```

Expected: PASS

- [ ] **Step 4: Commit the UI implementation**

```bash
git add lib/presentation/pages/app_detail/app_detail_page.dart lib/presentation/pages/app_detail/screenshot_preview_lightbox.dart test/widget/presentation/pages/screenshot_preview_lightbox_test.dart
git commit -m "feat: 改为主窗口截图灯箱预览"
```

### Task 4: Remove Multi-Window Screenshot Infrastructure

**Files:**
- Modify: `lib/main.dart`
- Modify: `linux/runner/my_application.cc`
- Modify: `pubspec.yaml`
- Delete: `lib/presentation/pages/app_detail/screenshot_preview_app.dart`
- Delete: `lib/presentation/pages/app_detail/screenshot_preview_window_coordinator.dart`
- Delete: `lib/presentation/pages/app_detail/screenshot_preview_window_payload.dart`
- Delete: `test/widget/presentation/pages/screenshot_preview_app_test.dart`
- Delete: `test/unit/presentation/pages/app_detail/screenshot_preview_window_coordinator_test.dart`
- Delete: `test/unit/presentation/pages/app_detail/screenshot_preview_window_payload_test.dart`

- [ ] **Step 1: Remove screenshot-specific sub-window startup code**

Delete the preview-window branch from `main.dart` and revert Linux runner code that existed only for `desktop_multi_window`.

- [ ] **Step 2: Remove obsolete files and dependency**

Delete the payload/coordinator/app files and remove the `desktop_multi_window` dependency.

- [ ] **Step 3: Run focused analysis and tests**

Run:

```bash
/home/han/flutter/bin/flutter analyze lib/main.dart lib/presentation/pages/app_detail/
/home/han/flutter/bin/flutter test test/widget/presentation/pages/screenshot_preview_lightbox_test.dart
```

Expected: both commands pass

- [ ] **Step 4: Commit the cleanup**

```bash
git add lib/main.dart linux/runner/my_application.cc pubspec.yaml lib/presentation/pages/app_detail/ test/widget/presentation/pages/ test/unit/presentation/pages/app_detail/
git commit -m "refactor: 移除截图多窗口预览链路"
```

### Task 5: Final Verification

**Files:**
- Review all changed files above

- [ ] **Step 1: Run final verification**

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/pages/screenshot_preview_lightbox_test.dart test/widget/presentation/pages/search_list_page_test.dart
/home/han/flutter/bin/flutter analyze lib/main.dart lib/presentation/pages/app_detail/
/home/han/flutter/bin/flutter build linux --debug
```

- [ ] **Step 2: Review acceptance criteria against the spec**

Confirm:

- no separate screenshot system window remains
- dialog follows main app theme and locale
- multi-window dependency path is removed
- tests cover the new lightbox behavior

- [ ] **Step 3: Prepare handoff summary**

Report changed behavior, verification evidence, and any residual risk.
