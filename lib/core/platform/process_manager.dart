import 'dart:async';
import 'dart:io';

import '../logging/app_logger.dart';
import 'cli_executor.dart';

/// 进程管理器
///
/// 提供 ll-cli 进程相关的管理功能：
/// - 查询运行中应用
/// - 终止应用进程
/// - 清理废弃服务
class ProcessManager {
  ProcessManager._();

  /// 查询运行中的应用
  ///
  /// 返回应用信息列表
  static Future<List<RunningAppInfo>> getRunningApps() async {
    try {
      final output = await CliExecutor.execute(
        ['ps'],
        timeout: kQueryTimeout,
      );

      if (!output.success) {
        AppLogger.warning('[ProcessManager] 查询运行中应用失败: ${output.stderr}');
        return [];
      }

      return _parsePsOutput(output.stdout);
    } catch (e, stack) {
      AppLogger.error('[ProcessManager] 查询运行中应用异常', e, stack);
      return [];
    }
  }

  /// 终止指定应用
  ///
  /// [appName] 应用名称
  /// [force] 是否强制终止
  static Future<bool> killApp(String appName, {bool force = false}) async {
    try {
      AppLogger.info('[ProcessManager] 终止应用: $appName (force: $force)');

      final args = ['kill', appName];
      if (force) {
        args.add('--force');
      }

      final output = await CliExecutor.execute(
        args,
        timeout: const Duration(seconds: 10),
      );

      if (output.success) {
        AppLogger.info('[ProcessManager] 应用已终止: $appName');
        return true;
      } else {
        AppLogger.warning('[ProcessManager] 终止应用失败: ${output.stderr}');
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('[ProcessManager] 终止应用异常: $appName', e, stack);
      return false;
    }
  }

  /// 清理废弃服务
  ///
  /// 删除所有未使用的应用数据和运行时
  static Future<String> prune() async {
    try {
      AppLogger.info('[ProcessManager] 开始清理废弃服务');

      final output = await CliExecutor.execute(
        ['prune'],
        timeout: const Duration(minutes: 5),
      );

      if (output.success) {
        AppLogger.info('[ProcessManager] 清理完成');
        return output.stdout;
      } else {
        AppLogger.warning('[ProcessManager] 清理失败: ${output.stderr}');
        return '清理失败: ${output.stderr}';
      }
    } catch (e, stack) {
      AppLogger.error('[ProcessManager] 清理异常', e, stack);
      return '清理异常: $e';
    }
  }

  /// 获取应用 PID
  ///
  /// [appId] 应用ID
  static Future<int?> getAppPid(String appId) async {
    final apps = await getRunningApps();
    try {
      final app = apps.firstWhere((a) => a.appId == appId);
      return app.pid;
    } catch (_) {
      return null;
    }
  }

  /// 检查应用是否正在运行
  ///
  /// [appId] 应用ID
  static Future<bool> isAppRunning(String appId) async {
    final pid = await getAppPid(appId);
    return pid != null;
  }

  /// 解析 ll-cli ps 输出
  ///
  /// 输出格式示例：
  /// ```
  /// NAME                      PID     APPID
  /// wechat                    12345   com.tencent.wechat
  /// wps-office                12346   cn.wps.wps-office
  /// ```
  static List<RunningAppInfo> _parsePsOutput(String output) {
    final List<RunningAppInfo> apps = [];
    final lines = output.split('\n');

    bool headerFound = false;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // 跳过表头
      if (!headerFound) {
        if (trimmed.contains('NAME') || trimmed.contains('PID')) {
          headerFound = true;
        }
        continue;
      }

      // 解析行数据
      // 格式: NAME PID APPID
      // 使用正则匹配，处理多空格情况
      final match = RegExp(
        r'^(\S+)\s+(\d+)\s+(\S+)',
      ).firstMatch(trimmed);

      if (match != null) {
        final name = match.group(1)!;
        final pid = int.tryParse(match.group(2)!) ?? 0;
        final appId = match.group(3)!;

        if (pid > 0 && appId.isNotEmpty) {
          apps.add(RunningAppInfo(
            appId: appId,
            name: name,
            pid: pid,
          ));
        }
      }
    }

    return apps;
  }
}

/// 运行中应用信息
class RunningAppInfo {
  const RunningAppInfo({
    required this.appId,
    required this.name,
    required this.pid,
  });

  /// 应用ID
  final String appId;

  /// 应用名称
  final String name;

  /// 进程ID
  final int pid;

  @override
  String toString() => 'RunningAppInfo(appId: $appId, name: $name, pid: $pid)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunningAppInfo &&
          runtimeType == other.runtimeType &&
          appId == other.appId &&
          pid == other.pid;

  @override
  int get hashCode => Object.hash(appId, pid);
}

/// 进程状态枚举
enum ProcessStatus {
  /// 运行中
  running,

  /// 已停止
  stopped,

  /// 僵尸进程
  zombie,

  /// 未知
  unknown,
}

/// 进程详细信息
class ProcessDetail {
  const ProcessDetail({
    required this.pid,
    required this.name,
    required this.status,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.startTime,
  });

  final int pid;
  final String name;
  final ProcessStatus status;
  final double cpuUsage;
  final double memoryUsage;
  final DateTime startTime;
}

/// 系统进程工具
class SystemProcessUtils {
  SystemProcessUtils._();

  /// 检查进程是否存在
  static Future<bool> processExists(int pid) async {
    try {
      final result = await Process.run('kill', ['-0', '$pid']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 发送信号到进程
  static Future<bool> sendSignal(int pid, ProcessSignal signal) async {
    try {
      final signalName = signal == ProcessSignal.sigterm
          ? 'TERM'
          : signal == ProcessSignal.sigkill
              ? 'KILL'
              : 'INT';

      final result = await Process.run('kill', ['-s', signalName, '$pid']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 获取进程 CPU 和内存使用
  static Future<ProcessDetail?> getProcessDetail(int pid) async {
    try {
      final result = await Process.run('ps', [
        '-p', '$pid',
        '-o', 'pid,comm,stat,%cpu,%mem,lstart',
      ]);

      if (result.exitCode != 0) return null;

      final lines = (result.stdout as String).split('\n');
      if (lines.length < 2) return null;

      final parts = lines[1].trim().split(RegExp(r'\s+'));
      if (parts.length < 6) return null;

      return ProcessDetail(
        pid: int.parse(parts[0]),
        name: parts[1],
        status: _parseStatus(parts[2]),
        cpuUsage: double.tryParse(parts[3]) ?? 0.0,
        memoryUsage: double.tryParse(parts[4]) ?? 0.0,
        startTime: DateTime.now(), // 简化处理
      );
    } catch (_) {
      return null;
    }
  }

  static ProcessStatus _parseStatus(String stat) {
    if (stat.isEmpty) return ProcessStatus.unknown;

    switch (stat[0]) {
      case 'R':
        return ProcessStatus.running;
      case 'S':
        return ProcessStatus.running; // sleeping
      case 'T':
        return ProcessStatus.stopped;
      case 'Z':
        return ProcessStatus.zombie;
      default:
        return ProcessStatus.unknown;
    }
  }
}