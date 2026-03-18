import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/presentation/widgets/app_detail_secondary_actions.dart';

void main() {
  Future<void> pumpSecondaryActions(
    WidgetTester tester, {
    required bool isVisible,
    VoidCallback? onCreateShortcut,
    VoidCallback? onUninstall,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDetailSecondaryActions(
            isVisible: isVisible,
            onCreateShortcut: onCreateShortcut ?? () {},
            onUninstall: onUninstall ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('未安装时隐藏次级操作', (tester) async {
    await pumpSecondaryActions(tester, isVisible: false);

    expect(find.text('创建桌面快捷方式'), findsNothing);
    expect(find.text('卸载'), findsNothing);
  });

  testWidgets('已安装时展示并响应次级操作', (tester) async {
    var shortcutTapped = false;
    var uninstallTapped = false;

    await pumpSecondaryActions(
      tester,
      isVisible: true,
      onCreateShortcut: () => shortcutTapped = true,
      onUninstall: () => uninstallTapped = true,
    );

    expect(find.text('创建桌面快捷方式'), findsOneWidget);
    expect(find.text('卸载'), findsOneWidget);

    await tester.tap(find.text('创建桌面快捷方式'));
    await tester.pump();
    await tester.tap(find.text('卸载'));
    await tester.pump();

    expect(shortcutTapped, isTrue);
    expect(uninstallTapped, isTrue);
  });
}
