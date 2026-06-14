import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../core/platform/shell_command_executor.dart';
import '../../core/storage/app_xdg_paths.dart';
import '../../domain/models/linglong_env_check_result.dart';
import '../../domain/models/linglong_environment_management.dart';
import 'linglong_environment_service.dart';

typedef ManagementClock = DateTime Function();

class LinglongEnvironmentManagementService {
  LinglongEnvironmentManagementService({
    required ShellCommandExecutor executor,
    required LinglongEnvironmentService environmentService,
    ManagementClock? clock,
    String linglongRootPath = '/var/lib/linglong',
    String? logDirectoryPath,
  }) : _executor = executor,
       _environmentService = environmentService,
       _clock = clock ?? DateTime.now,
       _linglongRootPath = linglongRootPath,
       _logDirectoryPath = logDirectoryPath;

  final ShellCommandExecutor _executor;
  final LinglongEnvironmentService _environmentService;
  final ManagementClock _clock;
  final String _linglongRootPath;
  final String? _logDirectoryPath;

  static const Map<String, String> _englishLocaleEnv = {
    'LC_ALL': 'C.UTF-8',
    'LANG': 'C.UTF-8',
    'LANGUAGE': 'C.UTF-8',
    'LC_MESSAGES': 'C.UTF-8',
  };

  Future<LinglongEnvironmentAnalysis> analyzeEnvironment() async {
    final envResult = await _environmentService.checkEnvironment();
    final runningAppCount = await _loadRunningAppCount();
    final storage = await _loadStorageInfo();
    final ostree = await _checkOstreeRepository();
    final issues = _buildIssues(
      envResult: envResult,
      storage: storage,
      ostree: ostree,
      runningAppCount: runningAppCount,
    );

    return LinglongEnvironmentAnalysis(
      envResult: envResult,
      storage: storage,
      ostree: ostree,
      issues: issues,
      runningAppCount: runningAppCount,
      analyzedAt: _clock(),
    );
  }

  Future<LinglongEnvironmentRepairResult> repairOstreeRepository({
    String? logFilePath,
  }) async {
    final resolvedLogFilePath =
        logFilePath ?? await _createLogFilePath('linglong-ostree-repair');
    final result = await _executor.run(
      [
        'pkexec',
        'ostree',
        'fsck',
        '--repo=$_linglongRootPath/repo',
        '--all',
        '--delete',
      ],
      timeout: const Duration(minutes: 20),
      environment: _englishLocaleEnv,
      logOptions: ShellCommandLogOptions(
        filePath: resolvedLogFilePath,
        overwrite: true,
      ),
    );

    return LinglongEnvironmentRepairResult(
      action: LinglongEnvironmentRepairAction.ostreeFsckDelete,
      success: result.success,
      message: result.success ? 'OSTree 仓库完整性修复已执行' : 'OSTree 仓库完整性修复失败',
      logFilePath: resolvedLogFilePath,
      output: _truncateOutput(_primaryOutput(result)),
    );
  }

  Future<LinglongEnvironmentRepairResult> moveLinglongStorage(
    String targetPath, {
    String? logFilePath,
  }) async {
    final runningAppCount = await _loadRunningAppCount();
    if (runningAppCount > 0) {
      return LinglongEnvironmentRepairResult(
        action: LinglongEnvironmentRepairAction.moveStorageRoot,
        success: false,
        message: '仍有 $runningAppCount 个玲珑应用正在运行，请关闭后再移动保存位置',
      );
    }

    final script = buildStorageMigrationScript(targetPath);
    final scriptFile = await _writeTemporaryScript(script);
    final resolvedLogFilePath =
        logFilePath ?? await _createLogFilePath('linglong-storage-move');

    try {
      final result = await _executor.run(
        ['pkexec', 'bash', scriptFile.path],
        timeout: const Duration(hours: 2),
        environment: _englishLocaleEnv,
        logOptions: ShellCommandLogOptions(
          filePath: resolvedLogFilePath,
          overwrite: true,
        ),
      );

      return LinglongEnvironmentRepairResult(
        action: LinglongEnvironmentRepairAction.moveStorageRoot,
        success: result.success,
        message: result.success ? '玲珑保存位置已移动' : '移动玲珑保存位置失败',
        logFilePath: resolvedLogFilePath,
        output: _truncateOutput(_primaryOutput(result)),
      );
    } finally {
      await _deleteFileIfExists(scriptFile);
    }
  }

