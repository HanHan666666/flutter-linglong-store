import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';

part 'network_speed_provider.g.dart';

/// 网络速度（字节/秒）
class NetworkSpeed {
  const NetworkSpeed({this.downloadBytesPerSec = 0});

  /// 下载速度（字节/秒）
  final double downloadBytesPerSec;

  /// 格式化为人类可读字符串（KB/s 或 MB/s）
  String get formatted {
    final bps = downloadBytesPerSec;
    if (bps <= 0) return '';
    if (bps < 1024) return '${bps.toStringAsFixed(0)} B/s';
    if (bps < 1024 * 1024) {
      return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}

/// 网络速度 Provider
///
/// 通过每秒读取 /proc/net/dev 计算下载速度，仅在有订阅者时运行。
/// Auto-dispose：无人订阅时自动停止轮询。
@riverpod
class NetworkSpeedNotifier extends _$NetworkSpeedNotifier {
  Timer? _timer;
  int _lastRxBytes = 0;
  DateTime? _lastReadTime;

  @override
  NetworkSpeed build() {
    // 注册销毁回调，停止 Timer
    ref.onDispose(_stopTimer);
    // 启动轮询
    _startPolling();
    return const NetworkSpeed();
  }

  void _startPolling() {
    // 先读取一次初始值
    _readNetDevBytes();
    // 每秒更新一次
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _readNetDevBytes());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 读取 /proc/net/dev 并计算下载速度
  Future<void> _readNetDevBytes() async {
    try {
      final content = await File('/proc/net/dev').readAsString();
      final rxBytes = _parseRxBytes(content);
      final now = DateTime.now();

      if (_lastReadTime != null && _lastRxBytes > 0) {
        final elapsed =
            now.difference(_lastReadTime!).inMilliseconds / 1000.0;
        if (elapsed > 0) {
          final diff = rxBytes - _lastRxBytes;
          // diff 可能为负（系统重置），忽略
          final bps = diff > 0 ? diff / elapsed : 0.0;
          state = NetworkSpeed(downloadBytesPerSec: bps);
        }
      }

      _lastRxBytes = rxBytes;
      _lastReadTime = now;
    } catch (e) {
      // /proc/net/dev 读取失败时静默忽略
      AppLogger.debug('读取网络速度失败: $e');
    }
  }

  /// 从 /proc/net/dev 内容中累加所有非 loopback 接口的 RX bytes
  int _parseRxBytes(String content) {
    var total = 0;
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      // 跳过头部两行和 loopback
      if (trimmed.startsWith('lo:') ||
          trimmed.startsWith('Inter') ||
          trimmed.startsWith('face')) {
        continue;
      }
      // 格式：  eth0: 12345 ...
      final colonIdx = trimmed.indexOf(':');
      if (colonIdx < 0) continue;
      final fields = trimmed.substring(colonIdx + 1).trim().split(RegExp(r'\s+'));
      if (fields.isNotEmpty) {
        total += int.tryParse(fields[0]) ?? 0;
      }
    }
    return total;
  }
}
