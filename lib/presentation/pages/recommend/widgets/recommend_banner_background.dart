/// 推荐 Banner 的主题背景与异步品牌取色边界。
///
/// 主题切换立即使用对应的中性底色，取色结果仅补充品牌反光；网络完成顺序
/// 不能将旧主题或旧应用的调色板重新写回当前画面。
library;

import 'package:flutter/material.dart';

import '../../../../domain/models/recommend_models.dart';
import 'recommend_banner_palette_resolver.dart';

/// 将取色结果集中下发，避免背景、文案和展台各自请求或判断主题。
class RecommendBannerBackground extends StatefulWidget {
  /// 构建器只负责表现层，不在构建过程中执行图片解析或网络请求。
  const RecommendBannerBackground({
    required this.banner,
    required this.builder,
    super.key,
  });

  /// 当前轮播条目，标题在无图时提供稳定的兜底色种子。
  final BannerInfo banner;

  /// 同一份调色板同时用于文字、展台和图标托板。
  final Widget Function(BuildContext, RecommendBannerPalette) builder;

  /// 将异步取色绑定到条目生命周期。
  @override
  State<RecommendBannerBackground> createState() =>
      _RecommendBannerBackgroundState();
}

/// 只保存视觉取色状态，不持有轮播、导航或业务数据的第二份状态。
class _RecommendBannerBackgroundState extends State<RecommendBannerBackground> {
  /// 立即可用的主题底色，等待取色期间也保持可读。
  late RecommendBannerPalette _palette;

  /// 避免无关依赖变化触发重复取色。
  Brightness? _lastBrightness;

  /// 每次主题或条目切换递增，丢弃已过期的异步响应。
  int _paletteRequest = 0;

  /// 主题切换立即重建中性底色，不等待网络取色。
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      _loadPalette();
    }
  }

  /// 复用轮播位置但条目变化时，使旧图片的异步结果失效。
  @override
  void didUpdateWidget(covariant RecommendBannerBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banner.imageUrl != widget.banner.imageUrl ||
        oldWidget.banner.title != widget.banner.title) {
      _loadPalette();
    }
  }

  /// 生命周期方法随后会构建首帧；只有有效异步结果需要额外重绘。
  Future<void> _loadPalette() async {
    final request = ++_paletteRequest;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _palette = RecommendBannerPaletteResolver.buildPaletteFromBaseColor(
      const Color(0xFF637B9B),
      isDark: isDark,
    );
    final palette = await RecommendBannerPaletteResolver.resolve(
      seed: widget.banner.title,
      imageUrl: widget.banner.imageUrl,
      isDark: isDark,
    );
    if (!mounted || request != _paletteRequest) return;
    setState(() => _palette = palette);
  }

  /// 背景仅由普通渐变构成，不使用全幅模糊或离屏玻璃合成。
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('recommend-banner-background'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [_palette.start, _palette.end],
        ),
      ),
      child: widget.builder(context, _palette),
    );
  }
}
