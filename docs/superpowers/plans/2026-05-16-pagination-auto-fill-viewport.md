# 分页列表全屏未撑满自动补页 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复全部应用页、自定义分类页、搜索页等分页列表在全屏/大视口下首屏内容不足一屏时无法触底、无法继续加载的问题。

**Architecture:** 不修改后端接口、不新增业务 Provider、不扩大 `ll-cli` 使用。把“内容未撑满视口时自动补页”和“窗口尺寸变化后重新检查”统一收口到 `AutoLoadWhenNotScrollable` mixin，各页面只在数据已渲染后调用统一入口。

**Tech Stack:** Flutter, Riverpod, CustomScrollView, ScrollController, ScrollMetricsNotification, Widget Test, Mockito.

---

## 0. 背景与根因

当前问题页面包括：

- `全部应用`：`lib/presentation/pages/all_apps/all_apps_page.dart`
- `自定义分类页`，例如截图里的 `系统 (1371)`：`lib/presentation/pages/custom_category/custom_category_page.dart`
- `搜索结果页`：`lib/presentation/pages/search_list/search_list_page.dart`

根因：

- 这些页面已经接入 `AutoLoadWhenNotScrollable`。
- 但当前自动补页主要依赖：
  - 页面可见性变化时调用 `onVisibilityChanged(true)`
  - 用户滚动时触发 `onScroll()`
- 当首屏数据加载完成后，如果内容本身不足一屏，用户无法滚动，`onScroll()` 不会触发。
- 如果页面可见性回调早于数据加载完成，`onVisibilityChanged(true)` 那次检查也会因为 `isLoading=true` 或 `hasMore=false/data=null` 被短路。
- 最终表现为：全屏时显示一页数据，但底部还有空白，无法触底，也不会请求下一页。

正确策略：

- 数据渲染完成后，主动安排一次 post-frame 检查。
- 窗口尺寸变化、全屏变化后，也主动安排一次 post-frame 检查。
- 如果 `maxScrollExtent <= 1 && hasMore && !isLoading && !isLoadingMore && isPageVisible`，自动调用 `loadMore()`。
- 每次 `loadMore()` 完成并重新渲染后继续检查，直到内容可滚动或 `hasMore=false`。

---

## 1. 方案取舍

### 方案 A：只增大 pageSize

不推荐。

优点：改动小。

缺点：不能根治。大屏、缩放、分类数据少、搜索结果少时仍会复现。

### 方案 B：每个页面各自补一段 post-frame 检查

不推荐。

优点：局部修复快。

缺点：重复逻辑扩散，后续分页页面容易遗漏。

### 方案 C：增强 `AutoLoadWhenNotScrollable`，页面统一调用

推荐。

优点：

- 复用现有架构。
- 所有分页页行为一致。
- 不改接口、不改 Provider 数据结构。
- 符合项目里“统一入口，避免页面重复副作用”的约束。

---

## 2. 文件改动清单

### Modify

- `lib/presentation/mixins/auto_load_when_not_scrollable.dart`
  - 新增公开给页面调用的 protected 方法。
  - 新增 `ScrollMetricsNotification` 处理入口。
  - 不改变现有 `onScroll()` 行为。

- `lib/presentation/pages/recommend/recommend_page.dart`
  - 把当前借用 `onVisibilityChanged(true)` 的数据完成检查，改成语义明确的新方法。
  - 给 `CustomScrollView` 包 `NotificationListener<ScrollMetricsNotification>`。

- `lib/presentation/pages/all_apps/all_apps_page.dart`
  - 数据存在后调用自动补页检查。
  - 给 `CustomScrollView` 包 `NotificationListener<ScrollMetricsNotification>`。

- `lib/presentation/pages/custom_category/custom_category_page.dart`
  - 数据存在后调用自动补页检查。
  - 给 `CustomScrollView` 包 `NotificationListener<ScrollMetricsNotification>`。

