# App List Arch Filtering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent cross-architecture apps from appearing in catalog lists and causing `应用详情不存在` failures on the detail page.

**Architecture:** Preserve architecture information end-to-end: every remote catalog request must include the current arch, list DTO/view models must retain remote arch, and detail loading must reuse the list item arch when available. Keep the change scoped to existing providers/mappers/models and protect it with regression tests.

**Tech Stack:** Flutter, Riverpod, Freezed/JsonSerializable, Mockito, flutter_test

---

### Task 1: Stabilize generated sources and add regression tests

**Files:**
- Modify: `lib/domain/models/recommend_models.dart`
- Modify: `lib/data/models/api_dto.dart`
- Modify: `test/unit/data/repositories/app_repository_impl_test.dart`
- Modify: `test/unit/application/providers/all_apps_provider_test.dart`
- Modify: `test/unit/application/providers/recommend_provider_test.dart`
- Create or Modify: generated `*.g.dart` / `*.freezed.dart` affected by the above

- [ ] **Step 1: Write failing tests for missing arch propagation**
- [ ] **Step 2: Run targeted tests and confirm they fail for the expected reason**
- [ ] **Step 3: Add missing model fields needed by the tests (`arch` on catalog DTO/view model)**
- [ ] **Step 4: Re-run targeted tests to keep the failure focused on implementation gaps, not missing types**

### Task 2: Propagate arch through repository/provider catalog requests

**Files:**
- Modify: `lib/data/repositories/app_repository_impl.dart`
- Modify: `lib/application/providers/all_apps_provider.dart`
- Modify: `lib/application/providers/recommend_provider.dart`
- Modify: `lib/application/providers/ranking_provider.dart`
- Modify: `lib/application/providers/custom_category_provider.dart`
- Modify: `lib/data/mappers/app_list_mapper.dart`

- [ ] **Step 1: Update repository-level catalog requests to always send current arch**
- [ ] **Step 2: Update provider-level direct API calls to always send current arch**
- [ ] **Step 3: Preserve backend-returned arch in catalog mapping instead of overwriting it locally**
- [ ] **Step 4: Re-run targeted catalog tests and confirm they pass**

### Task 3: Reuse list-item arch when entering detail flow

**Files:**
- Modify: `lib/application/providers/app_detail_provider.dart`
- Modify: `lib/core/config/routes.dart` (only if route extra handling needs strengthening)
- Modify: `test/widget/presentation/pages/app_detail/app_detail_page_test.dart` or add a focused provider test if better scoped

- [ ] **Step 1: Add a failing regression test showing detail loading should prefer `initialApp.arch`**
- [ ] **Step 2: Implement minimal provider change so detail API uses the incoming app context arch**
- [ ] **Step 3: Re-run the detail regression test and confirm it passes**

### Task 4: Regenerate code and verify the full regression slice

**Files:**
- Modify: generated `*.g.dart` / `*.freezed.dart` / Riverpod outputs touched by the changes

- [ ] **Step 1: Run code generation (`build_runner`) and review generated diffs**
- [ ] **Step 2: Run targeted unit/widget tests for repository/providers/detail flow**
- [ ] **Step 3: Run `flutter analyze` on the worktree and confirm zero new issues in changed code paths**
- [ ] **Step 4: Request code review before reporting completion**
