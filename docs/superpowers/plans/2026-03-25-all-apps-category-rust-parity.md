# All Apps Category Rust Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Realign the Flutter all-apps category flow with the Rust implementation so category chips query `/visit/getSearchAppList` with real `categoryId` values, page size `30`, and stable regression coverage across DTO, provider, and page layers.

**Architecture:** Keep the current UI structure intact, but correct the data contract and query path underneath it. The fix starts at the shared search request DTO, then rewires `AppRepositoryImpl` and `all_apps_provider.dart` to use one consistent category-filtered search API, and finally adds page-level interaction tests plus docs to lock the rule into the repo.

**Tech Stack:** Flutter, Riverpod codegen, Freezed/json_serializable, Mockito, flutter_test

---

## Preflight

- In a fresh worktree, this repo does not contain tracked generated files such as `all_apps_provider.g.dart` and `recommend_models.freezed.dart`.
- Before trusting provider/widget test failures, materialize generated outputs once:

```bash
/home/han/flutter/bin/dart run build_runner build --delete-conflicting-outputs
```

- Do not skip this step. Without it, `flutter test` can fail for missing generated parts before reaching the real regression.
- Treat every `*.g.dart` / `*.freezed.dart` path below as a `build_runner` output. Do not hand-edit those files.

### Task 1: Restore the search request contract for category filters

**Files:**
- Modify: `lib/data/models/api_dto.dart`
- Modify: `lib/data/models/api_dto.g.dart`
- Modify: `lib/data/repositories/app_repository_impl.dart`
- Modify: `test/unit/data/models/search_request_test.dart`
- Modify: `test/unit/data/repositories/app_repository_impl_test.dart`

- [ ] **Step 1: Add the failing DTO serialization assertion**

Extend `test/unit/data/models/search_request_test.dart` with a case like:

```dart
test('should serialize categoryId when provided', () {
  const request = SearchAppListRequest(
    keyword: '',
    categoryId: '07',
    pageNo: 1,
    pageSize: 30,
    repoName: 'stable',
  );

  final json = request.toJson();

  expect(json['name'], equals(''));
  expect(json['categoryId'], equals('07'));
  expect(json['pageSize'], equals(30));
});
```

- [ ] **Step 2: Add the failing repository passthrough assertion**

Extend `test/unit/data/repositories/app_repository_impl_test.dart` with a case like:

```dart
test('passes category to getSearchAppList when requesting filtered all apps', () async {
  when(mockApiService.getSearchAppList(any)).thenAnswer(
    (_) async => _buildSearchResponse(const []),
  );

  await repository.getAllApps(category: '07', page: 1, pageSize: 30);

  final captured =
      verify(mockApiService.getSearchAppList(captureAny)).captured.single
          as SearchAppListRequest;
  expect(captured.keyword, equals(''));
  expect(captured.categoryId, equals('07'));
  expect(captured.pageSize, equals(30));
});
```

- [ ] **Step 3: Run focused tests to verify RED**

Run:

```bash
/home/han/flutter/bin/flutter test test/unit/data/models/search_request_test.dart
/home/han/flutter/bin/flutter test test/unit/data/repositories/app_repository_impl_test.dart
```

Expected: FAIL because `SearchAppListRequest` has no `categoryId` field and `AppRepositoryImpl.getAllApps(category: ...)` ignores its `category` argument.

- [ ] **Step 4: Implement the minimal request-contract fix**

Update `SearchAppListRequest` in `lib/data/models/api_dto.dart` to include the missing field:

```dart
const factory SearchAppListRequest({
  @JsonKey(name: 'name') required String keyword,
  String? categoryId,
  @JsonKey(name: 'pageNo') @Default(1) int pageNo,
  @JsonKey(name: 'pageSize') @Default(20) int pageSize,
  ...
}) = _SearchAppListRequest;
```

Then update `AppRepositoryImpl.getAllApps()` to forward the optional category:

```dart
SearchAppListRequest(
  keyword: '',
  categoryId: category,
  pageNo: page,
  pageSize: pageSize,
  lan: _resolveLang(ApiClient.getLocale?.call()),
)
```

- [ ] **Step 5: Regenerate JSON output**

Run:

```bash
/home/han/flutter/bin/dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Re-run the focused tests to verify GREEN**

Run:

```bash
/home/han/flutter/bin/flutter test test/unit/data/models/search_request_test.dart
/home/han/flutter/bin/flutter test test/unit/data/repositories/app_repository_impl_test.dart
```

Expected: PASS, and the captured request now contains `categoryId`.

- [ ] **Step 7: Commit the contract fix**

```bash
git add lib/data/models/api_dto.dart \
  lib/data/models/api_dto.g.dart \
  lib/data/repositories/app_repository_impl.dart \
  test/unit/data/models/search_request_test.dart \
  test/unit/data/repositories/app_repository_impl_test.dart
