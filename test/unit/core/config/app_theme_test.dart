import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/theme.dart';

void main() {
  const expectedLinuxFontFallback = <String>[
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    'WenQuanYi Micro Hei',
    'WenQuanYi Zen Hei',
    'Noto Color Emoji',
  ];

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

  group('AppTheme Linux font fallback', () {
    test(
      'light theme text styles include explicit Chinese-capable fallbacks',
      () {
        expect(
          AppTheme.lightTheme.textTheme.bodyMedium?.fontFamilyFallback,
          expectedLinuxFontFallback,
        );
      },
    );

    test(
      'dark theme text styles include explicit Chinese-capable fallbacks',
      () {
        expect(
          AppTheme.darkTheme.textTheme.bodyMedium?.fontFamilyFallback,
          expectedLinuxFontFallback,
        );
      },
    );

    test('component theme text styles reuse the same fallback list', () {
      expect(
        AppTheme.lightTheme.appBarTheme.titleTextStyle?.fontFamilyFallback,
        expectedLinuxFontFallback,
      );
      expect(
        AppTheme.darkTheme.appBarTheme.titleTextStyle?.fontFamilyFallback,
        expectedLinuxFontFallback,
      );
    });
  });
}
