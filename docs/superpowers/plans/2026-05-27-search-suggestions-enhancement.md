# 搜索候选增强 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将标题栏搜索候选从后端 API 切换为 ll-cli 本地内存索引，并增加鼠标 hover 高亮、键盘 ↑↓ 选中、Enter/点击跳转详情等交互。

**Architecture:** 启动时执行 `ll-cli search . --json` 加载全部应用到内存，候选匹配在 Dart 侧纯内存扫描。`TitleSearchSuggestionsProvider` 重构为同步 `updateQuery`，不再调后端。`_TitleSearchBox` 增加 `_selectedIndex` 状态和 `KeyboardListener` 处理上下键与回车。

**Tech Stack:** Flutter, Riverpod, GoRouter, Widget Test.

---

## 0. 实施前约束

- 不使用 git worktree；当前仓库规则禁止未经允许使用 worktree。
- 不在 `master` 直接写实现代码；使用功能分支承载开发。
- 先写失败测试，再写实现代码。
- 修改 Riverpod 注解时必须同步更新生成产物。

---

## 1. 文件改动清单

### Create

- `lib/application/providers/app_search_index_provider.dart` — ll-cli 搜索索引加载与本地匹配
- `test/unit/application/providers/app_search_index_provider_test.dart` — 索引 provider 测试

### Modify

- `lib/application/providers/title_search_suggestions_provider.dart` — 重构为同步本地匹配
- `lib/presentation/widgets/title_bar.dart` — 增加 hover/键盘/跳转交互
- `test/unit/application/providers/title_search_suggestions_provider_test.dart` — 适配新的同步接口
- `test/widget/presentation/widgets/title_bar_search_test.dart` — 新增键盘/hover/跳转测试

### Generate

- `lib/application/providers/app_search_index_provider.g.dart` — Riverpod 代码生成

---

## 2. Task 1：新增 ll-cli 搜索索引 Provider

**Files:**

- Create: `lib/application/providers/app_search_index_provider.dart`
- Generate: `lib/application/providers/app_search_index_provider.g.dart`
- Test: `test/unit/application/providers/app_search_index_provider_test.dart`

- [ ] **Step 1: 先写失败测试**

新增 `test/unit/application/providers/app_search_index_provider_test.dart`：

```dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/app_search_index_provider.dart';

void main() {
  group('SearchSuggestionEntry', () {
    test('parses ll-cli search JSON and deduplicates by appId', () {
      final json = jsonEncode({
        'stable': [
          {'id': 'org.example.browser', 'name': '浏览器', 'arch': ['x86_64']},
          {'id': 'org.example.browser', 'name': '浏览器', 'arch': ['arm64']},
          {'id': 'org.example.editor', 'name': '编辑器', 'arch': ['x86_64']},
        ],
      });

      final entries = parseSearchIndexJson(json);

      // 同 id 去重，只保留第一条
      expect(entries.length, 2);
      expect(entries[0].appId, 'org.example.browser');
      expect(entries[0].name, '浏览器');
      expect(entries[1].appId, 'org.example.editor');
    });

    test('handles empty JSON object', () {
      final json = '{}';
      final entries = parseSearchIndexJson(json);
      expect(entries, isEmpty);
    });

    test('handles malformed JSON gracefully', () {
      final entries = parseSearchIndexJson('not valid json');
      expect(entries, isEmpty);
    });
  });

  group('searchSuggestions', () {
    final entries = [
      const SearchSuggestionEntry(appId: 'org.mozilla.firefox', name: 'Firefox 浏览器'),
      const SearchSuggestionEntry(appId: 'org.chromium', name: 'Chromium 浏览器'),
      const SearchSuggestionEntry(appId: 'org.deepin.browser', name: '浏览器'),
      const SearchSuggestionEntry(appId: 'org.deepin.editor', name: '文本编辑器'),
      const SearchSuggestionEntry(appId: 'org.deepin.music', name: '音乐播放器'),
      const SearchSuggestionEntry(appId: 'com.visualstudio.code', name: 'Visual Studio Code'),
    ];

    test('empty query returns empty list', () {
      expect(searchSuggestions(entries, ''), isEmpty);
      expect(searchSuggestions(entries, '   '), isEmpty);
    });

    test('returns matching entries, prefix matches first', () {
      final results = searchSuggestions(entries, '浏览');

      // "浏览器" 以 "浏览" 开头 → 前缀匹配，排前面
      // "Firefox 浏览器" 包含但非前缀 → 排后面
      expect(results.length, 3);
      expect(results[0].appId, 'org.deepin.browser'); // 前缀匹配 "浏览器"
    });

    test('respects maxResults limit', () {
      final manyEntries = List.generate(
        20,
        (i) => SearchSuggestionEntry(appId: 'app.$i', name: '测试应用$i'),
      );

      final results = searchSuggestions(manyEntries, '测试', maxResults: 5);
      expect(results.length, 5);
    });

    test('case-insensitive matching', () {
      final results = searchSuggestions(entries, 'firefox');
      expect(results.length, 1);
      expect(results[0].appId, 'org.mozilla.firefox');
    });

    test('no match returns empty list', () {
      final results = searchSuggestions(entries, '不存在');
      expect(results, isEmpty);
    });
  });
}
```

