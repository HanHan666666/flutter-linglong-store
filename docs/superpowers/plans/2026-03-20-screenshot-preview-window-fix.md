# Screenshot Preview Window Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix screenshot preview sub-window regressions while keeping the separate desktop window UX.

**Architecture:** Add a typed preview payload plus a main-window coordinator/gateway so `AppDetailPage` stops creating anonymous windows directly. Keep the preview sub-window lightweight, but give it a narrow window-method API, safe argument parsing, and explicit locale/theme configuration.

**Tech Stack:** Flutter desktop, Riverpod, `desktop_multi_window`, `window_manager`, widget tests, unit tests

---

### Task 1: Add Typed Payload and Coordinator Abstractions

**Files:**
- Create: `lib/presentation/pages/app_detail/screenshot_preview_window_payload.dart`
- Create: `lib/presentation/pages/app_detail/screenshot_preview_window_coordinator.dart`
- Test: `test/unit/presentation/pages/app_detail/screenshot_preview_window_payload_test.dart`
- Test: `test/unit/presentation/pages/app_detail/screenshot_preview_window_coordinator_test.dart`

- [ ] **Step 1: Write the failing payload tests**

Cover:
- serialize/parse valid payload
- reject malformed payload
- preserve locale and theme fields

- [ ] **Step 2: Run payload tests to verify they fail**

Run: `flutter test test/unit/presentation/pages/app_detail/screenshot_preview_window_payload_test.dart`

- [ ] **Step 3: Implement the payload model**

Add:
- preview window type constant
- JSON encode/decode helpers
- safe parse result for invalid payloads

- [ ] **Step 4: Run payload tests to verify they pass**

Run: `flutter test test/unit/presentation/pages/app_detail/screenshot_preview_window_payload_test.dart`

- [ ] **Step 5: Write the failing coordinator tests**

Cover:
- create on first open
- reuse tracked window on second open
- recreate after stale-window update failure

- [ ] **Step 6: Run coordinator tests to verify they fail**

Run: `flutter test test/unit/presentation/pages/app_detail/screenshot_preview_window_coordinator_test.dart`

- [ ] **Step 7: Implement the coordinator and testable gateway abstraction**

Rules:
- UI code does not touch `WindowController` directly
- coordinator awaits create/show/update calls
- stale controller failure clears cache and retries once

- [ ] **Step 8: Run coordinator tests to verify they pass**

Run: `flutter test test/unit/presentation/pages/app_detail/screenshot_preview_window_coordinator_test.dart`

- [ ] **Step 9: Commit**

```bash
git add lib/presentation/pages/app_detail/screenshot_preview_window_payload.dart \
  lib/presentation/pages/app_detail/screenshot_preview_window_coordinator.dart \
  test/unit/presentation/pages/app_detail/screenshot_preview_window_payload_test.dart \
  test/unit/presentation/pages/app_detail/screenshot_preview_window_coordinator_test.dart
git commit -m "feat: 收敛截图预览窗口参数与协调逻辑"
```

### Task 2: Refactor the Preview Sub-Window App

**Files:**
- Modify: `lib/presentation/pages/app_detail/screenshot_preview_app.dart`
- Test: `test/widget/presentation/pages/screenshot_preview_app_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Cover:
- locale-driven title rendering
- theme selection from payload
- `preview_update` replaces screenshots/index
- close action calls sub-window close callback instead of killing the main app

- [ ] **Step 2: Run widget tests to verify they fail**

Run: `flutter test test/widget/presentation/pages/screenshot_preview_app_test.dart`

- [ ] **Step 3: Refactor the preview app for testability**

Add:
- typed payload input
- localized/theme-aware `MaterialApp`
- injectable close callback / controller adapter
- narrow method handler for `preview_update` and `window_close`
- compact invalid-payload error state

- [ ] **Step 4: Run widget tests to verify they pass**

Run: `flutter test test/widget/presentation/pages/screenshot_preview_app_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/app_detail/screenshot_preview_app.dart \
  test/widget/presentation/pages/screenshot_preview_app_test.dart
git commit -m "fix: 修复截图预览子窗口关闭与主题语言同步"
```

### Task 3: Wire Main App Startup and Detail Page to the Coordinator

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
- Modify: `docs/superpowers/specs/2026-03-20-screenshot-preview-window-fix-design.md`

- [ ] **Step 1: Write the failing integration-shaped tests if needed**

If direct widget coverage is insufficient, add narrow unit coverage for:
- startup payload routing fallback
- page-side preview open request building

- [ ] **Step 2: Run the targeted tests to verify they fail**

Run the smallest new test target added in Step 1.

- [ ] **Step 3: Implement main-app wiring**

Rules:
- `main.dart` parses preview payload safely
- invalid payload shows preview error app instead of crashing
- `AppDetailPage` delegates to the coordinator
- page passes current locale/theme-derived data into the preview payload

- [ ] **Step 4: Run all screenshot-preview targeted tests**

Run:
- `flutter test test/unit/presentation/pages/app_detail/screenshot_preview_window_payload_test.dart`
- `flutter test test/unit/presentation/pages/app_detail/screenshot_preview_window_coordinator_test.dart`
- `flutter test test/widget/presentation/pages/screenshot_preview_app_test.dart`

- [ ] **Step 5: Update the design doc if the protocol or file split changed**

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart \
  lib/presentation/pages/app_detail/app_detail_page.dart \
  docs/superpowers/specs/2026-03-20-screenshot-preview-window-fix-design.md
git commit -m "fix: 接入截图预览窗口协调器"
```

### Task 4: Verify and Finish

**Files:**
- Modify: any touched files above if verification reveals issues

- [ ] **Step 1: Run focused verification**

Run:
- `flutter test test/unit/presentation/pages/app_detail/screenshot_preview_window_payload_test.dart`
- `flutter test test/unit/presentation/pages/app_detail/screenshot_preview_window_coordinator_test.dart`
- `flutter test test/widget/presentation/pages/screenshot_preview_app_test.dart`

- [ ] **Step 2: Run broader regression coverage**

Run:
- `flutter analyze lib/main.dart lib/presentation/pages/app_detail/`

- [ ] **Step 3: Manual verification on Linux desktop**

Check:
- preview close button only closes preview
- preview ESC only closes preview
- repeated open reuses a single preview window
- locale/theme changes are reflected on next open/update

- [ ] **Step 4: Record actual verification results before claiming completion**

- [ ] **Step 5: Use finishing workflow**

Follow `superpowers:finishing-a-development-branch` after verification is complete.
