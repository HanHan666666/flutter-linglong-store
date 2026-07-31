/// 玲珑环境管理结构化状态的本地化映射。
///
/// Domain 与 Application 只传播稳定代码、结构化事实和原始诊断；本文件作为
/// Presentation 唯一翻译入口，防止自然语言重新泄漏到业务状态或系统服务中。
library;

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/linglong_env_check_result.dart';
import '../../../domain/models/linglong_environment_management.dart';

/// 环境问题卡片需要展示的本地化标题和说明。
class LinglongEnvironmentIssueText {
  /// 创建问题展示文案。
  const LinglongEnvironmentIssueText({
    required this.title,
    required this.description,
  });

  /// 问题标题。
  final String title;

  /// 问题影响与处理建议。
  final String description;
}

/// 把环境检测事实映射为当前语言的紧凑状态文案。
String localizeLinglongEnvironmentStatus(
  AppLocalizations l10n,
  LinglongEnvCheckResult result,
) {
  if (result.isOk && result.warningMessage != null) {
    return l10n.envManagementEnvironmentHealthyUpgrade;
  }
  if (result.isOk) {
    return l10n.envManagementEnvironmentHealthy;
  }
  if (result.recoveryAction ==
      LinglongEnvRecoveryAction.restartPackageManagerService) {
    return l10n.envManagementRepositoryReadFailed;
  }
  if (result.llCliVersion == null) {
    return l10n.envIssueLlCliUnavailableTitle;
  }
  return l10n.envManagementEnvironmentAbnormal;
}

/// 把仓库状态映射为当前语言的紧凑文案。
String localizeLinglongRepositoryStatus(
  AppLocalizations l10n,
  RepoStatus status,
) {
  return switch (status) {
    RepoStatus.ok => l10n.envRepoStatusNormal,
    RepoStatus.notConfigured => l10n.envRepoStatusNotConfigured,
    RepoStatus.misconfigured => l10n.envRepoStatusMisconfigured,
    RepoStatus.unavailable => l10n.envRepoStatusUnavailable,
    RepoStatus.unknown => l10n.envRepoStatusUnknown,
  };
}

/// 把本地数据读取状态映射为当前语言的紧凑文案。
String localizeLinglongLocalDataStatus(
  AppLocalizations l10n,
  LinglongOstreeCheckResult localData,
) {
  if (!localData.isAvailable) {
    return l10n.envLocalDataDetectionFailed;
  }
  if (!localData.isOk) {
    return l10n.envLocalDataUnavailable;
  }
  return l10n.envLocalDataNormal;
}

/// 根据稳定问题代码和结构化事实生成问题卡片文案。
LinglongEnvironmentIssueText localizeLinglongEnvironmentIssue(
  AppLocalizations l10n,
  LinglongEnvironmentIssue issue,
) {
  return switch (issue.code) {
    LinglongEnvironmentIssueCode.llCliUnavailable ||
    LinglongEnvironmentIssueCode.ostreeToolUnavailable =>
      LinglongEnvironmentIssueText(
        title: l10n.envIssueLlCliUnavailableTitle,
        description: l10n.envIssueLlCliUnavailableDescription,
      ),
    LinglongEnvironmentIssueCode.repositoryNotConfigured =>
      LinglongEnvironmentIssueText(
        title: l10n.envIssueRepositoryNotConfiguredTitle,
        description: l10n.envIssueRepositoryNotConfiguredDescription,
      ),
    LinglongEnvironmentIssueCode.linglongDataPermissionAbnormal =>
      LinglongEnvironmentIssueText(
        title: l10n.envIssueDataPermissionTitle,
        description: l10n.envIssueDataPermissionDescription(
          issue.subject ?? 'deepin-linglong',
        ),
      ),
    LinglongEnvironmentIssueCode.localDataDetectionFailed =>
      LinglongEnvironmentIssueText(
        title: l10n.envIssueLocalDataDetectionTitle,
        description: l10n.envIssueLocalDataDetectionDescription,
      ),
    LinglongEnvironmentIssueCode.ostreeRepositoryCorrupted =>
      LinglongEnvironmentIssueText(
        title: l10n.envIssueLocalDataUnavailableTitle,
        description: l10n.envIssueLocalDataUnavailableDescription,
      ),
    LinglongEnvironmentIssueCode.storageNearlyFull =>
      LinglongEnvironmentIssueText(
        title: l10n.envIssueStorageSpaceTitle,
        description: l10n.envIssueStorageSpaceDescription(
          issue.subject ?? '/var/lib/linglong',
          issue.percent ?? 0,
        ),
      ),
    LinglongEnvironmentIssueCode.runningAppsBlockStorageMove =>
      LinglongEnvironmentIssueText(
        title: l10n.envIssueRunningAppsTitle,
        description: l10n.envIssueRunningAppsDescription(issue.count ?? 0),
      ),
  };
}

