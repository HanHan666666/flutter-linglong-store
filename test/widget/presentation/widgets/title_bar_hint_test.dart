import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:linglong_store/application/providers/app_search_index_provider.dart';
import 'package:linglong_store/application/providers/search_hint_provider.dart';
import 'package:linglong_store/core/config/routes.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/presentation/widgets/title_bar.dart';

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

  testWidgets('placeholder 展示下载量榜首个应用名', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(_findHintText('应用一'), findsOneWidget);
  });

  testWidgets('placeholder 每 5 秒顺序切换到下一个应用名', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(_findHintText('应用一'), findsOneWidget);

    // 推进 5 秒，触发轮播 Timer 切换到第二个。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(_findHintText('应用二'), findsOneWidget);

    // 再推进 5 秒，切换到第三个。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(_findHintText('应用三'), findsOneWidget);
  });

  testWidgets('空输入回车跳转当前 placeholder 应用的详情页', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // 先聚焦输入框，receiveAction 才会触发 onSubmitted。
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    // 不输入任何内容，直接触发 search action（等价于空输入回车）。
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('detail:com.app1'), findsOneWidget);
    // 校验身份字段一并透传，符合详情页精确查询约定。
    expect(find.text('detail-extra:x86_64|main|runtime'), findsOneWidget);
  });

  testWidgets('空输入回车在 5 秒后跳转第二个 placeholder 应用', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('detail:com.app2'), findsOneWidget);
  });

  testWidgets('轮播数据为空时回退静态 placeholder 且空回车不跳转', (tester) async {
    await tester.pumpWidget(_buildApp(hints: const []));
    await tester.pumpAndSettle();

    // 静态兜底文案应可见。
    expect(
      find.text('在这里搜索你想搜索的应用'),
      findsOneWidget,
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // 不应跳转到任何详情页。
    expect(find.byKey(const Key('detail-page')), findsNothing);
  });
}

/// 在 TextField 的 hintText 里定位文案。
Finder _findHintText(String text) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.hintText == text,
  );
}

Widget _buildApp({List<SearchHintApp>? hints}) {
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
        builder: (context, state) {
          final appInfo = state.extra is InstalledApp
              ? state.extra! as InstalledApp
              : null;
          return Scaffold(
            key: const Key('detail-page'),
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
      // 关闭本地候选索引，避免与 hint 测试互相干扰。
      appSearchIndexProvider.overrideWith(() => _EmptyFakeIndex()),
      searchHintAppsProvider.overrideWithValue(
        hints ??
            const [
              SearchHintApp(
                appId: 'com.app1',
                name: '应用一',
                version: '1.0.0',
                arch: 'x86_64',
                repoName: 'main',
                module: 'runtime',
              ),
              SearchHintApp(
                appId: 'com.app2',
                name: '应用二',
                version: '2.0.0',
                arch: 'x86_64',
                repoName: 'main',
                module: 'binary',
              ),
              SearchHintApp(
                appId: 'com.app3',
                name: '应用三',
                version: '3.0.0',
                arch: 'x86_64',
                repoName: 'main',
                module: 'runtime',
              ),
            ],
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

/// 空假索引，避免候选项干扰 placeholder 测试。
class _EmptyFakeIndex extends AppSearchIndex {
  @override
  AsyncValue<List<SearchSuggestionEntry>> build() => const AsyncData([]);
}
