# Top Right Notification Center Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace scattered bottom SnackBars with a unified top-right notification center that appears in the content area, supports stacking, dismiss, and optional actions.

**Architecture:** Build a global notification pipeline with a Riverpod controller plus a Shell-aware viewport rendered above the right-side content area inside `AppShell`. Migrate existing `showSnackBar` call sites to a shared notification API in batches, starting from the highest-frequency user-visible flows, while keeping application services free from presentation-layer imports.

**Tech Stack:** Flutter, Riverpod, flutter_test, go_router

---

### Task 1: Map Current Notification Surface And Add Test Harness

**Files:**
- Modify: `test/widget/widget_test.dart` only if the existing shared harness is the best fit
- Create: `test/unit/application/providers/app_notification_controller_test.dart`
- Create: `test/widget/presentation/widgets/app_notification_viewport_test.dart`

- [ ] **Step 1: Write the failing controller test**

Cover:
- pushing a notification inserts it into visible state
- more than `3` notifications trims the oldest one
- manual dismiss removes the targeted item

- [ ] **Step 2: Run the controller test to verify it fails**

Run: `flutter test test/unit/application/providers/app_notification_controller_test.dart`
Expected: FAIL because the controller and notification model do not exist yet

- [ ] **Step 3: Write the failing viewport widget test**

Cover:
- notifications render in a top-right stack
- action button and dismiss button are visible when configured

- [ ] **Step 4: Run the viewport widget test to verify it fails**

Run: `flutter test test/widget/presentation/widgets/app_notification_viewport_test.dart`
Expected: FAIL because the viewport widget does not exist yet

### Task 2: Build Notification Domain Model And Controller

**Files:**
- Create: `lib/application/notifications/app_notification.dart`
- Create: `lib/application/providers/app_notification_provider.dart`
- Test: `test/unit/application/providers/app_notification_controller_test.dart`

- [ ] **Step 1: Add the notification entity**

Implementation:
- define immutable notification data
- include type, duration, dismissible, optional action label, and `actionId`
- do not store closures directly in provider state

- [ ] **Step 2: Add the controller/provider**

Implementation:
- expose show success/error/info/warning helpers
- manage insertion order, max visible count, dismiss behavior, and a private action-handler registry
- define the provider as app-wide keepAlive

- [ ] **Step 3: Add timer lifecycle handling**

Implementation:
- start auto-dismiss timers when notifications are shown
- cancel timers when notifications are dismissed or replaced
- clear registered action handlers when notifications are removed

- [ ] **Step 4: Run the controller test and make it pass**

Run: `flutter test test/unit/application/providers/app_notification_controller_test.dart`
Expected: PASS

### Task 3: Build Global Viewport And Card UI

**Files:**
- Create: `lib/presentation/notifications/app_notification_card.dart`
- Create: `lib/presentation/notifications/app_notification_viewport.dart`
- Modify: `lib/presentation/widgets/app_shell.dart`
- Test: `test/widget/presentation/widgets/app_notification_viewport_test.dart`

- [ ] **Step 1: Add the notification card widget**

Implementation:
- icon + message + optional action button + dismiss button
- success/error/info/warning visual variants
- concise comments only where animation or hit testing is non-obvious

- [ ] **Step 2: Add the viewport widget**

Implementation:
- anchor to the AppShell content-area top-right region
- offset from the title bar using `CustomTitleBar.height` and the right content container geometry
- stack up to `3` cards with animated insert/reorder/remove behavior

- [ ] **Step 3: Mount the viewport globally**

Implementation:
- mount the viewport from `AppShell` so only Shell pages participate in the content-area positioning contract
- explicitly leave `LaunchPage` out of the first rollout unless product scope changes

- [ ] **Step 4: Run the viewport widget test and make it pass**

Run: `flutter test test/widget/presentation/widgets/app_notification_viewport_test.dart`
Expected: PASS

### Task 4: Introduce Shared Notification Helpers For Call Sites

**Files:**
- Create: `lib/presentation/notifications/app_notification_helpers.dart`
- Create: `lib/application/notifications/app_notification_dispatcher.dart`
- Modify: `lib/application/services/app_uninstall_service.dart`
- Modify: `lib/application/providers/app_uninstall_provider.dart`
- Modify: `lib/presentation/widgets/app_card_actions.dart`
- Modify: `lib/presentation/pages/setting/setting_page.dart`
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
- Modify: `lib/presentation/widgets/feedback_dialog.dart`
- Modify: `lib/presentation/widgets/linglong_env_dialog.dart`
- Modify: `lib/presentation/widgets/linglong_process_panel.dart`
- Modify: `lib/presentation/widgets/app_detail_info_section.dart`
- Modify: `lib/presentation/pages/recommend/recommend_page.dart`

- [ ] **Step 1: Add shared helper APIs**

Implementation:
- provide easy `showSuccessNotification` / `showErrorNotification` style helpers
- keep helper signatures small so page code stays readable
- keep presentation helpers inside presentation only

- [ ] **Step 2: Migrate service-layer notification usage**

