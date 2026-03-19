import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 推荐页轮播背景调色板。
class RecommendBannerPalette {
  const RecommendBannerPalette({
    required this.start,
    required this.end,
    required this.accent,
  });

  final Color start;
  final Color end;
  final Color accent;
}

/// 推荐页轮播主色解析器。
///
/// 先尝试从 logo 本身提取主色，再基于主色生成同色系调色板；
/// 只有在提取失败时，才退回稳定的兜底色盘。
class RecommendBannerPaletteResolver {
  RecommendBannerPaletteResolver._();

  static final Dio _dio = Dio();
  static final Map<String, Future<Color?>> _sourceColorCache =
      <String, Future<Color?>>{};

  static Future<RecommendBannerPalette> resolve({
    required String seed,
    required bool isDark,
    String? imageUrl,
  }) async {
    final baseColor = await _resolveBaseColor(imageUrl: imageUrl);
    if (baseColor == null) {
      return _fallbackPalette(seed: seed, isDark: isDark);
    }
    return buildPaletteFromBaseColor(baseColor, isDark: isDark);
  }

  static RecommendBannerPalette buildPaletteFromBaseColor(
    Color baseColor, {
    required bool isDark,
  }) {
    final hsl = HSLColor.fromColor(baseColor);
    final normalized = hsl
        .withSaturation(hsl.saturation.clamp(0.42, 0.82))
        .withLightness(hsl.lightness.clamp(0.32, 0.58));

    final start = normalized
        .withSaturation(
          (normalized.saturation * (isDark ? 0.92 : 0.84)).clamp(0.38, 0.82),
        )
        .withLightness(isDark ? 0.34 : 0.58)
        .toColor();
    final end = normalized
        .withSaturation((normalized.saturation * 0.96).clamp(0.40, 0.84))
        .withLightness(isDark ? 0.22 : 0.48)
        .toColor();
    final accent = normalized
        .withSaturation((normalized.saturation * 0.72).clamp(0.28, 0.68))
        .withLightness(isDark ? 0.40 : 0.68)
        .toColor();

    return RecommendBannerPalette(start: start, end: end, accent: accent);
  }

  static Color? extractPrimaryColorFromSvgContent(String svgContent) {
    final matches = RegExp(
      r'#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b',
    ).allMatches(svgContent);
    final scores = <Color, double>{};

    for (final match in matches) {
      final hex = match.group(0);
      if (hex == null) continue;
      final color = _parseHexColor(hex);
      if (color == null) continue;

      final hsl = HSLColor.fromColor(color);
      if (hsl.saturation < 0.10) continue;
      if (hsl.lightness > 0.96 || hsl.lightness < 0.06) continue;

      final score =
          hsl.saturation * 0.70 + (1 - (hsl.lightness - 0.52).abs()) * 0.30;
      scores.update(color, (value) => value + score, ifAbsent: () => score);
    }

    if (scores.isEmpty) return null;

    return scores.entries.reduce((best, candidate) {
      return candidate.value > best.value ? candidate : best;
    }).key;
  }

  static Color? extractDominantColorFromRgba(Uint8List rgbaBytes) {
    if (rgbaBytes.isEmpty) return null;

    final buckets = <int, double>{};
    for (var i = 0; i <= rgbaBytes.length - 4; i += 4) {
      final r = rgbaBytes[i];
      final g = rgbaBytes[i + 1];
      final b = rgbaBytes[i + 2];
      final a = rgbaBytes[i + 3];
      if (a < 24) continue;

      final color = Color.fromARGB(a, r, g, b);
      final hsl = HSLColor.fromColor(color);
      if (hsl.saturation < 0.12) continue;
      if (hsl.lightness > 0.96 || hsl.lightness < 0.06) continue;

      // 低分辨率量化后选取得分最高的色桶，避免平均色被灰化。
      final bucket = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4);
      final score = 1 + hsl.saturation * 2.4;
      buckets.update(bucket, (value) => value + score, ifAbsent: () => score);
    }

    if (buckets.isEmpty) return null;

    final bestBucket = buckets.entries.reduce((best, candidate) {
      return candidate.value > best.value ? candidate : best;
    }).key;
    final r = ((bestBucket >> 8) & 0xF) * 17;
    final g = ((bestBucket >> 4) & 0xF) * 17;
    final b = (bestBucket & 0xF) * 17;
    return Color.fromARGB(255, r, g, b);
  }

  static Future<Color?> _resolveBaseColor({String? imageUrl}) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    final cacheKey = imageUrl;
    return _sourceColorCache.putIfAbsent(
      cacheKey,
      () => _loadBaseColor(imageUrl),
    );
  }

  static Future<Color?> _loadBaseColor(String imageUrl) async {
    try {
      if (_looksLikeSvg(imageUrl)) {
        final svgContent = await _loadText(imageUrl);
        if (svgContent != null) {
          return extractPrimaryColorFromSvgContent(svgContent);
        }
      }

      final bytes = await _loadBytes(imageUrl);
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 24,
        targetHeight: 24,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        return null;
      }
      return extractDominantColorFromRgba(byteData.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static bool _looksLikeSvg(String path) {
    return path.toLowerCase().contains('.svg');
  }

  static Future<String?> _loadText(String path) async {
    if (_isRemote(path)) {
      final response = await _dio.get<String>(
        path,
        options: Options(responseType: ResponseType.plain),
      );
      return response.data;
    }
    if (_isAssetPath(path)) {
      return rootBundle.loadString(path);
    }
    final file = File(path);
    if (await file.exists()) {
      return file.readAsString();
    }
    return null;
  }

  static Future<Uint8List?> _loadBytes(String path) async {
    if (_isRemote(path)) {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      return data == null ? null : Uint8List.fromList(data);
    }
    if (_isAssetPath(path)) {
      final byteData = await rootBundle.load(path);
      return byteData.buffer.asUint8List();
    }
    final file = File(path);
    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }

  static bool _isRemote(String path) {
    final uri = Uri.tryParse(path);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static bool _isAssetPath(String path) {
    return !path.startsWith('/') && !path.contains('://');
  }

  static Color? _parseHexColor(String hex) {
    final normalized = hex.replaceFirst('#', '');
    if (normalized.length == 3) {
      final expanded = normalized.split('').map((char) => '$char$char').join();
      return Color(int.parse('FF$expanded', radix: 16));
    }
    if (normalized.length == 6) {
      return Color(int.parse('FF$normalized', radix: 16));
    }
    return null;
  }

  static RecommendBannerPalette _fallbackPalette({
    required String seed,
    required bool isDark,
  }) {
    const bases = <Color>[
      Color(0xFF1D74FF),
      Color(0xFF22C55E),
      Color(0xFFFF8F1F),
      Color(0xFF14B8A6),
    ];
    final base = bases[seed.hashCode.abs() % bases.length];
    return buildPaletteFromBaseColor(base, isDark: isDark);
  }
}
