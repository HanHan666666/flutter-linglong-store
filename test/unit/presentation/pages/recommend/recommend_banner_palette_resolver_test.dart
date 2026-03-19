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

    test('builds a light palette that keeps the source hue family', () {
      const baseColor = Color(0xFF025BFF);

      final palette = RecommendBannerPaletteResolver.buildPaletteFromBaseColor(
        baseColor,
        isDark: false,
      );

      expect(_blue(palette.start), greaterThan(_red(palette.start)));
      expect(_blue(palette.end), greaterThan(_red(palette.end)));
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
  });
}

int _red(Color color) => (color.r * 255.0).round().clamp(0, 255);

int _green(Color color) => (color.g * 255.0).round().clamp(0, 255);

int _blue(Color color) => (color.b * 255.0).round().clamp(0, 255);
