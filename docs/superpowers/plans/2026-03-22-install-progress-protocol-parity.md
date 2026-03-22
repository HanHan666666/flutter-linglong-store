# Install Progress Protocol Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate Flutter install/update progress handling to the Rust store's event protocol so all UI surfaces render normalized localized text instead of raw JSON payloads.

**Architecture:** Expand the install-progress contract to preserve Rust-like event semantics, normalize CLI events in the repository layer, persist queue-facing display text separately from raw detail, and update all install-progress widgets to consume the normalized task fields.

**Tech Stack:** Flutter desktop, Riverpod, Freezed, build_runner, widget tests, unit tests

---

### Task 1: Document The Approved Protocol Migration

**Files:**
- Create: `docs/superpowers/specs/2026-03-22-install-progress-protocol-parity-design.md`
- Create: `docs/superpowers/plans/2026-03-22-install-progress-protocol-parity.md`

- [ ] **Step 1: Write the approved design spec**

Capture the Rust event semantics, Flutter deltas, and normalized field boundaries.

- [ ] **Step 2: Write the implementation plan**

Break the work into model, parser/repository, queue, UI, and verification tasks.

- [ ] **Step 3: Commit the docs**

```bash
git add docs/superpowers/specs/2026-03-22-install-progress-protocol-parity-design.md docs/superpowers/plans/2026-03-22-install-progress-protocol-parity.md
git commit -m "docs: 补充安装进度协议迁移方案"
```

### Task 2: Add Red Tests For The Normalized Progress Contract

**Files:**
- Modify: `test/unit/data/mappers/cli_output_parser_test.dart`
- Modify: `test/unit/application/providers/install_queue_provider_test.dart`
- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`
- Modify or create: focused install-status widget tests if existing coverage is insufficient

- [ ] **Step 1: Add parser/repository-facing expectations**

Cover:

- JSON progress events keep raw message text but expose normalized status text
- JSON error events keep error detail while mapping localized error summary
- message-only JSON events do not leak raw payload text

- [ ] **Step 2: Add queue expectations**

Cover:

- queue current task stores normalized display text
- failed task stores localized summary plus raw detail separately
- cancelled task still produces consistent localized cancellation text

- [ ] **Step 3: Add widget expectations**

Cover:

- download manager renders normalized text, not raw JSON
- detail/update surfaces render normalized task text for active installs

- [ ] **Step 4: Run focused tests to verify RED**

```bash
/home/han/flutter/bin/flutter test test/unit/data/mappers/cli_output_parser_test.dart
/home/han/flutter/bin/flutter test test/unit/application/providers/install_queue_provider_test.dart
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart
```

Expected: new protocol-parity assertions fail before implementation.

- [ ] **Step 5: Commit the red/green test coverage**

```bash
git add test/unit/data/mappers/cli_output_parser_test.dart test/unit/application/providers/install_queue_provider_test.dart test/widget/presentation/widgets/download_manager_dialog_test.dart
git commit -m "test: 补充安装进度协议迁移测试"
```

### Task 3: Expand The Install Progress Contract

**Files:**
- Modify: `lib/domain/models/install_progress.dart`
- Modify: `lib/domain/models/install_task.dart`
- Modify: `lib/core/i18n/install_messages.dart`
- Modify: generated files updated by build_runner

- [ ] **Step 1: Add explicit event semantics to progress/task models**

Introduce fields needed to preserve Rust-like event kind, normalized display text, and raw error detail.

- [ ] **Step 2: Move status/error text mapping into install i18n helpers**

Keep repository logic free of widget dependencies while reproducing Rust mappings.

- [ ] **Step 3: Regenerate generated files**

```bash
/home/han/flutter/bin/dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Run focused unit tests**

```bash
/home/han/flutter/bin/flutter test test/unit/data/mappers/cli_output_parser_test.dart
```

- [ ] **Step 5: Commit the contract changes**

```bash
git add lib/domain/models/install_progress.dart lib/domain/models/install_task.dart lib/core/i18n/install_messages.dart
git add lib/domain/models/*.g.dart lib/domain/models/*.freezed.dart lib/application/providers/*.g.dart
git commit -m "refactor: 统一安装进度事件协议"
```

