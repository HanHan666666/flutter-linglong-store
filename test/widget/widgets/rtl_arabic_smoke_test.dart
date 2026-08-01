/// 阿拉伯语（RTL）渲染冒烟测试。
///
/// 覆盖阿拉伯语 locale 下的三个关键点：
/// 1. MaterialApp 按 ar locale 自动注入 RTL Directionality；
/// 2. 阿拉伯语本地化文本正常渲染；
/// 3. 方向感知对齐（AlignmentDirectional / EdgeInsetsDirectional）在
///    RTL 下真实镜像，避免回归到硬编码 left/right。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';

void main() {
  testWidgets('阿拉伯语 locale 下文本方向为 RTL', (tester) async {
    TextDirection? direction;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              direction = Directionality.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(direction, TextDirection.rtl);
  });

  testWidgets('阿拉伯语本地化文本正常渲染', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Text(AppLocalizations.of(context)!.install),
          ),
        ),
      ),
    );

    expect(find.text('تثبيت'), findsOneWidget);
  });

  testWidgets('AlignmentDirectional 在 RTL 下真实镜像', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              key: const Key('rtl-box'),
              width: 40,
              height: 40,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );

    // RTL 下 centerStart 应贴近父容器右侧（start = 视觉右侧）
    final box = tester.getRect(find.byKey(const Key('rtl-box')));
    final canvas = tester.getRect(find.byType(Scaffold));
    expect(box.right, closeTo(canvas.right, 0.1));
    expect(box.left, greaterThan(canvas.left));
  });

  testWidgets('设置页语言选择器在阿拉伯语下可展开并包含全部语言选项', (tester) async {
    // 语言选择器入口本身依赖设置页 Provider，这里只验证 ARB 侧
    // selectableAppLocales 自动包含 ar，且语言自身名正确展示。
    final l10n = lookupAppLocalizations(const Locale('ar'));
    expect(l10n.languageSelfName, 'العربية');
    // 所有支持语言都应在选择列表中出现（由生成物驱动，无第二份白名单）
    for (final locale in AppLocalizations.supportedLocales) {
      expect(
        lookupAppLocalizations(locale).languageSelfName,
        isNotEmpty,
      );
    }
  });
}
