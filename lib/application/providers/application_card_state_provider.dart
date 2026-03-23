import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/version_compare.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_task.dart';
import '../../presentation/widgets/install_button.dart';
import 'install_queue_provider.dart';
import 'installed_apps_provider.dart';
import 'update_apps_provider.dart';

/// 页面级卡片状态索引。
///
/// 只聚合已安装列表、更新列表和安装队列的轻量索引，避免卡片组件直接订阅多个全局 Provider。
class ApplicationCardStateIndex {
  const ApplicationCardStateIndex({
    required this.installedVersionByAppId,
    required this.updateAppIds,
    required this.activeTasksByAppId,
  });

  final Map<String, String> installedVersionByAppId;
  final Set<String> updateAppIds;
  final Map<String, InstallTask> activeTasksByAppId;

  /// 解析单个应用卡片需要展示的状态。
  ResolvedApplicationCardState resolve({
    required String appId,
    String? latestVersion,
  }) {
    if (appId.isEmpty) {
      return const ResolvedApplicationCardState(
        buttonState: InstallButtonState.notInstalled,
      );
    }

    final installedVersion = installedVersionByAppId[appId];
    final isInstalled = installedVersion != null;
    final hasVersionUpdate =
        latestVersion != null &&
        latestVersion.isNotEmpty &&
        installedVersion != null &&
        VersionCompare.greaterThan(latestVersion, installedVersion);
    final hasUpdate = updateAppIds.contains(appId) || hasVersionUpdate;
    final activeTask = activeTasksByAppId[appId];
    final isInstalling = activeTask != null;
    final activeButtonState = switch (activeTask?.status) {
      InstallStatus.pending => InstallButtonState.pending,
      InstallStatus.downloading || InstallStatus.installing =>
        InstallButtonState.installing,
      _ => null,
    };

    return ResolvedApplicationCardState(
      buttonState:
          activeButtonState ??
          (!isInstalled
              ? InstallButtonState.notInstalled
              : (hasUpdate
                    ? InstallButtonState.update
                    : InstallButtonState.open)),
      isInstalled: isInstalled,
      hasUpdate: hasUpdate,
      isInstalling: isInstalling,
      progress: activeTask?.progress ?? 0.0,
    );
  }
}

/// 卡片解析后的轻量状态。
class ResolvedApplicationCardState {
  const ResolvedApplicationCardState({
    required this.buttonState,
    this.isInstalled = false,
    this.hasUpdate = false,
    this.isInstalling = false,
    this.progress = 0.0,
  });

  final InstallButtonState buttonState;
  final bool isInstalled;
  final bool hasUpdate;
  final bool isInstalling;
  final double progress;
}

final applicationCardStateIndexProvider = Provider<ApplicationCardStateIndex>((
  ref,
) {
  final installedApps = ref.watch(installedAppsProvider).apps;
  final updateApps = ref.watch(updateAppsProvider).apps;
  final installQueue = ref.watch(installQueueProvider);

  final installedVersionByAppId = <String, String>{};
  for (final app in installedApps) {
    final currentVersion = installedVersionByAppId[app.appId];
    if (currentVersion == null ||
        VersionCompare.greaterThan(app.version, currentVersion)) {
      installedVersionByAppId[app.appId] = app.version;
    }
  }

  final updateAppIds = updateApps.map((app) => app.appId).toSet();
  final activeTasksByAppId = <String, InstallTask>{};

  void addActiveTask(InstallTask? task) {
    if (task == null || task.appId.isEmpty) {
      return;
    }
    switch (task.status) {
      case InstallStatus.pending:
      case InstallStatus.downloading:
      case InstallStatus.installing:
        activeTasksByAppId[task.appId] = task;
        break;
      case InstallStatus.success:
      case InstallStatus.failed:
      case InstallStatus.cancelled:
        break;
    }
  }

  addActiveTask(installQueue.currentTask);
  for (final task in installQueue.queue) {
    addActiveTask(task);
  }

  return ApplicationCardStateIndex(
    installedVersionByAppId: installedVersionByAppId,
    updateAppIds: updateAppIds,
    activeTasksByAppId: activeTasksByAppId,
  );
});
