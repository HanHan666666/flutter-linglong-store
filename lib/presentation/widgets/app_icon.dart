import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../../core/config/theme.dart';

enum _AppIconLoadStrategy { svg, directNetwork, cachedNetwork }

_AppIconLoadStrategy _resolveAppIconLoadStrategy(String url) {
  final normalized = url.trim().toLowerCase();
  if (normalized.startsWith('data:image/svg+xml')) {
    return _AppIconLoadStrategy.svg;
  }

  final uri = Uri.tryParse(normalized);
  final path = uri?.path ?? normalized;
  if (path.endsWith('.svg')) {
    return _AppIconLoadStrategy.svg;
  }

  if (_shouldUseDirectNetworkImageUrl(uri)) {
    return _AppIconLoadStrategy.directNetwork;
  }

  return _AppIconLoadStrategy.cachedNetwork;
}

bool _shouldUseDirectNetworkImageUrl(Uri? uri) {
  if (uri == null) {
    return false;
  }

  final scheme = uri.scheme.toLowerCase();
  if (scheme.isNotEmpty && scheme != 'http' && scheme != 'https') {
    return false;
  }

  if (uri.pathSegments.isEmpty) {
    return false;
  }

  final lastSegment = uri.pathSegments.last.toLowerCase();
  return !lastSegment.contains('.');
}

/// 应用图标组件
///
/// 支持网络图片和本地占位符，带有缓存机制
class AppIcon extends StatelessWidget {
  /// 图标URL
  final String? iconUrl;

  /// 图标大小
  final double size;

  /// 边框圆角
  final double borderRadius;

  /// 占位符背景色
  final Color? placeholderColor;

  /// 错误占位符背景色
  final Color? errorColor;

  /// 应用名称（用于占位符显示首字母）
  final String? appName;

  /// SVG 加载时使用的 HTTP client，仅用于测试和受控网络场景。
  final http.Client? svgHttpClient;

  /// 内存缓存解码宽度（物理像素）。
  ///
  /// 未显式指定时按 显示尺寸 × DPR 计算，并封顶 2 倍：DPR=1 的 Linux 桌面
  /// （主流场景）按逻辑尺寸解码即可清晰，固定倍率过解码会浪费 4 倍面积；
  /// 高倍屏也无需超过 2x，图标是全应用数量最多的位图类型。
  final int? memCacheWidth;

  /// 磁盘缓存解码宽度（物理像素）。
  ///
  /// 未显式指定时按 显示尺寸 × DPR 计算并封顶 3 倍，磁盘端可适当冗余
  /// 以便不同尺寸场景复用同一份缩量图。
  final int? maxDiskCacheWidth;

