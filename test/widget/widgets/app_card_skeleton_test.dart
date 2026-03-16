import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:linglong_store/presentation/widgets/app_card.dart';

void main() {
  group('AppCard Skeleton Tests', () {
    testWidgets('skeleton constructor should display shimmer loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard.skeleton(),
          ),
        ),
      );

      // 应该显示 Shimmer 组件
      expect(find.byType(Shimmer), findsWidgets);

      // 应该显示卡片容器
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('skeleton should have correct layout structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard.skeleton(),
          ),
        ),
      );

      // 验证骨架屏结构：图标占位 + 内容占位 + 按钮占位
      final row = tester.widget<Row>(find.byType(Row).first);
      // Row 包含: icon, SizedBox, Expanded(content), SizedBox, button = 5 个子元素
      expect(row.children.length, equals(5));
    });

    testWidgets('multiple skeletons should display correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AppCard.skeleton(),
                  AppCard.skeleton(),
                  AppCard.skeleton(),
                ],
              ),
            ),
          ),
        ),
      );

      // 应该显示 3 个卡片
      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('skeleton should adapt to dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: AppCard.skeleton(),
          ),
        ),
      );

      // 骨架屏应该在深色主题下正常渲染
      expect(find.byType(Shimmer), findsWidgets);
    });

    testWidgets('skeleton should adapt to light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: AppCard.skeleton(),
          ),
        ),
      );

      // 骨架屏应该在浅色主题下正常渲染
      expect(find.byType(Shimmer), findsWidgets);
    });
  });

  group('AppCardType Enum', () {
    test('should have all expected types', () {
      expect(AppCardType.values, contains(AppCardType.default_));
      expect(AppCardType.values, contains(AppCardType.recommend));
      expect(AppCardType.values, contains(AppCardType.list));
      expect(AppCardType.values, contains(AppCardType.grid));
    });
  });
}