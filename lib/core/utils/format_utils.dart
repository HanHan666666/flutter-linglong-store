import '../i18n/l10n/app_localizations.dart';

/// 格式化工具
class FormatUtils {
  FormatUtils._();

  static const int _bytesPerKilobyte = 1024;
  static const int _bytesPerMegabyte = _bytesPerKilobyte * 1024;
  static const int _bytesPerGigabyte = _bytesPerMegabyte * 1024;

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < _bytesPerKilobyte) {
      return '$bytes B';
    } else if (bytes < _bytesPerMegabyte) {
      return '${(bytes / _bytesPerKilobyte).toStringAsFixed(1)} KB';
    } else if (bytes < _bytesPerGigabyte) {
      return '${(bytes / _bytesPerMegabyte).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / _bytesPerGigabyte).toStringAsFixed(1)} GB';
    }
  }

  /// 对齐 Rust 版本详情页：支持后端字符串字节值并统一输出人性化体积。
  static String formatFileSizeValue(Object? size) {
    if (size == null) {
      return '--';
    }

    final normalized = size is String ? size.trim() : size.toString().trim();
    if (normalized.isEmpty) {
      return '--';
    }

    final bytes = num.tryParse(normalized);
    if (bytes == null) {
      return '--';
    }

    return _formatHumanReadableFileSize(bytes.toDouble());
  }

  /// 格式化下载量
  static String formatDownloadCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 10000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else if (count < 100000000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    } else {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    }
  }

  /// 格式化速度 (bytes/s)
  static String formatSpeed(int bytesPerSecond) {
    return '${formatFileSize(bytesPerSecond)}/s';
  }

  static String _formatHumanReadableFileSize(double bytes) {
    if (bytes >= _bytesPerGigabyte) {
      return '${(bytes / _bytesPerGigabyte).toStringAsFixed(2)} GB';
    }
    if (bytes >= _bytesPerMegabyte) {
      return '${(bytes / _bytesPerMegabyte).toStringAsFixed(2)} MB';
    }
    return '${(bytes / _bytesPerKilobyte).toStringAsFixed(2)} KB';
  }
}

/// 格式化上架时间为相对时间
///
/// 规则：
/// - < 24小时：显示"X小时前上架"
/// - < 7天：显示"X天前上架"
/// - >= 7天：显示"YYYY-MM-DD上架"
String formatRelativeTime(String? createTime, AppLocalizations l10n) {
  if (createTime == null) return '';

  final parsed = DateTime.tryParse(createTime);
  if (parsed == null) return '';

  final now = DateTime.now();
  final difference = now.difference(parsed);

  if (difference.inHours < 24) {
    return l10n.uploadedXHoursAgo(difference.inHours);
  } else if (difference.inDays < 7) {
    return l10n.uploadedXDaysAgo(difference.inDays);
  } else {
    final dateStr = parsed.toIso8601String().split('T')[0];
    return l10n.uploadedOnDate(dateStr);
  }
}

/// 格式化下载量显示
///
/// 格式："下载 XXX次"（使用千位分隔符）
String formatDownloadCountText(int? count, AppLocalizations l10n) {
  if (count == null || count <= 0) return '';

  final formatted = count.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );

  return l10n.downloadedXTimes(formatted);
}
