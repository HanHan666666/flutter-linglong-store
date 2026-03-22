# Install Progress Protocol Parity Design

**Date:** 2026-03-22
**Status:** Approved for implementation
**Scope:** Flutter install/update progress pipeline, error handling, and UI text rendering

## Background

The Flutter store currently parses `ll-cli install --json` only partially.

The visible symptom is that raw JSON lines such as `{"message":"Beginning to pull data","percentage":5}` leak into `task.message` and are rendered directly in the download manager, detail page, and update page.

The deeper problem is architectural:

1. The Rust store distinguishes `progress`, `message`, `error`, and `cancelled` event semantics.
2. The Flutter store currently mixes raw CLI output, user-facing status text, and failure text into the same `message` field.
3. Error-code mapping and raw error detail are not preserved with the same boundaries as the Rust implementation.
4. UI surfaces consume `task.message` directly, so any protocol ambiguity becomes a user-visible regression immediately.

The target is not a local UI patch. Flutter must reproduce the Rust install-progress contract so every surface sees normalized, localized data instead of raw transport payloads.

## Goals

- Fully align Flutter install/update progress handling with the Rust store's JSON event semantics.
- Ensure raw JSON output never reaches presentation widgets as display text.
- Preserve both user-facing localized status text and backend raw detail text.
- Reuse the existing Flutter i18n layer for all user-facing install/update status and error messages.
- Keep the existing single-task queue model and cancellation flow intact.

## Non-Goals

- Do not redesign the install queue concurrency model.
- Do not introduce new `ll-cli` commands or shell polling.
- Do not add a second progress data source outside the current repository/provider pipeline.
- Do not change unrelated download-center layout behavior beyond consuming normalized task text.

## Rust Behavior To Preserve

The Rust store treats each JSON line as one of four semantic event kinds:

- `progress`: carries `percentage` and raw `message`
- `message`: carries raw `message` without changing progress
- `error`: carries `code` plus raw `message`
- `cancelled`: synthetic UI event for user-triggered cancellation

It then derives:

- user-facing `status` text from message content or error code
- progress percentage from `percentage`
- raw detail text from backend `message`
- final state from explicit success, explicit error, cancellation, timeout, or process exit

Flutter must mirror that separation instead of collapsing everything into one display string.

## Chosen Approach

Introduce a normalized install-event contract in Flutter and feed every UI surface from that contract.

Why:

- It fixes the current JSON leakage at the correct layer.
- It keeps parsing logic centralized in the CLI/repository pipeline.
- It preserves Rust parity for error handling and i18n without adding duplicated UI parsing.
- It reduces future drift because widgets will only render normalized fields.

## Architecture

### 1. Normalize CLI Events Before They Reach The Queue

`CliOutputParser` should continue recognizing JSON and text output, but the repository must stop passing raw `event.line` into display-text mapping.

Instead, the repository should:

- parse the line into a JSON event when possible
- derive the transport-level event kind
- map the raw `message` to a localized `status`
- keep the original message text as raw detail/context

This makes the repository the single boundary between transport payloads and UI-friendly task state.

### 2. Expand The Install Progress Model To Match Rust Semantics

`InstallProgress` should explicitly carry:

- `eventType`
- `message` for raw backend message text
- `statusText` or equivalent user-facing normalized status
- `errorCode`
- `errorDetail`

Flutter naming may differ from Rust if it fits the codebase better, but the semantic split must remain:

- raw backend text
- localized user-facing text
- raw backend error detail

The queue should persist and propagate these fields so history and in-flight task cards stay consistent.

### 3. Keep Error Mapping And Status Mapping In Install I18n Helpers

`InstallMessages` is the correct place to hold user-facing status and error mapping because it already decouples repository logic from widget-tree localization.

It should be extended to reproduce Rust behavior more faithfully:

- map known message phrases to localized install/update status strings
- map known error codes to localized failure strings
- provide operation-aware success/cancelled wording for install vs update
- provide a safe fallback when the backend returns an unknown message or unknown code

This keeps i18n deterministic and prevents UI widgets from hand-rolling text interpretation.

### 4. Queue State Should Store Normalized Display Text, Not Transport Payloads

`InstallQueue` currently copies `progress.message` directly into `task.message`. After the migration, the queue must store normalized user-facing text for display fields and preserve raw detail separately.

Required behavior:

- active task visible text uses normalized localized status
- failure summary uses localized error string
- failure detail preserves backend raw detail when present
- cancellation keeps existing queue semantics but uses the same normalized text contract

The queue remains the single source of truth for download manager, detail page, update page, and install buttons.

### 5. Presentation Widgets Only Render Normalized Fields

The following surfaces must stop assuming `task.message` contains safe text if that assumption is no longer guaranteed:

- download manager dialog
- app detail install status area
- update page install status area
- install button and any inline progress affordance

Widgets should render the queue-provided normalized status text and, when appropriate, the preserved raw detail in failure-specific slots.

No widget should parse JSON or infer status from CLI phrases directly.

## File Strategy

- Modify: `lib/domain/models/install_progress.dart`
- Modify: `lib/domain/models/install_task.dart`
- Modify: `lib/core/i18n/install_messages.dart`
- Modify: `lib/data/mappers/cli_output_parser.dart`
- Modify: `lib/data/repositories/linglong_cli_repository_impl.dart`
- Modify: `lib/domain/models/install_state_machine.dart`
- Modify: `lib/application/providers/install_queue_provider.dart`
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
- Modify: `lib/presentation/pages/update_app/update_app_page.dart`
- Modify if needed: `lib/presentation/widgets/install_button.dart`
- Modify tests under `test/unit/data/`, `test/unit/application/`, and `test/widget/presentation/widgets/`

## Testing Strategy

### Parser And Repository

- JSON progress events expose raw message plus normalized status
- JSON error events expose localized failure text plus raw detail
- JSON message events update text without surfacing raw JSON
- non-JSON lines still fall back safely

### Queue

- current task stores normalized status text
- failed task stores localized error summary and backend detail separately
- cancelled task does not regress existing queue behavior
- timeout behavior stays aligned with current Rust implementation

### UI

- download manager never renders raw JSON lines
- detail page and update page show normalized status text only
- failure UI prefers localized summary and preserves detail where already supported

## Acceptance Criteria

- No install/update UI surface renders raw JSON payload text.
- Flutter progress/error/message handling matches the Rust semantic split.
- Known error codes render localized friendly text.
- Raw backend message text is preserved only as detail/context, not as transport JSON.
- Existing install queue, cancellation, and history flows continue to work after the migration.
