# og Protocol Install Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Do not use git worktree; repository instructions forbid it without explicit permission.

**Goal:** Make the Flutter Linux desktop store handle `og://appId` links from the web store and enqueue the requested application install through the existing installation queue.

**Architecture:** XDG desktop metadata declares `x-scheme-handler/og` and passes URLs via `%u`. Linux/Dart startup and the existing single-instance socket deliver URLs to a new application-layer controller that parses, validates, waits for launch readiness, fetches app details, and reuses `appOperationQueueControllerProvider`.

**Tech Stack:** Flutter Linux, Riverpod, go_router, Unix domain socket single-instance bridge, FreeDesktop desktop entry metadata.

---

### Task 1: Protocol Parsing And Single-Instance Message Model

**Files:**
- Create: `lib/core/protocol/og_protocol_request.dart`
- Modify: `lib/core/platform/single_instance.dart`
- Test: `test/unit/core/protocol/og_protocol_request_test.dart`
- Test: `test/unit/core/platform/single_instance_protocol_test.dart`

- [ ] Write failing parser tests for valid and invalid `og://` URLs.
- [ ] Implement `OgProtocolRequest.tryParse`.
- [ ] Write failing single-instance message tests for activate-only and open-url payloads.
- [ ] Extend single-instance socket messages from plain `ACTIVATE` to JSON while keeping old `ACTIVATE` compatible.
- [ ] Run focused tests and commit.

### Task 2: Application Controller

**Files:**
- Create: `lib/application/providers/og_install_controller.dart`
- Modify: `lib/app.dart`
- Test: `test/unit/application/providers/og_install_controller_test.dart`

- [ ] Write failing tests for pending-before-launch, environment block, detail lookup, queue dedupe, and enqueue success.
- [ ] Implement `OgInstallController` with an in-memory pending appId queue and mounted-safe async processing.
- [ ] Add an app-level listener that drains protocol requests after `launchSequenceProvider.isCompleted`.
- [ ] Run focused tests and commit.

### Task 3: Linux Entry Point And XDG Metadata

**Files:**
- Modify: `lib/main.dart`
- Modify: `linux/runner/my_application.cc`
- Modify: `build/packaging/linux/linglong-store.desktop.in`
- Test: `test/unit/packaging/desktop_entry_protocol_test.dart`

- [ ] Write failing desktop metadata test for `Exec=@EXECUTABLE_NAME@ %u` and `MimeType=x-scheme-handler/og;`.
- [ ] Pass startup args from `main(List<String> args)` into the controller.
- [ ] Ensure Linux runner forwards URL arguments and existing instances send URL payloads to the primary process through `SingleInstance`.
- [ ] Update desktop template according to XDG conventions.
- [ ] Run focused tests and commit.

### Task 4: Verification And Documentation

**Files:**
- Modify: `docs/AGENTS.md` if present or root `AGENTS.md`/`CLAUDE.md` equivalent if repository guide needs a new convention.
- Verify generated files if Riverpod annotations change.

- [ ] Run code generation if generated provider files changed.
- [ ] Run `flutter test` for focused suites.
- [ ] Run `flutter analyze`.
- [ ] Run a packaging render check for desktop metadata.
- [ ] Commit final documentation/verification adjustments.