- `lib/presentation/pages/search_list/search_list_page.dart`
  - 搜索结果存在后调用自动补页检查。
  - 给 `CustomScrollView` 包 `NotificationListener<ScrollMetricsNotification>`。

### Test

- `test/unit/core/mixins/auto_load_when_not_scrollable_test.dart`
- `test/widget/presentation/pages/all_apps_page_test.dart`
- `test/widget/presentation/pages/custom_category_page_test.dart`
- `test/widget/presentation/pages/search_list_page_test.dart`

### Docs

- 新增或更新：
  - `docs/superpowers/plans/2026-05-16-pagination-auto-fill-viewport.md`
  - 如项目维护变更记录，也同步补充到 `AGENTS.md` 或对应规范文档。

---

## 3. Git Worktree

- [ ] **Step 1: 创建独立 worktree**

```bash
cd /home/han/linglong-store/flutter-linglong-store
git worktree add ../flutter-linglong-store-pagination-auto-fill -b codex/pagination-auto-fill
cd ../flutter-linglong-store-pagination-auto-fill
```

Expected:

```text
Preparing worktree
输出包含 `HEAD is now at`，并显示当前基线提交信息。
```

- [ ] **Step 2: 检查工作区**

```bash
git status --short
```

Expected:

```text
# 无未提交变更，或只有明确属于当前任务的变更
```

---

## 4. Task 1：为 Mixin 增加统一触发入口

**Files:**

- Modify: `lib/presentation/mixins/auto_load_when_not_scrollable.dart`
- Test: `test/unit/core/mixins/auto_load_when_not_scrollable_test.dart`

- [ ] **Step 1: 添加 protected 方法**

在 `onVisibilityChanged` 后面添加：

```dart
  /// 数据渲染完成、窗口尺寸变化或布局约束变化后，安排一次自动补页检查。
  ///
  /// 页面层应在分页数据已进入正常渲染分支后调用该方法。
  /// 方法内部会通过 [_shouldAutoLoadWhenNotScrollable] 统一判断：
  /// - 页面必须可见
  /// - 不能处于首次加载或加载更多中
  /// - 必须还有更多数据
  ///
  /// 实际读取滚动尺寸会延迟到 post-frame，避免在 build/layout 未完成时读取
  /// `ScrollPosition` 得到过期尺寸。
  @protected
  void scheduleAutoLoadCheckAfterLayout() {
    _scheduleAutoLoadCheck();
  }

  /// 处理视口尺寸变化，例如窗口最大化、退出全屏或 DPI 缩放变化。
  ///
  /// 返回 false，允许通知继续向上冒泡，不拦截其他滚动监听。
  @protected
  bool onScrollMetricsNotification(ScrollMetricsNotification notification) {
    scheduleAutoLoadCheckAfterLayout();
    return false;
  }
```

- [ ] **Step 2: 保持现有方法不破坏**

不要删除：

```dart
void onVisibilityChanged(bool visible)
void onScroll()
void _scheduleAutoLoadCheck()
void _maybeLoadMoreWhenNotScrollable()
```

- [ ] **Step 3: 跑 mixin 测试**

```bash
flutter test test/unit/core/mixins/auto_load_when_not_scrollable_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/mixins/auto_load_when_not_scrollable.dart test/unit/core/mixins/auto_load_when_not_scrollable_test.dart
git commit -m "refactor: 统一分页列表自动补页触发入口"
```

---

## 5. Task 2：修复自定义分类页，也就是截图里的“系统”页

**Files:**

- Modify: `lib/presentation/pages/custom_category/custom_category_page.dart`
- Test: `test/widget/presentation/pages/custom_category_page_test.dart`

- [ ] **Step 1: 在 build 中数据存在后安排检查**

找到：

```dart
final state = ref.watch(customCategoryProvider(widget.code));
```

下面添加：

```dart
    if (state.data != null) {
      scheduleAutoLoadCheckAfterLayout();
    }
```

- [ ] **Step 2: 给 CustomScrollView 包尺寸变化监听**

