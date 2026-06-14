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

class LinglongOstreeCheckResult {
  const LinglongOstreeCheckResult({
    required this.isAvailable,
    required this.isOk,
    this.detail,
  });

  final bool isAvailable;
  final bool isOk;
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
