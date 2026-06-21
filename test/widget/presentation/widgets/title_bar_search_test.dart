import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:linglong_store/application/providers/app_search_index_provider.dart';
import 'package:linglong_store/application/providers/search_hint_provider.dart';
import 'package:linglong_store/core/config/routes.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/app_detail.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/presentation/widgets/title_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
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

  testWidgets(
    'submitting header search navigates to search page with q query',
    (tester) async {
      await tester.pumpWidget(_buildRouterApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'firefox');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('route:/search_list?q=firefox'), findsOneWidget);
    },
  );

  testWidgets('typing in header search shows local suggestions', (
    tester,
  ) async {
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

    expect(find.text('detail:org.example.browser'), findsOneWidget);
  });

  testWidgets('opening header suggestion passes detail identity fields', (
    tester,
  ) async {
    await tester.pumpWidget(_buildRouterApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '浏览');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    await tester.tap(find.text('浏览器'));
    await tester.pumpAndSettle();

    expect(find.text('detail-extra:x86_64|stable|binary'), findsOneWidget);
  });

  testWidgets(
    'mouse click on header suggestion survives text field focus loss',
    (tester) async {
      await tester.pumpWidget(_buildRouterApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '浏览');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      final suggestion = find.text('浏览器');
      final gesture = await tester.startGesture(
        tester.getCenter(suggestion),
        kind: PointerDeviceKind.mouse,
      );

      // 桌面端真实鼠标点击会在 pointer down 时先触发 TextField 外部点击失焦；
      // 这里推进到超过失焦关闭延迟，覆盖 overlay 在 pointer up 前被移除的竞态。
      await tester.pump(const Duration(milliseconds: 350));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('detail:org.example.browser'), findsOneWidget);
    },
  );

  testWidgets('keyboard arrow down selects next suggestion', (tester) async {
    await tester.pumpWidget(_buildRouterApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '编');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // 按下箭头选中第一个
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

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

    // 不按箭头，直接 Enter（通过 TextInputAction）
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

  testWidgets('header search uses single-layer pill styling by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSearchIndexProvider.overrideWith(() => _EmptyFakeIndex()),
          // placeholder 轮播与样式断言无关，override 为空避免触发网络/日志依赖。
          searchHintAppsProvider.overrideWithValue(const <SearchHintApp>[]),
        ],
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
        overrides: [
          appSearchIndexProvider.overrideWith(() => _EmptyFakeIndex()),
          // placeholder 轮播与样式断言无关，override 为空避免触发网络/日志依赖。
          searchHintAppsProvider.overrideWithValue(const <SearchHintApp>[]),
        ],
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

  group('tag chip', () {
    testWidgets('tag route renders compact chip inside original search box', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildRouterApp(initialLocation: '/search_list?tag=办公&tagLan=zh_CN'),
      );
      await tester.pumpAndSettle();

      // 标签模式必须保留原搜索框的尺寸、背景和搜索图标，只替换内部输入区域。
      final searchBox = find.byKey(const Key('title-search-box'));
      expect(searchBox, findsOneWidget);
      expect(tester.getSize(searchBox).height, 32);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byKey(const Key('title-search-tag-chip')), findsOneWidget);
      expect(find.byType(InputChip), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('浏览器'), findsNothing);
    });

    testWidgets('deleting tag chip returns to empty text search', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildRouterApp(initialLocation: '/search_list?tag=办公&tagLan=zh_CN'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('title-search-tag-remove')));
      await tester.pumpAndSettle();

      // 删除胶囊后回到普通文本搜索模式（空查询），TextField 重新出现
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const Key('title-search-tag-chip')), findsNothing);
      expect(find.text('route:/search_list?q='), findsOneWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, isTrue);
    });

    testWidgets('backspace removes focused tag chip', (tester) async {
      await tester.pumpWidget(
        _buildRouterApp(initialLocation: '/search_list?tag=办公&tagLan=zh_CN'),
      );
      await tester.pumpAndSettle();

      // 胶囊自动聚焦后 Backspace 应删除标签并回到文本搜索
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('title-search-tag-chip')), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets(
      'tag chip exposes localized semantics without stretching shell',
      (tester) async {
        // 直接渲染标题栏（与现有样式测试一致）：
        // 标签语义是组件自身属性，不依赖路由上下文；ShellRoute 的 navigator 重建会干扰
        // 测试框架 getSemantics(byKey) 读取，故这里用直接渲染验证语义与尺寸契约。
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appSearchIndexProvider.overrideWith(() => _EmptyFakeIndex()),
              searchHintAppsProvider.overrideWithValue(const <SearchHintApp>[]),
            ],
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
                  currentSearchTag: const AppTag(name: '办公', language: 'zh_CN'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final chip = find.byKey(const Key('title-search-tag-chip'));
        expect(chip, findsOneWidget);
        // 胶囊保持在 32px 搜索框内，整体搜索区域提供键盘焦点和本地化语义。
        expect(tester.getSize(chip).height, lessThanOrEqualTo(32));
        expect(tester.getSemantics(chip).label, contains('按标签搜索：办公'));
      },
    );
  });
}

Widget _buildRouterApp({String initialLocation = '/'}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final query = state.uri.queryParameters['q'] ?? '';
          final tagName = state.uri.queryParameters['tag'];
          final tagLan = state.uri.queryParameters['tagLan'];
          final currentTag = tagName != null && tagLan != null
              ? AppTag(name: tagName, language: tagLan)
              : null;
          return Scaffold(
            body: Column(
              children: [
                CustomTitleBar(
                  isMaximized: false,
                  onMinimize: () {},
                  onMaximize: () {},
                  onClose: () {},
                  currentSearchQuery: query,
                  currentSearchTag: currentTag,
                ),
                Expanded(child: child),
              ],
            ),
          );
        },
        routes: [
          GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),
          GoRoute(
            path: AppRoutes.searchList,
            builder: (_, state) => Text(
              'route:${state.uri.path}?q=${state.uri.queryParameters['q'] ?? ''}',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/app/:id',
        builder: (context, state) {
          final appInfo = state.extra is InstalledApp
              ? state.extra! as InstalledApp
              : null;
          return Scaffold(
            body: Column(
              children: [
                Text('detail:${state.pathParameters['id']}'),
                if (appInfo != null)
                  Text(
                    'detail-extra:${appInfo.arch}|${appInfo.repoName}|${appInfo.module}',
                  ),
              ],
            ),
          );
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appSearchIndexProvider.overrideWith(
        () => _FakeAppSearchIndex([
          const SearchSuggestionEntry(
            appId: 'org.example.browser',
            name: '浏览器',
            version: '1.0.0',
            arch: 'x86_64',
            repoName: 'stable',
            module: 'binary',
          ),
          const SearchSuggestionEntry(
            appId: 'org.deepin.editor',
            name: '文本编辑器',
          ),
        ]),
      ),
      // placeholder 轮播数据与本测试关注的搜索/候选逻辑无关，
      // override 为空列表，避免真实构建 provider 触发网络请求与日志依赖。
      searchHintAppsProvider.overrideWithValue(const <SearchHintApp>[]),
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
class _FakeAppSearchIndex extends AppSearchIndex {
  final List<SearchSuggestionEntry> _entries;

  _FakeAppSearchIndex(this._entries);

  @override
  AsyncValue<List<SearchSuggestionEntry>> build() => AsyncData(_entries);
}

/// 空假索引，用于不需要候选项的样式测试
class _EmptyFakeIndex extends AppSearchIndex {
  @override
  AsyncValue<List<SearchSuggestionEntry>> build() => const AsyncData([]);
}