Implementation:
- remove direct `ScaffoldMessenger` usage from uninstall service
- do not import `presentation/notifications/*` from `application/services/*`
- make uninstall service return typed results to the caller
- convert the provider/page boundary into the only place that maps service results to notifications

- [ ] **Step 3: Migrate high-frequency page/widget call sites**

Implementation:
- replace direct `showSnackBar` calls in the listed files with the shared notification API
- keep existing localized messages and error coloring semantics
- add one focused migration at a time so grep and regression checks stay attributable

- [ ] **Step 4: Run targeted grep to verify old calls were reduced**

Run: `rg "showSnackBar\(" lib`
Expected: zero direct `showSnackBar(` usages remain in business code before the task is considered complete

### Task 5: Polish Behavior And Desktop Interaction Details

**Files:**
- Modify: `lib/presentation/notifications/app_notification_card.dart`
- Modify: `lib/presentation/notifications/app_notification_viewport.dart`
- Test: `test/widget/presentation/widgets/app_notification_viewport_test.dart`

- [ ] **Step 1: Add hover-aware auto-dismiss behavior**

Implementation:
- pause auto-dismiss while pointer is over a card
- resume after hover ends

- [ ] **Step 2: Verify action handling clears the notification correctly**

Implementation:
- clicking the action must execute the registered handler and then always dismiss the notification

- [ ] **Step 3: Expand widget coverage for hover and multi-item stacking**

Run: `flutter test test/widget/presentation/widgets/app_notification_viewport_test.dart`
Expected: PASS with coverage for stacking, hover, dismiss, action behavior, and dialog/overlay hit testing

### Task 6: Verify, Document, And Prepare For Implementation Handoff

**Files:**
- Modify: `docs/superpowers/specs/2026-03-23-top-right-notification-center-design.md`
- Modify: `docs/superpowers/plans/2026-03-23-top-right-notification-center.md`

- [ ] **Step 1: Run focused tests**

Run:
- `flutter test test/unit/application/providers/app_notification_controller_test.dart`
- `flutter test test/widget/presentation/widgets/app_notification_viewport_test.dart`
- `flutter test test/widget/presentation/pages/update_app/update_app_page_test.dart` only if shared harness changes affect shell overlays

- [ ] **Step 2: Add targeted behavior regression coverage before broad migration**

Cover at least:
- one page success/failure notification flow
- one dialog submit notification flow
- one uninstall-service-driven result flow through the provider boundary
- one process or context-menu-driven notification flow

- [ ] **Step 3: Run targeted analysis**

Run:
- `flutter analyze lib/application/providers/app_notification_provider.dart lib/application/providers/app_uninstall_provider.dart lib/application/services/app_uninstall_service.dart lib/application/notifications lib/presentation/notifications lib/presentation/widgets/app_shell.dart lib/presentation/pages/app_detail/app_detail_page.dart lib/presentation/pages/setting/setting_page.dart lib/presentation/widgets/app_card_actions.dart lib/presentation/widgets/feedback_dialog.dart lib/presentation/widgets/linglong_env_dialog.dart lib/presentation/widgets/linglong_process_panel.dart lib/presentation/widgets/app_detail_info_section.dart lib/presentation/pages/recommend/recommend_page.dart test/unit/application/providers/app_notification_controller_test.dart test/widget/presentation/widgets/app_notification_viewport_test.dart`

- [ ] **Step 4: Reconcile docs with final implementation details**

- [ ] **Step 5: Enforce final grep acceptance before commit**

Run:
- `rg "ScaffoldMessenger|showSnackBar" lib`
Expected: zero business-code call sites remain

- [ ] **Step 6: Commit with conventional commit message once implementation lands**

```bash
git add docs/superpowers/specs/2026-03-23-top-right-notification-center-design.md \
        docs/superpowers/plans/2026-03-23-top-right-notification-center.md \
        lib/application/notifications/app_notification.dart \
        lib/application/notifications/app_notification_dispatcher.dart \
        lib/application/providers/app_notification_provider.dart \
        lib/application/providers/app_uninstall_provider.dart \
        lib/application/services/app_uninstall_service.dart \
        lib/presentation/notifications/app_notification_card.dart \
        lib/presentation/notifications/app_notification_helpers.dart \
        lib/presentation/notifications/app_notification_viewport.dart \
        lib/presentation/widgets/app_shell.dart \
        lib/presentation/pages/app_detail/app_detail_page.dart \
        lib/presentation/pages/setting/setting_page.dart \
        lib/presentation/pages/recommend/recommend_page.dart \
        lib/presentation/widgets/app_card_actions.dart \
        lib/presentation/widgets/app_detail_info_section.dart \
        lib/presentation/widgets/feedback_dialog.dart \
        lib/presentation/widgets/linglong_env_dialog.dart \
        lib/presentation/widgets/linglong_process_panel.dart \
        test/unit/application/providers/app_notification_controller_test.dart \
        test/widget/presentation/widgets/app_notification_viewport_test.dart
git commit -m "feat: 新增右上角通知中心"
```