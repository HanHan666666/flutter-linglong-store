# 标题栏搜索候选 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为标题栏搜索框增加远端搜索候选，候选仅展示应用名称，点击后直接进入详情页，同时保持 `Enter` 继续进入搜索结果页。

**Architecture:** 不新增接口，不改搜索结果页状态机。新增独立的标题栏候选 provider，输入框内做防抖，请求 `/visit/getSearchAppList` 的第一页小页量数据；候选点击沿用现有详情页路由，并把搜索结果模型到详情页的 `arch + repoName + module` 透传补齐。

**Tech Stack:** Flutter, Riverpod, GoRouter, Widget Test, Mockito.

---

## 0. 实施前约束

- 不使用 git worktree；当前仓库规则禁止未经允许使用 worktree。
- 不在 `master` 直接写实现代码；使用功能分支承载开发。
- 先写失败测试，再写实现代码。
- 修改 Riverpod 注解时必须同步更新生成产物。

## 1. 文件改动清单

### Create

- `lib/application/providers/title_search_suggestions_provider.dart`
- `test/unit/application/providers/title_search_suggestions_provider_test.dart`
- `test/unit/data/mappers/app_list_mapper_test.dart`

### Modify

- `lib/domain/models/recommend_models.dart`
- `lib/data/mappers/app_list_mapper.dart`
- `lib/presentation/widgets/title_bar.dart`
- `test/widget/presentation/widgets/title_bar_search_test.dart`
- `AGENTS.md`

### Generate

- `lib/application/providers/title_search_suggestions_provider.g.dart`

---

## 2. Task 1：补齐搜索结果到详情页的身份透传

**Files:**

- Modify: `lib/domain/models/recommend_models.dart`
- Modify: `lib/data/mappers/app_list_mapper.dart`
- Test: `test/unit/data/mappers/app_list_mapper_test.dart`

- [ ] **Step 1: 先写失败测试**

新增 `test/unit/data/mappers/app_list_mapper_test.dart`，覆盖两个行为：

```dart
test('mapAppListToRecommendApps preserves arch module and repoName', () {
  final response = AppListPagedData(
    records: const [
      AppListItemDTO(
        appId: 'org.example.app',
        appName: '示例应用',
        appVersion: '1.2.3',
        arch: 'arm64',
        module: 'binary',
        repoName: 'repo',
      ),
    ],
    total: 1,
    size: 8,
    current: 1,
    pages: 1,
  );

  final mapped = mapAppListToRecommendApps(response, pageSize: 8).items.single;

  expect(mapped.arch, 'arm64');
  expect(mapped.module, 'binary');
  expect(mapped.repoName, 'repo');
});

test('RecommendAppInfo.toInstalledApp keeps module and repoName', () {
  const app = RecommendAppInfo(
    appId: 'org.example.app',
    name: '示例应用',
    version: '1.2.3',
    arch: 'arm64',
    module: 'binary',
    repoName: 'repo',
  );

  final installed = app.toInstalledApp();

  expect(installed.arch, 'arm64');
  expect(installed.module, 'binary');
  expect(installed.repoName, 'repo');
});
```

- [ ] **Step 2: 运行测试并确认 RED**

Run:

```bash
flutter test test/unit/data/mappers/app_list_mapper_test.dart
```

Expected:

```text
FAIL，提示 `RecommendAppInfo` 缺少 `module` / `repoName` 或映射断言不成立。
```

- [ ] **Step 3: 写最小实现**

在 `lib/domain/models/recommend_models.dart` 的 `RecommendAppInfo` 中补字段，并在 `toInstalledApp()` 中透传：

```dart
const factory RecommendAppInfo({
  required String appId,
  required String name,
  required String version,
  String? description,
  String? icon,
  String? developer,
  String? category,
  String? size,
  String? arch,
  String? module,
  String? repoName,
  double? rating,
  int? downloadCount,
  @Default(false) bool isInstalled,
  @Default(false) bool hasUpdate,
}) = _RecommendAppInfo;
```

并在 `lib/data/mappers/app_list_mapper.dart` 中补齐：

```dart
      .map(
        (dto) => RecommendAppInfo(
          appId: dto.appId,
          name: dto.appName,
          version: dto.appVersion ?? '',
          description: dto.appDesc,
          icon: dto.appIcon,
          developer: dto.developerName,
          category: dto.categoryName,
          size: dto.packageSize,
          arch: dto.arch,
          module: dto.module,
          repoName: dto.repoName,
          downloadCount: dto.downloadTimes,
        ),
      )
```

- [ ] **Step 4: 运行测试并确认 GREEN**

Run:

```bash
flutter test test/unit/data/mappers/app_list_mapper_test.dart
```

Expected:

