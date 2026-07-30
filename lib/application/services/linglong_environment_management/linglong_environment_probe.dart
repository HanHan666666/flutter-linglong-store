/// 玲珑运行环境的只读系统探测。
///
/// 该文件统一翻译 `ll-cli`、`df`、`findmnt` 和 `stat` 输出，只提供事实，
/// 不生成修复方案，也不执行会改变系统状态的命令。
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../../core/platform/shell_command_executor.dart';
import '../../../domain/models/linglong_environment_management.dart';
import 'linglong_management_command_workspace.dart';

/// 指定路径所在文件系统的容量快照。
///
/// 该模型用于保存位置迁移的空间校验，不向 Presentation 暴露命令输出格式。
class LinglongFilesystemInfo {
  /// 创建文件系统容量快照。
  const LinglongFilesystemInfo({
    this.filesystem,
    this.capacityBytes,
    this.usedBytes,
    this.availableBytes,
    this.usagePercent,
    this.mountedOn,
  });

  /// 文件系统设备或来源名称。
  final String? filesystem;

  /// 文件系统总容量。
  final int? capacityBytes;

  /// 文件系统已使用容量。
  final int? usedBytes;

  /// 文件系统可用容量。
  final int? availableBytes;

  /// 文件系统使用率。
  final int? usagePercent;

  /// 文件系统挂载点。
  final String? mountedOn;
}

/// 汇总玲珑环境管理需要的只读系统事实。
class LinglongEnvironmentProbe {
  /// 创建只读探测器。
  LinglongEnvironmentProbe({
    required ShellCommandExecutor executor,
    required LinglongManagementCommandWorkspace workspace,
    required this.rootPath,
    this.serviceUser = 'deepin-linglong',
    this.serviceGroup = 'deepin-linglong',
  }) : _executor = executor,
       _workspace = workspace;

  final ShellCommandExecutor _executor;
  final LinglongManagementCommandWorkspace _workspace;

  /// 玲珑本地数据根目录。
  final String rootPath;

  /// `ll-package-manager` 的运行用户。
  final String serviceUser;

  /// `ll-package-manager` 的运行用户组。
  final String serviceGroup;

  static const List<String> _permissionCheckRelativePaths = [
    '',
    '.version',
    'config.yaml',
    'states.json',
    'repo',
    'layers',
    'entries',
    'merged',
  ];

