import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/theme.dart';

void main() {
  // 与 AppTheme._linuxFontFamilyFallback 保持一致：MiSans 优先（已装用户
  // 生效，未装自然回落）+ CJK + 阿拉伯语 + 表情符号
  const expectedLinuxFontFallback = <String>[
    'MiSans',
    'MiSans VF',
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    'WenQuanYi Micro Hei',
    'WenQuanYi Zen Hei',
    'Noto Sans Arabic',
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

    test('traditional Chinese locale also prefers MiSans (方案 A)', () {
      final fallback = AppTheme.buildLightTheme(
        appLocale: const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
        ),
      ).textTheme.bodyMedium?.fontFamilyFallback;

      // MiSans 繁中码位全覆盖，前插不会混排；地区字库继续兜底缺字。
      expect(fallback?.first, 'MiSans');
      expect(fallback?[1], 'MiSans VF');
      expect(fallback, contains('Noto Sans CJK TC'));
    });

    test('korean locale keeps regional font first (MiSans has no hangul)', () {
      final fallback = AppTheme.buildLightTheme(
        appLocale: const Locale('ko'),
      ).textTheme.bodyMedium?.fontFamilyFallback;

      // 实测 MiSans cmap 无谚文字符，前插对韩文无效果，维持 Noto KR 优先。
      expect(fallback?.first, 'Noto Sans CJK KR');
      expect(fallback, isNot(contains('MiSans')));
    });
  });

  group('AppTheme dynamic typography', () {
    test('bolder typography shifts body text one weight step up', () {
      final theme = AppTheme.buildLightTheme(
        fontWeightAdjustment: AppFontWeightAdjustment.bolder,
      );

      expect(theme.textTheme.bodyMedium?.fontWeight, FontWeight.w500);
      expect(
        theme.extension<AppTypographyStyles>()?.body.fontWeight,
        FontWeight.w500,
      );
    });

    test('system bold text also increases semantic font weight', () {
      final theme = AppTheme.buildDarkTheme(systemBoldText: true);

      expect(theme.textTheme.bodyMedium?.fontWeight, FontWeight.w500);
      expect(theme.textTheme.titleMedium?.fontWeight, FontWeight.w700);
    });
  });
}
