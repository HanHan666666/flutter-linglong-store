import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:linglong_store/presentation/widgets/loading_shimmer.dart';

void main() {
  group('LoadingShimmer Tests', () {
    group('Card Type', () {
      testWidgets('should display card shimmer with correct structure', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingShimmer.card(),
            ),
          ),
        );

        // 应该显示 Shimmer 组件
        expect(find.byType(Shimmer), findsWidgets);
      });

      testWidgets('should display multiple card shimmers when count > 1', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LoadingShimmer.card(count: 3),
              ),
            ),
          ),
        );

        // 应该显示多个 Shimmer 组件
        expect(find.byType(Shimmer), findsWidgets);
      });

      testWidgets('should not display when disabled', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingShimmer.card(enabled: false),
            ),
          ),
        );

        // 应该不显示任何内容
        expect(find.byType(Shimmer), findsNothing);
      });
    });

    group('ListItem Type', () {
      testWidgets('should display list item shimmer', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingShimmer.listItem(),
            ),
          ),
        );

        expect(find.byType(Shimmer), findsWidgets);
      });

      testWidgets('should display multiple list items', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LoadingShimmer.listItem(count: 5),
              ),
            ),
          ),
        );

        expect(find.byType(Shimmer), findsWidgets);
      });
    });

    group('Grid Type', () {
      testWidgets('should display grid shimmer', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingShimmer.grid(),
            ),
          ),
        );

        expect(find.byType(Shimmer), findsWidgets);
      });

      testWidgets('should display multiple grid items', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LoadingShimmer.grid(count: 6),
              ),
            ),
          ),
        );

        expect(find.byType(Shimmer), findsWidgets);
      });
    });

    group('Theme Adaptation', () {
      testWidgets('should adapt to dark theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: LoadingShimmer.card(),
            ),
          ),
        );

        // 骨架屏应该在深色主题下正常渲染
        expect(find.byType(LoadingShimmer), findsOneWidget);
      });

      testWidgets('should adapt to light theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: LoadingShimmer.card(),
            ),
          ),
        );

        // 骨架屏应该在浅色主题下正常渲染
        expect(find.byType(LoadingShimmer), findsOneWidget);
      });
    });

    group('ShimmerType Enum', () {
      test('should have all expected types', () {
        expect(ShimmerType.values, contains(ShimmerType.card));
        expect(ShimmerType.values, contains(ShimmerType.listItem));
        expect(ShimmerType.values, contains(ShimmerType.grid));
      });
    });
  });
}