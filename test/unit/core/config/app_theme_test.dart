import 'package:flutter/material.dart';
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

  group('AppTheme button styles', () {
    test('filled button theme uses unified pill sizing in light theme', () {
      final style = AppTheme.lightTheme.filledButtonTheme.style;

      expect(style?.minimumSize?.resolve(<WidgetState>{}), const Size(88, 40));
      expect(
        style?.padding?.resolve(<WidgetState>{}),
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      );
      expect(style?.shape?.resolve(<WidgetState>{}), isA<StadiumBorder>());
    });

    test('outlined button theme unifies hover feedback in dark theme', () {
      final style = AppTheme.darkTheme.outlinedButtonTheme.style;

      expect(style?.minimumSize?.resolve(<WidgetState>{}), const Size(88, 40));
      expect(
        style?.backgroundColor?.resolve(<WidgetState>{WidgetState.hovered}),
        AppColorPalette.dark.surfaceContainerHighest,
      );
      expect(
        style?.side?.resolve(<WidgetState>{})?.color,
        AppColorPalette.dark.border,
      );
    });

    test('light theme still exposes the shared chip theme tokens', () {
      final chipTheme = AppTheme.lightTheme.chipTheme;

      expect(chipTheme.backgroundColor, AppColorPalette.light.cardBackground);
      expect(chipTheme.selectedColor, AppColorPalette.light.primaryLight);
      expect(chipTheme.side?.color, AppColorPalette.light.border);
    });
  });
}
