import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/di/providers.dart';
import '../../presentation/widgets/download_manager_dialog.dart';
import 'app_collection_sync_provider.dart';
import 'install_queue_provider.dart';
import 'installed_apps_provider.dart';
import 'running_process_provider.dart';
import '../services/app_uninstall_service.dart';

part 'app_uninstall_provider.g.dart';

/// 应用卸载服务 Provider
@riverpod
AppUninstallService appUninstallService(Ref ref) {
  final runningProcess = ref.read(runningProcessProvider.notifier);
  final installedApps = ref.read(installedAppsProvider.notifier);
  final cliRepository = ref.read(linglongCliRepositoryProvider);
  final analyticsRepository = ref.read(analyticsRepositoryProvider);
  final collectionSyncService = ref.read(appCollectionSyncServiceProvider);

  return AppUninstallService(
    readRunningApps: () => runningProcess.currentApps,
    killRunningApp: runningProcess.killApp,
    uninstallApp: cliRepository.uninstallApp,
    removeInstalledApp: installedApps.removeApp,
    syncAfterUninstall: collectionSyncService.syncAfterSuccessfulOperation,
    reportUninstall: analyticsRepository.reportUninstall,
    // 读取当前正在执行（非排队等待）的安装/更新任务
    readActiveInstallTask: () {
      final currentTask = ref.read(installQueueProvider).currentTask;
      // 只有 isProcessing 的任务才触发拦截（pending/排队 任务不阻断）
      if (currentTask == null || !currentTask.isProcessing) return null;
      final name = currentTask.appName.isNotEmpty
          ? currentTask.appName
          : currentTask.appId;
      return (name, currentTask.appId);
    },
    // 打开下载管理弹窗（在拦截后由用户选择触发）
    openDownloadManager: showDownloadManagerDialog,
  );
}
