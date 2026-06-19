import 'linglong_env_check_result.dart';

enum LinglongEnvironmentIssueSeverity { info, warning, error }

enum LinglongEnvironmentIssueCode {
  llCliUnavailable,
  repositoryNotConfigured,
  ostreeRepositoryCorrupted,
  ostreeToolUnavailable,
  storageNearlyFull,
  runningAppsBlockStorageMove,
}

enum LinglongEnvironmentRepairAction {
  refreshRepositoryConfig,
  ostreeFsckDelete,
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

/// OSTree 仓库检查结果。
///
/// `isOk` 表示玲珑运行路径能否读取本地仓库，不等同于深度 `fsck` 完全干净；
/// 深度校验发现对象风险时通过 `hasIntegrityWarning` 单独表达，避免把仍可运行的环境误判为不可用。
class LinglongOstreeCheckResult {
  const LinglongOstreeCheckResult({
    required this.isAvailable,
    required this.isOk,
    this.hasIntegrityWarning = false,
    this.detail,
  });

  /// `ostree` 命令是否可用于本地仓库检查。
  final bool isAvailable;

  /// 本地仓库是否能完成玲珑运行所依赖的只读访问。
  final bool isOk;

  /// 深度对象完整性校验是否发现风险。
  ///
  /// 该字段为 `true` 时代表需要提示用户择机修复或重新拉取受影响内容，
  /// 但不能直接推导为玲珑基础环境不可用。
  final bool hasIntegrityWarning;

  /// 面向诊断展示的命令输出摘要，完整输出仍应以日志文件为准。
  final String? detail;
}

class LinglongEnvironmentAnalysis {
  const LinglongEnvironmentAnalysis({
    required this.envResult,
    required this.storage,
    required this.ostree,
    required this.issues,
    required this.runningAppCount,
    required this.analyzedAt,
  });

  final LinglongEnvCheckResult envResult;
  final LinglongStorageInfo storage;
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
