import 'dart:ui' show SemanticsFlag;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/accessibility/a11y_semantics.dart';

void main() {
  group('A11yButton', () {
    testWidgets('具有 button: true 语义', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yButton(
              semanticsLabel: '测试按钮',
              onTap: () {},
              child: const Text('按钮'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(A11yButton));
      expect(semantics.label, contains('测试按钮'));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('禁用态不可点击', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yButton(
              semanticsLabel: '禁用按钮',
              onTap: () {},
              enabled: false,
              child: const Text('按钮'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(A11yButton));
      expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });

    testWidgets('启用态可点击', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yButton(
              semanticsLabel: '启用按钮',
              onTap: () => tapped = true,
              enabled: true,
              child: const Text('按钮'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });
  });

  group('A11yIconButton', () {
    testWidgets('具有 48x48 最小交互尺寸', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yIconButton(
              icon: const Icon(Icons.close),
              semanticsLabel: '关闭',
              onTap: () {},
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(InkWell));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('具有 button: true 语义', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yIconButton(
              icon: const Icon(Icons.close),
              semanticsLabel: '关闭',
              onTap: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(A11yIconButton));
      expect(semantics.label, '关闭');
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('禁用态不可点击', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yIconButton(
              icon: const Icon(Icons.close),
              semanticsLabel: '禁用图标按钮',
              onTap: () {},
              enabled: false,
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(A11yIconButton));
      expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });
  });

  group('A11yListItem', () {
    testWidgets('使用 MergeSemantics 合并语义', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yListItem(
              semanticsLabel: '列表项',
              child: const Column(
                children: [
                  Text('标题'),
                  Text('描述'),
                ],
              ),
            ),
          ),
        ),
      );

      // 应该只读到一个 Semantics 节点（MergeSemantics 会合并子节点文本）
      final semantics = tester.getSemantics(find.byType(A11yListItem));
      expect(semantics.label, contains('列表项'));
    });

    testWidgets('支持 onTap 交互', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yListItem(
              semanticsLabel: '可点击列表项',
              onTap: () => tapped = true,
              child: const Text('列表项内容'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('支持语义值 value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yListItem(
              semanticsLabel: '带值列表项',
              semanticsValue: '已安装',
              child: const Text('列表项内容'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(A11yListItem));
      expect(semantics.value, '已安装');
    });
  });

  group('A11yTab', () {
    testWidgets('标注选中状态', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yTab(
              label: '标签1',
              selected: true,
              onTap: () {},
              child: const Text('标签1'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(A11yTab));
      expect(semantics.label, contains('标签1'));
      expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
    });

    testWidgets('未选中状态', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yTab(
              label: '标签2',
              selected: false,
              onTap: () {},
              child: const Text('标签2'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(A11yTab));
      expect(semantics.hasFlag(SemanticsFlag.isSelected), isFalse);
    });

    testWidgets('具有 48px 高度', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yTab(
              label: '标签3',
              selected: false,
              onTap: () {},
              child: const Text('标签3'),
            ),
          ),
        ),
      );

      // 查找 A11yTab 内部的 SizedBox（高度 48px）
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(A11yTab),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, 48.0);
    });
  });

  group('A11yCard', () {
    testWidgets('具有 label 语义', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yCard(
              semanticsLabel: '测试卡片',
              onTap: () {},
              child: const Text('卡片内容'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(A11yCard));
      expect(semantics.label, contains('测试卡片'));
    });

    testWidgets('支持 hint 语义', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yCard(
              semanticsLabel: '提示卡片',
              semanticsHint: '双击查看详情',
              onTap: () {},
              child: const Text('卡片内容'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(A11yCard));
      expect(semantics.hint, '双击查看详情');
    });

    testWidgets('支持 onTap 交互', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yCard(
              semanticsLabel: '可点击卡片',
              onTap: () => tapped = true,
              child: const Text('卡片内容'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('无 onTap 时不包含 InkWell', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: A11yCard(
              semanticsLabel: '静态卡片',
              child: const Text('卡片内容'),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });
  });
}
