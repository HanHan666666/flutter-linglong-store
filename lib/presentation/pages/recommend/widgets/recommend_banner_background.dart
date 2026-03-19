import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/recommend_models.dart';
import 'recommend_banner_palette_resolver.dart';

/// 推荐页轮播背景层。
///
/// 职责仅限于渲染品牌色背景与风格化背景元素，
/// 后续替换为图片背景或其他风格时，只需要替换这个组件。
class RecommendBannerBackground extends StatefulWidget {
  const RecommendBannerBackground({
    required this.banner,
    required this.child,
    super.key,
  });

  final BannerInfo banner;
  final Widget child;

  @override
  State<RecommendBannerBackground> createState() =>
      _RecommendBannerBackgroundState();
}

class _RecommendBannerBackgroundState extends State<RecommendBannerBackground> {
  RecommendBannerPalette? _resolvedPalette;
  Brightness? _lastBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      _resolvedPalette = null;
      _loadPalette();
    }
  }

  @override
  void didUpdateWidget(covariant RecommendBannerBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banner.imageUrl != widget.banner.imageUrl ||
        oldWidget.banner.title != widget.banner.title) {
      _resolvedPalette = null;
      _loadPalette();
    }
  }

  Future<void> _loadPalette() async {
    final palette = await RecommendBannerPaletteResolver.resolve(
      seed: widget.banner.title,
      imageUrl: widget.banner.imageUrl,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    if (!mounted) return;
    setState(() => _resolvedPalette = palette);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final banner = widget.banner;
    final palette =
        _resolvedPalette ??
        RecommendBannerPaletteResolver.buildPaletteFromBaseColor(
          const Color(0xFF1D74FF),
          isDark: isDark,
        );

    return DecoratedBox(
      key: const Key('recommend-banner-background'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.start, palette.end],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: -36,
              top: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.06 : 0.12,
                      ),
                      blurRadius: 56,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const SizedBox(width: 1, height: 1),
              ),
            ),
            Positioned(
              right: -44,
              top: -34,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.08),
                ),
              ),
            ),
            if (banner.imageUrl.isNotEmpty)
              Positioned(
                right: -12,
                top: -8,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: isDark ? 0.18 : 0.24,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Transform.rotate(
                        angle: -0.18,
                        child: CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          width: 196,
                          height: 196,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _FallbackBrandShape(palette: palette),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                right: -18,
                top: -8,
                child: _FallbackBrandShape(palette: palette),
              ),
            Positioned(
              right: 36,
              top: 30,
              child: _PreviewPlate(isDark: isDark),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.02 : 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _FallbackBrandShape extends StatelessWidget {
  const _FallbackBrandShape({required this.palette});

  final RecommendBannerPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      height: 196,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.32),
            palette.accent.withValues(alpha: 0.48),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 32,
            top: 26,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: 30,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPlate extends StatelessWidget {
  const _PreviewPlate({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final border = Colors.white.withValues(alpha: isDark ? 0.10 : 0.16);
    final fill = isDark
        ? Colors.black.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.14);

    return Container(
      width: 176,
      height: 104,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 108,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.30),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 86,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
