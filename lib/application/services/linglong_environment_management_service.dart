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

  static const String _linglongServiceName =
      'org.deepin.linglong.PackageManager.service';
  static const String _linglongServiceUser = 'deepin-linglong';
  static const String _linglongServiceGroup = 'deepin-linglong';
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
    final dataPermission = await _checkDataPermissions();
    final ostree = await _checkOstreeRepository();
    final issues = _buildIssues(
      envResult: envResult,
      storage: storage,
      dataPermission: dataPermission,
      ostree: ostree,
      runningAppCount: runningAppCount,
    );

    return LinglongEnvironmentAnalysis(
      envResult: envResult,
      storage: storage,
      dataPermission: dataPermission,
      ostree: ostree,
      issues: issues,
      runningAppCount: runningAppCount,
      analyzedAt: _clock(),
    );
  }

  /// 执行 OSTree 仓库修复。
  ///
  /// 新版 OSTree 在 `--delete` 删除损坏对象后，可能因为 affected commit 被标记为
  /// fsck partial 而返回非零码；这类结果不能当成修复成功，需要重新拉取并复验。
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

      if (!_isUnsupportedOstreeOption(fallbackResult, '--delete') &&
          _isFsckDetectedPartialCommitState(fallbackResult)) {
        final repullResult = await _runOstreePartialRepullCommand(
          logFilePath: resolvedLogFilePath,
        );
        return _buildOstreeRepullRepairResult(
          fsckResult: fallbackResult,
          repullResult: repullResult,
          logFilePath: resolvedLogFilePath,
          outputResults: [primaryResult, fallbackResult, repullResult],
          usedLegacyFallback: true,
        );
      }

      return _buildOstreeRepairResult(
        result: fallbackResult,
        logFilePath: resolvedLogFilePath,
        outputResults: [primaryResult, fallbackResult],
        usedLegacyFallback: true,
      );
    }

    if (!_isUnsupportedOstreeOption(primaryResult, '--delete') &&
        _isFsckDetectedPartialCommitState(primaryResult)) {
      final repullResult = await _runOstreePartialRepullCommand(
        logFilePath: resolvedLogFilePath,
      );
      return _buildOstreeRepullRepairResult(
        fsckResult: primaryResult,
        repullResult: repullResult,
        logFilePath: resolvedLogFilePath,
        outputResults: [primaryResult, repullResult],
      );
    }

    return _buildOstreeRepairResult(
      result: primaryResult,
      logFilePath: resolvedLogFilePath,
      outputResults: [primaryResult],
    );
  }

  /// 修复玲珑数据目录属主。
  ///
  /// `ll-package-manager` 以 `deepin-linglong` 身份运行，数据目录如果被 root 接管，
  /// 会导致 `.version` 打不开、OSTree pull 无法 mkdir、layer 目录无法创建。
  Future<LinglongEnvironmentRepairResult> repairLinglongDataPermissions({
    String? logFilePath,
  }) async {
    final script = buildDataPermissionRepairScript();
    final scriptFile = await _writeTemporaryScript(
      script,
      prefix: 'linglong-permission-repair',
    );
    final resolvedLogFilePath =
        logFilePath ?? await _createLogFilePath('linglong-permission-repair');

    try {
      final result = await _executor.run(
        ['pkexec', 'bash', scriptFile.path],
        timeout: const Duration(minutes: 20),
        environment: _englishLocaleEnv,
        logOptions: ShellCommandLogOptions(
          filePath: resolvedLogFilePath,
          overwrite: true,
        ),
      );

      return LinglongEnvironmentRepairResult(
        action: LinglongEnvironmentRepairAction.fixDataPermissions,
        success: result.success,
        message: result.success ? '玲珑数据目录权限已修复' : '玲珑数据目录权限修复失败',
        logFilePath: resolvedLogFilePath,
        output: _truncateOutput(_combinedCommandOutput(result)),
      );
    } finally {
      await _deleteFileIfExists(scriptFile);
    }
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

  /// 构建数据目录权限修复脚本。
  ///
  /// 脚本只处理玲珑运行所需的本地数据树，不创建新仓库、不删除损坏对象；
  /// 修复后通过重启 package-manager 和读取仓库配置验证运行路径恢复。
  String buildDataPermissionRepairScript() {
    return '''
#!/usr/bin/env bash
set -euo pipefail

ROOT=${_shellSingleQuote(_linglongRootPath)}
SERVICE=${_shellSingleQuote(_linglongServiceName)}
USER_NAME=${_shellSingleQuote(_linglongServiceUser)}
GROUP_NAME=${_shellSingleQuote(_linglongServiceGroup)}

if ! id "\$USER_NAME" >/dev/null 2>&1; then
  echo "玲珑服务用户不存在：\$USER_NAME" >&2
  exit 2
fi

if ! getent group "\$GROUP_NAME" >/dev/null 2>&1; then
  echo "玲珑服务用户组不存在：\$GROUP_NAME" >&2
  exit 3
fi

if [ ! -d "\$ROOT" ]; then
  echo "玲珑数据目录不存在：\$ROOT" >&2
  exit 4
fi

systemctl stop "\$SERVICE" 2>/dev/null || true

chown "\$USER_NAME:\$GROUP_NAME" "\$ROOT"

if [ -e "\$ROOT/.version" ]; then
  chown "\$USER_NAME:\$GROUP_NAME" "\$ROOT/.version"
  chmod u+rw "\$ROOT/.version" 2>/dev/null || true
fi
if [ -e "\$ROOT/config.yaml" ]; then
  chown "\$USER_NAME:\$GROUP_NAME" "\$ROOT/config.yaml"
  chmod u+rw "\$ROOT/config.yaml" 2>/dev/null || true
fi
if [ -e "\$ROOT/states.json" ]; then
  chown "\$USER_NAME:\$GROUP_NAME" "\$ROOT/states.json"
  chmod u+rw "\$ROOT/states.json" 2>/dev/null || true
fi

if [ -d "\$ROOT/repo" ]; then
  chown -R "\$USER_NAME:\$GROUP_NAME" "\$ROOT/repo"
fi
if [ -d "\$ROOT/layers" ]; then
  chown -R "\$USER_NAME:\$GROUP_NAME" "\$ROOT/layers"
fi
if [ -d "\$ROOT/entries" ]; then
  chown -R "\$USER_NAME:\$GROUP_NAME" "\$ROOT/entries"
fi
if [ -d "\$ROOT/merged" ]; then
  chown -R "\$USER_NAME:\$GROUP_NAME" "\$ROOT/merged"
fi

for dir in repo layers entries merged; do
  target="\$ROOT/\$dir"
  if [ -d "\$target" ]; then
    find "\$target" -type d -exec chmod u+rwx {} +
  fi
done

systemctl reset-failed "\$SERVICE" 2>/dev/null || true
systemctl restart "\$SERVICE"
ll-cli --json repo show >/dev/null

echo "玲珑数据目录权限已修复。"
''';
  }

  /// 构建 OSTree partial commit 重新拉取脚本。
  ///
  /// OSTree 普通 partial commit 可能来自 linyaps 的元数据/子路径拉取；只有 marker
  /// 内容为 `f` 的 commit 才是 fsck 检测损坏后的截断状态。脚本只重拉这类 ref，
  /// 并在最后重新执行 fsck，让 UI 依据复验结果展示是否真正恢复。
  String buildOstreePartialRepullScript() {
    return '''
#!/usr/bin/env bash
set -uo pipefail

ROOT=${_shellSingleQuote(_linglongRootPath)}
REPO="\$ROOT/repo"
SERVICE_USER=${_shellSingleQuote(_linglongServiceUser)}

if [ ! -d "\$REPO" ]; then
  echo "OSTree 仓库目录不存在：\$REPO" >&2
  exit 2
fi

if ! command -v ostree >/dev/null 2>&1; then
  echo "ostree 命令不可用，无法重新拉取受影响 ref。" >&2
  exit 3
fi

repo_mode="\$(ostree config --repo="\$REPO" get core.mode 2>/dev/null || true)"
if [ -n "\$repo_mode" ]; then
  echo "OSTree repo mode: \$repo_mode"
fi

run_ostree_pull() {
  remote_name="\$1"
  remote_ref="\$2"
  if command -v runuser >/dev/null 2>&1 && id "\$SERVICE_USER" >/dev/null 2>&1; then
    runuser -u "\$SERVICE_USER" -- env HOME="\$ROOT" \\
      ostree --repo="\$REPO" pull --disable-static-deltas "\$remote_name" "\$remote_ref" ||
    runuser -u "\$SERVICE_USER" -- env HOME="\$ROOT" \\
      ostree --repo="\$REPO" pull "\$remote_name" "\$remote_ref"
  else
    ostree --repo="\$REPO" pull --disable-static-deltas "\$remote_name" "\$remote_ref" ||
    ostree --repo="\$REPO" pull "\$remote_name" "\$remote_ref"
  fi
}

refs="\$(ostree refs --repo="\$REPO")" || exit 4
partial_count=0
pull_failures=0

while IFS= read -r ref; do
  [ -n "\$ref" ] || continue
  rev="\$(ostree rev-parse --repo="\$REPO" "\$ref" 2>/dev/null || true)"
  [ -n "\$rev" ] || continue
  marker="\$REPO/state/\${rev}.commitpartial"
  [ -f "\$marker" ] || continue
  reason="\$(dd if="\$marker" bs=1 count=1 2>/dev/null || true)"
  [ "\$reason" = "f" ] || continue

  partial_count=\$((partial_count + 1))
  if printf '%s' "\$ref" | grep -q ':'; then
    remote_name="\${ref%%:*}"
    remote_ref="\${ref#*:}"
  else
    remote_name="\$(ostree remote list --repo="\$REPO" | head -n 1)"
    remote_ref="\$ref"
  fi

  if [ -z "\$remote_name" ] || [ -z "\$remote_ref" ]; then
    echo "无法解析受影响 ref 的远端信息：\$ref" >&2
    pull_failures=\$((pull_failures + 1))
    continue
  fi

  echo "RE-PULL \$ref"
  if ! run_ostree_pull "\$remote_name" "\$remote_ref"; then
    echo "重新拉取失败：\$ref" >&2
    pull_failures=\$((pull_failures + 1))
  fi
done <<< "\$refs"

echo "发现 \$partial_count 个 fsck 标记的 partial commits。"
if [ "\$partial_count" -eq 0 ]; then
  echo "未发现需要重新拉取的 fsck partial ref，直接执行复验。"
fi

ostree fsck --repo="\$REPO" --quiet
verify_rc=\$?

if [ "\$pull_failures" -gt 0 ]; then
  exit 5
fi

exit "\$verify_rc"
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
    required LinglongDataPermissionCheckResult dataPermission,
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

    if (!dataPermission.isOk) {
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.linglongDataPermissionAbnormal,
          severity: LinglongEnvironmentIssueSeverity.error,
          title: '玲珑数据目录权限异常',
          description:
              'll-package-manager 以 $_linglongServiceUser 用户运行，但玲珑数据目录或关键状态文件属主异常，'
              '可能导致仓库迁移、下载对象或创建 layer 失败。',
          repairAction: LinglongEnvironmentRepairAction.fixDataPermissions,
          rawDetail: dataPermission.detail,
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
              '深度校验发现对象存储存在损坏记录，但当前玲珑仓库仍可读取。'
              '建议在空闲时执行修复，系统会删除可清理的损坏对象，必要时重新拉取受影响应用或基础环境并复验。',
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

  Future<LinglongDataPermissionCheckResult> _checkDataPermissions() async {
    final statPaths = _permissionCheckRelativePaths
        .map(
          (relativePath) => relativePath.isEmpty
              ? _linglongRootPath
              : path.join(_linglongRootPath, relativePath),
        )
        .toList(growable: false);
    final result = await _run([
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
        detail: _truncateOutput(_combinedCommandOutput(result)),
      );
    }

    final entries = _parsePermissionEntries(result.stdout);
    final abnormalEntries = entries
        .where((entry) {
          final expectedOwner =
              entry.owner == _linglongServiceUser &&
              entry.group == _linglongServiceGroup;
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
              '期望 $_linglongServiceUser:$_linglongServiceGroup 且 owner 可写',
        )
        .join('\n');

    return LinglongDataPermissionCheckResult(
      isAvailable: true,
      isOk: false,
      detail: _truncateOutput(detail),
    );
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

  /// 解析 `stat -c %U:%G:%a:%n` 的输出。
  ///
  /// 路径理论上不包含冒号，但这里仍保留剩余字段拼接，避免后续测试路径或非标准挂载点中
  /// 出现冒号时把权限记录误拆坏。
  List<_PermissionEntry> _parsePermissionEntries(String output) {
    return const LineSplitter()
        .convert(output)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final parts = line.split(':');
          if (parts.length < 4) {
            return null;
          }
          return _PermissionEntry(
            owner: parts[0],
            group: parts[1],
            mode: parts[2],
            path: parts.sublist(3).join(':'),
          );
        })
        .nonNulls
        .toList(growable: false);
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

  Future<File> _writeTemporaryScript(
    String script, {
    String prefix = 'linglong-storage-move',
  }) async {
    final file = File(
      path.join(
        Directory.systemTemp.path,
        '$prefix-${_clock().millisecondsSinceEpoch}.sh',
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

  /// 重新拉取被 fsck 标记为 partial 的受影响 ref，并把输出追加到同一份日志。
  ///
  /// 重拉可能下载大量基础环境对象，因此只在 `fsck-detected corruption` 已明确出现后执行，
  /// 且由最终 fsck 复验结果决定是否算修复成功。
  Future<ShellCommandResult> _runOstreePartialRepullCommand({
    required String logFilePath,
  }) async {
    final scriptFile = await _writeTemporaryScript(
      buildOstreePartialRepullScript(),
      prefix: 'linglong-ostree-repull',
    );

    try {
      return await _executor.run(
        ['pkexec', 'bash', scriptFile.path],
        timeout: const Duration(hours: 2),
        environment: _englishLocaleEnv,
        logOptions: ShellCommandLogOptions(
          filePath: logFilePath,
          overwrite: false,
        ),
      );
    } finally {
      await _deleteFileIfExists(scriptFile);
    }
  }

  /// 将 OSTree 修复命令结果归类为 UI 可理解的业务状态。
  ///
  /// 这里刻意不只看退出码：新版 OSTree 会在删除损坏对象后返回 partial commit 错误，
  /// 这种状态已经由调用方进入重拉复验流程；旧版缺少参数则需要给出可操作的版本兼容信息。
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

    final successMessage = usedLegacyFallback
        ? 'OSTree 仓库完整性修复已执行（已兼容旧版 OSTree）'
        : 'OSTree 仓库完整性修复已执行';
    final failureMessage = _hasChecksumCorruption(result)
        ? 'OSTree 校验发现对象 checksum 不一致，自动删除后仍未完成修复；'
              '若重新拉取后仍复现，通常需要上游仓库数据或 OSTree/玲珑兼容性修复。'
        : 'OSTree 仓库完整性修复失败';
    return LinglongEnvironmentRepairResult(
      action: action,
      success: result.success,
      message: result.success ? successMessage : failureMessage,
      logFilePath: logFilePath,
      output: output,
    );
  }

  /// 构建 fsck partial 重拉后的最终修复结果。
  ///
  /// 重拉脚本自身会执行复验；只要复验仍返回 checksum mismatch 或 corruption，
  /// 就必须把结果报告为失败，避免把上游数据/仓库模式兼容问题包装成已修复。
  LinglongEnvironmentRepairResult _buildOstreeRepullRepairResult({
    required ShellCommandResult fsckResult,
    required ShellCommandResult repullResult,
    required String logFilePath,
    required List<ShellCommandResult> outputResults,
    bool usedLegacyFallback = false,
  }) {
    final count = _extractPartialCommitCount(fsckResult);
    final countText = count == null ? '部分' : '$count 个';
    final legacySuffix = usedLegacyFallback ? '（已兼容旧版 OSTree 参数）' : '';
    final output = _truncateOutput(_combinedPrimaryOutput(outputResults));
    const action = LinglongEnvironmentRepairAction.ostreeFsckDelete;

    if (repullResult.success) {
      return LinglongEnvironmentRepairResult(
        action: action,
        success: true,
        message:
            'OSTree 已删除损坏对象，并重新拉取 $countText fsck partial commits，'
            '复验通过$legacySuffix。',
        logFilePath: logFilePath,
        output: output,
      );
    }

    final compatibilityHint = _hasChecksumCorruption(repullResult)
        ? '复验仍发现 checksum 不一致，可能是上游仓库数据在当前 bare-user-only 模式下与 OSTree 校验不兼容。'
        : '请查看日志确认具体 ref 的拉取或复验失败原因。';
    return LinglongEnvironmentRepairResult(
      action: action,
      success: false,
      message:
          'OSTree 已删除可自动清理的损坏对象，并尝试重新拉取 $countText partial commits，'
          '但重新拉取后复验仍未通过。$compatibilityHint$legacySuffix',
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
            output.contains('fsck-detected corruption'));
  }

  /// 判断输出是否包含对象 checksum 损坏。
  ///
  /// uuu/loong64 环境实测这类错误在全新 bare-user-only repo 中也能复现，
  /// 因此文案必须提示上游仓库数据或 OSTree 模式兼容风险，而不是继续建议反复 fsck。
  bool _hasChecksumCorruption(ShellCommandResult result) {
    final output = _combinedCommandOutput(result).toLowerCase();
    return output.contains('corrupted file object') ||
        (output.contains('checksum expected') && output.contains('actual='));
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

class _PermissionEntry {
  const _PermissionEntry({
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
  /// `stat %a` 可能输出 `755` 或带特殊位的 `2755`，权限判断只取最后三位中的 owner 位。
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
