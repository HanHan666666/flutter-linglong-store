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
