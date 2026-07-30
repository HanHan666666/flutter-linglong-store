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
              'll-package-manager 以 ${_probe.serviceUser} 用户运行，但玲珑数据目录或关键状态文件属主异常，'
              '可能导致仓库迁移、下载对象或创建 layer 失败。',
          repairAction: LinglongEnvironmentRepairAction.fixDataPermissions,
          rawDetail: dataPermission.detail,
        ),
      );
    }

    if (!localData.isAvailable || !localData.isOk) {
      final isDetectionFailure = !localData.isAvailable;
      issues.add(
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.ostreeRepositoryCorrupted,
          severity: LinglongEnvironmentIssueSeverity.error,
          title: isDetectionFailure ? '玲珑本地数据检测失败' : '玲珑本地数据不可用',
          description: isDetectionFailure
              ? '无法执行 linyaps 本地数据读取检查，请确认 ll-cli 和 package-manager 服务状态。'
              : '无法按 linyaps 运行路径读取已安装应用数据，可能影响应用列表、安装或运行。'
                    '请先确认玲珑数据目录权限和基础环境状态，再按需执行修复。',
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
          title: '玲珑保存位置空间不足',
          description:
              '当前 ${_probe.rootPath} 所在文件系统使用率约 ${storage.usagePercent}%，建议清理或移动保存位置。',
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
}
