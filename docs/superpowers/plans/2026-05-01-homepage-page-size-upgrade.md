# Homepage Recommend Page Size Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the homepage recommend feed to request 30 apps per page on first load and subsequent pagination, instead of 10.

**Architecture:** Keep the change scoped to the existing recommend-page flow. Update the recommend provider's page-size constant, lock the new behavior with provider and widget tests, and sync the repo docs that currently codify homepage page size as 10 so code and guidance stay aligned.

**Tech Stack:** Flutter, Riverpod, Flutter Test, Mockito, Markdown docs

---

### Task 1: Lock the new homepage pagination behavior with tests

**Files:**
- Modify: `test/unit/application/providers/recommend_provider_test.dart`
- Modify: `test/widget/presentation/pages/recommend_page_test.dart`

- [ ] **Step 1: Update provider test expectations to 30**

```dart
    test('loads more with upgraded page size 30', () async {
      ...
      expect(captured[0].pageSize, equals(30));
      expect(captured[1].pageNo, equals(2));
      expect(captured[1].pageSize, equals(30));
    });
```

- [ ] **Step 2: Update widget test assertions to 30**

```dart
      expect(captured, hasLength(2));
      expect(captured[0].pageNo, equals(1));
      expect(captured[0].pageSize, equals(30));
      expect(captured[1].pageNo, equals(2));
      expect(captured[1].pageSize, equals(30));
```

- [ ] **Step 3: Run the targeted tests and verify they fail before production changes**

Run: `flutter test test/unit/application/providers/recommend_provider_test.dart test/widget/presentation/pages/recommend_page_test.dart`
Expected: FAIL because `recommend_provider.dart` still requests page size 10.

### Task 2: Upgrade homepage recommend provider to 30

**Files:**
- Modify: `lib/application/providers/recommend_provider.dart`

- [ ] **Step 1: Change the recommend provider page-size constant**

```dart
class Recommend extends _$Recommend {
  static const int _pageSize = 30;
```

- [ ] **Step 2: Keep all request and merge paths using the shared constant**

```dart
        PageParams(
          pageNo: 1,
          pageSize: _pageSize,
          arch: _arch,
          lan: resolveApiLang(ApiClient.getLocale?.call()),
        ),
```

- [ ] **Step 3: Re-run the targeted tests and verify they pass**

Run: `flutter test test/unit/application/providers/recommend_provider_test.dart test/widget/presentation/pages/recommend_page_test.dart`
Expected: PASS.

### Task 3: Sync repository docs with the new homepage rule

**Files:**
- Modify: `docs/03d-ui-pages.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Update homepage page-size rule in the page spec**

```md
- 推荐列表分页大小固定为 `30`
```

- [ ] **Step 2: Update the repo guidance entry that still states 10**

```md
- 2026-03-19：推荐页必须严格对齐当前 Rust 首页，只保留轮播区、`玲珑推荐` 标题和推荐应用列表；分页大小固定为 `30`，首屏支持缓存优先展示，但暂不做页面重新可见后的后台刷新缓存页。
```

- [ ] **Step 3: Re-scan the touched docs for stale homepage page-size references**

Run: `rg -n "推荐页.*分页大小固定为|推荐列表分页大小固定为" docs/03d-ui-pages.md AGENTS.md`
Expected: Only `30` remains in those updated files.

### Task 4: Final verification

**Files:**
- Verify only

- [ ] **Step 1: Run targeted homepage tests**

Run: `flutter test test/unit/application/providers/recommend_provider_test.dart test/widget/presentation/pages/recommend_page_test.dart`
Expected: PASS.

- [ ] **Step 2: Run static analysis on the changed provider and tests**

Run: `flutter analyze lib/application/providers/recommend_provider.dart test/unit/application/providers/recommend_provider_test.dart test/widget/presentation/pages/recommend_page_test.dart`
Expected: No issues found.

- [ ] **Step 3: Confirm working tree only contains the intended homepage upgrade changes**

Run: `git status --short`
Expected: Shows the recommend provider, the updated tests, the updated docs, and this plan file.