/// 根据稳定结果代码生成修复或迁移反馈文案。
String localizeLinglongEnvironmentRepairResult(
  AppLocalizations l10n,
  LinglongEnvironmentRepairResult result,
) {
  final partialCommits = result.count == null
      ? l10n.envPartialCommitsUnknown
      : l10n.envPartialCommitsCount(result.count!);

  return switch (result.code) {
    LinglongEnvironmentRepairResultCode.dataPermissionRepairCompleted =>
      l10n.envResultDataPermissionCompleted,
    LinglongEnvironmentRepairResultCode.dataPermissionRepairFailed =>
      l10n.envResultDataPermissionFailed,
    LinglongEnvironmentRepairResultCode.localDataRepairUnsupported =>
      l10n.envResultLocalDataUnsupported,
    LinglongEnvironmentRepairResultCode.localDataRepairCompleted =>
      result.usedLegacyFallback
          ? l10n.envResultLocalDataCompletedLegacy
          : l10n.envResultLocalDataCompleted,
    LinglongEnvironmentRepairResultCode.localDataRepairFailed =>
      l10n.envResultLocalDataFailed,
    LinglongEnvironmentRepairResultCode.localDataRepairChecksumMismatch =>
      l10n.envResultLocalDataChecksumMismatch,
    LinglongEnvironmentRepairResultCode.localDataRepullCompleted =>
      result.usedLegacyFallback
          ? l10n.envResultLocalDataRepullCompletedLegacy(partialCommits)
          : l10n.envResultLocalDataRepullCompleted(partialCommits),
    LinglongEnvironmentRepairResultCode.localDataRepullFailed =>
      result.usedLegacyFallback
          ? l10n.envResultLocalDataRepullFailedLegacy(partialCommits)
          : l10n.envResultLocalDataRepullFailed(partialCommits),
    LinglongEnvironmentRepairResultCode.localDataRepullChecksumMismatch =>
      result.usedLegacyFallback
          ? l10n.envResultLocalDataRepullChecksumMismatchLegacy(partialCommits)
          : l10n.envResultLocalDataRepullChecksumMismatch(partialCommits),
    LinglongEnvironmentRepairResultCode.storageMoveBlockedByRunningApps =>
      l10n.envResultStorageBlockedRunningApps(result.count ?? 0),
    LinglongEnvironmentRepairResultCode.storageMoveBlockedByActiveTask =>
      l10n.envResultStorageBlockedActiveTask,
    LinglongEnvironmentRepairResultCode.storageMoveBlockedByNamedActiveTask =>
      l10n.envResultStorageBlockedNamedTask(
        result.subject ?? l10n.envManagementUnknown,
      ),
    LinglongEnvironmentRepairResultCode.storageAlreadyBindMounted =>
      l10n.envResultStorageAlreadyBindMounted(
        result.subject ?? '/var/lib/linglong',
      ),
    LinglongEnvironmentRepairResultCode.storageTargetFilesystemUnavailable =>
      l10n.envResultStorageFilesystemUnavailable(
        result.subject ?? l10n.envManagementUnknown,
      ),
    LinglongEnvironmentRepairResultCode.storageSpaceUnknown =>
      l10n.envResultStorageSpaceUnknown,
    LinglongEnvironmentRepairResultCode.storageInsufficientSpace =>
      l10n.envResultStorageInsufficientSpace(
        result.requiredSpace ?? l10n.envManagementUnknown,
        result.availableSpace ?? l10n.envManagementUnknown,
      ),
    LinglongEnvironmentRepairResultCode.storageTargetInvalid =>
      _localizeStorageTargetFailure(l10n, result.storageTargetFailureReason),
    LinglongEnvironmentRepairResultCode.storageMoveCompleted =>
      l10n.envResultStorageMoveCompleted,
    LinglongEnvironmentRepairResultCode.storageMoveFailed =>
      l10n.envResultStorageMoveFailed,
    LinglongEnvironmentRepairResultCode.unexpectedFailure =>
      l10n.envResultUnexpectedFailure(result.diagnostic ?? l10n.errorUnknown),
  };
}

/// 把保存位置输入校验原因映射为当前语言文案。
String _localizeStorageTargetFailure(
  AppLocalizations l10n,
  LinglongStorageTargetFailureReason? reason,
) {
  return switch (reason) {
    LinglongStorageTargetFailureReason.notAbsolute =>
      l10n.envResultStorageTargetNotAbsolute,
    LinglongStorageTargetFailureReason.containsLineBreak =>
      l10n.envResultStorageTargetContainsLineBreak,
    LinglongStorageTargetFailureReason.unsafeSystemPath =>
      l10n.envResultStorageTargetUnsafeSystemPath,
    LinglongStorageTargetFailureReason.insideCurrentRoot =>
      l10n.envResultStorageTargetInsideCurrentRoot,
    null => l10n.envResultUnexpectedFailure(l10n.errorUnknown),
  };
}
