import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/theme.dart';

void main() {
  group('AppTheme tooltip timing', () {
    test('light theme uses a unified 800ms tooltip wait duration', () {
      expect(
        AppTheme.lightTheme.tooltipTheme.waitDuration,
        const Duration(milliseconds: 800),
      );
    });

    test('dark theme uses a unified 800ms tooltip wait duration', () {
      expect(
        AppTheme.darkTheme.tooltipTheme.waitDuration,
        const Duration(milliseconds: 800),
      );
    });
  });
}