- [ ] **Step 2: 运行测试并确认 RED**

Run:

```bash
flutter test test/unit/application/providers/app_search_index_provider_test.dart
```

Expected: FAIL，提示 `app_search_index_provider.dart` 不存在。

- [ ] **Step 3: 写最小实现**

新增 `lib/application/providers/app_search_index_provider.dart`：

```dart
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/platform/cli_executor.dart';

part 'app_search_index_provider.g.dart';

/// 轻量候选条目，只保留跳转详情页所需的最小字段。
class SearchSuggestionEntry {
  const SearchSuggestionEntry({required this.appId, required this.name});

  /// 应用唯一标识，如 "org.example.browser"
  final String appId;

  /// 应用名称，用于候选展示和模糊匹配
  final String name;
}

/// 解析 `ll-cli search . --json` 的 JSON 输出。
///
/// 遍历所有 channel，按 appId 去重，只保留 id + name。
List<SearchSuggestionEntry> parseSearchIndexJson(String jsonStr) {
  try {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final seen = <String>{};
    final entries = <SearchSuggestionEntry>[];

    for (final channel in map.values) {
      if (channel is! List) continue;
      for (final item in channel) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id'];
        final name = item['name'];
        if (id is! String || name is! String) continue;
        if (seen.contains(id)) continue;
        seen.add(id);
        entries.add(SearchSuggestionEntry(appId: id, name: name));
      }
    }

    return entries;
  } catch (e, stack) {
    AppLogger.warning('解析 ll-cli search JSON 失败', e, stack);
    return const [];
  }
}

/// 在候选列表中做模糊匹配，返回 top N 结果。
///
/// 排序策略：前缀匹配优先 → 按出现位置排序 → 按 name 字母序。
List<SearchSuggestionEntry> searchSuggestions(
  List<SearchSuggestionEntry> entries,
  String query, {
  int maxResults = 8,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return const [];

  final scored = <({SearchSuggestionEntry entry, int priority, int position})>[];

  for (final entry in entries) {
    final lowerName = entry.name.toLowerCase();
    final idx = lowerName.indexOf(normalizedQuery);
    if (idx == -1) continue;

    // 前缀匹配 priority=0（最高），包含匹配 priority=1
    final priority = idx == 0 ? 0 : 1;
    scored.add((entry: entry, priority: priority, position: idx));
  }

  scored.sort((a, b) {
    final cmp = a.priority.compareTo(b.priority);
    if (cmp != 0) return cmp;
    return a.position.compareTo(b.position);
  });

  return scored.take(maxResults).map((s) => s.entry).toList();
}

/// 应用搜索索引 Provider。
///
/// 启动时异步执行 `ll-cli search . --json`，解析后常驻内存。
/// 加载失败时静默回退为空列表，不阻塞启动。
@riverpod
class AppSearchIndex extends _$AppSearchIndex {
  @override
  AsyncValue<List<SearchSuggestionEntry>> build() {
    _loadIndex();
    return const AsyncLoading();
  }

  Future<void> _loadIndex() async {
    try {
      final output = await CliExecutor.execute(
        ['search', '.', '--json'],
        timeout: const Duration(seconds: 30),
      );
      if (!output.success) {
        state = const AsyncData([]);
        return;
      }
      final entries = parseSearchIndexJson(output.stdout);
      AppLogger.info('[SearchIndex] 加载完成: ${entries.length} 条应用');
      state = AsyncData(entries);
    } catch (e, stack) {
      AppLogger.warning('[SearchIndex] 加载失败，候选功能不可用', e, stack);
      state = const AsyncData([]);
    }
  }
}
```

