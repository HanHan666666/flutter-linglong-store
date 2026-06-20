import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/app_detail.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/presentation/widgets/app_detail_hero_header.dart';
import 'package:linglong_store/presentation/widgets/install_button.dart';

void main() {
  testWidgets('detail tag is accessible and emits full tag identity',
      (tester) async {
    // 标签必须可点击、有最小 48px 交互高度、按钮语义，且点击回调原样透传 name+language，
    // 禁止只传名称丢失语言身份
    AppTag? selected;
    await tester.pumpWidget(_buildHeader(
      tags: const [AppTag(name: '办公', language: 'zh_CN')],
      onTagPressed: (tag) => selected = tag,
    ));
    await tester.pumpAndSettle();

    final tag = find.byKey(const ValueKey('app-detail-tag-办公-zh_CN'));
    expect(tag, findsOneWidget);
    expect(tester.getSize(tag).height, greaterThanOrEqualTo(48));

    await tester.tap(tag);
    await tester.pumpAndSettle();
    expect(selected, const AppTag(name: '办公', language: 'zh_CN'));

    final semantics = tester.getSemantics(tag);
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
  });
}

/// 构建详情头部测试宿主，隔离详情页其它依赖。
Widget _buildHeader({
  required List<AppTag> tags,
  required ValueChanged<AppTag> onTagPressed,
}) {
  return MaterialApp(
    locale: const Locale('zh'),
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: AppDetailHeroHeader(
        app: const InstalledApp(
          appId: 'org.example.app',
          name: 'Example',
          version: '1.0.0',
        ),
        installSourceKey: GlobalKey(),
        buttonState: InstallButtonState.notInstalled,
        progress: 0,
        showInstalledActions: false,
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
