/// 展台 Banner 的主题、方向、键盘操作及窄窗口回归。
///
/// 使用无网络图标隔离表现层，避免渲染测试依赖远端服务可用性。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:linglong_store/presentation/pages/recommend/widgets/recommend_banner.dart';

/// 长文案用于验证中英文以外的语言也能在有限横向空间中正常省略。
const _banner = BannerInfo(
  id: 'exhibit',
  title: 'A carefully selected application with a longer localized name',
  description:
      'A useful app for your desktop, with a description that can wrap onto two lines.',
  imageUrl: '',
);

/// 验证已批准的两种主题表现与既有导航契约。
void main() {
  testWidgets('keeps long copy and actions inside narrow and scaled banners', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // 同时覆盖紧凑布局断点、正常展台和大字号，避免仅验证默认宽度。
    for (final width in [360.0, 600.0, 1000.0]) {
      for (final scale in [1.0, 1.5]) {
        await tester.pumpWidget(_host(width: width, scale: scale));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$width / $scale');
        final frame = tester.getRect(find.byType(RecommendBanner));
        final copy = tester.getRect(
          find.byKey(const Key('recommend-banner-copy')),
        );
        final art = tester.getRect(
          find.byKey(const Key('recommend-banner-artwork')),
        );
        expect(frame.contains(copy.topLeft), isTrue);
        expect(frame.contains(copy.bottomRight), isTrue);
        expect(copy.right, lessThan(art.left));
        expect(find.text('查看详情'), findsOneWidget);
      }
    }
  });

  testWidgets('mirrors composition in RTL without mirroring the app icon', (
    tester,
  ) async {
    await tester.pumpWidget(_host(locale: const Locale('ar')));
    await tester.pump();
    final copy = tester.getRect(find.byKey(const Key('recommend-banner-copy')));
    final art = tester.getRect(
      find.byKey(const Key('recommend-banner-artwork')),
    );
    expect(copy.left, greaterThan(art.right));
    // 图标没有 Transform 镜像；画布内的装饰镜像不影响商标。
    expect(
      find.ancestor(
        of: find.byKey(const Key('recommend-banner-icon-plate')),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('updates background and copy together when the theme changes', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pump();
    final lightTitle = tester.widget<Text>(find.text(_banner.title));
    expect(lightTitle.style!.color!.computeLuminance(), lessThan(0.1));
    await tester.pumpWidget(_host(dark: true));
    await tester.pumpAndSettle();
    final darkTitle = tester.widget<Text>(find.text(_banner.title));
    final box = tester.widget<DecoratedBox>(
      find.byKey(const Key('recommend-banner-background')),
    );
    final gradient =
        (box.decoration as BoxDecoration).gradient! as LinearGradient;
    expect(darkTitle.style!.color!.computeLuminance(), greaterThan(0.8));
    expect(gradient.colors.first.computeLuminance(), lessThan(0.05));
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens details once through a focused keyboard action', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(_host(onTap: () => opens++));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opens, 1);
    final l10n = lookupAppLocalizations(const Locale('zh'));
    expect(
      find.bySemanticsLabel('${l10n.a11yAppDetailPage}: ${_banner.title}'),
      findsOneWidget,
    );
  });
}

/// 提供项目真实主题和本地化，并按页面约定为大字号预留纵向空间。
Widget _host({
  double width = 760,
  double scale = 1,
  bool dark = false,
  Locale locale = const Locale('zh'),
  VoidCallback? onTap,
}) => MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: SizedBox(
          width: width,
          height: 236 + (scale - 1) * 160,
          child: RecommendBanner(banner: _banner, onTap: onTap ?? () {}),
        ),
      ),
    ),
  ),
);