把正常显示分支里的：

```dart
child: CustomScrollView(
  controller: _scrollController,
  slivers: [
```

改成：

```dart
child: NotificationListener<ScrollMetricsNotification>(
  onNotification: onScrollMetricsNotification,
  child: CustomScrollView(
    controller: _scrollController,
    slivers: [
```

并在原 `CustomScrollView` 结束位置补齐 `),`，确保结构为：

```dart
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: onScrollMetricsNotification,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryHeaderDelegate(
                categoryName: state.data!.categoryInfo.name,
                appCount: state.data!.categoryInfo.appCount,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: _AppsGrid(apps: state.data!.apps.items),
            ),
            PaginationFooterSliver(
              isLoadingMore: state.isLoadingMore,
              hasMore: state.data!.apps.hasMore,
              hasItems: state.data!.apps.items.isNotEmpty,
            ),
          ],
        ),
      ),
```

- [ ] **Step 3: 添加 Widget 测试**

修改 `test/widget/presentation/pages/custom_category_page_test.dart`。

新增 import：

```dart
import 'package:linglong_store/application/providers/application_card_state_provider.dart';
```

在当前文件的 `group('CustomCategoryPage', () {` 测试组内、现有测试后新增测试：

```dart
    testWidgets('auto loads next page when first page cannot fill viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      when(mockApiService.getSidebarApps(any)).thenAnswer((invocation) async {
        final request =
            invocation.positionalArguments.single as SidebarAppsRequest;

        final records = request.pageNo == 1
            ? const [
                AppListItemDTO(
                  appId: 'system.one',
                  appName: 'System One',
                  appVersion: '1.0.0',
                ),
              ]
            : const [
                AppListItemDTO(
                  appId: 'system.two',
                  appName: 'System Two',
                  appVersion: '2.0.0',
                ),
              ];

        return HttpResponse(
          AppListResponse(
            code: 200,
            data: AppListPagedData(
              records: records,
              total: 2,
              size: request.pageSize,
              current: request.pageNo,
              pages: 2,
            ),
          ),
          Response(requestOptions: RequestOptions(path: '/app/sidebar/apps')),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appApiServiceProvider.overrideWithValue(mockApiService),
            applicationCardStateIndexProvider.overrideWithValue(
              const ApplicationCardStateIndex(
                installedVersionByAppId: {},
                updateAppIds: {},
                activeTasksByAppId: {},
              ),
            ),
            sidebarConfigProvider.overrideWith(
              (ref) async => const [
                SidebarMenuDTO(menuCode: 'system', menuName: '系统'),
              ],
            ),
          ],
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: CustomCategoryPage(code: 'system')),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('System One'), findsOneWidget);
      expect(find.text('System Two'), findsOneWidget);

      final captured = verify(
        mockApiService.getSidebarApps(captureAny),
      ).captured.cast<SidebarAppsRequest>();

      expect(captured.map((r) => r.pageNo), containsAllInOrder([1, 2]));
      expect(captured.every((r) => r.menuCode == 'system'), isTrue);
      expect(captured.every((r) => r.pageSize == 30), isTrue);
    });
```

- [ ] **Step 4: 先跑测试，确认修复前失败，修复后通过**

```bash
flutter test test/widget/presentation/pages/custom_category_page_test.dart
```

Expected after fix:

```text
All tests passed!
```

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/custom_category/custom_category_page.dart test/widget/presentation/pages/custom_category_page_test.dart
git commit -m "fix: 修复自定义分类页全屏未撑满时无法加载更多"
```

---

## 6. Task 3：修复全部应用页

**Files:**

- Modify: `lib/presentation/pages/all_apps/all_apps_page.dart`
- Test: `test/widget/presentation/pages/all_apps_page_test.dart`

- [ ] **Step 1: 数据存在后安排检查**

在：

```dart
final state = ref.watch(allAppsProvider);
```

下面添加：

```dart
    if (state.data != null) {
      scheduleAutoLoadCheckAfterLayout();
    }
