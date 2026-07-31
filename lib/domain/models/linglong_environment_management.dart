import 'linglong_env_check_result.dart';

enum LinglongEnvironmentIssueSeverity { info, warning, error }

enum LinglongEnvironmentIssueCode {
  llCliUnavailable,
  repositoryNotConfigured,
  localDataDetectionFailed,
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
    this.repairAction,
    this.rawDetail,
    this.subject,
    this.count,
    this.percent,
  });

  /// 可供 Presentation 稳定映射本地化文案的问题代码。
  final LinglongEnvironmentIssueCode code;

  /// 决定问题卡片视觉层级的严重程度。
  final LinglongEnvironmentIssueSeverity severity;

  /// 用户确认后允许执行的受控修复动作。
  final LinglongEnvironmentRepairAction? repairAction;

  /// 不参与翻译的原始命令或系统诊断。
  final String? rawDetail;

  /// 问题涉及的服务用户、路径或其他不可翻译标识。
  final String? subject;

  /// 问题涉及的应用或对象数量。
  final int? count;

  /// 问题涉及的整数百分比。
  final int? percent;

  /// 当前问题是否提供受控修复入口。
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

/// 环境管理操作的稳定结果代码。
///
/// Application 只返回代码和事实，Presentation 根据当前 Locale 生成用户文案。
enum LinglongEnvironmentRepairResultCode {
  dataPermissionRepairCompleted,
  dataPermissionRepairFailed,
  localDataRepairUnsupported,
  localDataRepairCompleted,
  localDataRepairFailed,
  localDataRepairChecksumMismatch,
  localDataRepullCompleted,
  localDataRepullFailed,
  localDataRepullChecksumMismatch,
  storageMoveBlockedByRunningApps,
  storageMoveBlockedByActiveTask,
  storageMoveBlockedByNamedActiveTask,
  storageAlreadyBindMounted,
  storageTargetFilesystemUnavailable,
  storageSpaceUnknown,
  storageInsufficientSpace,
  storageTargetInvalid,
  storageMoveCompleted,
  storageMoveFailed,
  unexpectedFailure,
}

/// 保存位置输入校验失败的稳定原因。
enum LinglongStorageTargetFailureReason {
  notAbsolute,
  containsLineBreak,
  unsafeSystemPath,
  insideCurrentRoot,
}

/// 环境修复或保存位置迁移结果。
class LinglongEnvironmentRepairResult {
  const LinglongEnvironmentRepairResult({
    required this.action,
    required this.success,
    required this.code,
    this.logFilePath,
    this.output,
    this.diagnostic,
    this.subject,
    this.count,
    this.requiredSpace,
    this.availableSpace,
    this.usedLegacyFallback = false,
    this.storageTargetFailureReason,
  });

  /// 本次结果对应的受控动作。
  final LinglongEnvironmentRepairAction action;

  /// 动作是否达到业务成功终态。
  final bool success;

  /// 供 Presentation 映射本地化文案的稳定代码。
  final LinglongEnvironmentRepairResultCode code;

  /// 完整日志文件路径。
  final String? logFilePath;

  /// 界面允许展示的截断命令输出。
  final String? output;

  /// 不参与翻译的异常或命令诊断。
  final String? diagnostic;

  /// 路径、任务名称等不可翻译的动态事实。
  final String? subject;

  /// 应用或 partial commit 数量。
  final int? count;

  /// 空间校验要求的格式化容量。
  final String? requiredSpace;

  /// 空间校验中当前可用的格式化容量。
  final String? availableSpace;

  /// 是否使用了旧版系统参数兼容路径。
  final bool usedLegacyFallback;

  /// 保存位置输入失败时的具体稳定原因。
  final LinglongStorageTargetFailureReason? storageTargetFailureReason;
}
