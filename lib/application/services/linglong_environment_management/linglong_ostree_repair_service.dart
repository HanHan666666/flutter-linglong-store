/// 玲珑本地数据修复服务。
///
/// 该文件集中维护 OSTree 参数兼容、fsck partial 识别、受影响 ref 重拉和复验，
/// 这些规则只属于用户显式触发的深度修复，不参与默认环境健康判断。
library;

import '../../../core/platform/shell_command_executor.dart';
import '../../../domain/models/linglong_environment_management.dart';
import 'linglong_management_command_workspace.dart';

/// 执行玲珑本地数据清理、兼容降级和 partial ref 重拉复验。
class LinglongOstreeRepairService {
  /// 创建玲珑本地数据修复服务。
  LinglongOstreeRepairService({
    required ShellCommandExecutor executor,
    required LinglongManagementCommandWorkspace workspace,
    required String rootPath,
    String serviceUser = 'deepin-linglong',
  }) : _executor = executor,
       _workspace = workspace,
       _rootPath = rootPath,
       _serviceUser = serviceUser;

  final ShellCommandExecutor _executor;
  final LinglongManagementCommandWorkspace _workspace;
  final String _rootPath;
  final String _serviceUser;

  /// 执行玲珑本地数据修复。
  ///
  /// 优先使用带全量对象的自动清理命令；旧系统只在明确不支持 `--all` 时降级，
  /// 不支持 `--delete` 时返回明确失败，不能把只检查伪装成修复成功。
  Future<LinglongEnvironmentRepairResult> repair({String? logFilePath}) async {
    final resolvedLogFilePath =
        logFilePath ??
        await _workspace.createLogFilePath('linglong-local-data-repair');

    final primaryResult = await _runRepairCommand(
      includeAllObjects: true,
      logFilePath: resolvedLogFilePath,
      overwriteLog: true,
    );

    if (_isUnsupportedOption(primaryResult, '--all')) {
      final fallbackResult = await _runRepairCommand(
        includeAllObjects: false,
        logFilePath: resolvedLogFilePath,
        overwriteLog: false,
      );

      if (!_isUnsupportedOption(fallbackResult, '--delete') &&
          _needsPartialRepull(fallbackResult)) {
        final repullResult = await _runPartialRepullCommand(
          logFilePath: resolvedLogFilePath,
        );
        return _buildRepullRepairResult(
          fsckResult: fallbackResult,
          repullResult: repullResult,
          logFilePath: resolvedLogFilePath,
          outputResults: [primaryResult, fallbackResult, repullResult],
          usedLegacyFallback: true,
        );
      }

      return _buildRepairResult(
        result: fallbackResult,
        logFilePath: resolvedLogFilePath,
        outputResults: [primaryResult, fallbackResult],
        usedLegacyFallback: true,
      );
    }

    if (!_isUnsupportedOption(primaryResult, '--delete') &&
        _needsPartialRepull(primaryResult)) {
      final repullResult = await _runPartialRepullCommand(
        logFilePath: resolvedLogFilePath,
      );
      return _buildRepullRepairResult(
        fsckResult: primaryResult,
        repullResult: repullResult,
        logFilePath: resolvedLogFilePath,
        outputResults: [primaryResult, repullResult],
      );
    }

    return _buildRepairResult(
      result: primaryResult,
      logFilePath: resolvedLogFilePath,
      outputResults: [primaryResult],
    );
  }