  String buildStorageMigrationScript(String targetPath) {
    final normalizedTargetPath = _normalizeStorageTargetPath(targetPath);

    // 玲珑当前不支持自定义安装目录；这里按 linyaps#1411 的维护者建议，
    // 通过 systemd mount unit 把新目录 bind 到 /var/lib/linglong。
    return '''
#!/usr/bin/env bash
set -euo pipefail

SRC=${_shellSingleQuote(_linglongRootPath)}
DST=${_shellSingleQuote(normalizedTargetPath)}
UNIT=/etc/systemd/system/var-lib-linglong.mount

if ll-cli --json ps 2>/dev/null | grep -q '"pid"'; then
  echo "仍有玲珑应用正在运行，请关闭后重试。" >&2
  exit 2
fi

mkdir -p "\$SRC" "\$DST"

if command -v rsync >/dev/null 2>&1; then
  rsync -aHAX --numeric-ids "\$SRC"/ "\$DST"/
else
  cp -a "\$SRC"/. "\$DST"/
fi

chown --reference="\$SRC" "\$DST" 2>/dev/null || true
chmod --reference="\$SRC" "\$DST" 2>/dev/null || true

cat > "\$UNIT" <<'EOF'
[Unit]
Description=Bind for linglong root dir
After=local-fs.target

[Mount]
What=$normalizedTargetPath
Where=$_linglongRootPath
Type=none
Options=bind

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now var-lib-linglong.mount
findmnt ${_shellSingleQuote(_linglongRootPath)}
''';
  }