```text
All tests passed.
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/domain/models/recommend_models.dart \
  lib/data/mappers/app_list_mapper.dart \
  test/unit/data/mappers/app_list_mapper_test.dart
git commit -m "refactor: 补齐搜索结果详情身份透传"
```

---

## 3. Task 2：新增标题栏候选 provider

**Files:**

- Create: `lib/application/providers/title_search_suggestions_provider.dart`
- Generate: `lib/application/providers/title_search_suggestions_provider.g.dart`
- Test: `test/unit/application/providers/title_search_suggestions_provider_test.dart`

- [ ] **Step 1: 先写失败测试**

新增 `test/unit/application/providers/title_search_suggestions_provider_test.dart`，至少覆盖：

```dart
test('loadSuggestions with empty query clears state and skips API', () async {
  final api = MockAppApiService();
  final container = ProviderContainer(
    overrides: [appApiServiceProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);

  await container
      .read(titleSearchSuggestionsProvider.notifier)
      .loadSuggestions('   ');

  final state = container.read(titleSearchSuggestionsProvider);
  expect(state.items, isEmpty);
  expect(state.isLoading, isFalse);
  verifyNever(api.getSearchAppList(any));
});

test('loadSuggestions fetches first page with pageSize 8', () async {
  final api = MockAppApiService();
  when(api.getSearchAppList(any)).thenAnswer((_) async => _buildSearchResponse());

  final container = ProviderContainer(
    overrides: [appApiServiceProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);

  await container
      .read(titleSearchSuggestionsProvider.notifier)
      .loadSuggestions('browser');

  final captured = verify(api.getSearchAppList(captureAny))
      .captured
      .single as SearchAppListRequest;
  expect(captured.keyword, 'browser');
  expect(captured.pageNo, 1);
  expect(captured.pageSize, 8);
});
```

- [ ] **Step 2: 运行测试并确认 RED**

Run:

```bash
flutter test test/unit/application/providers/title_search_suggestions_provider_test.dart
```

Expected:

```text
FAIL，提示 provider 或状态类型不存在。
```

- [ ] **Step 3: 写最小实现**

在 `lib/application/providers/title_search_suggestions_provider.dart` 中新增轻量状态与 provider：

```dart
class TitleSearchSuggestionsState {
  const TitleSearchSuggestionsState({
    this.items = const [],
    this.isLoading = false,
  });

  final List<RecommendAppInfo> items;
  final bool isLoading;

  TitleSearchSuggestionsState copyWith({
    List<RecommendAppInfo>? items,
    bool? isLoading,
  }) {
    return TitleSearchSuggestionsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
```

```dart
@riverpod
class TitleSearchSuggestions extends _$TitleSearchSuggestions {
  int _requestId = 0;

  @override
  TitleSearchSuggestionsState build() => const TitleSearchSuggestionsState();

  Future<void> loadSuggestions(String query) async {
    final normalizedQuery = query.trim();
    final requestId = ++_requestId;

    if (normalizedQuery.isEmpty) {
      state = const TitleSearchSuggestionsState();
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final response = await ref.read(appApiServiceProvider).getSearchAppList(
        SearchAppListRequest(
          keyword: normalizedQuery,
          pageNo: 1,
          pageSize: 8,
          arch: ref.read(globalAppProvider).arch ?? 'x86_64',
          lan: resolveApiLang(ApiClient.getLocale?.call()),
        ),
      );

      if (requestId != _requestId) {
        return;
      }

      final mapped = mapAppListToRecommendApps(response.data.data, pageSize: 8);
      state = TitleSearchSuggestionsState(items: mapped.items);
    } catch (_) {
      if (requestId != _requestId) {
        return;
      }
      state = const TitleSearchSuggestionsState();
    }
  }

  void clear() {
    _requestId++;
    state = const TitleSearchSuggestionsState();
  }
}
```

并生成产物：

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: 运行测试并确认 GREEN**

Run:

```bash
flutter test test/unit/application/providers/title_search_suggestions_provider_test.dart
```

Expected:

```text
All tests passed.
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/application/providers/title_search_suggestions_provider.dart \
  lib/application/providers/title_search_suggestions_provider.g.dart \
  test/unit/application/providers/title_search_suggestions_provider_test.dart
git commit -m "feat: 增加标题栏搜索候选状态"
```

---

## 4. Task 3：接入标题栏候选交互

**Files:**

- Modify: `lib/presentation/widgets/title_bar.dart`
- Test: `test/widget/presentation/widgets/title_bar_search_test.dart`

- [ ] **Step 1: 先写失败测试**

在 `test/widget/presentation/widgets/title_bar_search_test.dart` 新增两个场景：