  /// 构建只重新拉取 fsck 标记 partial commit 的受控脚本。
  ///
  /// 普通 partial commit 可能来自 linyaps 元数据或子路径拉取；只有 marker
  /// 内容为 `f` 的 commit 才属于完整性审计截断后的损坏状态。
  String buildPartialRepullScript() {
    return '''
#!/usr/bin/env bash
set -uo pipefail

ROOT=${_workspace.shellSingleQuote(_rootPath)}
REPO="\$ROOT/repo"
SERVICE_USER=${_workspace.shellSingleQuote(_serviceUser)}

if [ ! -d "\$REPO" ]; then
  echo "玲珑本地数据仓库目录不存在：\$REPO" >&2
  exit 2
fi

if ! command -v ostree >/dev/null 2>&1; then
  echo "底层仓库工具不可用，无法重新拉取受影响 ref。" >&2
  exit 3
fi

repo_mode="\$(ostree config --repo="\$REPO" get core.mode 2>/dev/null || true)"
if [ -n "\$repo_mode" ]; then
  echo "玲珑本地数据仓库模式：\$repo_mode"
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

  /// 按指定兼容参数执行一次特权 fsck，并写入同一份操作日志。
  Future<ShellCommandResult> _runRepairCommand({
    required bool includeAllObjects,
    required String logFilePath,
    required bool overwriteLog,
  }) {
    final command = [
      'pkexec',
      'ostree',
      'fsck',
      '--repo=$_rootPath/repo',
      if (includeAllObjects) '--all',
      '--delete',
    ];

    return _executor.run(
      command,
      timeout: const Duration(minutes: 20),
      environment: LinglongManagementCommandWorkspace.englishLocaleEnvironment,
      logOptions: ShellCommandLogOptions(
        filePath: logFilePath,
        overwrite: overwriteLog,
      ),
    );
  }

  /// 执行 partial ref 重拉脚本并把结果追加到原修复日志。
  Future<ShellCommandResult> _runPartialRepullCommand({
    required String logFilePath,
  }) async {
    final scriptFile = await _workspace.writeTemporaryScript(
      buildPartialRepullScript(),
      prefix: 'linglong-local-data-repull',
    );

    try {
      return await _executor.run(
        ['pkexec', 'bash', scriptFile.path],
        timeout: const Duration(hours: 2),
        environment:
            LinglongManagementCommandWorkspace.englishLocaleEnvironment,
        logOptions: ShellCommandLogOptions(
          filePath: logFilePath,
          overwrite: false,
        ),
      );
    } finally {
      await _workspace.deleteTemporaryScript(scriptFile);
    }
  }

  /// 把单次或兼容降级后的 fsck 结果归类为业务修复结果。
  LinglongEnvironmentRepairResult _buildRepairResult({
    required ShellCommandResult result,
    required String logFilePath,
    required List<ShellCommandResult> outputResults,
    bool usedLegacyFallback = false,
  }) {
    final output = _workspace.truncateOutput(
      _workspace.combinedCommandOutputs(outputResults),
    );
    const action = LinglongEnvironmentRepairAction.ostreeFsckDelete;

    if (_isUnsupportedOption(result, '--delete')) {
      return LinglongEnvironmentRepairResult(
        action: action,
        success: false,
        message: '当前系统组件不支持自动清理问题对象，无法自动修复玲珑本地数据，请升级系统相关组件或使用发行版工具处理。',
        logFilePath: logFilePath,
        output: output,
      );
    }

    final successMessage = usedLegacyFallback
        ? '玲珑本地数据修复已执行（已兼容旧版系统参数）'
        : '玲珑本地数据修复已执行';
    final failureMessage = _hasChecksumCorruption(result)
        ? '玲珑本地数据复验发现对象 checksum 不一致，自动清理后仍未完成修复；'
              '若重新拉取后仍复现，通常需要上游仓库数据或 linyaps 本地存储兼容性修复。'
        : '玲珑本地数据修复失败';
    return LinglongEnvironmentRepairResult(
      action: action,
      success: result.success,
      message: result.success ? successMessage : failureMessage,
      logFilePath: logFilePath,
      output: output,
    );
  }

  /// 根据重拉后的最终复验状态构建业务修复结果。
  LinglongEnvironmentRepairResult _buildRepullRepairResult({
    required ShellCommandResult fsckResult,
    required ShellCommandResult repullResult,
    required String logFilePath,
    required List<ShellCommandResult> outputResults,
    bool usedLegacyFallback = false,
  }) {
    final count = _extractPartialCommitCount(fsckResult);
    final countText = count == null ? '部分' : '$count 个';
    final legacySuffix = usedLegacyFallback ? '（已兼容旧版系统参数）' : '';
    final output = _workspace.truncateOutput(
      _workspace.combinedCommandOutputs(outputResults),
    );
    const action = LinglongEnvironmentRepairAction.ostreeFsckDelete;

    if (repullResult.success) {
      return LinglongEnvironmentRepairResult(
        action: action,
        success: true,
        message:
            '玲珑本地数据已清理问题对象，并重新拉取 $countText partial commits，'
            '复验通过$legacySuffix。',
        logFilePath: logFilePath,
        output: output,
      );
    }

    final compatibilityHint = _hasChecksumCorruption(repullResult)
        ? '复验仍发现 checksum 不一致，可能是上游仓库数据与 linyaps 本地存储模式不兼容。'
        : '请查看日志确认具体 ref 的拉取或复验失败原因。';
    return LinglongEnvironmentRepairResult(
      action: action,
      success: false,
      message:
          '玲珑本地数据已清理可自动处理的问题对象，并尝试重新拉取 $countText partial commits，'
          '但重新拉取后复验仍未通过。$compatibilityHint$legacySuffix',
      logFilePath: logFilePath,
      output: output,
    );
  }

  /// 兼容识别不同发行版底层工具的“不支持参数”措辞。
  bool _isUnsupportedOption(ShellCommandResult result, String option) {
    final output = _workspace.combinedCommandOutput(result).toLowerCase();
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

  /// 判断输出是否明确属于 fsck 损坏检测产生的 partial commit。
  bool _isFsckDetectedPartialCommitState(ShellCommandResult result) {
    final output = _workspace.combinedCommandOutput(result).toLowerCase();
    return output.contains('partial commits from fsck-detected corruption') ||
        (output.contains('partial commits') &&
            output.contains('fsck-detected corruption'));
  }

  /// 判断自动清理后是否需要进入受影响 ref 的重拉复验流程。
  bool _needsPartialRepull(ShellCommandResult result) {
    if (_isFsckDetectedPartialCommitState(result)) {
      return true;
    }

    final output = _workspace.combinedCommandOutput(result).toLowerCase();
    return output.contains('marking commit as partial') &&
        output.contains('repository corruption encountered') &&
        _hasChecksumCorruption(result);
  }

  /// 判断输出是否包含对象 checksum 损坏证据。
  bool _hasChecksumCorruption(ShellCommandResult result) {
    final output = _workspace.combinedCommandOutput(result).toLowerCase();
    return output.contains('corrupted file object') ||
        (output.contains('checksum expected') && output.contains('actual='));
  }

  /// 提取 partial commit 数量，供结果文案展示真实影响规模。
  int? _extractPartialCommitCount(ShellCommandResult result) {
    final match = RegExp(
      r'(\d+)\s+partial\s+commits?',
      caseSensitive: false,
    ).firstMatch(_workspace.combinedCommandOutput(result));
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }
}
