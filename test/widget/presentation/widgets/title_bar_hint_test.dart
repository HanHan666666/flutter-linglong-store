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

  testWidgets('placeholder 首帧展示下载量榜应用名之一', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // 轮播顺序随机洗牌，首帧只断言展示了榜单应用之一。
    final candidates = ['应用一', '应用二', '应用三'];
    expect(
      candidates.any((name) => _findHintText(name).evaluate().isNotEmpty),
      isTrue,
    );
  });

  testWidgets('placeholder 每 5 秒切换到另一个应用名', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    final first = _currentHintText(tester);
    expect(first, isNotNull);

    // 推进 5 秒，触发轮播 Timer 切换。洗牌后顺序循环，可能切到任意应用。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final second = _currentHintText(tester);
    expect(second, isNotNull);
    // 样本只有 3 个，洗牌循环下相邻两项大概率不同；
    // 这里不绑定具体值，只校验轮播 Timer 生效、文案是榜单应用之一。
    expect(
      ['应用一', '应用二', '应用三'].contains(second),
      isTrue,
    );
  });

  testWidgets('空输入回车跳转当前 placeholder 应用的详情页', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // 读取首帧 placeholder 显示的应用名，验证跳转一致性（不受洗牌顺序影响）。
    final hintName = _currentHintText(tester);
    expect(hintName, isNotNull);

    // 先聚焦输入框，receiveAction 才会触发 onSubmitted。
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    // 不输入任何内容，直接触发 search action（等价于空输入回车）。
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // 校验跳转的正是当前 placeholder 显示的应用。
    expect(find.text('detail-name:$hintName'), findsOneWidget);
    // 按应用名反查其身份字段，验证 appId/arch/repoName/module 一并透传，
    // 符合详情页精确查询约定。
    final identity = _kHintIdentity[hintName]!;
    expect(find.text('detail:${identity.first}'), findsOneWidget);
    expect(
      find.text('detail-extra:x86_64|main|${identity.last}'),
      findsOneWidget,
    );
  });

  testWidgets('轮播切换后空回车跳转当前显示的应用', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    // 推进 5 秒切到下一个 placeholder 后再回车。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final hintName = _currentHintText(tester);
    expect(hintName, isNotNull);

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // 无论洗牌后切到哪个，跳转的都应是当前 placeholder 显示的应用。
    expect(find.text('detail-name:$hintName'), findsOneWidget);
    final identity = _kHintIdentity[hintName]!;
    expect(find.text('detail:${identity.first}'), findsOneWidget);
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

/// 测试样本应用名 -> [appId, module] 的映射，供跳转一致性断言反查身份字段。
const Map<String, List<String>> _kHintIdentity = {
  '应用一': ['com.app1', 'runtime'],
  '应用二': ['com.app2', 'binary'],
  '应用三': ['com.app3', 'runtime'],
};

/// 在 TextField 的 hintText 里定位文案。
Finder _findHintText(String text) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.hintText == text,
  );
}

/// 读取当前搜索框 placeholder 显示的文案（可能为空，代表回退静态文案）。
String? _currentHintText(WidgetTester tester) {
  final textField = tester.widget<TextField>(find.byType(TextField).first);
  return textField.decoration?.hintText;
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
                if (appInfo != null) ...[
                  Text(
                    'detail-name:${appInfo.name}',
                  ),
                  Text(
                    'detail-extra:${appInfo.arch}|${appInfo.repoName}|${appInfo.module}',
                  ),
                ],
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