### Task 4: Normalize Repository And Queue Behavior

**Files:**
- Modify: `lib/data/mappers/cli_output_parser.dart`
- Modify: `lib/data/repositories/linglong_cli_repository_impl.dart`
- Modify: `lib/domain/models/install_state_machine.dart`
- Modify: `lib/application/providers/install_queue_provider.dart`
- Modify: `test/unit/application/providers/install_queue_provider_test.dart`

- [ ] **Step 1: Stop using raw CLI lines as display text**

Repository output must derive normalized status from parsed events instead of passing `event.line` through.

- [ ] **Step 2: Preserve raw detail while storing normalized queue text**

Queue state should keep user-facing display text separate from raw backend detail.

- [ ] **Step 3: Align timeout/message handling with the current Rust implementation**

Retain the current Rust-style timeout window and `message` event timestamp refresh behavior.

- [ ] **Step 4: Run focused queue and parser tests**

```bash
/home/han/flutter/bin/flutter test test/unit/data/mappers/cli_output_parser_test.dart
/home/han/flutter/bin/flutter test test/unit/application/providers/install_queue_provider_test.dart
/home/han/flutter/bin/flutter test test/unit/domain/models/install_state_machine_test.dart
```

- [ ] **Step 5: Commit repository and queue normalization**

```bash
git add lib/data/mappers/cli_output_parser.dart lib/data/repositories/linglong_cli_repository_impl.dart lib/domain/models/install_state_machine.dart lib/application/providers/install_queue_provider.dart test/unit/application/providers/install_queue_provider_test.dart test/unit/data/mappers/cli_output_parser_test.dart
git commit -m "fix: 规范安装链路进度文案"
```

### Task 5: Switch Presentation To Normalized Task Fields

**Files:**
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
- Modify: `lib/presentation/pages/update_app/update_app_page.dart`
- Modify if needed: `lib/presentation/widgets/install_button.dart`
- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`

- [ ] **Step 1: Replace raw task-message assumptions in install UI**

Widgets should render queue-provided normalized display text and only show detail where that surface already supports detail messaging.

- [ ] **Step 2: Keep error and success affordances unchanged**

Do not regress cancel/retry/open/remove flows or progress display structure.

- [ ] **Step 3: Run focused widget verification**

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart
```

- [ ] **Step 4: Commit the UI switch**

```bash
git add lib/presentation/widgets/download_manager_dialog.dart lib/presentation/pages/app_detail/app_detail_page.dart lib/presentation/pages/update_app/update_app_page.dart lib/presentation/widgets/install_button.dart test/widget/presentation/widgets/download_manager_dialog_test.dart
git commit -m "fix: 统一安装进度展示文案"
```

### Task 6: Final Verification

**Files:**
- Review all changed files above

- [ ] **Step 1: Regenerate generated files one final time**

```bash
/home/han/flutter/bin/dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Run full focused verification**

```bash
/home/han/flutter/bin/flutter test test/unit/data/mappers/cli_output_parser_test.dart test/unit/application/providers/install_queue_provider_test.dart test/unit/domain/models/install_state_machine_test.dart test/widget/presentation/widgets/download_manager_dialog_test.dart
/home/han/flutter/bin/flutter analyze lib/domain/models/install_progress.dart lib/domain/models/install_task.dart lib/core/i18n/install_messages.dart lib/data/mappers/cli_output_parser.dart lib/data/repositories/linglong_cli_repository_impl.dart lib/domain/models/install_state_machine.dart lib/application/providers/install_queue_provider.dart lib/presentation/widgets/download_manager_dialog.dart lib/presentation/pages/app_detail/app_detail_page.dart lib/presentation/pages/update_app/update_app_page.dart lib/presentation/widgets/install_button.dart
```

- [ ] **Step 3: Review acceptance criteria against the design**

Confirm:

- raw JSON no longer reaches UI
- Rust-like event semantics are preserved
- localized error mapping and raw detail both remain available
- queue and cancellation behavior remain stable

- [ ] **Step 4: Prepare handoff summary**

Report verification evidence, key changes, and residual risks if any remain.