```

- [ ] **Step 2: 包尺寸变化监听**

把正常分支的 `CustomScrollView` 改为：

```dart
child: NotificationListener<ScrollMetricsNotification>(
  onNotification: onScrollMetricsNotification,
  child: CustomScrollView(
    controller: _scrollController,
    slivers: [
      CategoryFilterSection(
        categories: state.data!.categories,
        selectedIndex: state.selectedCategoryIndex,
        onSelected: (index) {
          ref.read(allAppsProvider.notifier).selectCategory(index);
        },
        showCount: true,
        isExpanded: _isCategoryExpanded,
        onToggleExpand: () => setState(() {
          _isCategoryExpanded = !_isCategoryExpanded;
        }),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: _AppsGrid(apps: state.data!.apps.items),
      ),
      PaginationFooterSliver(
        isLoadingMore: state.isLoadingMore,
        hasMore: state.data!.apps.hasMore,
        hasItems: state.data!.apps.items.isNotEmpty,
      ),
    ],
  ),
),
```

- [ ] **Step 3: 给 `all_apps_page_test.dart` 的测试 app 包可见性 Scope**

新增 import：

```dart
import 'package:linglong_store/core/config/shell_branch_visibility.dart';
import 'package:linglong_store/core/config/shell_primary_route.dart';
```

把 `_buildTestApp` 中的 home builder 从：

```dart
builder: (_, __) => const Scaffold(body: AllAppsPage()),
```

改成：

```dart
builder: (_, __) => const ShellBranchVisibilityScope(
  activeRoute: ShellPrimaryRoute.allApps,
  currentRoute: ShellPrimaryRoute.allApps,
  child: Scaffold(body: AllAppsPage()),
),
```

- [ ] **Step 4: 新增全屏自动补页测试**

让 `_buildSearchResponse` 支持分页参数：

```dart
HttpResponse<AppListResponse> _buildSearchResponse(
  List<AppListItemDTO> items, {
  int pageSize = 30,
  int currentPage = 1,
  int total = 1,
  int pages = 1,
}) {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: items,
        total: total,
        size: pageSize,
        current: currentPage,
        pages: pages,
      ),
    ),
    Response(requestOptions: RequestOptions(path: '/visit/getSearchAppList')),
  );
}
```

新增测试：

```dart
    testWidgets('auto loads next page when first page cannot fill viewport', (
      tester,
    ) async {
      final mockApiService = MockAppApiService();

      when(mockApiService.getDisCategoryList()).thenAnswer(
        (_) async => _buildCategoryResponse(const [
          CategoryDTO(categoryId: '08', categoryName: '系统工具'),
        ]),
      );

      when(mockApiService.getSearchAppList(any)).thenAnswer((invocation) async {
        final request =
            invocation.positionalArguments.single as SearchAppListRequest;

        if (request.pageNo == 1) {
          return _buildSearchResponse(
            const [
              AppListItemDTO(
                appId: 'all.one',
                appName: 'All One',
                appVersion: '1.0.0',
              ),
            ],
            currentPage: 1,
            total: 2,
            pages: 2,
          );
        }

        return _buildSearchResponse(
          const [
            AppListItemDTO(
              appId: 'all.two',
              appName: 'All Two',
              appVersion: '2.0.0',
            ),
          ],
          currentPage: 2,
          total: 2,
          pages: 2,
        );
      });

      await tester.binding.setSurfaceSize(const Size(1600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(mockApiService));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('All One'), findsOneWidget);
      expect(find.text('All Two'), findsOneWidget);

      final captured = verify(
        mockApiService.getSearchAppList(captureAny),
      ).captured.cast<SearchAppListRequest>();

      expect(captured.map((r) => r.pageNo), containsAllInOrder([1, 2]));
      expect(captured.every((r) => r.pageSize == 30), isTrue);
    });
