/// 首页精品应用展台。
///
/// 文案与展品共享一套布局，主题只改变材质和光照；所有造型由静态矢量绘制，
/// 不引入海报资源、持续动画或独立业务状态。
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/accessibility.dart';
import '../../../../core/config/theme.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../domain/models/recommend_models.dart';
import '../../../widgets/app_icon.dart';
import 'recommend_banner_background.dart';
import 'recommend_banner_palette_resolver.dart';

/// 展示服务端提供的应用信息，点击仍由推荐页统一路由。
class RecommendBanner extends StatelessWidget {
  /// 只接收当前条目与操作，不订阅全局 Provider。
  const RecommendBanner({required this.banner, required this.onTap, super.key});

  /// 现有推荐数据，不虚构标签、评分或推荐理由。
  final BannerInfo banner;

  /// 复用推荐页已有的详情或外链入口。
  final VoidCallback onTap;

  /// 窄窗口优先保留文案与操作，将装饰展台收敛成图标托板。
  @override
  Widget build(BuildContext context) {
    return RecommendBannerBackground(
      banner: banner,
      builder: (context, palette) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          return Padding(
            // 两侧留出轮播控件的安全区，底部留出指示器空间。
            padding: EdgeInsetsDirectional.fromSTEB(
              compact ? 64 : 88,
              22,
              compact ? 64 : 72,
              34,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _BannerCopy(
                    banner: banner,
                    palette: palette,
                    onTap: onTap,
                    compact: compact,
                  ),
                ),
                SizedBox(width: compact ? 12 : 24),
                SizedBox(
                  width: compact
                      ? 72
                      : (constraints.maxWidth * 0.36).clamp(180.0, 360.0),
                  child: ExcludeSemantics(
                    // 展品重复了标题中的应用身份，不让读屏再读一次占位字母。
                    child: RepaintBoundary(
                      child: _BannerArtwork(
                        banner: banner,
                        palette: palette,
                        compact: compact,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 开放式文案区，用排版层级取代玻璃卡片嵌套。
class _BannerCopy extends StatelessWidget {
  /// 所有颜色来自同一份主题调色板。
  const _BannerCopy({
    required this.banner,
    required this.palette,
    required this.onTap,
    required this.compact,
  });

  /// 当前应用的真实标题与描述。
  final BannerInfo banner;

  /// 固定可读的前景色与中性材质。
  final RecommendBannerPalette palette;

  /// 页面统一处理的导航回调。
  final VoidCallback onTap;

  /// 窄窗口减小标题字号，保留操作空间。
  final bool compact;

  /// 系统字体缩放由父级增加 Banner 高度承接，不缩小文字规避溢出。
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const Key('recommend-banner-copy'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: banner.title,
          child: Text(
            banner.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 26 : 32,
              fontWeight: context.appFontWeight(FontWeight.w600),
              color: palette.foreground,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          banner.description?.trim().isNotEmpty == true
              ? banner.description!
              : l10n.appDescriptionPlaceholder,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: palette.secondaryForeground,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Material(
          color: palette.foreground,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: A11yButton(
            semanticsLabel: '${l10n.a11yAppDetailPage}: ${banner.title}',
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.viewDetail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: context.appFontWeight(FontWeight.w600),
                            color: palette.start,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        // 该 Material 图标自带 matchTextDirection，避免重复镜像。
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: palette.start,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 静态雕塑薄片、椭圆展台和真实应用图标组成的单一主视觉。
class _BannerArtwork extends StatelessWidget {
  /// 紧凑模式只保留图标托板，避免装饰挤压文字。
  const _BannerArtwork({
    required this.banner,
    required this.palette,
    required this.compact,
  });

  /// 复用 AppIcon 的缓存、SVG 支持和错误占位。
  final BannerInfo banner;

  /// 两种主题的材质参数。
  final RecommendBannerPalette palette;

  /// 小空间省去雕塑背景。
  final bool compact;

  /// 图标不随画布镜像，避免 RTL 下翻转应用商标。
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: compact ? 1 : 360 / 216,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plateSize = compact
              ? constraints.maxWidth
              : constraints.maxWidth * 0.35;
          final inset = plateSize * 0.10;
          return Stack(
            key: const Key('recommend-banner-artwork'),
            fit: StackFit.expand,
            children: [
              if (!compact)
                CustomPaint(
                  painter: _ExhibitPainter(
                    palette: palette,
                    textDirection: Directionality.of(context),
                  ),
                ),
              Align(
                alignment: compact
                    ? Alignment.center
                    : const AlignmentDirectional(0.05, -0.30),
                child: Container(
                  key: const Key('recommend-banner-icon-plate'),
                  width: plateSize,
                  height: plateSize,
                  padding: EdgeInsets.all(inset),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(plateSize * 0.23),
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [
                        Color.lerp(palette.surface, palette.accent, 0.08)!,
                        palette.surface,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: palette.isDark ? 0.16 : 0.8,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF070C18,
                        ).withValues(alpha: palette.isDark ? 0.30 : 0.12),
                        blurRadius: compact ? 12 : 24,
                        offset: Offset(0, compact ? 6 : 14),
                      ),
                    ],
                  ),
                  child: AppIcon(
                    iconUrl: banner.imageUrl,
                    appName: banner.title.trim().isEmpty ? null : banner.title,
                    size: plateSize - inset * 2,
                    borderRadius: plateSize * 0.15,
                    placeholderColor: palette.surface,
                    errorColor: palette.surface,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 用少量贝塞尔曲线与渐变绘制空间层次，不需要持续帧或模糊滤镜。
class _ExhibitPainter extends CustomPainter {
  /// 仅尺寸、主题、品牌色和方向变化时重绘。
  const _ExhibitPainter({required this.palette, required this.textDirection});

  /// 材质与反光的唯一颜色来源。
  final RecommendBannerPalette palette;

  /// 自定义画布需显式跟随阅读方向镜像。
  final TextDirection textDirection;

  /// 所有几何以 360×216 的局部画布绘制，随展品区域缩放。
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (textDirection == TextDirection.rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.scale(size.width / 360, size.height / 216);
    final dark = palette.isDark;
    const bounds = Rect.fromLTWH(0, -40, 360, 280);

    // 画廊聚光与浅色环境光同源，径向渐变代替大范围模糊。
    _softEllipse(
      canvas,
      const Rect.fromLTWH(24, -60, 338, 278),
      palette.accent.withValues(alpha: dark ? 0.19 : 0.13),
    );

    final ribbon = Path()
      ..moveTo(74, 211)
      ..cubicTo(109, 118, 113, 24, 204, -19)
      ..cubicTo(281, -55, 372, -9, 343, 95)
      ..cubicTo(348, 18, 284, -9, 231, 26)
      ..cubicTo(169, 68, 158, 155, 132, 218)
      ..close();
    canvas.drawPath(
      ribbon,
      Paint()
        ..shader = LinearGradient(
          colors: dark
              ? [const Color(0xFF555D69), const Color(0xFF2D343F), palette.end]
              : [const Color(0xFFFAFBFD), const Color(0xFFD3D9E2), palette.end],
          stops: const [0, 0.48, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
    );
    final rim = Path()
      ..moveTo(74, 211)
      ..cubicTo(109, 118, 113, 24, 204, -19)
      ..cubicTo(281, -55, 372, -9, 343, 95);
    canvas.drawPath(
      rim,
      Paint()
        ..color = Colors.white.withValues(alpha: dark ? 0.24 : 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // 第二片只露出轮廓与切面，形成有节制的前后层次。
    final fold = Path()
      ..moveTo(271, 191)
      ..cubicTo(325, 152, 350, 102, 359, 38)
      ..cubicTo(383, 123, 339, 192, 304, 216)
      ..close();
    canvas.drawPath(
      fold,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(palette.surface, palette.accent, dark ? 0.26 : 0.12)!,
            palette.end,
          ],
        ).createShader(bounds),
    );

    _softEllipse(
      canvas,
      const Rect.fromLTWH(50, 178, 282, 48),
      const Color(0xFF0A1120).withValues(alpha: dark ? 0.48 : 0.18),
    );
    const top = Rect.fromLTWH(83, 164, 214, 38);
    final front = Path()
      ..moveTo(83, 183)
      ..cubicTo(83, 208, 297, 208, 297, 183)
      ..lineTo(297, 199)
      ..cubicTo(297, 226, 83, 226, 83, 199)
      ..close();
    canvas.drawPath(
      front,
      Paint()
        ..shader = LinearGradient(
          colors: dark
              ? [const Color(0xFF414A57), const Color(0xFF222832)]
              : [const Color(0xFFD7DDE6), const Color(0xFFF0F2F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(83, 183, 214, 36)),
    );
    canvas.drawOval(
      top,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(palette.surface, palette.accent, dark ? 0.18 : 0.06)!,
            palette.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(top),
    );
    canvas.drawOval(
      top,
      Paint()
        ..color = Colors.white.withValues(alpha: dark ? 0.18 : 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    _softEllipse(
      canvas,
      const Rect.fromLTWH(133, 167, 112, 23),
      const Color(0xFF0B1424).withValues(alpha: dark ? 0.42 : 0.16),
    );
    canvas.restore();
  }

  /// 将圆形渐变压成椭圆，模拟柔光和接触阴影，无需离屏模糊。
  void _softEllipse(Canvas canvas, Rect rect, Color color) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.scale(rect.width / 2, rect.height / 2);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(const Rect.fromLTWH(-1, -1, 2, 2)),
    );
    canvas.restore();
  }

  /// 页面其它区域更新不会触发静态展台重绘。
  @override
  bool shouldRepaint(covariant _ExhibitPainter oldDelegate) =>
      oldDelegate.palette.start != palette.start ||
      oldDelegate.palette.end != palette.end ||
      oldDelegate.palette.accent != palette.accent ||
      oldDelegate.palette.isDark != palette.isDark ||
      oldDelegate.textDirection != textDirection;
}
