import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  /// 内存缓存最大宽度（像素），默认为 size * 3
  final int? memCacheWidth;

  /// 磁盘缓存最大宽度（像素），默认为 size * 4
  final int? maxDiskCacheWidth;

  const AppIcon({
    super.key,
    this.iconUrl,
    this.size = 64,
    this.borderRadius = 12,
    this.placeholderColor,
    this.errorColor,
    this.appName,
    this.memCacheWidth,
    this.maxDiskCacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = placeholderColor ??
        (theme.brightness == Brightness.light
            ? Colors.grey[200]
            : Colors.grey[800]);

    // 如果没有图标URL，显示占位符
    if (iconUrl == null || iconUrl!.isEmpty) {
      return _buildPlaceholder(context, bgColor!);
    }

    // 缓存策略：内存缓存约为显示尺寸的2倍，磁盘缓存约为显示尺寸的3倍
    // 这样可以在保证清晰度的同时节省内存
    final effectiveMemCacheWidth = memCacheWidth ?? (size * 2).toInt();
    final effectiveDiskCacheWidth = maxDiskCacheWidth ?? (size * 3).toInt();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: iconUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: effectiveMemCacheWidth,
        maxWidthDiskCache: effectiveDiskCacheWidth,
        placeholder: (context, url) => _buildPlaceholder(context, bgColor!),
        errorWidget: (context, url, error) => _buildErrorWidget(context, bgColor!),
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
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
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
           (codeUnit >= 0x61 && codeUnit <= 0x7A);   // a-z
  }

  /// 构建默认图标
  ///
  /// 使用玲珑应用商店的默认应用图标
  Widget _buildDefaultIcon(BuildContext context) {
    return Icon(
      Icons.apps,
      size: size * 0.5,
      color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.3),
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
      child: Icon(
        Icons.broken_image,
        size: size * 0.4,
        color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.3),
      ),
    );
  }
}