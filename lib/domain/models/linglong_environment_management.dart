import 'linglong_env_check_result.dart';

enum LinglongEnvironmentIssueSeverity { info, warning, error }

enum LinglongEnvironmentIssueCode {
  llCliUnavailable,
  repositoryNotConfigured,
  ostreeRepositoryCorrupted,
  ostreeToolUnavailable,

  /// 玲珑服务用户无法读写本地数据树时使用，避免误归类为本地仓库对象损坏。
  linglongDataPermissionAbnormal,
  storageNearlyFull,
  runningAppsBlockStorageMove,
}

enum LinglongEnvironmentRepairAction {
  refreshRepositoryConfig,
  ostreeFsckDelete,

  /// 通过受控特权脚本恢复 `/var/lib/linglong` 关键路径属主和 owner 写权限。
  fixDataPermissions,
  moveStorageRoot,
}

class LinglongEnvironmentIssue {
  const LinglongEnvironmentIssue({
    required this.code,
    required this.severity,
    required this.title,
    required this.description,
    this.repairAction,
    this.rawDetail,
  });

  final LinglongEnvironmentIssueCode code;
  final LinglongEnvironmentIssueSeverity severity;
  final String title;
  final String description;
  final LinglongEnvironmentRepairAction? repairAction;
  final String? rawDetail;

  bool get isRepairable => repairAction != null;
}

class LinglongStorageInfo {
  const LinglongStorageInfo({
    required this.rootPath,
    this.filesystem,
    this.mountedOn,
    this.mountSource,
    this.capacityBytes,
    this.usedBytes,
    this.availableBytes,
    this.usagePercent,
    this.isMounted = false,
    this.isBindMounted = false,
  });

  final String rootPath;
  final String? filesystem;
  final String? mountedOn;
  final String? mountSource;
  final int? capacityBytes;
  final int? usedBytes;
  final int? availableBytes;
  final int? usagePercent;
  final bool isMounted;
  final bool isBindMounted;

  bool get isNearlyFull => (usagePercent ?? 0) >= 90;
}

/// 玲珑数据目录权限检查结果。
///
/// `ll-package-manager` 以 `deepin-linglong` 用户运行，本地数据目录如果被 root 接管，
/// 会导致 `.version` 迁移、对象拉取或 layer 生成在运行期失败。
class LinglongDataPermissionCheckResult {
  const LinglongDataPermissionCheckResult({
    required this.isAvailable,
    required this.isOk,
    this.detail,
  });

  /// 是否成功读取本地数据目录权限信息。
  final bool isAvailable;

  /// 关键目录和状态文件是否由玲珑服务用户持有，并具备 owner 写权限。
  final bool isOk;

  /// 面向诊断展示的权限异常摘要。
  final String? detail;
}

/// 玲珑本地数据检查结果。
///
/// 该类型沿用历史命名以减少 Provider 和 UI 改动面，但业务语义已经收敛到
/// linyaps 运行路径：`isOk` 表示 `ll-cli`/package-manager 能否读取本地数据。
/// 深度对象审计只属于手动修复日志和高级诊断，不参与默认环境健康结论。
class LinglongOstreeCheckResult {
  const LinglongOstreeCheckResult({
    required this.isAvailable,
    required this.isOk,
    this.hasIntegrityWarning = false,
    this.detail,
  });

  /// 是否成功执行 linyaps 本地数据读取检查。
  final bool isAvailable;

  /// 本地数据是否能完成玲珑运行所依赖的只读访问。
  final bool isOk;

  /// 历史字段，保留给手动深度诊断结果表达。
  ///
  /// 默认环境分析不再设置该字段，避免把底层存储审计结果误判为 linyaps 运行异常。
  final bool hasIntegrityWarning;

  /// 面向诊断展示的命令输出摘要，完整输出仍应以日志文件为准。
  final String? detail;
}

class LinglongEnvironmentAnalysis {
  const LinglongEnvironmentAnalysis({
    required this.envResult,
    required this.storage,
    required this.dataPermission,
    required this.ostree,
    required this.issues,
    required this.runningAppCount,
    required this.analyzedAt,
  });

  final LinglongEnvCheckResult envResult;
  final LinglongStorageInfo storage;
  final LinglongDataPermissionCheckResult dataPermission;
  final LinglongOstreeCheckResult ostree;
  final List<LinglongEnvironmentIssue> issues;
  final int runningAppCount;
  final DateTime analyzedAt;

  bool get hasRepairableIssues => issues.any((issue) => issue.isRepairable);

  bool get canMoveStorage => runningAppCount == 0;
}

class LinglongEnvironmentRepairResult {
  const LinglongEnvironmentRepairResult({
    required this.action,
    required this.success,
    required this.message,
    this.logFilePath,
    this.output,
  });

  final LinglongEnvironmentRepairAction action;
  final bool success;
  final String message;
  final String? logFilePath;
  final String? output;
}
