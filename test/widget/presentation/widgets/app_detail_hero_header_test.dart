/// 详情页头部布局回归测试。
///
/// 独立验证默认窗口剩余宽度、缩放和方向变化，避免测试依赖安装队列或平台服务。
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/app_detail.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/presentation/widgets/app_detail_hero_header.dart';
import 'package:linglong_store/presentation/widgets/app_icon.dart';
import 'package:linglong_store/presentation/widgets/install_button.dart';

/// 检查可见位置和溢出，保护用户调整窗口与展开操作时的体验。
void main() {
  for (final width in [1088.0, 944.0, 864.0]) {
    for (final state in [
      InstallButtonState.notInstalled,
      InstallButtonState.update,
      InstallButtonState.installing,
      InstallButtonState.pending,
      InstallButtonState.installed,
    ]) {
      testWidgets('默认窗口内容宽度 $width 下 $state 主按钮保持在行尾', (tester) async {
        // 1280px 窗口扣除 176/320/400px 侧栏与 16px 手柄及工作区留白。
        // 这些空间足以并排展示身份信息和按钮，不应因旧宽屏门槛提前换行。
        await _pumpHeader(tester, width: width, buttonState: state);

        _expectPrimaryBesideIcon(tester);
        final panel = tester.getSize(
          find.byKey(const Key('app-detail-hero-action-panel')),
        );
        expect(panel.width, lessThanOrEqualTo(184));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('窗口收窄到空间不足时整体换行，加宽后恢复行尾布局', (tester) async {
    // 持续改变同一窗口约束，验证响应式布局没有依赖首次构建或全局窗口断点。
    for (final width in [864.0, 700.0, 600.0, 944.0]) {
      await _pumpHeader(tester, width: width);
      if (width == 600) {
        final icon = tester.getRect(find.byType(AppIcon));
        final primary = tester.getRect(
          find.byKey(const Key('app-detail-hero-primary-action')),
        );
        expect(primary.top, greaterThanOrEqualTo(icon.bottom));
      } else {
        _expectPrimaryBesideIcon(tester);
      }
      expect(tester.takeException(), isNull);
    }
  });

  for (final locale in [
    const Locale('zh'),
    const Locale('en'),
    const Locale('ar'),
  ]) {
    testWidgets('${locale.languageCode} 次级操作展开时不挤出头部边界', (tester) async {
      // 在接近并排布局最小宽度时逐个展开，覆盖长英文、阿拉伯语和 RTL。
      await _pumpHeader(tester, width: 700, locale: locale);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      for (final key in [
        'app_detail_create_shortcut',
        'app_detail_uninstall',
        'app_detail_share',
      ]) {
        final button = find.byKey(Key(key));
        final originalTop = tester.getTopLeft(button).dy;
        await gesture.moveTo(tester.getCenter(button));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: button,
            matching: find.byKey(
              const ValueKey('expandable-icon-button-label'),
            ),
          ),
          findsOneWidget,
        );

        final headerRect = tester.getRect(
          find.byKey(const Key('app-detail-hero-header')),
        );
        final buttonRect = tester.getRect(button);
        expect(buttonRect.top, closeTo(originalTop, 0.1));
        expect(headerRect.contains(buttonRect.topLeft), isTrue);
        expect(headerRect.contains(buttonRect.bottomRight), isTrue);
        _expectPrimaryBesideIcon(tester, rtl: locale.languageCode == 'ar');
        expect(tester.takeException(), isNull);

        await gesture.moveTo(Offset.zero);
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('大字号和长应用信息仍保留主按钮并排布局', (tester) async {
    // 字体缩放增加信息区预算；文案换行不应压缩主操作或产生 RenderFlex 溢出。
    await _pumpHeader(tester, width: 864, textScale: 1.5);
    _expectPrimaryBesideIcon(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'detail tag preserves compact appearance and emits full identity',
    (tester) async {
      // 标签只增加交互能力，不得改变详情页原有紧凑胶囊的视觉高度；
      // 点击回调仍需原样透传 name+language，禁止丢失语言身份。
      AppTag? selected;
      await tester.pumpWidget(
        _buildHeader(
          tags: const [AppTag(name: '办公', language: 'zh_CN')],
          onTagPressed: (tag) => selected = tag,
        ),
      );
      await tester.pumpAndSettle();

      final tag = find.byKey(const ValueKey('app-detail-tag-办公-zh_CN'));
      expect(tag, findsOneWidget);
      expect(tester.getSize(tag).height, lessThan(48));

      await tester.tap(tag);
      await tester.pumpAndSettle();
      expect(selected, const AppTag(name: '办公', language: 'zh_CN'));

      final semantics = tester.getSemantics(tag);
      // flagsCollection 取代已废弃的 hasFlag（v3.32.0 后弃用）
      expect(semantics.flagsCollection.isButton, isTrue);
    },
  );
}

/// 在真实有界宽度下渲染，确保每个用例结束后恢复测试视口。
Future<void> _pumpHeader(
  WidgetTester tester, {
  required double width,
  InstallButtonState buttonState = InstallButtonState.update,
  Locale locale = const Locale('zh'),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1000);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    _buildHeader(
      buttonState: buttonState,
      locale: locale,
      textScale: textScale,
      showInstalledActions: buttonState != InstallButtonState.notInstalled,
      tags: const [
        AppTag(name: '即时通讯', language: 'zh_CN'),
        AppTag(name: '社区贡献者维护', language: 'zh_CN'),
      ],
    ),
  );
  // 排队态有持续旋转的等待指示器，不能用等待所有动画结束的方式推进帧。
  if (buttonState == InstallButtonState.pending) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  } else {
    await tester.pumpAndSettle();
  }
}

/// 以几何关系验证主按钮在图标行尾，RTL 下同步镜像。
void _expectPrimaryBesideIcon(WidgetTester tester, {bool rtl = false}) {
  final icon = tester.getRect(find.byType(AppIcon));
  final header = tester.getRect(
    find.byKey(const Key('app-detail-hero-header')),
  );
  final primary = tester.getRect(
    find.byKey(const Key('app-detail-hero-primary-action')),
  );
  expect(primary.top, closeTo(icon.top, 0.1));
  if (rtl) {
    expect(primary.right, lessThan(icon.left));
    expect(primary.left, closeTo(header.left + 21, 0.1));
  } else {
    expect(primary.left, greaterThan(icon.right));
    expect(primary.right, closeTo(header.right - 21, 0.1));
  }
}

/// 构建详情头部测试宿主，隔离详情页其它依赖。
Widget _buildHeader({
  List<AppTag> tags = const [],
  ValueChanged<AppTag>? onTagPressed,
  InstallButtonState buttonState = InstallButtonState.notInstalled,
  bool showInstalledActions = false,
  Locale locale = const Locale('zh'),
  double textScale = 1,
}) {
  return MaterialApp(
    locale: locale,
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: AppDetailHeroHeader(
        app: const InstalledApp(
          appId: 'org.example.app',
          name: '微信 GNU/Linux 原生版本',
          version: '1.0.0',
          repoName: 'stable',
          arch: 'x86_64',
        ),
        installSourceKey: GlobalKey(),
        buttonState: buttonState,
        progress: 0.5,
        downloadSpeed: '2.5 MB/s',
        showInstalledActions: showInstalledActions,
        description: '微信 GNU/Linux 原生版本，支持聊天记录导入导出与跨设备通讯。',
        tags: tags,
        onTagPressed: onTagPressed,
        onPrimaryPressed: () {},
        onCancel: () {},
        onCreateShortcut: () {},
        onUninstall: () {},
        onShare: () {},
      ),
    ),
  );
}
