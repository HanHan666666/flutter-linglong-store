# Install Failure Detail And Actions Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show ll-cli failure message details in download-center failed items and align the failed status tag with action buttons.

**Architecture:** Keep CLI parsing and queue state ownership unchanged. Normalize failure text at `LinglongCliRepositoryImpl`, keep platform guidance in `InstallQueue`, and adjust `_TaskCard` layout so status and actions live in one right-side row.

**Tech Stack:** Flutter, Riverpod, Flutter widget tests, Dart unit tests.

---

## Files

- Modify: `lib/data/repositories/linglong_cli_repository_impl.dart`
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`
- Modify: `test/unit/data/repositories/linglong_cli_repository_impl_command_test.dart`
- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`
- Add: `docs/superpowers/specs/2026-06-06-install-failure-detail-and-actions-alignment-design.md`
- Add: `docs/superpowers/plans/2026-06-06-install-failure-detail-and-actions-alignment.md`

## Task 1: Failure Detail Tests

- [ ] Add a repository test where progress emits `{"code":-1,"message":"ostree...Could not resolve hostname"}` and assert:
  - last event is failed
  - `error` contains `安装失败`
  - `error` contains `Could not resolve hostname`
  - `error` does not contain `通用错误`

- [ ] Add a repository test where progress emits `{"code":3001,"message":"mirror unavailable"}` and assert `error` contains both `网络错误` and `mirror unavailable`.

- [ ] Run:

```bash
/home/han/flutter/bin/flutter test test/unit/data/repositories/linglong_cli_repository_impl_command_test.dart --plain-name "includes ll-cli json message"
```

Expected: fails before implementation.

## Task 2: Download Center Layout Test

- [ ] Add a widget test that builds a failed history task with command output and retry/remove actions.
- [ ] Find the Row that contains `失败`, `复制日志`, refresh icon, and close icon.
- [ ] Assert that all four controls are descendants of the same Row.
- [ ] Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart --plain-name "aligns failed status with action buttons"
```

Expected: fails before implementation because the status tag is currently in the title row.

## Task 3: Implementation

- [ ] In `LinglongCliRepositoryImpl`, add a helper that combines the error summary and raw message detail.
- [ ] For `code=-1`, use `_messages.failed(operationLabel)` as the summary.
- [ ] For other codes, use `_messages.getErrorMessageFromCode(code)` as the summary.
- [ ] Append non-empty detail with `：` unless it equals the summary.
- [ ] In `_TaskCard`, remove status pill from the title row.
- [ ] Render `_buildStatusPill(context)` as the first child of `_buildActionButtons()`.
- [ ] Keep copy/retry/remove behavior unchanged.

## Task 4: Verification And Commit

- [ ] Run repository focused tests.
- [ ] Run download manager widget tests.
- [ ] Run targeted analyze on modified Dart files.
- [ ] Commit:

```bash
git add lib/data/repositories/linglong_cli_repository_impl.dart lib/presentation/widgets/download_manager_dialog.dart test/unit/data/repositories/linglong_cli_repository_impl_command_test.dart test/widget/presentation/widgets/download_manager_dialog_test.dart docs/superpowers/specs/2026-06-06-install-failure-detail-and-actions-alignment-design.md docs/superpowers/plans/2026-06-06-install-failure-detail-and-actions-alignment.md
git commit -m "fix: 展示安装失败详情并对齐操作按钮"
```
