import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:linglong_store/application/providers/app_search_index_provider.dart';
import 'package:linglong_store/core/config/routes.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
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

    // 只传 appId
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
        () => _FakeAppSearchIndex([
          const SearchSuggestionEntry(
            appId: 'org.example.browser',
            name: '浏览器',
          ),
          const SearchSuggestionEntry(
            appId: 'org.deepin.editor',
            name: '文本编辑器',
          ),
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
