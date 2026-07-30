/// 玲珑保存位置迁移服务。
///
/// 该文件维护 systemd bind mount 迁移方案、危险路径限制和磁盘空间前置校验，
/// 不把“保存位置”误建模成 linyaps 原生自定义安装目录。
library;

import 'dart:math' as math;

import 'package:path/path.dart' as path;

import '../../../core/platform/shell_command_executor.dart';
import '../../../domain/models/linglong_environment_management.dart';
import 'linglong_environment_probe.dart';
import 'linglong_management_command_workspace.dart';

/// 按 systemd bind mount 方案迁移玲珑本地数据根目录。
class LinglongStorageMigrationService {
  /// 创建保存位置迁移服务。
  LinglongStorageMigrationService({
    required ShellCommandExecutor executor,
    required LinglongManagementCommandWorkspace workspace,
    required LinglongEnvironmentProbe probe,
  }) : _executor = executor,
       _workspace = workspace,
       _probe = probe;

  final ShellCommandExecutor _executor;
  final LinglongManagementCommandWorkspace _workspace;
  final LinglongEnvironmentProbe _probe;

  /// 校验前置条件并执行保存位置迁移。
  Future<LinglongEnvironmentRepairResult> move(
    String targetPath, {
    String? logFilePath,
  }) async {
    final normalizedTargetPath = _normalizeTargetPath(targetPath);
    final runningAppCount = await _probe.loadRunningAppCount();
    if (runningAppCount > 0) {
      return LinglongEnvironmentRepairResult(
        action: LinglongEnvironmentRepairAction.moveStorageRoot,
        success: false,
        message: '仍有 $runningAppCount 个玲珑应用正在运行，请关闭后再移动保存位置',
      );
    }

    final validationError = await _validatePreconditions(normalizedTargetPath);
    if (validationError != null) {
      return LinglongEnvironmentRepairResult(
        action: LinglongEnvironmentRepairAction.moveStorageRoot,
        success: false,
        message: validationError,
      );
    }

    final scriptFile = await _workspace.writeTemporaryScript(
      buildScript(normalizedTargetPath),
    );
    final resolvedLogFilePath =
        logFilePath ??
        await _workspace.createLogFilePath('linglong-storage-move');

    try {
      final result = await _executor.run(
        ['pkexec', 'bash', scriptFile.path],
        timeout: const Duration(hours: 2),
        environment:
            LinglongManagementCommandWorkspace.englishLocaleEnvironment,
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
        output: _workspace.truncateOutput(_workspace.primaryOutput(result)),
      );
    } finally {
      await _workspace.deleteTemporaryScript(scriptFile);
    }
  }

  /// 构建 systemd bind mount 迁移脚本。
  ///
  /// 脚本在特权边界再次检查运行中应用，复制后校验 repo/config，并保留旧目录
  /// 备份，使应用层前置检查与最终执行之间的竞态不会直接破坏现有数据。
  String buildScript(String targetPath) {
    final normalizedTargetPath = _normalizeTargetPath(targetPath);
    final rootPath = _probe.rootPath;

    return '''
#!/usr/bin/env bash
set -euo pipefail

SRC=${_workspace.shellSingleQuote(rootPath)}
DST=${_workspace.shellSingleQuote(normalizedTargetPath)}
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
Where=$rootPath
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

  /// 校验挂载状态和目标文件系统空间，不执行任何变更命令。
  Future<String?> _validatePreconditions(String normalizedTargetPath) async {
    final storage = await _probe.loadStorageInfo();
    if (storage.isBindMounted) {
      return '${_probe.rootPath} 当前已经是 bind mount，请先确认现有挂载配置后再迁移。';
    }

    final targetProbePath = await _probe.nearestExistingPath(
      normalizedTargetPath,
    );
    final targetInfo = await _probe.loadFilesystemInfo(targetProbePath);
    if (targetInfo == null) {
      return '无法读取目标路径所在文件系统空间：$targetProbePath';
    }

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

  /// 规范化目标绝对路径并拒绝系统级或玲珑根目录内部的危险目标。
  String _normalizeTargetPath(String targetPath) {
    final trimmed = targetPath.trim();
    if (trimmed.isEmpty || !path.isAbsolute(trimmed)) {
      throw ArgumentError.value(targetPath, 'targetPath', '必须是绝对路径');
    }
    if (trimmed.contains('\n') || trimmed.contains('\r')) {
      throw ArgumentError.value(targetPath, 'targetPath', '路径不能包含换行符');
    }
    final normalized = path.normalize(trimmed);
    final currentRoot = path.normalize(_probe.rootPath);
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

  /// 使用迁移提示约定的二进制单位格式化容量。
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
