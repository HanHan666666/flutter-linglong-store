import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/accessibility/a11y_text_scaler.dart';

void main() {
  group('clampTextScaler', () {
    testWidgets('返回系统缩放比例在范围内', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.0)),
          child: Builder(
            builder: (context) {
              final scaler = clampTextScaler(context);
              expect(
                scaler.scale(16.0),
                inInclusiveRange(16.0 * 0.8, 16.0 * 1.5),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('限制最大缩放为 1.5x', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
          child: Builder(
            builder: (context) {
              final scaler = clampTextScaler(context);
              expect(scaler.scale(16.0), lessThanOrEqualTo(16.0 * 1.5));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('限制最小缩放为 0.8x', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
          child: Builder(
            builder: (context) {
              final scaler = clampTextScaler(context);
              expect(scaler.scale(16.0), greaterThanOrEqualTo(16.0 * 0.8));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('A11yText', () {
    testWidgets('渲染文本不报错', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.0)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: A11yText('测试文本'),
          ),
        ),
      );

      expect(find.text('测试文本'), findsOneWidget);
    });
  });
}
