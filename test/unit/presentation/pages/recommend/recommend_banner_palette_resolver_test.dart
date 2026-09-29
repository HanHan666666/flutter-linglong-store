import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/presentation/pages/recommend/widgets/recommend_banner_palette_resolver.dart';

void main() {
  group('RecommendBannerPaletteResolver', () {
    test('extracts blue dominant color from logo svg', () {
      final svgContent = File('assets/icons/logo.svg').readAsStringSync();

      final color =
          RecommendBannerPaletteResolver.extractPrimaryColorFromSvgContent(
            svgContent,
          );

      expect(color, isNotNull);
      expect(_blue(color!), greaterThan(_red(color)));
      expect(_blue(color), greaterThan(_green(color)));
      expect(_blue(color), greaterThan(180));
    });

    test('keeps brand hue in the accent and a neutral light background', () {
      const baseColor = Color(0xFF025BFF);

      final palette = RecommendBannerPaletteResolver.buildPaletteFromBaseColor(
        baseColor,
        isDark: false,
      );

      // 品牌色仅用作反光，背景必须维持高亮、低饱和的珍珠灰。
      expect(HSLColor.fromColor(palette.start).lightness, greaterThan(0.9));
      expect(HSLColor.fromColor(palette.end).saturation, lessThan(0.3));
      expect(_blue(palette.accent), greaterThan(_red(palette.accent)));
    });

    test('builds a darker palette for dark theme from the same base color', () {
      const baseColor = Color(0xFF025BFF);

      final lightPalette =
          RecommendBannerPaletteResolver.buildPaletteFromBaseColor(
            baseColor,
            isDark: false,
          );
      final darkPalette =
          RecommendBannerPaletteResolver.buildPaletteFromBaseColor(
            baseColor,
            isDark: true,
          );

      expect(
        HSLColor.fromColor(darkPalette.start).lightness,
        lessThan(HSLColor.fromColor(lightPalette.start).lightness),
      );
      expect(
        HSLColor.fromColor(darkPalette.end).lightness,
        lessThan(HSLColor.fromColor(lightPalette.end).lightness),
      );
    });

    test('keeps copy readable for saturated and neutral app icons', () {
      // 取色可能来自任何应用，文字对比度不能依赖品牌的明暗或色相。
      for (final source in [
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.yellow,
        Colors.purple,
        Colors.black,
        Colors.white,
      ]) {
        for (final isDark in [false, true]) {
          final palette =
              RecommendBannerPaletteResolver.buildPaletteFromBaseColor(
                source,
                isDark: isDark,
              );
          for (final background in [palette.start, palette.end]) {
            expect(
              _contrast(palette.foreground, background),
              greaterThanOrEqualTo(4.5),
            );
            expect(
              _contrast(palette.secondaryForeground, background),
              greaterThanOrEqualTo(4.5),
            );
          }
        }
      }
    });
  });
}

/// 按 WCAG 相对亮度计算正文与背景的对比度。
double _contrast(Color a, Color b) {
  final values = [a.computeLuminance(), b.computeLuminance()]..sort();
  return (values.last + 0.05) / (values.first + 0.05);
}

int _red(Color color) => (color.r * 255.0).round().clamp(0, 255);

int _green(Color color) => (color.g * 255.0).round().clamp(0, 255);

int _blue(Color color) => (color.b * 255.0).round().clamp(0, 255);
