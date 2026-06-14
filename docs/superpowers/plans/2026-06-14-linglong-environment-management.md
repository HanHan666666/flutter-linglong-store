# Linglong Environment Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add full Linglong repository management, environment analysis/repair, and storage-location migration through a centralized settings dialog.

**Architecture:** Extend the existing layered Flutter architecture. `LinglongCliRepository` owns all `ll-cli` commands, `LinglongEnvironmentManagementService` owns non-CLI system diagnostics and controlled privileged scripts, Riverpod providers expose immutable UI state, and presentation widgets stay command-free.

**Tech Stack:** Flutter, Riverpod, existing ShellCommandExecutor/CliExecutor, ll-cli, ostree, systemd mount units, flutter_test.

---

## File Structure

- Modify `lib/domain/repositories/linglong_cli_repository.dart`: add repo management methods.
- Modify `lib/data/repositories/linglong_cli_repository_impl.dart`: implement repo commands and parsing.
- Create `lib/domain/models/linglong_repository_config.dart`: repository config value object.
- Create `lib/domain/models/linglong_environment_management.dart`: analysis, issue, storage, action result models.
- Create `lib/application/services/linglong_environment_management_service.dart`: system diagnostics, fsck, migration script generation/execution.
- Create `lib/application/providers/linglong_repository_management_provider.dart`: repository management state.
- Create `lib/application/providers/linglong_environment_management_provider.dart`: environment analysis and repair state.
- Create `lib/presentation/widgets/linglong_environment_management_dialog.dart`: three-tab management dialog.
- Modify `lib/presentation/pages/setting/setting_page.dart`: add settings entry.
- Modify `lib/core/di/providers.dart`: export new providers if needed.
- Add unit tests under `test/unit/`.
- Add widget tests under `test/widget/`.
- Update docs and AGENTS/CLAUDE guidance after implementation.

## Tasks

### Task 1: Documentation Baseline

- [ ] Add `docs/21-linglong-environment-management.md`.
- [ ] Add spec and implementation plan under `docs/superpowers/`.
- [ ] Commit with `docs: 设计玲珑环境管理功能`.

### Task 2: Repository Management Domain And CLI

- [ ] Write failing tests for repo config parsing and repo command construction.
- [ ] Add `LinglongRepositoryConfig`.
- [ ] Extend `LinglongCliRepository`.
- [ ] Implement repo command methods in `LinglongCliRepositoryImpl`.
- [ ] Run focused unit tests.
- [ ] Commit with `feat: 添加玲珑仓库管理命令`.

### Task 3: Environment Analysis Service

- [ ] Write failing tests for storage diagnostics, OSTree fsck parsing, issue classification, and migration validation.
- [ ] Add environment management domain models.
- [ ] Implement `LinglongEnvironmentManagementService`.
- [ ] Run focused unit tests.
- [ ] Commit with `feat: 添加玲珑环境分析服务`.

### Task 4: Riverpod State

- [ ] Write failing provider tests for repository reload/mutation and analysis/repair state transitions.
- [ ] Add repository management provider.
- [ ] Add environment management provider.
- [ ] Run focused provider tests.
- [ ] Commit with `feat: 添加玲珑环境管理状态`.

### Task 5: Presentation

- [ ] Write failing widget tests for settings entry, dialog tabs, repository form validation, issue display, migration blocking.
- [ ] Add `LinglongEnvironmentManagementDialog`.
- [ ] Add repository form and storage migration form.
- [ ] Add settings page entry.
- [ ] Run focused widget tests.
- [ ] Commit with `feat: 添加玲珑环境管理界面`.

### Task 6: Docs, Generated Files, Verification

- [ ] Run code generation if needed.
- [ ] Run `flutter test test/unit/`.
- [ ] Run `flutter test test/widget/`.
- [ ] Run `flutter analyze`.
- [ ] Update AGENTS.md / CLAUDE.md change record with maintenance conventions.
- [ ] Commit docs/update if separated from code.
