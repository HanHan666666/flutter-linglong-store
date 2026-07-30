/// 玲珑运行期环境管理应用服务门面。
///
/// 该文件为 Provider 提供稳定的环境分析、修复和保存位置迁移入口。具体命令、
/// 输出解析和脚本规则由单职责协作者维护，Presentation 无需感知内部组合。
library;

import '../../core/platform/shell_command_executor.dart';
import '../../domain/models/linglong_environment_management.dart';
import 'linglong_environment_management/linglong_data_permission_repair_service.dart';
import 'linglong_environment_management/linglong_environment_health_analyzer.dart';
import 'linglong_environment_management/linglong_environment_probe.dart';
import 'linglong_environment_management/linglong_management_command_workspace.dart';
import 'linglong_environment_management/linglong_ostree_repair_service.dart';
import 'linglong_environment_management/linglong_storage_migration_service.dart';
import 'linglong_environment_service.dart';

/// 环境管理可注入时钟。
///
/// 日志命名和分析时间统一复用该时钟，使生产与测试使用相同的装配路径。
typedef ManagementClock = DateTime Function();

/// 玲珑环境管理用例门面。
///
/// 上层只通过该门面发起环境分析和三类系统变更。门面保持原有公共协议，
/// 内部按健康分析、本地数据修复、权限修复和保存位置迁移分别委托。
class LinglongEnvironmentManagementService {
  /// 创建环境管理门面并装配内部协作者。
  ///
  /// [linglongRootPath] 和 [logDirectoryPath] 主要用于测试和受控部署覆盖；
  /// 默认路径继续使用 `/var/lib/linglong` 与应用 XDG 日志目录。
  LinglongEnvironmentManagementService({
    required ShellCommandExecutor executor,
    required LinglongEnvironmentService environmentService,
    ManagementClock? clock,
    String linglongRootPath = '/var/lib/linglong',
    String? logDirectoryPath,
  }) {
    final resolvedClock = clock ?? DateTime.now;
    final workspace = LinglongManagementCommandWorkspace(
      clock: resolvedClock,
      logDirectoryPath: logDirectoryPath,
    );
    final probe = LinglongEnvironmentProbe(
      executor: executor,
      workspace: workspace,
      rootPath: linglongRootPath,
    );

    _healthAnalyzer = LinglongEnvironmentHealthAnalyzer(
      environmentService: environmentService,
      probe: probe,
      clock: resolvedClock,
    );
    _ostreeRepairService = LinglongOstreeRepairService(
      executor: executor,
      workspace: workspace,
      rootPath: linglongRootPath,
    );
    _dataPermissionRepairService = LinglongDataPermissionRepairService(
      executor: executor,
      workspace: workspace,
      rootPath: linglongRootPath,
    );
    _storageMigrationService = LinglongStorageMigrationService(
      executor: executor,
      workspace: workspace,
      probe: probe,
    );
  }

  late final LinglongEnvironmentHealthAnalyzer _healthAnalyzer;
  late final LinglongOstreeRepairService _ostreeRepairService;
  late final LinglongDataPermissionRepairService _dataPermissionRepairService;
  late final LinglongStorageMigrationService _storageMigrationService;

  /// 分析当前玲珑运行环境，不执行会改变系统状态的命令。
  Future<LinglongEnvironmentAnalysis> analyzeEnvironment() {
    return _healthAnalyzer.analyze();
  }

  /// 执行玲珑本地数据清理、兼容降级和复验。
  Future<LinglongEnvironmentRepairResult> repairOstreeRepository({
    String? logFilePath,
  }) {
    return _ostreeRepairService.repair(logFilePath: logFilePath);
  }

  /// 修复玲珑数据目录属主和运行所需的 owner 写权限。
  Future<LinglongEnvironmentRepairResult> repairLinglongDataPermissions({
    String? logFilePath,
  }) {
    return _dataPermissionRepairService.repair(logFilePath: logFilePath);
  }

  /// 校验前置条件并按 systemd bind mount 方案移动玲珑保存位置。
  Future<LinglongEnvironmentRepairResult> moveLinglongStorage(
    String targetPath, {
    String? logFilePath,
  }) {
    return _storageMigrationService.move(targetPath, logFilePath: logFilePath);
  }

  /// 构建保存位置迁移脚本。
  ///
  /// 该兼容入口供现有诊断和测试使用；业务调用应通过 [moveLinglongStorage]，
  /// 以确保运行中应用、挂载和磁盘空间前置检查不会被绕过。
  String buildStorageMigrationScript(String targetPath) {
    return _storageMigrationService.buildScript(targetPath);
  }

  /// 构建玲珑数据目录权限修复脚本。
  ///
  /// 该兼容入口不执行脚本，实际修复必须通过 [repairLinglongDataPermissions]。
  String buildDataPermissionRepairScript() {
    return _dataPermissionRepairService.buildScript();
  }

  /// 构建 fsck partial commit 重新拉取和复验脚本。
  ///
  /// 该兼容入口不改变系统状态，实际流程必须通过 [repairOstreeRepository]。
  String buildOstreePartialRepullScript() {
    return _ostreeRepairService.buildPartialRepullScript();
  }
}
