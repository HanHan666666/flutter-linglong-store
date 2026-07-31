/// 声明 Application 层使用的外部依赖端口。
///
/// 本文件只引用稳定接口，不创建 Data 或 Platform 具体实现。正式实现由应用
/// bootstrap 组合根统一覆盖，测试则按实际触达范围注入 Fake。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/app_self_update_gateways.dart';
import '../../domain/repositories/app_operation_journal_repository.dart';
import '../../domain/repositories/app_repository.dart';
import '../../domain/repositories/error_solution_repository.dart';
import '../../domain/repositories/linglong_cli_repository.dart';
import '../../domain/repositories/linglong_repository_management_repository.dart';
import '../../domain/repositories/legacy_app_operation_state_repository.dart';
import '../../domain/repositories/system_notification_gateway.dart';

/// 应用启动阶段初始化的用户偏好存储端口。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  return _missingDependency('sharedPreferencesProvider');
});

/// 商店后端应用数据仓储端口。
final appRepositoryProvider = Provider<AppRepository>((ref) {
  return _missingDependency('appRepositoryProvider');
});

/// 匿名统计仓储端口。
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return _missingDependency('analyticsRepositoryProvider');
});

/// 安装错误解决方案仓储端口。
final errorSolutionRepositoryProvider = Provider<ErrorSolutionRepository>((
  ref,
) {
  return _missingDependency('errorSolutionRepositoryProvider');
});

/// 玲珑命令能力端口。
final linglongCliRepositoryProvider = Provider<LinglongCliRepository>((ref) {
  return _missingDependency('linglongCliRepositoryProvider');
});

/// 玲珑仓库配置管理端口。
final linglongRepositoryManagementRepositoryProvider =
    Provider<LinglongRepositoryManagementRepository>((ref) {
      return _missingDependency(
        'linglongRepositoryManagementRepositoryProvider',
      );
    });

/// 应用操作完整快照 Journal 端口。
final appOperationJournalRepositoryProvider =
    Provider<AppOperationJournalRepository>((ref) {
      return _missingDependency('appOperationJournalRepositoryProvider');
    });

/// 旧版 SharedPreferences 操作队列迁移端口。
final legacyAppOperationStateRepositoryProvider =
    Provider<LegacyAppOperationStateRepository>((ref) {
      return _missingDependency('legacyAppOperationStateRepositoryProvider');
    });

/// 桌面系统通知投递端口。
final systemNotificationGatewayProvider = Provider<SystemNotificationGateway>((
  ref,
) {
  return _missingDependency('systemNotificationGatewayProvider');
});

/// 当前进程安装身份探测端口。
final appInstallationProbeProvider = Provider<AppInstallationProbe>((ref) {
  return _missingDependency('appInstallationProbeProvider');
});

/// XDG 自更新工作区工厂端口。
final appUpdateWorkspaceFactoryProvider = Provider<AppUpdateWorkspaceFactory>((
  ref,
) {
  return _missingDependency('appUpdateWorkspaceFactoryProvider');
});

/// DEB、RPM 与 AppImage 安装适配器集合。
final appUpdateInstallersProvider = Provider<List<AppUpdateInstaller>>((ref) {
  return _missingDependency('appUpdateInstallersProvider');
});

/// 为遗漏的根装配提供包含端口名称的确定性错误。
Never _missingDependency(String providerName) {
  throw StateError('应用依赖未注入: $providerName');
}
