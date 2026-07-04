import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/presentation/widgets/expandable_icon_button.dart';

void main() {
  group('ExpandableIconButton', () {
    testWidgets('默认态只显示图标，不显示文字', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableIconButton(
              icon: Icons.share_outlined,
              label: '分享',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      expect(find.text('分享'), findsNothing);
    });

    testWidgets('鼠标悬浮后显示文字', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableIconButton(
              icon: Icons.share_outlined,
              label: '分享',
              onTap: () {},
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(ExpandableIconButton)));
      await tester.pumpAndSettle();

      // Tooltip 也会渲染相同文字，因此通过 Key 定位展开后实际显示的 Text。
      expect(
        find.descendant(
          of: find.byType(ExpandableIconButton),
          matching: find.byKey(const ValueKey('expandable-icon-button-label')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('点击触发 onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableIconButton(
              icon: Icons.share_outlined,
              label: '分享',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ExpandableIconButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('自定义图标颜色生效', (tester) async {
      const customColor = Colors.red;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableIconButton(
              icon: Icons.share_outlined,
              label: '分享',
              onTap: () {},
              iconColor: customColor,
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.share_outlined));
      expect(iconWidget.color, customColor);
    });

    testWidgets('无障碍语义标签使用 label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableIconButton(
              icon: Icons.share_outlined,
              label: '分享',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == '分享' &&
              widget.properties.button == true,
        ),
        findsOneWidget,
      );
    });
  });
}
