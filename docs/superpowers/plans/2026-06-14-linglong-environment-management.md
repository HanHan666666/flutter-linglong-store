# Linglong Environment Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add full Linglong repository management, environment analysis/repair, and storage-location migration through a centralized settings dialog.

**Architecture:** Extend the existing layered Flutter architecture. `LinglongRepositoryManagementRepository` owns `ll-cli repo` commands through `LinglongCliRepositoryImpl`, `LinglongEnvironmentManagementService` owns non-repository system diagnostics and controlled privileged scripts, Riverpod providers expose immutable UI state, and presentation widgets stay command-free.

**Tech Stack:** Flutter, Riverpod, existing ShellCommandExecutor/CliExecutor, ll-cli, ostree, systemd mount units, flutter_test.

---

## File Structure

- Create `lib/domain/repositories/linglong_repository_management_repository.dart`: add repo management interface.
- Modify `lib/data/repositories/linglong_cli_repository_impl.dart`: implement repo commands and parsing.
- Create `lib/domain/models/linglong_repository_config.dart`: repository config value object.
- Create `lib/domain/models/linglong_environment_management.dart`: analysis, issue, storage, action result models.
- Create `lib/application/services/linglong_environment_management_service.dart`: system diagnostics, fsck, migration script generation/execution.
- Create `lib/application/providers/linglong_environment_management_provider.dart`: environment analysis, repository management, and repair state.
- Create `lib/presentation/widgets/linglong_environment_management_dialog.dart`: three-tab management dialog.
- Modify `lib/presentation/pages/setting/setting_page.dart`: add settings entry.
- Add unit tests under `test/unit/`.
- Add widget tests under `test/widget/`.
- Update docs and AGENTS/CLAUDE guidance after implementation.

## Tasks

### Task 1: Documentation Baseline

- [x] Add `docs/21-linglong-environment-management.md`.
- [x] Add spec and implementation plan under `docs/superpowers/`.
- [x] Commit with `docs: 设计玲珑环境管理功能`.

### Task 2: Repository Management Domain And CLI

- [x] Write failing tests for repo config parsing and repo command construction.
- [x] Add `LinglongRepositoryConfig`.
- [x] Add `LinglongRepositoryManagementRepository`.
- [x] Implement repo command methods in `LinglongCliRepositoryImpl`.
- [x] Run focused unit tests.
- [x] Commit with `feat: 添加玲珑仓库管理命令层`.

### Task 3: Environment Analysis Service

- [x] Write failing tests for storage diagnostics, OSTree fsck parsing, issue classification, and migration validation.
- [x] Add environment management domain models.
- [x] Implement `LinglongEnvironmentManagementService`.
- [x] Run focused unit tests.
- [x] Commit with `feat: 添加玲珑环境分析修复服务`.

### Task 4: Riverpod State

- [x] Write failing provider tests for repository reload/mutation and analysis/repair state transitions.
- [x] Add repository management providers.
- [x] Add environment management provider.
- [x] Run focused provider tests.
- [x] Commit with `feat: 添加玲珑环境管理状态编排`.

### Task 5: Presentation

- [x] Write failing widget tests for settings entry and dialog tabs.
- [x] Add `LinglongEnvironmentManagementDialog`.
- [x] Add repository form and storage migration form.
- [x] Add settings page entry.
- [x] Run focused widget tests.
- [x] Commit with `feat: 添加玲珑环境管理对话框`.

### Task 6: Docs, Generated Files, Verification

- [x] Run code generation if needed.
- [x] Run focused unit/widget tests.
- [x] Run `flutter analyze`.
- [x] Update AGENTS.md / CLAUDE.md change record with maintenance conventions.
- [x] Commit docs/update if separated from code.