  const AppIcon({
    super.key,
    this.iconUrl,
    this.size = 64,
    this.borderRadius = 12,
    this.placeholderColor,
    this.errorColor,
    this.appName,
    this.svgHttpClient,
    this.memCacheWidth,
    this.maxDiskCacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        placeholderColor ??
        (theme.brightness == Brightness.light
            ? Colors.grey[200]
            : Colors.grey[800]);

    // 如果没有图标URL，显示占位符
    if (iconUrl == null || iconUrl!.isEmpty) {
      return _buildPlaceholder(context, bgColor!);
    }

    final normalizedIconUrl = iconUrl!.trim();

    // 解码尺寸随 DPR 缩放并封顶：见 memCacheWidth / maxDiskCacheWidth 字段注释
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final effectiveMemCacheWidth =
        memCacheWidth ?? (size * dpr.clamp(1.0, 2.0)).toInt();
    final effectiveDiskCacheWidth =
        maxDiskCacheWidth ?? (size * dpr.clamp(1.0, 3.0)).toInt();
    final loadStrategy = _resolveAppIconLoadStrategy(normalizedIconUrl);

    if (loadStrategy == _AppIconLoadStrategy.svg) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: size,
          height: size,
          child: SvgPicture.network(
            normalizedIconUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            httpClient: svgHttpClient,
            placeholderBuilder: (context) =>
                _buildPlaceholder(context, bgColor!),
            errorBuilder: (context, error, stackTrace) =>
                _buildErrorWidget(context, bgColor!),
          ),
        ),
      );
    }

    // 联通后端存在一类无扩展名图标地址，Linux 下走 CachedNetworkImage
    // 会出现无法显示的问题。此类地址直接交给 Image.network 解码，
    // 若实际内容是 SVG，则在位图解码失败后再回退到 SvgPicture。
    if (loadStrategy == _AppIconLoadStrategy.directNetwork) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          normalizedIconUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: effectiveMemCacheWidth,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _buildPlaceholder(context, bgColor!);
          },
          errorBuilder: (context, error, stackTrace) {
            if (error is NetworkImageLoadException) {
              return _buildErrorWidget(context, bgColor!);
            }

            return SizedBox(
              width: size,
              height: size,
              child: SvgPicture.network(
                normalizedIconUrl,
                width: size,
                height: size,
                fit: BoxFit.contain,
                httpClient: svgHttpClient,
                placeholderBuilder: (context) =>
                    _buildPlaceholder(context, bgColor!),
                errorBuilder: (context, svgError, svgStackTrace) =>
                    _buildErrorWidget(context, bgColor!),
              ),
            );
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: normalizedIconUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: effectiveMemCacheWidth,
        maxWidthDiskCache: effectiveDiskCacheWidth,
        placeholder: (context, url) => _buildPlaceholder(context, bgColor!),
        errorWidget: (context, url, error) =>
            _buildErrorWidget(context, bgColor!),
      ),
    );
  }

  /// 构建占位符
  Widget _buildPlaceholder(BuildContext context, Color bgColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: appName != null && appName!.isNotEmpty
            ? _buildInitials(context)
            : _buildDefaultIcon(context),
      ),
    );
  }

  /// 构建首字母显示
  ///
  /// 提取应用名称的首字符作为占位符显示
  /// 支持中英文混合名称，优先提取中文字符或英文单词首字母
  Widget _buildInitials(BuildContext context) {
    final initial = _extractInitial(appName!);
    return Text(
      initial,
      style: TextStyle(
        fontSize: size * 0.4,
        fontWeight: context.appFontWeight(FontWeight.w700),
        color: Theme.of(
          context,
        ).textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
      ),
    );
  }

  /// 从应用名称中提取首字符
  ///
  /// 规则：
  /// 1. 如果第一个字符是中文，直接返回该字符
  /// 2. 如果是英文字母，返回大写形式
  /// 3. 其他情况返回第一个字符
  String _extractInitial(String name) {
    if (name.isEmpty) return '?';

    final firstChar = name.trim()[0];

    // 检查是否为中文字符
    if (_isChinese(firstChar)) {
      return firstChar;
    }

    // 英文字母转大写
    if (_isEnglishLetter(firstChar)) {
      return firstChar.toUpperCase();
    }

    // 其他字符直接返回
    return firstChar;
  }

  /// 检查字符是否为中文字符
  bool _isChinese(String char) {
    final codeUnit = char.codeUnitAt(0);
    return codeUnit >= 0x4E00 && codeUnit <= 0x9FFF;
  }

  /// 检查字符是否为英文字母
  bool _isEnglishLetter(String char) {
    final codeUnit = char.codeUnitAt(0);
    return (codeUnit >= 0x41 && codeUnit <= 0x5A) || // A-Z
        (codeUnit >= 0x61 && codeUnit <= 0x7A); // a-z
  }

  /// 构建默认图标
  ///
  /// 使用玲珑应用商店的默认应用图标
  Widget _buildDefaultIcon(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(
        Icons.apps,
        size: size * 0.5,
        color: Theme.of(
          context,
        ).textTheme.bodyLarge?.color?.withValues(alpha: 0.3),
      ),
    );
  }

  /// 构建错误占位符
  Widget _buildErrorWidget(BuildContext context, Color bgColor) {
    final errorBg = errorColor ?? bgColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: errorBg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ExcludeSemantics(
        child: Icon(
          Icons.broken_image,
          size: size * 0.4,
          color: Theme.of(
            context,
          ).textTheme.bodyLarge?.color?.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
