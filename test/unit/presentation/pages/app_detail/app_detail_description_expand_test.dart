import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/presentation/pages/app_detail/app_detail_page.dart';

void main() {
  group('App detail description expand visibility', () {
    test('does not show expand button for a short single-line description', () {
      final textStyle = const TextStyle(fontSize: 14, height: 1.4);

      final shouldShow = shouldShowDescriptionExpandButton(
        text: '这是一个很短的应用简介，不应该出现展开按钮。',
        maxWidth: 480,
        style: textStyle,
        textDirection: TextDirection.ltr,
        maxLines: 3,
      );

      expect(shouldShow, isFalse);
    });

    test(
      'shows expand button when the description actually exceeds three lines',
      () {
        final textStyle = const TextStyle(fontSize: 14, height: 1.4);
        final longDescription = List.filled(
          12,
          '这是一个用于验证应用详情页简介折叠逻辑的较长描述文本',
        ).join();

        final shouldShow = shouldShowDescriptionExpandButton(
          text: longDescription,
          maxWidth: 220,
          style: textStyle,
          textDirection: TextDirection.ltr,
          maxLines: 3,
        );

        expect(shouldShow, isTrue);
      },
    );
  });
}