```

- [ ] **Step 5: Run**

```bash
flutter test test/widget/presentation/pages/all_apps_page_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/pages/all_apps/all_apps_page.dart test/widget/presentation/pages/all_apps_page_test.dart
git commit -m "fix: 修复全部应用页全屏未撑满时无法加载更多"
```

---

## 7. Task 4：修复搜索结果页

**Files:**

- Modify: `lib/presentation/pages/search_list/search_list_page.dart`
- Test: `test/widget/presentation/pages/search_list_page_test.dart`

- [ ] **Step 1: 结果存在后安排检查**

在：

```dart
final state = ref.watch(searchProvider);
```

下面添加：

```dart
    if (state.results.isNotEmpty) {
      scheduleAutoLoadCheckAfterLayout();
    }
```

- [ ] **Step 2: 包尺寸变化监听**

把搜索结果分支中的：

```dart
child: CustomScrollView(
  controller: _scrollController,
  slivers: [
```

改为：

```dart
child: NotificationListener<ScrollMetricsNotification>(
  onNotification: onScrollMetricsNotification,
  child: CustomScrollView(
    controller: _scrollController,
    slivers: [
```

并补齐结束括号。

- [ ] **Step 3: 添加搜索页自动补页测试**

在 `test/widget/presentation/pages/search_list_page_test.dart` 新增必要 imports：

```dart
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/application_card_state_provider.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/data/models/api_dto.dart';

import '../../../mocks/mock_classes.mocks.dart';
```

新增 helper：

```dart
HttpResponse<AppListResponse> _buildSearchResponse(
  List<AppListItemDTO> records, {
  required int currentPage,
  required int total,
  required int pages,
}) {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: records,
        total: total,
        size: 20,
        current: currentPage,
        pages: pages,
      ),
    ),
    Response(requestOptions: RequestOptions(path: '/visit/getSearchAppList')),
  );
}
```

新增测试：

```dart
  testWidgets('auto loads next page when search results cannot fill viewport', (
    tester,
  ) async {
    final mockApiService = MockAppApiService();

    when(mockApiService.getSearchAppList(any)).thenAnswer((invocation) async {
      final request =
          invocation.positionalArguments.single as SearchAppListRequest;

      if (request.pageNo == 1) {
        return _buildSearchResponse(
          const [
            AppListItemDTO(
              appId: 'search.one',
              appName: 'Search One',
              appVersion: '1.0.0',
            ),
          ],
          currentPage: 1,
          total: 2,
          pages: 2,
        );
      }

      return _buildSearchResponse(
        const [
          AppListItemDTO(
            appId: 'search.two',
            appName: 'Search Two',
            appVersion: '2.0.0',
          ),
        ],
        currentPage: 2,
        total: 2,
        pages: 2,
      );
    });

    await tester.binding.setSurfaceSize(const Size(1600, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
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
          locale: const Locale('zh'),
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SearchListPage(initialQuery: 'browser'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Search One'), findsOneWidget);
    expect(find.text('Search Two'), findsOneWidget);

    final captured = verify(
      mockApiService.getSearchAppList(captureAny),
    ).captured.cast<SearchAppListRequest>();

    expect(captured.map((r) => r.pageNo), containsAllInOrder([1, 2]));
    expect(captured.every((r) => r.keyword == 'browser'), isTrue);
    expect(captured.every((r) => r.pageSize == 20), isTrue);
  });
```

- [ ] **Step 4: Run**

```bash
flutter test test/widget/presentation/pages/search_list_page_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/search_list/search_list_page.dart test/widget/presentation/pages/search_list_page_test.dart
git commit -m "fix: 修复搜索结果页全屏未撑满时无法加载更多"
```

---

## 8. Task 5：整理推荐页触发语义

**Files:**

- Modify: `lib/presentation/pages/recommend/recommend_page.dart`
- Test: `test/widget/presentation/pages/recommend_page_test.dart`

- [ ] **Step 1: 替换语义不清的调用**

把：

```dart
    if (state.data != null) {
      onVisibilityChanged(true);
    }
```

改为：

```dart
    if (state.data != null) {
      scheduleAutoLoadCheckAfterLayout();
    }
```

- [ ] **Step 2: 给推荐页 CustomScrollView 加尺寸变化监听**

把：

```dart
return CustomScrollView(
  controller: _scrollController,
  slivers: [
```

改为：

```dart
return NotificationListener<ScrollMetricsNotification>(
  onNotification: onScrollMetricsNotification,
  child: CustomScrollView(
    controller: _scrollController,
    slivers: [
```

并补齐结束括号。

- [ ] **Step 3: Run 推荐页现有测试**

```bash
flutter test test/widget/presentation/pages/recommend_page_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/pages/recommend/recommend_page.dart test/widget/presentation/pages/recommend_page_test.dart
git commit -m "refactor: 明确推荐页自动补页触发语义"
```

---

## 9. Task 6：补充文档约定

**File:** `docs/03d-ui-pages.md`

- [ ] **Step 1: 在无限滚动约定下补充**

添加：

```markdown
- 所有分页列表必须在分页数据进入正常渲染分支后调用统一自动补页检查；禁止只依赖滚动触底事件。
- 所有分页 `CustomScrollView` 必须监听 `ScrollMetricsNotification`，窗口全屏、退出全屏、DPI 缩放或内容区尺寸变化后，如果内容不足一屏且 `hasMore=true`，应继续补页。
- 页面隐藏时自动补页必须暂停；主页面通过 `ShellBranchVisibilityMixin` 控制，非主页面在路由销毁前可视为可见。
```

- [ ] **Step 2: Commit**

```bash
git add docs/03d-ui-pages.md
git commit -m "docs: 补充分页列表全屏自动补页约定"
```

---

## 10. Final Verification

- [ ] **Step 1: 运行目标测试**

```bash
flutter test test/unit/core/mixins/auto_load_when_not_scrollable_test.dart
flutter test test/widget/presentation/pages/custom_category_page_test.dart
flutter test test/widget/presentation/pages/all_apps_page_test.dart
flutter test test/widget/presentation/pages/search_list_page_test.dart
flutter test test/widget/presentation/pages/recommend_page_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 2: 静态分析**

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 3: 手动验证**

```bash
flutter run -d linux
```

手动流程：

1. 打开应用。
2. 最大化窗口。
3. 进入 `全部应用`。
4. 确认首屏不足一屏时会自动追加下一页，直到列表可滚动或没有更多。
5. 点击左侧 `系统` 分类。
6. 确认 `系统 (1371)` 页面自动追加下一页。
7. 使用顶部搜索框搜索一个结果较多的关键词。
8. 确认搜索结果页首屏不足一屏时自动追加下一页。
9. 切换到其他主页面再切回来，确认隐藏页不会继续乱发请求。
10. 调整窗口大小，确认 resize 后仍会重新检查。

---

## 11. 验收标准

必须全部满足：

- `系统` 自定义分类页全屏时不再卡在第一页。
- `全部应用` 全屏时不再卡在第一页。
- `搜索结果页` 全屏时不再卡在第一页。
- 推荐页现有自动补页能力不退化。
- 页面隐藏时不触发自动补页。
- `loadMore()` 不重复并发请求。
- 不新增接口。
- 不新增 Shell/`ll-cli` 调用。
- `flutter analyze` 无 error/warning。
- 目标测试全部通过。

---

## 12. 最终提交检查

```bash
git log --oneline -n 8
git status --short
```

Expected:

```text
# git status 无未提交变更
```

推荐最终提交序列：

```text
refactor: 统一分页列表自动补页触发入口
fix: 修复自定义分类页全屏未撑满时无法加载更多
fix: 修复全部应用页全屏未撑满时无法加载更多
fix: 修复搜索结果页全屏未撑满时无法加载更多
refactor: 明确推荐页自动补页触发语义
docs: 补充分页列表全屏自动补页约定
```