  List<LinglongEnvironmentIssue> _buildIssues({
    required LinglongEnvCheckResult envResult,
    required LinglongStorageInfo storage,
    required LinglongOstreeCheckResult ostree,
    required int runningAppCount,
  }) {
    final issues = <LinglongEnvironmentIssue>[];

    if (envResult.llCliVersion == null) {
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.llCliUnavailable,
          severity: LinglongEnvironmentIssueSeverity.error,
          title: 'll-cli 不可用',
          description: envResult.errorMessage ?? '未检测到可用的玲珑命令行环境',
          rawDetail: envResult.errorDetail,
        ),
      );
    } else if (envResult.repoStatus == RepoStatus.notConfigured ||
        envResult.repos.isEmpty) {
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.repositoryNotConfigured,
          severity: LinglongEnvironmentIssueSeverity.error,
          title: '未配置玲珑仓库',
          description: '当前没有可用的玲珑仓库配置，需要先添加或修复仓库。',
          repairAction: LinglongEnvironmentRepairAction.refreshRepositoryConfig,
          rawDetail: envResult.errorDetail,
        ),
      );
    }

    if (!ostree.isAvailable) {
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.ostreeToolUnavailable,
          severity: LinglongEnvironmentIssueSeverity.warning,
          title: 'OSTree 工具不可用',
          description: '无法执行 OSTree 仓库完整性检查，请确认 ostree 命令已安装。',
          rawDetail: ostree.detail,
        ),
      );
    } else if (!ostree.isOk) {
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.ostreeRepositoryCorrupted,
          severity: LinglongEnvironmentIssueSeverity.error,
          title: 'OSTree 仓库完整性异常',
          description: '检测到玲珑本地 OSTree 仓库可能存在损坏对象，可执行修复后重试安装或更新。',
          repairAction: LinglongEnvironmentRepairAction.ostreeFsckDelete,
          rawDetail: ostree.detail,
        ),
      );
    }

    if (storage.isNearlyFull) {
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.storageNearlyFull,
          severity: (storage.usagePercent ?? 0) >= 95
              ? LinglongEnvironmentIssueSeverity.error
              : LinglongEnvironmentIssueSeverity.warning,
          title: '玲珑保存位置空间不足',
          description:
              '当前 $_linglongRootPath 所在文件系统使用率约 ${storage.usagePercent}%，建议清理或移动保存位置。',
          repairAction: LinglongEnvironmentRepairAction.moveStorageRoot,
        ),
      );
    }

    if (runningAppCount > 0) {
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.runningAppsBlockStorageMove,
          severity: LinglongEnvironmentIssueSeverity.warning,
          title: '有玲珑应用正在运行',
          description: '当前仍有 $runningAppCount 个玲珑应用正在运行，移动保存位置前必须先关闭。',
        ),
      );
    }

    return issues;
  }

  Future<int> _loadRunningAppCount() async {
    final result = await _run(['ll-cli', '--json', 'ps']);
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
      // Fall back to text table parsing below.
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

  Future<LinglongStorageInfo> _loadStorageInfo() async {
    final dfResult = await _run(['df', '-PB1', _linglongRootPath]);
    final mountResult = await _run(['findmnt', '--json', _linglongRootPath]);
    final parsedDf = _parseDfOutput(dfResult?.stdout);
    final parsedMount = _parseFindmntOutput(mountResult?.stdout);

    return LinglongStorageInfo(
      rootPath: _linglongRootPath,
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

  Future<LinglongOstreeCheckResult> _checkOstreeRepository() async {
    final result = await _run([
      'ostree',
      'fsck',
      '--repo=$_linglongRootPath/repo',
      '--quiet',
    ], timeout: const Duration(minutes: 2));

    if (result == null) {
      return const LinglongOstreeCheckResult(
        isAvailable: false,
        isOk: false,
        detail: 'ostree 命令执行失败',
      );
    }

    if (result.exitCode == 127) {
      return LinglongOstreeCheckResult(
        isAvailable: false,
        isOk: false,
        detail: _truncateOutput(_primaryOutput(result)),
      );
    }

    return LinglongOstreeCheckResult(
      isAvailable: true,
      isOk: result.success,
      detail: result.success ? null : _truncateOutput(_primaryOutput(result)),
    );
  }

  _DfInfo _parseDfOutput(String? output) {
    if (output == null || output.trim().isEmpty) {
      return const _DfInfo();
    }

    final lines = const LineSplitter()
        .convert(output)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length < 2) {
      return const _DfInfo();
    }

    final columns = lines[1].split(RegExp(r'\s+'));
    if (columns.length < 5) {
      return const _DfInfo();
    }

    return _DfInfo(
      filesystem: columns[0],
      capacityBytes: int.tryParse(columns[1]),
      usedBytes: int.tryParse(columns[2]),
      availableBytes: int.tryParse(columns[3]),
      usagePercent: int.tryParse(columns[4].replaceAll('%', '')),
      mountedOn: columns.length > 5 ? columns.sublist(5).join(' ') : null,
    );
  }

  _FindmntInfo _parseFindmntOutput(String? output) {
    if (output == null || output.trim().isEmpty) {
      return const _FindmntInfo();
    }

    try {
      final decoded = jsonDecode(output);
      if (decoded is! Map<String, dynamic>) {
        return const _FindmntInfo();
      }
      final filesystems = decoded['filesystems'];
      if (filesystems is! List<dynamic> || filesystems.isEmpty) {
        return const _FindmntInfo();
      }
      final item = filesystems.first;
      if (item is! Map<String, dynamic>) {
        return const _FindmntInfo();
      }
      final options = item['options']?.toString() ?? '';
      return _FindmntInfo(
        target: item['target']?.toString(),
        source: item['source']?.toString(),
        isBindMounted: options.split(',').contains('bind'),
      );
    } catch (_) {
      return const _FindmntInfo();
    }
  }

  Future<ShellCommandResult?> _run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    try {
      return await _executor.run(
        command,
        timeout: timeout,
        environment: _englishLocaleEnv,
      );
    } catch (_) {
      return null;
    }
  }

  String _normalizeStorageTargetPath(String targetPath) {
    final trimmed = targetPath.trim();
    if (trimmed.isEmpty || !path.isAbsolute(trimmed)) {
      throw ArgumentError.value(targetPath, 'targetPath', '必须是绝对路径');
    }
    if (trimmed == _linglongRootPath) {
      throw ArgumentError.value(targetPath, 'targetPath', '不能与当前玲珑目录相同');
    }
    if (trimmed.contains('\n') || trimmed.contains('\r')) {
      throw ArgumentError.value(targetPath, 'targetPath', '路径不能包含换行符');
    }
    return path.normalize(trimmed);
  }

  Future<File> _writeTemporaryScript(String script) async {
    final file = File(
      path.join(
        Directory.systemTemp.path,
        'linglong-storage-move-${_clock().millisecondsSinceEpoch}.sh',
      ),
    );
    await file.writeAsString(script, flush: true);
    return file;
  }

  Future<void> _deleteFileIfExists(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 临时脚本删除失败不影响主修复结果，日志中已有执行命令。
    }
  }

  Future<String> _createLogFilePath(String prefix) async {
    final directoryPath =
        _logDirectoryPath ??
        AppXdgPaths.resolveLogsDirectoryPath() ??
        path.join(Directory.systemTemp.path, 'linglong-store', 'logs');
    final directory = Directory(directoryPath);
    await directory.create(recursive: true);
    final now = _clock();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return path.join(directory.path, '$prefix-$timestamp.log');
  }

  String _primaryOutput(ShellCommandResult result) {
    final primary = result.primaryMessage;
    if (primary.isNotEmpty) {
      return primary;
    }
    return result.stdout.trim();
  }

  String _truncateOutput(String output, {int maxLength = 4000}) {
    if (output.length <= maxLength) {
      return output;
    }
    return '${output.substring(0, maxLength)}\n... 输出已截断，请查看完整日志。';
  }

  String _shellSingleQuote(String value) {
    return "'${value.replaceAll("'", "'\"'\"'")}'";
  }
}

class _DfInfo {
  const _DfInfo({
    this.filesystem,
    this.capacityBytes,
    this.usedBytes,
    this.availableBytes,
    this.usagePercent,
    this.mountedOn,
  });

  final String? filesystem;
  final int? capacityBytes;
  final int? usedBytes;
  final int? availableBytes;
  final int? usagePercent;
  final String? mountedOn;
}

class _FindmntInfo {
  const _FindmntInfo({this.target, this.source, this.isBindMounted = false});

  final String? target;
  final String? source;
  final bool isBindMounted;
}
