/// 声明 Application 层使用的外部依赖端口。
///
/// 本文件只引用稳定接口，不创建 Data 或 Platform 具体实现。正式实现由应用
/// bootstrap 组合根统一覆盖，测试则按实际触达范围注入 Fake。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/app_operation_journal_repository.dart';
import '../../domain/repositories/app_repository.dart';
import '../../domain/repositories/error_solution_repository.dart';
import '../../domain/repositories/linglong_cli_repository.dart';
import '../../domain/repositories/linglong_repository_management_repository.dart';
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

/// 桌面系统通知投递端口。
final systemNotificationGatewayProvider = Provider<SystemNotificationGateway>((
  ref,
) {
  return _missingDependency('systemNotificationGatewayProvider');
});

/// 为遗漏的根装配提供包含端口名称的确定性错误。
Never _missingDependency(String providerName) {
  throw StateError('应用依赖未注入: $providerName');
}
