import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/di/providers.dart';
import 'app_collection_sync_provider.dart';
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
  );
}
