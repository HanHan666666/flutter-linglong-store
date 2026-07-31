/// 玲珑环境健康分析与问题分类。
///
/// 该文件只把基础环境和只读探测事实聚合成领域模型，不执行任何系统修复，
/// 从而让健康规则变化不影响特权命令实现。
library;

import '../../../domain/models/linglong_env_check_result.dart';
import '../../../domain/models/linglong_environment_management.dart';
import '../linglong_environment_service.dart';
import 'linglong_environment_probe.dart';

/// 聚合玲珑环境事实并生成设置页可消费的健康结论。
class LinglongEnvironmentHealthAnalyzer {
  /// 创建健康分析器。
  LinglongEnvironmentHealthAnalyzer({
    required LinglongEnvironmentService environmentService,
    required LinglongEnvironmentProbe probe,
    required DateTime Function() clock,
  }) : _environmentService = environmentService,
       _probe = probe,
       _clock = clock;

  final LinglongEnvironmentService _environmentService;
  final LinglongEnvironmentProbe _probe;
  final DateTime Function() _clock;

  /// 执行一次完整但只读的玲珑运行环境分析。
  Future<LinglongEnvironmentAnalysis> analyze() async {
    final envResult = await _environmentService.checkEnvironment();
    final runningAppCount = await _probe.loadRunningAppCount();
    final storage = await _probe.loadStorageInfo();
    final dataPermission = await _probe.checkDataPermissions();
    final localData = await _probe.checkLocalDataAccess();
    final issues = _buildIssues(
      envResult: envResult,
      storage: storage,
      dataPermission: dataPermission,
      localData: localData,
      runningAppCount: runningAppCount,
    );

    return LinglongEnvironmentAnalysis(
      envResult: envResult,
      storage: storage,
      dataPermission: dataPermission,
      ostree: localData,
      issues: issues,
      runningAppCount: runningAppCount,
      analyzedAt: _clock(),
    );
  }

  /// 把系统事实映射为稳定的问题代码和可执行修复入口。
  List<LinglongEnvironmentIssue> _buildIssues({
    required LinglongEnvCheckResult envResult,
    required LinglongStorageInfo storage,
    required LinglongDataPermissionCheckResult dataPermission,
    required LinglongOstreeCheckResult localData,
    required int runningAppCount,
  }) {
    final issues = <LinglongEnvironmentIssue>[];

    if (envResult.llCliVersion == null) {
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.llCliUnavailable,
          severity: LinglongEnvironmentIssueSeverity.error,
          rawDetail: envResult.errorDetail ?? envResult.errorMessage,
        ),
      );
    } else if (envResult.repoStatus == RepoStatus.notConfigured ||
        envResult.repos.isEmpty) {
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.repositoryNotConfigured,
          severity: LinglongEnvironmentIssueSeverity.error,
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
          repairAction: LinglongEnvironmentRepairAction.fixDataPermissions,
          rawDetail: dataPermission.detail,
          subject: _probe.serviceUser,
        ),
      );
    }

    if (!localData.isAvailable || !localData.isOk) {
      final isDetectionFailure = !localData.isAvailable;
      issues.add(
        LinglongEnvironmentIssue(
          code: isDetectionFailure
              ? LinglongEnvironmentIssueCode.localDataDetectionFailed
              : LinglongEnvironmentIssueCode.ostreeRepositoryCorrupted,
          severity: LinglongEnvironmentIssueSeverity.error,
          repairAction: LinglongEnvironmentRepairAction.ostreeFsckDelete,
          rawDetail: localData.detail,
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
          repairAction: LinglongEnvironmentRepairAction.moveStorageRoot,
          subject: _probe.rootPath,
          percent: storage.usagePercent,
        ),
      );
    }

    if (runningAppCount > 0) {
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.runningAppsBlockStorageMove,
          severity: LinglongEnvironmentIssueSeverity.warning,
          count: runningAppCount,
        ),
      );
    }

    return issues;
  }
}
