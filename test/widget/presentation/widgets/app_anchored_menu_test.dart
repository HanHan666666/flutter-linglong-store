import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/presentation/widgets/app_anchored_menu.dart';

void main() {
  testWidgets('anchored menu opens immediately and closes before dispatch', (
    tester,
  ) async {
    String? selectedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppAnchoredMenuButton<String>(
            buttonKey: const ValueKey('menu-trigger'),
            tooltip: '更多操作',
            semanticsLabel: '更多操作',
            entries: const [
              AppAnchoredMenuItem<String>(
                key: ValueKey('menu-action'),
                value: 'action',
                label: '执行操作',
              ),
            ],
            onSelected: (value) {
              // 回调执行时弹层必须已经关闭，避免业务重建留下旧 Overlay。
              expect(find.byKey(const ValueKey('menu-action')), findsNothing);
              selectedValue = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('menu-trigger')));
    await tester.pump();

    expect(find.byKey(const ValueKey('menu-action')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('menu-action')));
    await tester.pump();
    await tester.pump();

    expect(selectedValue, 'action');
    expect(find.byKey(const ValueKey('menu-action')), findsNothing);
  });
}
