import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/app_search_index_provider.dart';
import 'package:linglong_store/application/providers/search_hint_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/presentation/widgets/title_bar.dart';

/// 标题栏标题宽度契约测试。
///
/// 覆盖「标题优先完整展示、搜索框让位收缩」的布局约定：标题按内容固有宽度
/// 排布，不再按固定像素截断；只有窗口窄到搜索区连最小宽度都保不住时，才回退
/// 省略号，并且任何窗口宽度下都不允许出现 RenderFlex 溢出。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // 占位 svg 资源，避免标题栏 logo 加载失败。
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

  // 西语标题是当前 10 种语言里最长的一条，作为「长语言」样本。
  const spanishTitle = 'Tienda de Aplicaciones Linyaps Edición Comunitaria';

  testWidgets('标准窗口宽度下长语言标题完整显示，不被省略号截断', (tester) async {
    await _pumpTitleBar(tester, locale: const Locale('es'), width: 1280);

    final titleFinder = find.text(spanishTitle);
    expect(titleFinder, findsOneWidget);
    // didExceedMaxLines 为真即代表发生了省略号截断（本次修复的核心回归点）。
    expect(
      tester.renderObject<RenderParagraph>(titleFinder).didExceedMaxLines,
      isFalse,
      reason: '西语标题在 1280px 窗口下必须完整显示',
    );
    // 标题变宽后不允许把 Row 挤溢出。
    expect(tester.takeException(), isNull);
  });

  testWidgets('最小窗口宽度下所有发布语言标题均完整显示', (tester) async {
    // 测试字体每个字符宽 1em，比真实字体更宽，因此该断言覆盖最坏情况：
    // 1280px（窗口最小宽度）下若连测试字体都不截断，真实字体必然完整显示。
    for (final locale in AppLocalizations.supportedLocales) {
      await _pumpTitleBar(tester, locale: locale, width: 1280);

      final context = tester.element(find.byType(CustomTitleBar));
      final title = AppLocalizations.of(context)!.appTitle;
      final titleFinder = find.text(title);
      expect(titleFinder, findsOneWidget, reason: '$locale 标题未渲染');
      expect(
        tester.renderObject<RenderParagraph>(titleFinder).didExceedMaxLines,
        isFalse,
        reason: '$locale 标题「$title」在 1280px 窗口下被截断',
      );
      expect(tester.takeException(), isNull, reason: '$locale 标题栏布局溢出');
    }
  });

  testWidgets('标题变长时搜索框让位：右移且收窄', (tester) async {
    final searchBox = find.byKey(const Key('title-search-box'));

    await _pumpTitleBar(tester, locale: const Locale('zh'), width: 1280);
    final zhRect = tester.getRect(searchBox);

    await _pumpTitleBar(tester, locale: const Locale('es'), width: 1280);
    final esRect = tester.getRect(searchBox);

    // 西语标题比中文宽，搜索框整体右移并收窄，而不是标题被截断。
    expect(esRect.left, greaterThan(zhRect.left));
    expect(esRect.width, lessThan(zhRect.width));
    // 让位后搜索框仍保留可渲染宽度，不能被压缩到不可用。
    expect(esRect.width, greaterThan(0));
  });

  testWidgets('极端窄窗口下标题回退省略号且不溢出', (tester) async {
    // 400px 远低于窗口最小宽度 1280px，只有 WM 忽略最小尺寸约束才可能出现；
    // 此时必须降级为省略号，而不是让标题撑爆标题栏。
    await _pumpTitleBar(tester, locale: const Locale('es'), width: 400);

    final titleFinder = find.text(spanishTitle);
    expect(titleFinder, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(titleFinder).didExceedMaxLines,
      isTrue,
      reason: '窗口窄到放不下时必须回退省略号，不能溢出',
    );
    expect(tester.takeException(), isNull);
  });
}

/// 渲染标题栏并等待布局稳定。
///
/// [width] 为逻辑像素宽度，用于模拟不同窗口宽度下的标题栏表现。
Future<void> _pumpTitleBar(
  WidgetTester tester, {
  required Locale locale,
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // 标题宽度与搜索候选无关，用空索引避免真实 provider 触发网络/日志依赖。
        appSearchIndexProvider.overrideWith(() => _EmptyFakeIndex()),
        searchHintAppsProvider.overrideWithValue(const <SearchHintApp>[]),
      ],
      child: MaterialApp(
        locale: locale,
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
  await tester.pumpAndSettle();
}

/// 空假索引，标题宽度断言不依赖候选项数据。
class _EmptyFakeIndex extends AppSearchIndex {
  @override
  AsyncValue<List<SearchSuggestionEntry>> build() => const AsyncData([]);
}
