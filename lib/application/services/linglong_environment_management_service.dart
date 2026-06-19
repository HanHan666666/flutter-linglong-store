/// 玲珑运行期环境管理应用服务。
///
/// 该文件集中承载设置页「玲珑环境管理」所需的环境分析、OSTree 修复和保存位置迁移编排。
/// 这些能力都涉及系统命令、管理员权限或磁盘状态，必须收敛在服务层，避免页面层直接拼接命令导致行为漂移。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as path;

import '../../core/platform/shell_command_executor.dart';
import '../../core/storage/app_xdg_paths.dart';
import '../../domain/models/linglong_env_check_result.dart';
import '../../domain/models/linglong_environment_management.dart';
import 'linglong_environment_service.dart';

typedef ManagementClock = DateTime Function();

/// 玲珑环境管理服务。
///
/// 负责把底层 shell/Rust 能力整理为 UI 可消费的诊断结果和修复结果。
/// 所有会改变系统状态的动作都必须由上层显式确认后再调用这里的方法。
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

  /// 执行 OSTree 仓库修复。
  ///
  /// 新版 OSTree 在 `--delete` 删除损坏对象后，可能因为 affected commit 被标记为 partial
  /// 而返回非零码；这类结果代表自动清理步骤已经完成，后续需要重新拉取受影响内容。
  /// 旧版 OSTree 可能不支持 `--all`，此处会降级到仅带 `--delete` 的修复命令。
  Future<LinglongEnvironmentRepairResult> repairOstreeRepository({
    String? logFilePath,
  }) async {
    final resolvedLogFilePath =
        logFilePath ?? await _createLogFilePath('linglong-ostree-repair');

    final primaryResult = await _runOstreeRepairCommand(
      includeAllObjects: true,
      logFilePath: resolvedLogFilePath,
      overwriteLog: true,
    );

    if (_isUnsupportedOstreeOption(primaryResult, '--all')) {
      final fallbackResult = await _runOstreeRepairCommand(
        includeAllObjects: false,
        logFilePath: resolvedLogFilePath,
        overwriteLog: false,
      );
      return _buildOstreeRepairResult(
        result: fallbackResult,
        logFilePath: resolvedLogFilePath,
        outputResults: [primaryResult, fallbackResult],
        usedLegacyFallback: true,
      );
    }

    return _buildOstreeRepairResult(
      result: primaryResult,
      logFilePath: resolvedLogFilePath,
      outputResults: [primaryResult],
    );
  }

  Future<LinglongEnvironmentRepairResult> moveLinglongStorage(
    String targetPath, {
    String? logFilePath,
  }) async {
    final normalizedTargetPath = _normalizeStorageTargetPath(targetPath);
    final runningAppCount = await _loadRunningAppCount();
    if (runningAppCount > 0) {
      return LinglongEnvironmentRepairResult(
        action: LinglongEnvironmentRepairAction.moveStorageRoot,
        success: false,
        message: '仍有 $runningAppCount 个玲珑应用正在运行，请关闭后再移动保存位置',
      );
    }

    final validationError = await _validateStorageMovePreconditions(
      normalizedTargetPath,
    );
    if (validationError != null) {
      return LinglongEnvironmentRepairResult(
        action: LinglongEnvironmentRepairAction.moveStorageRoot,
        success: false,
        message: validationError,
      );
    }

    final script = buildStorageMigrationScript(normalizedTargetPath);
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
BACKUP="\${SRC}.backup-\$(date +%Y%m%d-%H%M%S)"

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

if [ ! -d "\$DST/repo" ] || [ ! -f "\$DST/repo/config" ]; then
  echo "目标目录缺少 repo/config，复制校验失败。" >&2
  exit 3
fi

chown --reference="\$SRC" "\$DST" 2>/dev/null || true
chmod --reference="\$SRC" "\$DST" 2>/dev/null || true

restore_backup() {
  if findmnt "\$SRC" >/dev/null 2>&1; then
    return
  fi
  rmdir "\$SRC" 2>/dev/null || true
  if [ -d "\$BACKUP" ] && [ ! -e "\$SRC" ]; then
    mv "\$BACKUP" "\$SRC"
  fi
}
trap restore_backup ERR

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

mv "\$SRC" "\$BACKUP"
mkdir -p "\$SRC"

systemctl daemon-reload
systemctl enable --now var-lib-linglong.mount
findmnt "\$SRC"

if command -v ostree >/dev/null 2>&1; then
  ostree fsck --repo="\$SRC/repo" --quiet
fi

trap - ERR
echo "旧目录备份：\$BACKUP"
''';
  }

  Future<String?> _validateStorageMovePreconditions(
    String normalizedTargetPath,
  ) async {
    final storage = await _loadStorageInfo();
    if (storage.isBindMounted) {
      return '$_linglongRootPath 当前已经是 bind mount，请先确认现有挂载配置后再迁移。';
    }

    final targetProbePath = await _nearestExistingPath(normalizedTargetPath);
    final targetDfResult = await _run(['df', '-PB1', targetProbePath]);
    if (targetDfResult == null || !targetDfResult.success) {
      return '无法读取目标路径所在文件系统空间：$targetProbePath';
    }

    final targetInfo = _parseDfOutput(targetDfResult.stdout);
    final sourceUsedBytes = storage.usedBytes;
    final targetAvailableBytes = targetInfo.availableBytes;
    if (sourceUsedBytes == null || targetAvailableBytes == null) {
      return '无法确认当前目录或目标路径的磁盘空间，请检查后重试。';
    }

    final safetyMarginBytes = math.max(
      512 * 1024 * 1024,
      (sourceUsedBytes * 0.1).round(),
    );
    final requiredBytes = sourceUsedBytes + safetyMarginBytes;
    if (targetAvailableBytes < requiredBytes) {
      return '目标路径可用空间不足，需要至少 ${_formatBytes(requiredBytes)}，'
          '当前可用 ${_formatBytes(targetAvailableBytes)}。';
    }

    return null;
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
          title: 'OSTree 仓库不可用',
          description: '无法读取玲珑本地 OSTree 仓库 refs，可尝试执行修复；若目录缺失或权限异常，请先恢复仓库路径。',
          repairAction: LinglongEnvironmentRepairAction.ostreeFsckDelete,
          rawDetail: ostree.detail,
        ),
      );
    } else if (ostree.hasIntegrityWarning) {
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.ostreeRepositoryCorrupted,
          severity: LinglongEnvironmentIssueSeverity.warning,
          title: 'OSTree 对象完整性风险',
          description:
              '深度校验发现对象存储存在损坏记录，但当前玲珑仓库仍可读取。建议在空闲时执行修复，并重新安装或更新受影响应用/基础环境。',
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
    // linyaps 启动和运行时主要依赖仓库能被打开并读取 refs/cache。
    // 因此先执行轻量只读检查，避免把深度 fsck 的对象风险误判为整体不可用。
    final refsResult = await _run([
      'ostree',
      'refs',
      '--repo=$_linglongRootPath/repo',
    ], timeout: const Duration(minutes: 2));

    if (refsResult == null) {
      return const LinglongOstreeCheckResult(
        isAvailable: false,
        isOk: false,
        detail: 'ostree refs 命令执行失败',
      );
    }

    if (refsResult.exitCode == 127) {
      return LinglongOstreeCheckResult(
        isAvailable: false,
        isOk: false,
        detail: _truncateOutput(_primaryOutput(refsResult)),
      );
    }

    if (!refsResult.success) {
      return LinglongOstreeCheckResult(
        isAvailable: true,
        isOk: false,
        detail: _truncateOutput(_primaryOutput(refsResult)),
      );
    }

    // fsck 作为深度对象审计保留；它发现风险时只影响完整性提示，
    // 不覆盖上面的 linyaps 可用性判断。
    final fsckResult = await _run([
      'ostree',
      'fsck',
      '--repo=$_linglongRootPath/repo',
      '--quiet',
    ], timeout: const Duration(minutes: 2));

    if (fsckResult == null) {
      return const LinglongOstreeCheckResult(
        isAvailable: false,
        isOk: false,
        detail: 'ostree fsck 命令执行失败',
      );
    }

    if (fsckResult.exitCode == 127) {
      return LinglongOstreeCheckResult(
        isAvailable: false,
        isOk: false,
        detail: _truncateOutput(_primaryOutput(fsckResult)),
      );
    }

    return LinglongOstreeCheckResult(
      isAvailable: true,
      isOk: true,
      hasIntegrityWarning: !fsckResult.success,
      detail: fsckResult.success
          ? null
          : _truncateOutput(_combinedCommandOutput(fsckResult)),
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
    if (trimmed.contains('\n') || trimmed.contains('\r')) {
      throw ArgumentError.value(targetPath, 'targetPath', '路径不能包含换行符');
    }
    final normalized = path.normalize(trimmed);
    final currentRoot = path.normalize(_linglongRootPath);
    const blockedTargets = {'/', '/var', '/var/lib'};
    if (blockedTargets.contains(normalized) || normalized == currentRoot) {
      throw ArgumentError.value(
        targetPath,
        'targetPath',
        '目标路径不能是系统根目录或当前玲珑目录',
      );
    }
    if (path.isWithin(currentRoot, normalized)) {
      throw ArgumentError.value(targetPath, 'targetPath', '目标路径不能位于当前玲珑目录内部');
    }
    return normalized;
  }

  Future<String> _nearestExistingPath(String targetPath) async {
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

  /// 按当前 OSTree 版本能力执行一次修复命令。
  ///
  /// `includeAllObjects` 只控制是否携带 `--all`，`--delete` 是修复语义必须项；
  /// 如果目标 OSTree 不支持 `--delete`，调用方会返回明确失败而不是退化成只检查。
  Future<ShellCommandResult> _runOstreeRepairCommand({
    required bool includeAllObjects,
    required String logFilePath,
    required bool overwriteLog,
  }) {
    final command = [
      'pkexec',
      'ostree',
      'fsck',
      '--repo=$_linglongRootPath/repo',
      if (includeAllObjects) '--all',
      '--delete',
    ];

    return _executor.run(
      command,
      timeout: const Duration(minutes: 20),
      environment: _englishLocaleEnv,
      logOptions: ShellCommandLogOptions(
        filePath: logFilePath,
        overwrite: overwriteLog,
      ),
    );
  }

  /// 将 OSTree 修复命令结果归类为 UI 可理解的业务状态。
  ///
  /// 这里刻意不只看退出码：新版 OSTree 会在删除损坏对象后返回 partial commit 错误，
  /// 这种状态需要提示用户重新拉取受影响内容；旧版缺少参数则需要给出可操作的版本兼容信息。
  LinglongEnvironmentRepairResult _buildOstreeRepairResult({
    required ShellCommandResult result,
    required String logFilePath,
    required List<ShellCommandResult> outputResults,
    bool usedLegacyFallback = false,
  }) {
    final output = _truncateOutput(_combinedPrimaryOutput(outputResults));
    const action = LinglongEnvironmentRepairAction.ostreeFsckDelete;

    if (_isUnsupportedOstreeOption(result, '--delete')) {
      return LinglongEnvironmentRepairResult(
        action: action,
        success: false,
        message: '当前 OSTree 版本不支持 --delete，无法自动删除损坏对象，请升级 ostree 或使用发行版工具手动修复。',
        logFilePath: logFilePath,
        output: output,
      );
    }

    if (_isFsckDetectedPartialCommitState(result)) {
      final count = _extractPartialCommitCount(result);
      final countText = count == null ? '部分' : '$count 个';
      final legacySuffix = usedLegacyFallback ? '（已兼容旧版 OSTree 参数）' : '';
      return LinglongEnvironmentRepairResult(
        action: action,
        success: true,
        message:
            'OSTree 已删除可自动清理的损坏对象，但仍有 $countText partial commits 需要重新拉取。'
            '请重新安装或更新受影响应用/基础环境后再次执行环境分析$legacySuffix。',
        logFilePath: logFilePath,
        output: output,
      );
    }

    final successMessage = usedLegacyFallback
        ? 'OSTree 仓库完整性修复已执行（已兼容旧版 OSTree）'
        : 'OSTree 仓库完整性修复已执行';
    return LinglongEnvironmentRepairResult(
      action: action,
      success: result.success,
      message: result.success ? successMessage : 'OSTree 仓库完整性修复失败',
      logFilePath: logFilePath,
      output: output,
    );
  }

  /// 判断 OSTree 输出是否表示当前版本不支持指定参数。
  ///
  /// 不同发行版会使用 `unknown option`、`unrecognized option` 或 `invalid option`
  /// 等不同措辞，因此匹配时同时要求出现参数名，避免误判普通错误。
  bool _isUnsupportedOstreeOption(ShellCommandResult result, String option) {
    final output = _combinedCommandOutput(result).toLowerCase();
    final normalizedOption = option.toLowerCase();
    if (!output.contains(normalizedOption)) {
      return false;
    }
    return output.contains('unknown option') ||
        output.contains('unrecognized option') ||
        output.contains('invalid option') ||
        output.contains('no such option') ||
        output.contains('unsupported option');
  }

  /// 判断 `fsck --delete` 是否进入“损坏对象已处理但仍有 partial commits”的新版 OSTree 状态。
  ///
  /// 这类状态通常退出码非 0，但继续提示“修复失败”会误导用户；
  /// 正确处理是告知自动删除已执行，并引导重新拉取受影响对象。
  bool _isFsckDetectedPartialCommitState(ShellCommandResult result) {
    final output = _combinedCommandOutput(result).toLowerCase();
    return output.contains('partial commits from fsck-detected corruption') ||
        (output.contains('partial commits') &&
            output.contains('fsck-detected corruption')) ||
        output.contains('partial commits not verified');
  }

  /// 从 OSTree 输出中提取 partial commit 数量，用于给用户展示具体影响规模。
  int? _extractPartialCommitCount(ShellCommandResult result) {
    final match = RegExp(
      r'(\d+)\s+partial\s+commits?',
      caseSensitive: false,
    ).firstMatch(_combinedCommandOutput(result));
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
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

  /// 合并一次命令的 stdout/stderr，供兼容判断使用。
  ///
  /// `ShellCommandResult.primaryMessage` 会优先取 stderr，但 OSTree 的进度、partial 计数和错误原因
  /// 可能分散在两个流里，因此兼容判断必须读取完整输出。
  String _combinedCommandOutput(ShellCommandResult result) {
    return [
      result.stdout.trim(),
      result.stderr.trim(),
    ].where((item) => item.isNotEmpty).join('\n');
  }

  /// 合并多次修复尝试的输出，确保旧版参数降级时 UI 和日志入口能看到完整上下文。
  String _combinedPrimaryOutput(List<ShellCommandResult> results) {
    return results
        .map(_combinedCommandOutput)
        .where((item) => item.isNotEmpty)
        .join('\n');
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

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    return '$bytes B';
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