git commit -m "fix: 补齐全部应用分类请求契约"
```

### Task 2: Rewire the all-apps provider to the Rust query path

**Files:**
- Modify: `lib/application/providers/all_apps_provider.dart`
- Modify: `lib/application/providers/all_apps_provider.freezed.dart`
- Modify: `lib/application/providers/all_apps_provider.g.dart`
- Modify: `test/unit/application/providers/all_apps_provider_test.dart`
- Create: `test/widget/presentation/pages/all_apps_page_test.dart`

- [ ] **Step 1: Add failing provider and page behavior tests**

Expand `test/unit/application/providers/all_apps_provider_test.dart` to cover these behaviors:

```dart
test('loads all apps via getSearchAppList instead of welcome/sidebar endpoints', () async {
  when(mockApiService.getDisCategoryList()).thenAnswer((_) async => _buildCategoryResponse());
  when(mockApiService.getSearchAppList(any)).thenAnswer(
    (_) async => _buildSearchResponse(const [
      AppListItemDTO(appId: 'all.app', appName: 'All App', appVersion: '1.0.0'),
    ]),
  );

  final container = ProviderContainer(
    overrides: [appApiServiceProvider.overrideWithValue(mockApiService)],
  );
  addTearDown(container.dispose);

  container.listen(allAppsProvider, (_, __) {});
  await _flushAsyncWork();

  verify(mockApiService.getSearchAppList(any)).called(1);
  verifyNever(mockApiService.getWelcomeAppList(any));
  verifyNever(mockApiService.getSidebarApps(any));
});
```

Add a second test for category switching:

```dart
test('selectCategory sends real categoryId and keeps rust page size 30', () async {
  when(mockApiService.getDisCategoryList()).thenAnswer((_) async => _buildCategoryResponse());
  when(mockApiService.getSearchAppList(any)).thenAnswer(
    (invocation) async {
      final request = invocation.positionalArguments.single as SearchAppListRequest;
      return _buildSearchResponse(
        [
          AppListItemDTO(
            appId: request.categoryId == '07' ? 'office.app' : 'all.app',
            appName: request.categoryId == '07' ? 'Office App' : 'All App',
            appVersion: '1.0.0',
          ),
        ],
        currentPage: request.pageNo,
        pageSize: request.pageSize,
        total: 2,
        pages: 2,
      );
    },
  );

  final container = ProviderContainer(
    overrides: [appApiServiceProvider.overrideWithValue(mockApiService)],
  );
  addTearDown(container.dispose);

  container.listen(allAppsProvider, (_, __) {});
  await _flushAsyncWork();

  container.read(allAppsProvider.notifier).selectCategory(1);
  await _flushAsyncWork();

  final captured =
      verify(mockApiService.getSearchAppList(captureAny)).captured
          .cast<SearchAppListRequest>();
  expect(captured.last.categoryId, equals('07'));
  expect(captured.last.pageSize, equals(30));
});
```

Add a third provider test for `loadMore()` preserving `categoryId`.

Then create `test/widget/presentation/pages/all_apps_page_test.dart` with:

```dart
testWidgets('tapping a category chip shows that category app list instead of empty state', (tester) async {
  when(mockApiService.getDisCategoryList()).thenAnswer((_) async => _buildCategoryResponse(
    const [
      CategoryDTO(categoryId: '07', categoryName: '效率办公', appCount: 12),
      CategoryDTO(categoryId: '08', categoryName: '系统工具', appCount: 8),
    ],
  ));

  when(mockApiService.getSearchAppList(any)).thenAnswer((invocation) async {
    final request = invocation.positionalArguments.single as SearchAppListRequest;
    if (request.categoryId == '07') {
      return _buildSearchResponse(const [
        AppListItemDTO(appId: 'office.app', appName: 'Office App', appVersion: '1.0.0'),
      ]);
    }
    return _buildSearchResponse(const [
      AppListItemDTO(appId: 'all.app', appName: 'All App', appVersion: '1.0.0'),
    ]);
  });

  await tester.pumpWidget(_buildTestApp(mockApiService));
  await tester.pumpAndSettle();

  expect(find.text('All App'), findsOneWidget);
  await tester.tap(find.text('效率办公'));
  await tester.pumpAndSettle();

  expect(find.text('Office App'), findsOneWidget);
  expect(find.text('暂无应用'), findsNothing);
});
```

Use the same override pattern as `recommend_page_test.dart` for `applicationCardStateIndexProvider`:

```dart
applicationCardStateIndexProvider.overrideWithValue(
  const ApplicationCardStateIndex(
    installedVersionByAppId: {},
    updateAppIds: {},
    activeTasksByAppId: {},
  ),
)
```

Build the test shell with the same shape as the recommend-page tests so localization and theme-dependent widgets are available:

```dart
Widget _buildTestApp(MockAppApiService mockApiService) {
  return ProviderScope(
    overrides: [
      appApiServiceProvider.overrideWithValue(mockApiService),
      applicationCardStateIndexProvider.overrideWithValue(
        const ApplicationCardStateIndex(
          installedVersionByAppId: {},
          updateAppIds: {},
          activeTasksByAppId: {},
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AllAppsPage()),
    ),
  );
}
```

- [ ] **Step 2: Run the provider and page tests to verify RED**

Run:

```bash
/home/han/flutter/bin/flutter test test/unit/application/providers/all_apps_provider_test.dart
/home/han/flutter/bin/flutter test test/widget/presentation/pages/all_apps_page_test.dart
```

Expected: FAIL because the current provider calls `getWelcomeAppList` for “全部” and `getSidebarApps` for specific categories, both at page size `20`, so the widget test should still fall into the wrong data source path.

- [ ] **Step 3: Implement the provider realignment**

In `lib/application/providers/all_apps_provider.dart`:

- introduce a dedicated page-size constant:

```dart
const int _allAppsPageSize = 30;
```

- rename the selection helper to reflect actual semantics:

```dart
String? _getSelectedCategoryId()
```

- replace `_fetchApps()` with a single `getSearchAppList()` path:

```dart
final response = await apiService.getSearchAppList(
  SearchAppListRequest(
    keyword: '',
    categoryId: categoryId,
    pageNo: page,
    pageSize: _allAppsPageSize,
    lan: _resolveApiLang(ApiClient.getLocale?.call()),
  ),
);
```

- remove the branch that calls `getSidebarApps`
- remove the branch that calls `getWelcomeAppList`
- make `loadMore()` preserve `categoryId` and `pageSize: _allAppsPageSize`

- [ ] **Step 4: Regenerate Riverpod/Freezed output**

Run:

```bash
/home/han/flutter/bin/dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Re-run the provider and page tests to verify GREEN**

Run:

```bash
/home/han/flutter/bin/flutter test test/unit/application/providers/all_apps_provider_test.dart
/home/han/flutter/bin/flutter test test/widget/presentation/pages/all_apps_page_test.dart
```

Expected: PASS, with no calls to sidebar/welcome APIs, all captured requests using `pageSize: 30`, and the widget test rendering the category-specific app card after a chip tap.

- [ ] **Step 6: Commit the provider fix and page regression**

```bash
git add lib/application/providers/all_apps_provider.dart \
  lib/application/providers/all_apps_provider.freezed.dart \
  lib/application/providers/all_apps_provider.g.dart \
  test/unit/application/providers/all_apps_provider_test.dart \
  test/widget/presentation/pages/all_apps_page_test.dart
git commit -m "fix: 对齐全部应用分类查询逻辑"
```

### Task 3: Verify the changed slice and sync repo conventions

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/superpowers/specs/2026-03-25-all-apps-category-rust-parity-design.md`
- Modify: `docs/superpowers/plans/2026-03-25-all-apps-category-rust-parity.md`

- [ ] **Step 1: Run targeted verification**

Run:

```bash
/home/han/flutter/bin/dart analyze \
  lib/data/models/api_dto.dart \
  lib/data/repositories/app_repository_impl.dart \
  lib/application/providers/all_apps_provider.dart \
  test/unit/data/models/search_request_test.dart \
  test/unit/data/repositories/app_repository_impl_test.dart \
  test/unit/application/providers/all_apps_provider_test.dart \
  test/widget/presentation/pages/all_apps_page_test.dart

/home/han/flutter/bin/flutter test test/unit/data/models/search_request_test.dart
/home/han/flutter/bin/flutter test test/unit/data/repositories/app_repository_impl_test.dart
/home/han/flutter/bin/flutter test test/unit/application/providers/all_apps_provider_test.dart
/home/han/flutter/bin/flutter test test/widget/presentation/pages/all_apps_page_test.dart
```

Expected: analyze clean for the touched slice, all focused tests PASS.

- [ ] **Step 2: Update repo-level conventions**

Add a new `AGENTS.md` entry that records:
- 全部应用页分类筛选统一走 `/visit/getSearchAppList`
- 分类值必须传真实 `categoryId`，不能再把它当成 `menuCode`
- 全部应用页分页大小与 Rust 旧版对齐为 `30`

- [ ] **Step 3: Keep the docs in sync with the final implementation**

If implementation changes the agreed behavior or names in a meaningful way, update:
- `docs/superpowers/specs/2026-03-25-all-apps-category-rust-parity-design.md`
- `docs/superpowers/plans/2026-03-25-all-apps-category-rust-parity.md`

If implementation matches the documents exactly, only refresh wording that is genuinely stale. Do not churn the docs without signal.

- [ ] **Step 4: Commit docs separately**

```bash
git add AGENTS.md \
  docs/superpowers/specs/2026-03-25-all-apps-category-rust-parity-design.md \
  docs/superpowers/plans/2026-03-25-all-apps-category-rust-parity.md
git commit -m "docs: 记录全部应用分类 Rust 对齐约定"
```
