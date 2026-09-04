/// 组装正式运行环境所需的 Data、Platform 和外部资源实现。
///
/// 这是生产依赖的唯一组合根；业务 Provider 只读取 Application 端口，不得在
/// 其他位置重新创建 Repository、Journal 或系统通知具体实现。
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../application/providers/application_dependency_providers.dart';
import '../core/platform/file_downloader.dart';
import '../core/platform/privileged_helper/privileged_helper_client.dart';
import '../core/platform/shell_command_executor.dart';
import '../core/storage/app_xdg_paths.dart';
import '../data/repositories/analytics_repository_impl.dart';
import '../data/repositories/app_repository_impl.dart';
import '../data/repositories/error_solution_repository_impl.dart';
import '../data/repositories/file_app_operation_journal_repository.dart';
import '../data/repositories/linglong_cli_repository_impl.dart';
import '../data/repositories/shared_preferences_legacy_app_operation_state_repository.dart';
import '../domain/repositories/app_self_update_gateways.dart';
import '../platform/notifications/linux_system_notification_gateway.dart';
import '../platform/self_update/linux_app_installation_probe.dart';
import '../platform/self_update/linux_app_update_installers.dart';
import '../platform/self_update/xdg_app_update_workspace.dart';

/// 创建正式应用根 ProviderScope 使用的完整依赖覆盖。
///
/// [sharedPreferences] 必须由 main 在数据迁移和 PreferencesService 初始化完成后
/// 传入，避免组合根自行破坏启动顺序。
List<Override> createProductionDependencyOverrides({
  required SharedPreferences sharedPreferences,
}) {
  // 自更新的系统命令统一复用一个无状态执行器，避免三个安装适配器各自创建边界。
  final selfUpdateCommandExecutor = ShellCommandExecutor();
  final selfUpdateNetworkClient = Dio();

  // 特权 helper 会话是应用生命周期单例（docs/47 §4.3）：install/update 的
  // 首次授权一次、后续复用都依赖同一进程句柄；两个 CLI Repository 覆盖共享
  // 同一客户端，防止 autoDispose 重建实例时重复拉起 pkexec。
  final privilegedHelper = PrivilegedHelperClient();

  return [
    sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    appRepositoryProvider.overrideWith((ref) => AppRepositoryImpl()),
    analyticsRepositoryProvider.overrideWith(
      (ref) => AnalyticsRepositoryImpl(),
    ),
    errorSolutionRepositoryProvider.overrideWith(
      (ref) => ErrorSolutionRepositoryImpl(),
    ),
    linglongCliRepositoryProvider.overrideWith((ref) {
      return LinglongCliRepositoryImpl(privilegedHelper: privilegedHelper);
    }),
    linglongRepositoryManagementRepositoryProvider.overrideWith((ref) {
      return LinglongCliRepositoryImpl(privilegedHelper: privilegedHelper);
    }),
    appOperationJournalRepositoryProvider.overrideWith((ref) {
      final journalPath = AppXdgPaths.resolveOperationJournalFilePath();
      if (journalPath == null) {
        throw StateError('无法解析 XDG 应用操作 Journal 路径');
      }
      return FileAppOperationJournalRepository(File(journalPath));
    }),
    legacyAppOperationStateRepositoryProvider.overrideWith(
      (ref) =>
          SharedPreferencesLegacyAppOperationStateRepository(sharedPreferences),
    ),
    systemNotificationGatewayProvider.overrideWith(
      (ref) => const LinuxSystemNotificationGateway(),
    ),
    appInstallationProbeProvider.overrideWith((ref) {
      return LinuxAppInstallationProbe(
        shellExecutor: selfUpdateCommandExecutor,
      );
    }),
    appUpdateWorkspaceFactoryProvider.overrideWith((ref) {
      return XdgAppUpdateWorkspaceFactory(
        downloader: FileDownloader(dio: selfUpdateNetworkClient),
      );
    }),
    appUpdateInstallersProvider.overrideWith((ref) {
      return <AppUpdateInstaller>[
        DpkgAppUpdateInstaller(selfUpdateCommandExecutor),
        RpmAppUpdateInstaller(selfUpdateCommandExecutor),
        AppImageAppUpdateInstaller(selfUpdateCommandExecutor),
      ];
    }),
  ];
}
