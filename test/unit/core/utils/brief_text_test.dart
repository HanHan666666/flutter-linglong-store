import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/utils/brief_text.dart';

void main() {
  group('truncateBriefDescription', () {
    test('null 原样返回，不改变空值语义', () {
      expect(truncateBriefDescription(null), isNull);
    });

    test('短文本原样返回', () {
      expect(truncateBriefDescription('WPS 办公软件'), 'WPS 办公软件');
      expect(truncateBriefDescription(''), '');
    });

    test('超长文本截断到上限并追加省略号', () {
      final long = 'a' * 500;
      final result = truncateBriefDescription(long);
      expect(result!.length, 201);
      expect(result.endsWith('…'), isTrue);
    });

    test('恰好等于上限时不截断', () {
      final exact = 'b' * 200;
      expect(truncateBriefDescription(exact), exact);
    });

    test('支持自定义上限', () {
      expect(truncateBriefDescription('abcdef', maxChars: 3), 'abc…');
    });
  });
}