- [ ] **Step 4: 生成 Riverpod 产物**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: 运行测试并确认 GREEN**

Run:

```bash
flutter test test/unit/application/providers/app_search_index_provider_test.dart
```

Expected: All tests passed.

- [ ] **Step 6: Commit**

```bash
git add \
  lib/application/providers/app_search_index_provider.dart \
  lib/application/providers/app_search_index_provider.g.dart \
  test/unit/application/providers/app_search_index_provider_test.dart
git commit -m "feat: 新增 ll-cli 本地搜索索引 provider"
```

---

## 3. Task 2：重构候选 Provider 为同步本地匹配

**Files:**

- Modify: `lib/application/providers/title_search_suggestions_provider.dart`
- Modify: `test/unit/application/providers/title_search_suggestions_provider_test.dart`

- [ ] **Step 1: 先写失败测试**

修改 `test/unit/application/providers/title_search_suggestions_provider_test.dart`，替换为新的同步接口测试：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/app_search_index_provider.dart';
import 'package:linglong_store/application/providers/title_search_suggestions_provider.dart';

void main() {
  group('titleSearchSuggestionsProvider', () {
    test('empty query clears suggestions', () {
      final container = ProviderContainer(
        overrides: [
          appSearchIndexProvider.overrideWith(
            () => _FakeAppSearchIndex([
              const SearchSuggestionEntry(appId: 'org.example.browser', name: '浏览器'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(titleSearchSuggestionsProvider.notifier)
          .updateQuery('   ');

      final state = container.read(titleSearchSuggestionsProvider);
      expect(state.items, isEmpty);
    });

    test('non-empty query returns local matches', () {
      final container = ProviderContainer(
        overrides: [
          appSearchIndexProvider.overrideWith(
            () => _FakeAppSearchIndex([
              const SearchSuggestionEntry(appId: 'org.example.browser', name: '浏览器'),
              const SearchSuggestionEntry(appId: 'org.example.editor', name: '文本编辑器'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(titleSearchSuggestionsProvider.notifier)
          .updateQuery('浏览');

      final state = container.read(titleSearchSuggestionsProvider);
      expect(state.items.length, 1);
      expect(state.items.first.appId, 'org.example.browser');
      expect(state.items.first.name, '浏览器');
    });

    test('clear resets state', () {
      final container = ProviderContainer(
        overrides: [
          appSearchIndexProvider.overrideWith(
            () => _FakeAppSearchIndex([
              const SearchSuggestionEntry(appId: 'org.example.browser', name: '浏览器'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(titleSearchSuggestionsProvider.notifier)
          .updateQuery('浏览');
      expect(container.read(titleSearchSuggestionsProvider).items, isNotEmpty);

      container.read(titleSearchSuggestionsProvider.notifier).clear();
      expect(container.read(titleSearchSuggestionsProvider).items, isEmpty);
    });

    test('no matching results returns empty', () {
      final container = ProviderContainer(
        overrides: [
          appSearchIndexProvider.overrideWith(
            () => _FakeAppSearchIndex([
              const SearchSuggestionEntry(appId: 'org.example.browser', name: '浏览器'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(titleSearchSuggestionsProvider.notifier)
          .updateQuery('不存在');

      final state = container.read(titleSearchSuggestionsProvider);
      expect(state.items, isEmpty);
    });
  });
}

/// 假索引，直接返回预设数据
class _FakeAppSearchIndex extends AppSearchIndex {
  final List<SearchSuggestionEntry> _entries;

  _FakeAppSearchIndex(this._entries);

  @override
  AsyncValue<List<SearchSuggestionEntry>> build() => AsyncData(_entries);
}
```

- [ ] **Step 2: 运行测试并确认 RED**

Run:

```bash
flutter test test/unit/application/providers/title_search_suggestions_provider_test.dart
```

Expected: FAIL，提示 `updateQuery` 方法不存在或 `SearchSuggestionEntry` 类型不匹配。

- [ ] **Step 3: 重构 Provider 实现**

替换 `lib/application/providers/title_search_suggestions_provider.dart` 的全部内容：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_search_index_provider.dart';

part 'title_search_suggestions_provider.g.dart';

/// 候选条目，用于标题栏候选面板展示。
///
/// 对应 [SearchSuggestionEntry]，这里单独建模以解耦数据源与展示层。
class SuggestionItem {
  const SuggestionItem({required this.appId, required this.name});

  final String appId;
  final String name;
}

/// 标题栏搜索候选状态。
class TitleSearchSuggestionsState {
  const TitleSearchSuggestionsState({
    this.items = const [],
  });

  final List<SuggestionItem> items;

  TitleSearchSuggestionsState copyWith({
    List<SuggestionItem>? items,
  }) {
    return TitleSearchSuggestionsState(
      items: items ?? this.items,
    );
  }
}

/// 标题栏候选 provider。
///
/// 消费本地搜索索引做同步匹配，不再调用后端 API。
@riverpod
class TitleSearchSuggestions extends _$TitleSearchSuggestions {
  @override
  TitleSearchSuggestionsState build() {
    return const TitleSearchSuggestionsState();
  }

  /// 根据输入词同步更新候选列表。
  void updateQuery(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      state = const TitleSearchSuggestionsState();
      return;
    }

    final asyncIndex = ref.read(appSearchIndexProvider);
    final entries = asyncIndex.valueOrNull ?? const [];

    final results = searchSuggestions(entries, normalizedQuery);
    state = TitleSearchSuggestionsState(
      items: results
          .map((e) => SuggestionItem(appId: e.appId, name: e.name))
          .toList(),
    );
  }

  /// 清空候选。
  void clear() {
    state = const TitleSearchSuggestionsState();
  }
}
```

- [ ] **Step 4: 重新生成 Riverpod 产物**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: 运行测试并确认 GREEN**

Run:

```bash
flutter test test/unit/application/providers/title_search_suggestions_provider_test.dart
```

Expected: All tests passed.

- [ ] **Step 6: Commit**

```bash
git add \
  lib/application/providers/title_search_suggestions_provider.dart \
  lib/application/providers/title_search_suggestions_provider.g.dart \
  test/unit/application/providers/title_search_suggestions_provider_test.dart
git commit -m "refactor: 候选 provider 改为同步本地匹配"
```

---

## 4. Task 3：增强标题栏候选交互（hover + 键盘 + 跳转）

**Files:**

- Modify: `lib/presentation/widgets/title_bar.dart`
- Modify: `test/widget/presentation/widgets/title_bar_search_test.dart`

- [ ] **Step 1: 先写失败测试**

在 `test/widget/presentation/widgets/title_bar_search_test.dart` 中，将现有测试适配新 provider，并新增交互测试。

先修改 `_buildRouterApp` 和 `_buildSearchResponse` 以适配新接口。替换文件末尾的 helper 函数和新增测试：

```dart
// ... 保留文件头部所有 import ...

// 新增 import
import 'package:linglong_store/application/providers/app_search_index_provider.dart';
import 'package:linglong_store/application/providers/title_search_suggestions_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // SVG mock（保留不变）
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/icons/logo.svg') {
            final bytes = Uint8List.fromList(
              utf8.encode(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"></svg>',
              ),
            );
            return ByteData.view(bytes.buffer);
          }
          return null;
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  testWidgets('submitting header search navigates to search page with q query', (
    tester,
  ) async {
    await tester.pumpWidget(_buildRouterApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'firefox');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('route:/search_list?q=firefox'), findsOneWidget);
  });

  testWidgets('typing in header search shows local suggestions', (tester) async {
    await tester.pumpWidget(_buildRouterApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '浏览');
    // 100ms 防抖
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(find.text('浏览器'), findsOneWidget);
  });

  testWidgets('tapping header suggestion opens detail page', (tester) async {
    await tester.pumpWidget(_buildRouterApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '浏览');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    await tester.tap(find.text('浏览器'));
    await tester.pumpAndSettle();

    // 只传 appId，详情页自己拉取信息
    expect(find.text('detail:org.example.browser'), findsOneWidget);
  });

  testWidgets('keyboard arrow down selects next suggestion', (tester) async {
    await tester.pumpWidget(_buildRouterApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '编');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // 按下箭头选中第一个
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    // 验证选中项高亮（通过 find 包含 primaryLight 背景的 Container）
    // 选中后按 Enter 跳转详情
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('detail:org.deepin.editor'), findsOneWidget);
  });

  testWidgets('enter without selection goes to search page', (tester) async {
    await tester.pumpWidget(_buildRouterApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '编');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // 不按箭头，直接 Enter
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('route:/search_list?q=编'), findsOneWidget);
  });

  testWidgets('escape closes suggestion panel', (tester) async {
    await tester.pumpWidget(_buildRouterApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '浏览');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(find.text('浏览器'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('浏览器'), findsNothing);
  });

  // 保留原有的样式测试（不需要 provider mock）
  testWidgets('header search uses single-layer pill styling by default', (
    tester,
  ) async {
    // ... 保留原有样式测试不变 ...
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSearchIndexProvider.overrideWith(() => _FakeIndex())],
        child: MaterialApp(
          locale: const Locale('zh'),
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomTitleBar(
              isMaximized: false,
              onMinimize: () {},
              onMaximize: () {},
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    final decoration = textField.decoration!;
    final searchContainerFinder = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxWidth == 534,
    );
    final searchContainer = tester.widget<Container>(searchContainerFinder);
    final boxDecoration = searchContainer.decoration! as BoxDecoration;
    final searchSize = tester.getSize(searchContainerFinder);
    final border = boxDecoration.border as Border?;

    expect(decoration.filled, isFalse);
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
    expect(border, isNotNull);
    expect(border!.top.color, AppColors.borderSecondary);
    expect(border.top.width, 1);
    expect(boxDecoration.color, AppColors.surfaceContainerHighest);
    expect(searchSize.height, 32);
  });

  testWidgets('header search border turns blue when focused', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSearchIndexProvider.overrideWith(() => _FakeIndex())],
        child: MaterialApp(
          locale: const Locale('zh'),
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomTitleBar(
              isMaximized: false,
              onMinimize: () {},
              onMaximize: () {},
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    final searchContainerFinder = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxWidth == 534,
    );
    final searchContainer = tester.widget<Container>(searchContainerFinder);
    final boxDecoration = searchContainer.decoration! as BoxDecoration;
    final border = boxDecoration.border as Border?;

    expect(border, isNotNull);
    expect(border!.top.color, AppColors.primary);
    expect(border.top.width, 1);
  });
}

Widget _buildRouterApp() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: CustomTitleBar(
            isMaximized: false,
            onMinimize: () {},
            onMaximize: () {},
            onClose: () {},
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.searchList,
        builder: (context, state) => Scaffold(
          body: Text(
            'route:${state.uri.path}?q=${state.uri.queryParameters['q'] ?? ''}',
          ),
        ),
      ),
      GoRoute(
        path: '/app/:id',
        builder: (context, state) => Scaffold(
          body: Text('detail:${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appSearchIndexProvider.overrideWith(
        () => _FakeAppSearchIndexForRouter([
          const SearchSuggestionEntry(appId: 'org.example.browser', name: '浏览器'),
          const SearchSuggestionEntry(appId: 'org.deepin.editor', name: '文本编辑器'),
        ]),
      ),
    ],
    child: MaterialApp.router(
      locale: const Locale('zh'),
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

/// 供给路由测试用的假索引
class _FakeAppSearchIndexForRouter extends AppSearchIndex {
  final List<SearchSuggestionEntry> _entries;

  _FakeAppSearchIndexForRouter(this._entries);

  @override
  AsyncValue<List<SearchSuggestionEntry>> build() => AsyncData(_entries);
}

/// 空假索引，用于不需要候选项的样式测试
class _FakeIndex extends AppSearchIndex {
  @override
  AsyncValue<List<SearchSuggestionEntry>> build() => const AsyncData([]);
}
```

- [ ] **Step 2: 运行测试并确认 RED**

Run:

```bash
flutter test test/widget/presentation/widgets/title_bar_search_test.dart
```

Expected: FAIL，提示新测试中引用的交互行为（键盘选中、hover 等）在现有代码中不存在。

- [ ] **Step 3: 重写标题栏搜索框交互**

替换 `lib/presentation/widgets/title_bar.dart` 中 `_TitleSearchBox` 和 `_TitleSearchBoxState` 的完整实现。保留 `CustomTitleBar`、`_WindowDragHandle`、`_WindowDragSpacer`、`_WindowControls`、`_WindowButton` 不变。

关键变更点（在 `_TitleSearchBoxState` 中）：

1. **新增状态变量**：

```dart
int _selectedIndex = -1;
```

2. **防抖从 300ms 降到 100ms，调用同步 `updateQuery`**：

```dart
void _queueSuggestionsFetch() {
  _debounceTimer?.cancel();
  final query = _controller.text.trim();
  if (query.isEmpty) {
    ref.read(titleSearchSuggestionsProvider.notifier).clear();
    _selectedIndex = -1;
    _syncSuggestionsOverlay();
    return;
  }
  _debounceTimer = Timer(const Duration(milliseconds: 100), () {
    if (!mounted) return;
    ref.read(titleSearchSuggestionsProvider.notifier).updateQuery(_controller.text);
  });
}
```

3. **`_onTextChanged` 中增加 `_selectedIndex = -1` 重置**：

```dart
void _onTextChanged() {
  setState(() {
    _selectedIndex = -1;
  });
  _queueSuggestionsFetch();
}
```

4. **在 `TextField` 外层包 `KeyboardListener` 处理 ↑↓ Enter Escape**：

```dart
// 在 build 方法的 TextField 外层包裹
KeyboardListener(
  focusNode: _keyboardFocusNode, // 新增 FocusNode
  onKeyEvent: _onKeyEvent,
  child: TextField(...),
)
```

键盘事件处理：

```dart
KeyEventResult _onKeyEvent(KeyEvent event) {
  final state = ref.read(titleSearchSuggestionsProvider);
  if (!_shouldShowSuggestions(state) || state.items.isEmpty) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      _submitSearch();
    }
    return KeyEventResult.ignored;
  }

  if (event is! KeyDownEvent) return KeyEventResult.ignored;

  final items = state.items;
  switch (event.logicalKey) {
    case LogicalKeyboardKey.arrowDown:
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % items.length;
      });
      _ensureSelectedVisible();
      return KeyEventResult.handled;
    case LogicalKeyboardKey.arrowUp:
      setState(() {
        _selectedIndex = _selectedIndex <= 0
            ? items.length - 1
            : _selectedIndex - 1;
      });
      _ensureSelectedVisible();
      return KeyEventResult.handled;
    case LogicalKeyboardKey.enter:
      if (_selectedIndex >= 0 && _selectedIndex < items.length) {
        _openSuggestion(items[_selectedIndex]);
      } else {
        _submitSearch();
      }
      return KeyEventResult.handled;
    case LogicalKeyboardKey.escape:
      _removeSuggestionsOverlay();
      _selectedIndex = -1;
      return KeyEventResult.handled;
    default:
      return KeyEventResult.ignored;
  }
}
```

5. **候选项改为带 hover 高亮 + 箭头指示器的交互式 Widget**：

替换 `_buildSuggestionsOverlay` 中的 `ListView.separated` + `Divider` 为：

```dart
ListView.builder(
  controller: _scrollController, // 新增 ScrollController
  padding: const EdgeInsets.all(6),
  itemCount: state.items.length,
  itemBuilder: (context, index) {
    final item = state.items[index];
    final isSelected = index == _selectedIndex;

    return MouseRegion(
      onEnter: (_) => setState(() => _selectedIndex = index),
      child: GestureDetector(
        onTap: () => _openSuggestion(item),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? overlayContext.appColors.primaryLight
                : Colors.transparent,
            borderRadius: AppRadius.xsRadius,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: overlayContext.appTextStyles.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : overlayContext.appColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  },
)
```

6. **`_openSuggestion` 改为接收 `SuggestionItem`**：

```dart
void _openSuggestion(SuggestionItem item) {
  _debounceTimer?.cancel();
  ref.read(titleSearchSuggestionsProvider.notifier).clear();
  _removeSuggestionsOverlay();
  _focusNode.unfocus();
  // 只传 appId，详情页自己拉取完整信息
  context.goToAppDetail(item.appId);
}
```

7. **新增 `_ensureSelectedVisible` 方法**：

```dart
void _ensureSelectedVisible() {
  if (_selectedIndex < 0 || _scrollController.positions.isEmpty) return;
  // 利用 overlay rebuild 中的 ScrollController
  _syncSuggestionsOverlay();
}
```

8. **新增成员变量**（在 `_TitleSearchBoxState` 顶部）：

```dart
final FocusNode _keyboardFocusNode = FocusNode();
final ScrollController _scrollController = ScrollController();
```

9. **`dispose` 中清理新增资源**：

```dart
@override
void dispose() {
  _debounceTimer?.cancel();
  _removeSuggestionsOverlay();
  _controller.removeListener(_onTextChanged);
  _controller.dispose();
  _focusNode.removeListener(_onFocusChange);
  _focusNode.dispose();
  _keyboardFocusNode.dispose();
  _scrollController.dispose();
  super.dispose();
}
```

- [ ] **Step 4: 运行测试并确认 GREEN**

Run:

```bash
flutter test test/widget/presentation/widgets/title_bar_search_test.dart
```

Expected: All tests passed.

- [ ] **Step 5: 运行静态分析**

Run:

```bash
flutter analyze
```

Expected: 0 error / 0 warning。

- [ ] **Step 6: Commit**

```bash
git add \
  lib/presentation/widgets/title_bar.dart \
  test/widget/presentation/widgets/title_bar_search_test.dart
git commit -m "feat: 增强标题栏候选交互（hover/键盘/跳转）"
```

---

## 5. Task 4：全量验证与文档同步

**Files:**

- Modify: `CLAUDE.md` — 变更记录

- [ ] **Step 1: 跑全量相关测试**

Run:

```bash
flutter test test/unit/application/providers/app_search_index_provider_test.dart
flutter test test/unit/application/providers/title_search_suggestions_provider_test.dart
flutter test test/widget/presentation/widgets/title_bar_search_test.dart
```

Expected: 3 组测试全部通过。

- [ ] **Step 2: 跑静态分析**

Run:

```bash
flutter analyze
```

Expected: 0 error / 0 warning。

- [ ] **Step 3: 更新 CLAUDE.md 变更记录**

在 CLAUDE.md 的变更记录部分新增：

```text
- 2026-05-27：标题栏搜索候选数据源从后端 `/visit/getSearchAppList` 切换为 `ll-cli search . --json` 本地内存索引；新增 hover 高亮、键盘 ↑↓ 选中、Enter/点击跳转详情交互；候选防抖从 300ms 降为 100ms；新增 `AppSearchIndex` provider 和 `SearchSuggestionEntry` 轻量模型。
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: 同步搜索候选增强约定"
```
