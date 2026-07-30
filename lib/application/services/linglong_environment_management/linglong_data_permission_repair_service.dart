/// 玲珑数据目录权限修复服务。
///
/// 该文件集中维护服务用户、目录范围和受控特权脚本，避免权限规则散落到
/// 健康分析、Provider 或界面层。
library;

import '../../../core/platform/shell_command_executor.dart';
import '../../../domain/models/linglong_environment_management.dart';
import 'linglong_management_command_workspace.dart';

/// 修复 `ll-package-manager` 运行所需的数据目录属主和写权限。
class LinglongDataPermissionRepairService {
  /// 创建数据目录权限修复服务。
  LinglongDataPermissionRepairService({
    required ShellCommandExecutor executor,
    required LinglongManagementCommandWorkspace workspace,
    required String rootPath,
    String serviceName = 'org.deepin.linglong.PackageManager.service',
    String serviceUser = 'deepin-linglong',
    String serviceGroup = 'deepin-linglong',
  }) : _executor = executor,
       _workspace = workspace,
       _rootPath = rootPath,
       _serviceName = serviceName,
       _serviceUser = serviceUser,
       _serviceGroup = serviceGroup;

  final ShellCommandExecutor _executor;
  final LinglongManagementCommandWorkspace _workspace;
  final String _rootPath;
  final String _serviceName;
  final String _serviceUser;
  final String _serviceGroup;

  /// 执行权限修复并把完整过程写入 XDG 日志。
  Future<LinglongEnvironmentRepairResult> repair({String? logFilePath}) async {
    final scriptFile = await _workspace.writeTemporaryScript(
      buildScript(),
      prefix: 'linglong-permission-repair',
    );
    final resolvedLogFilePath =
        logFilePath ??
        await _workspace.createLogFilePath('linglong-permission-repair');

    try {
      final result = await _executor.run(
        ['pkexec', 'bash', scriptFile.path],
        timeout: const Duration(minutes: 20),
        environment:
            LinglongManagementCommandWorkspace.englishLocaleEnvironment,
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
        output: _workspace.truncateOutput(
          _workspace.combinedCommandOutput(result),
        ),
      );
    } finally {
      await _workspace.deleteTemporaryScript(scriptFile);
    }
  }

  /// 构建只覆盖玲珑运行期关键数据树的权限修复脚本。
  ///
  /// 脚本不创建仓库、不删除对象；修复后必须重启 package-manager 并通过
  /// `ll-cli --json repo show` 验证实际运行路径。
  String buildScript() {
    return '''
#!/usr/bin/env bash
set -euo pipefail

ROOT=${_workspace.shellSingleQuote(_rootPath)}
SERVICE=${_workspace.shellSingleQuote(_serviceName)}
USER_NAME=${_workspace.shellSingleQuote(_serviceUser)}
GROUP_NAME=${_workspace.shellSingleQuote(_serviceGroup)}

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
}
