# Download Center Polish Design

**Date:** 2026-03-22
**Status:** Approved for implementation
**Scope:** Sidebar download manager dialog on Linux desktop

## Background

The current Flutter download manager is functional but visually underdeveloped and structurally inconsistent with both the Rust store and the project design tokens.

The concrete problems confirmed in review are:

1. The dialog height collapses when there are only a few records, which makes the modal look narrow and unfinished.
2. The active download item does not stand out enough from waiting and completed history items.
3. The progress bar feels broken because the same install progress field is rendered with inconsistent assumptions across widgets.
4. The dialog does not follow the documented Rust-era structure that separates waiting, downloading, and completed tasks more clearly.

The product goal is not merely “make it prettier”. The dialog must become a stable, readable operation center for installs and updates.

## Goals

- Give the download manager a stronger desktop-quality modal presentation.
- Keep a stable dialog body height even when the list is short.
- Clearly separate active download, waiting queue, and completed history.
- Make progress readable with percent, speed, and stage text.
- Unify install progress rendering so the dialog and install buttons interpret the same task progress consistently.
- Stay within the existing theme/token system and avoid adding heavyweight new global state.

## Non-Goals

- Do not change install queue business rules or concurrency rules.
- Do not introduce shell-based download polling or new `ll-cli` calls.
- Do not redesign sidebar entry behavior; the entry remains a modal trigger.
- Do not add unrelated queue features such as pause/resume or bulk actions.

## Chosen Approach

Rebuild the dialog as a fixed-height, sectioned modal with a highlighted active task card, compact waiting/history rows, and shared progress formatting helpers.

Why:

- It aligns with the existing design docs that already expect a 400px centered modal with distinct task states.
- It fixes the “few rows cause layout collapse” problem without changing queue behavior.
- It solves the progress confusion at the rendering boundary, where the inconsistency is user-visible today.

## Architecture

### 1. Stable Modal Shell

Keep `DownloadManagerDialog` as the single modal entry point, but replace the content layout with a stable-height shell.

Behavior:

- The dialog keeps a fixed desktop width close to the documented 400px baseline.
- The content area gets a minimum/fixed usable height so one or two rows do not shrink the modal.
- Only the list region scrolls; header and footer remain visually anchored.

This preserves a fast, predictable modal structure and avoids the current content-driven collapse.

### 2. State-Driven Sections With Stronger Visual Hierarchy

The dialog continues consuming only `installQueueProvider` and `networkSpeedProvider`, but the UI is reorganized into explicit sections:

- active task
- waiting queue
- recent history

The active task receives:

- larger card treatment
- stronger title/metadata hierarchy
- visible linear progress bar
- inline phase text, percentage, and download speed

Waiting and completed tasks become compact rows so the active task remains the visual focus.

### 3. Shared Progress Presentation Contract

The current codebase already reveals a mismatch:

- `install_button.dart` treats progress as a ratio in the `0.0..1.0` range.
- `download_manager_dialog.dart` treats the same field as a percentage in the `0..100` range.

This design introduces one shared normalization path for install-task progress rendering.

Rules:

- UI widgets must consume a shared normalized progress ratio for progress indicators.
- UI widgets must consume a shared percentage label formatter for text.
- Legacy values greater than `1` should still be tolerated defensively so the dialog does not regress if an older caller emits `0..100`.
- Success-state progress should move toward a consistent ratio-based representation where feasible.

The goal is a single interpretation of install progress across dialog, card, and install button surfaces.

### 4. Rust-Parity Without Copying Rust Blindly

The Rust store uses a clearer task list structure and more obvious progress emphasis. Flutter should follow the same information hierarchy, but still respect current Flutter theme tokens and widget patterns.

Required parity points:

- download manager remains a centered modal
- waiting / downloading / completed information stays distinguishable
- active task exposes real-time network speed
- history retains open / retry / remove actions where applicable

Intentional Flutter adaptation:

- use token-based surfaces, radii, and spacing from `theme.dart`
- avoid heavy custom painting or animation for a basic operations dialog
- keep provider subscriptions minimal for responsiveness

## Files To Change

- Modify: `lib/presentation/widgets/download_manager_dialog.dart`
- Modify: `lib/domain/models/install_task.dart`
- Modify: `lib/presentation/widgets/install_button.dart`
- Modify: `lib/presentation/widgets/app_card.dart`
- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`
- Modify or create: focused widget tests for progress formatting surfaces if needed
- Create: `docs/superpowers/specs/2026-03-22-download-center-polish-design.md`
- Create: `docs/superpowers/plans/2026-03-22-download-center-polish.md`

## Testing Strategy

Add or update widget coverage for:

1. dialog opens with stable shell and close action still works
2. active task renders progress percentage and network speed together
3. waiting and completed sections remain visible and distinguishable
4. short lists do not collapse the modal below the intended shell height
5. progress formatting stays consistent with ratio-based task values

Manual verification:

1. open the sidebar download manager with 0, 1, and multiple tasks
2. verify modal height remains stable
3. verify active download progress advances visually and textually
4. verify completed item actions still work and remain readable
5. compare install button and download manager percent display for the same task

## Acceptance Criteria

- Download manager modal no longer collapses to a visually narrow height for short lists.
- Active task is visually prioritized over waiting and completed rows.
- Progress bar, percentage, and speed are readable in the modal.
- Dialog and install-related widgets use a consistent progress interpretation.
- Existing queue actions such as cancel, retry, open, and remove still function.