  /// 读取当前运行中的玲珑应用数量。
  ///
  /// 旧版 linyaps 输出形态存在差异，因此保留 JSON 对象和文本表格兼容读取；
  /// 探测失败按零处理，后续特权迁移脚本仍会再次阻断运行中的应用。
  Future<int> loadRunningAppCount() async {
    final result = await _runSafely(['ll-cli', '--json', 'ps']);
    if (result == null || !result.success) {
      return 0;
    }

    final stdout = result.stdout.trim();
    if (stdout.isEmpty) {
      return 0;
    }

    try {
      final decoded = jsonDecode(stdout);
      if (decoded is List<dynamic>) {
        return decoded.length;
      }
      if (decoded is Map<String, dynamic>) {
        final apps = decoded['apps'] ?? decoded['processes'] ?? decoded['data'];
        if (apps is List<dynamic>) {
          return apps.length;
        }
      }
    } catch (_) {
      // 兼容旧版非 JSON 输出，继续按文本表格统计。
    }

    return const LineSplitter()
        .convert(stdout)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) {
          final lowerLine = line.toLowerCase();
          return !lowerLine.contains('container') && !lowerLine.contains('pid');
        })
        .length;
  }

  /// 读取玲珑根目录的文件系统和挂载状态。
  Future<LinglongStorageInfo> loadStorageInfo() async {
    final dfResult = await _runSafely(['df', '-PB1', rootPath]);
    final mountResult = await _runSafely(['findmnt', '--json', rootPath]);
    final parsedDf = _parseDfOutput(dfResult?.stdout);
    final parsedMount = _parseFindmntOutput(mountResult?.stdout);

    return LinglongStorageInfo(
      rootPath: rootPath,
      filesystem: parsedDf.filesystem,
      mountedOn: parsedDf.mountedOn ?? parsedMount.target,
      mountSource: parsedMount.source,
      capacityBytes: parsedDf.capacityBytes,
      usedBytes: parsedDf.usedBytes,
      availableBytes: parsedDf.availableBytes,
      usagePercent: parsedDf.usagePercent,
      isMounted: parsedMount.target != null,
      isBindMounted: parsedMount.isBindMounted,
    );
  }

  /// 读取指定路径所在文件系统的容量信息。
  Future<LinglongFilesystemInfo?> loadFilesystemInfo(String probePath) async {
    final result = await _runSafely(['df', '-PB1', probePath]);
    if (result == null || !result.success) {
      return null;
    }
    return _parseDfOutput(result.stdout);
  }

  /// 检查玲珑关键数据路径的属主和 owner 写权限。
  Future<LinglongDataPermissionCheckResult> checkDataPermissions() async {
    final statPaths = _permissionCheckRelativePaths
        .map(
          (relativePath) => relativePath.isEmpty
              ? rootPath
              : path.join(rootPath, relativePath),
        )
        .toList(growable: false);
    final result = await _runSafely([
      'stat',
      '-c',
      '%U:%G:%a:%n',
      ...statPaths,
    ], timeout: const Duration(minutes: 1));

    if (result == null) {
      return const LinglongDataPermissionCheckResult(
        isAvailable: false,
        isOk: false,
        detail: '无法读取玲珑数据目录权限信息',
      );
    }

    if (!result.success) {
      return LinglongDataPermissionCheckResult(
        isAvailable: false,
        isOk: false,
        detail: _workspace.truncateOutput(
          _workspace.combinedCommandOutput(result),
        ),
      );
    }

    final abnormalEntries = _parsePermissionEntries(result.stdout)
        .where((entry) {
          final expectedOwner =
              entry.owner == serviceUser && entry.group == serviceGroup;
          return !expectedOwner || !entry.ownerCanWrite;
        })
        .toList(growable: false);

    if (abnormalEntries.isEmpty) {
      return const LinglongDataPermissionCheckResult(
        isAvailable: true,
        isOk: true,
      );
    }

    final detail = abnormalEntries
        .map(
          (entry) =>
              '${entry.path} 当前 ${entry.owner}:${entry.group} mode=${entry.mode}，'
              '期望 $serviceUser:$serviceGroup 且 owner 可写',
        )
        .join('\n');

    return LinglongDataPermissionCheckResult(
      isAvailable: true,
      isOk: false,
      detail: _workspace.truncateOutput(detail),
    );
  }

  /// 通过 linyaps 运行路径检查本地数据是否可读。
  ///
  /// 默认健康检查不执行底层完整性审计，避免把合法的 partial pull 误判为损坏。
  Future<LinglongOstreeCheckResult> checkLocalDataAccess() async {
    final listResult = await _runSafely([
      'll-cli',
      '--json',
      'list',
    ], timeout: const Duration(minutes: 2));

    if (listResult == null) {
      return const LinglongOstreeCheckResult(
        isAvailable: false,
        isOk: false,
        detail: 'll-cli list 命令执行失败',
      );
    }

    if (!listResult.success) {
      return LinglongOstreeCheckResult(
        isAvailable: true,
        isOk: false,
        detail: _workspace.truncateOutput(
          _workspace.combinedCommandOutput(listResult),
        ),
      );
    }

    return const LinglongOstreeCheckResult(isAvailable: true, isOk: true);
  }

  /// 向上寻找最近存在的目录，供尚未创建的迁移目标检查文件系统容量。
  Future<String> nearestExistingPath(String targetPath) async {
    var probe = Directory(targetPath);
    while (!await probe.exists()) {
      final parent = probe.parent;
      if (parent.path == probe.path) {
        return parent.path;
      }
      probe = parent;
    }
    return probe.path;
  }

  /// 执行只读探测命令，并把命令不可用或启动失败转换为缺失结果。
  Future<ShellCommandResult?> _runSafely(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    try {
      return await _executor.run(
        command,
        timeout: timeout,
        environment:
            LinglongManagementCommandWorkspace.englishLocaleEnvironment,
      );
    } catch (_) {
      return null;
    }
  }

  /// 解析 `df -PB1` 的稳定字节单位输出。
  LinglongFilesystemInfo _parseDfOutput(String? output) {
    if (output == null || output.trim().isEmpty) {
      return const LinglongFilesystemInfo();
    }

    final lines = const LineSplitter()
        .convert(output)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length < 2) {
      return const LinglongFilesystemInfo();
    }

    final columns = lines[1].split(RegExp(r'\s+'));
    if (columns.length < 5) {
      return const LinglongFilesystemInfo();
    }

    return LinglongFilesystemInfo(
      filesystem: columns[0],
      capacityBytes: int.tryParse(columns[1]),
      usedBytes: int.tryParse(columns[2]),
      availableBytes: int.tryParse(columns[3]),
      usagePercent: int.tryParse(columns[4].replaceAll('%', '')),
      mountedOn: columns.length > 5 ? columns.sublist(5).join(' ') : null,
    );
  }

  /// 解析 `findmnt --json` 的首个目标挂载记录。
  _LinglongMountInfo _parseFindmntOutput(String? output) {
    if (output == null || output.trim().isEmpty) {
      return const _LinglongMountInfo();
    }

    try {
      final decoded = jsonDecode(output);
      if (decoded is! Map<String, dynamic>) {
        return const _LinglongMountInfo();
      }
      final filesystems = decoded['filesystems'];
      if (filesystems is! List<dynamic> || filesystems.isEmpty) {
        return const _LinglongMountInfo();
      }
      final item = filesystems.first;
      if (item is! Map<String, dynamic>) {
        return const _LinglongMountInfo();
      }
      final options = item['options']?.toString() ?? '';
      return _LinglongMountInfo(
        target: item['target']?.toString(),
        source: item['source']?.toString(),
        isBindMounted: options.split(',').contains('bind'),
      );
    } catch (_) {
      return const _LinglongMountInfo();
    }
  }

  /// 解析 `stat -c %U:%G:%a:%n` 输出并保留路径中的冒号。
  List<_LinglongPermissionEntry> _parsePermissionEntries(String output) {
    return const LineSplitter()
        .convert(output)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final parts = line.split(':');
          if (parts.length < 4) {
            return null;
          }
          return _LinglongPermissionEntry(
            owner: parts[0],
            group: parts[1],
            mode: parts[2],
            path: parts.sublist(3).join(':'),
          );
        })
        .nonNulls
        .toList(growable: false);
  }
}

class _LinglongMountInfo {
  const _LinglongMountInfo({
    this.target,
    this.source,
    this.isBindMounted = false,
  });

  final String? target;
  final String? source;
  final bool isBindMounted;
}

class _LinglongPermissionEntry {
  const _LinglongPermissionEntry({
    required this.owner,
    required this.group,
    required this.mode,
    required this.path,
  });

  final String owner;
  final String group;
  final String mode;
  final String path;

  /// 判断属主是否具备写权限。
  ///
  /// `stat %a` 可能输出 `755` 或带特殊位的 `2755`，这里只取最后三位中的 owner 位。
  bool get ownerCanWrite {
    final normalizedMode = mode.length > 3
        ? mode.substring(mode.length - 3)
        : mode;
    if (normalizedMode.isEmpty) {
      return false;
    }
    final ownerDigit = int.tryParse(normalizedMode.substring(0, 1));
    if (ownerDigit == null) {
      return false;
    }
    return (ownerDigit & 2) == 2;
  }
}