```dart
testWidgets('typing in header search shows remote suggestions', (tester) async {
  final mockApiService = MockAppApiService();
  when(mockApiService.getSearchAppList(any)).thenAnswer((_) async {
    return _buildSearchResponse(
      const [
        AppListItemDTO(
          appId: 'org.example.browser',
          appName: '浏览器',
          appVersion: '1.0.0',
          arch: 'x86_64',
          module: 'binary',
          repoName: 'repo',
        ),
      ],
      currentPage: 1,
      total: 1,
      pages: 1,
    );
  });

  await tester.pumpWidget(_buildRouterApp(mockApiService));
  await tester.enterText(find.byType(TextField), '浏览');
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();

  expect(find.text('浏览器'), findsOneWidget);
});

testWidgets('tapping header suggestion opens detail page', (tester) async {
  final mockApiService = MockAppApiService();
  when(mockApiService.getSearchAppList(any)).thenAnswer((_) async {
    return _buildSearchResponse(
      const [
        AppListItemDTO(
          appId: 'org.example.browser',
          appName: '浏览器',
          appVersion: '1.0.0',
          arch: 'x86_64',
          module: 'binary',
          repoName: 'repo',
        ),
      ],
      currentPage: 1,
      total: 1,
      pages: 1,
    );
  });

  await tester.pumpWidget(_buildRouterApp(mockApiService));
  await tester.enterText(find.byType(TextField), '浏览');
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();

  await tester.tap(find.text('浏览器'));
  await tester.pumpAndSettle();

  expect(find.text('detail:org.example.browser:repo:binary'), findsOneWidget);
});
```

保留现有 `Enter` 跳 `/search_list?q=...` 的测试，作为回归保护。

- [ ] **Step 2: 运行测试并确认 RED**

Run:

```bash
flutter test test/widget/presentation/widgets/title_bar_search_test.dart
```

Expected:

```text
FAIL，提示候选文本不存在或点击后未进入详情路由。
```

- [ ] **Step 3: 写最小实现**

在 `lib/presentation/widgets/title_bar.dart` 中：

1. 把 `_TitleSearchBox` 改成 `ConsumerStatefulWidget`
2. 增加 `LayerLink + OverlayEntry + debounce Timer`
3. 输入变化时触发防抖请求
4. 根据 provider 状态展示候选 overlay
5. 点击候选时调用 `context.goToAppDetail(app.appId, appInfo: app.toInstalledApp())`
6. 提交搜索时继续走现有 `widget.onSearch(query)`

关键结构：

```dart
class _TitleSearchBox extends ConsumerStatefulWidget { ... }

class _TitleSearchBoxState extends ConsumerState<_TitleSearchBox> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _suggestionsEntry;
  Timer? _debounceTimer;

  void _queueSuggestionsFetch() {
    _debounceTimer?.cancel();
    final query = _controller.text;
    if (query.trim().isEmpty) {
      ref.read(titleSearchSuggestionsProvider.notifier).clear();
      _removeSuggestionsOverlay();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(titleSearchSuggestionsProvider.notifier).loadSuggestions(query);
    });
  }
}
```

候选内容使用：

```dart
A11yListItem(
  semanticsLabel: app.name,
  onTap: () => _openSuggestion(app),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Text(
      app.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  ),
)
```

- [ ] **Step 4: 运行测试并确认 GREEN**

Run:

```bash
flutter test test/widget/presentation/widgets/title_bar_search_test.dart
```

Expected:

```text
All tests passed.
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/presentation/widgets/title_bar.dart \
  test/widget/presentation/widgets/title_bar_search_test.dart
git commit -m "feat: 接入标题栏搜索候选交互"
```

---

## 5. Task 4：同步规范文档并做全量验证

**Files:**

- Modify: `AGENTS.md`
- Verify: `docs/superpowers/specs/2026-05-27-title-bar-search-suggestions-design.md`
- Verify: `docs/superpowers/plans/2026-05-27-title-bar-search-suggestions.md`

- [ ] **Step 1: 更新仓库约定**

在 `AGENTS.md` 的“变更记录”中新增一条，说明：

```text
标题栏搜索候选统一复用 `/visit/getSearchAppList`，仅展示应用名称；点击候选直接进入详情页，按 Enter 继续进入 `/search_list`；候选与搜索结果进入详情时都必须透传 `appId + arch + repoName + module`。
```

- [ ] **Step 2: 跑本任务相关验证**

Run:

```bash
flutter test test/unit/data/mappers/app_list_mapper_test.dart
flutter test test/unit/application/providers/title_search_suggestions_provider_test.dart
flutter test test/widget/presentation/widgets/title_bar_search_test.dart
```

Expected:

```text
3 组测试全部通过。
```

- [ ] **Step 3: 跑静态分析**

Run:

```bash
flutter analyze
```

Expected:

```text
exit 0，0 error / 0 warning。
```

- [ ] **Step 4: Commit**

```bash
git add \
  AGENTS.md \
  docs/superpowers/plans/2026-05-27-title-bar-search-suggestions.md
git commit -m "docs: 同步标题栏搜索候选约定"
```

