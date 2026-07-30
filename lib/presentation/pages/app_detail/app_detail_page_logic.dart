/// 应用详情页的纯派生规则。
///
/// 该文件不依赖 Flutter Widget、Riverpod 或 Repository，只根据调用方提供的事实
/// 计算按钮状态、版本集合和任务匹配，避免多个详情区域重复解释业务状态。
library;

import '../../../core/utils/version_compare.dart';
import '../../../domain/models/app_version.dart';
import '../../../domain/models/install_button_state.dart';
import '../../../domain/models/install_progress.dart';
import '../../../domain/models/install_queue_state.dart';
import '../../../domain/models/install_task.dart';
import '../../../domain/models/installed_app.dart';

/// 汇总应用详情页需要复用的无副作用派生规则。
abstract final class AppDetailPageLogic {
  /// 根据安装任务、本地安装事实和更新事实计算头部主按钮状态。
  static InstallButtonState installButtonState(
    InstallTask? installTask, {
    required bool hasInstalledInstance,
    required bool hasUpdate,
  }) {
    if (installTask != null) {
      switch (installTask.status) {
        case InstallStatus.pending:
          return InstallButtonState.pending;
        case InstallStatus.downloading:
        case InstallStatus.installing:
          return InstallButtonState.installing;
        case InstallStatus.success:
          return hasInstalledInstance
              ? InstallButtonState.open
              : InstallButtonState.notInstalled;
        case InstallStatus.failed:
        case InstallStatus.cancelled:
        case InstallStatus.interrupted:
          break;
      }
    }

    if (hasInstalledInstance) {
      return hasUpdate ? InstallButtonState.update : InstallButtonState.open;
    }
    return InstallButtonState.notInstalled;
  }

  /// 判断更新列表或远端版本是否表明当前应用存在可用更新。
  static bool hasAvailableUpdate({
    required String appId,
    required bool hasInstalledInstance,
    required Set<String> updateAppIds,
    required String? remoteVersion,
    required String? highestInstalledVersion,
  }) {
    if (!hasInstalledInstance) {
      return false;
    }
    if (updateAppIds.contains(appId)) {
      return true;
    }
    if (remoteVersion == null ||
        remoteVersion.isEmpty ||
        highestInstalledVersion == null ||
        highestInstalledVersion.isEmpty) {
      return false;
    }
    return VersionCompare.greaterThan(remoteVersion, highestInstalledVersion);
  }

  /// 返回已安装版本集合中的最高版本。
  static String? highestInstalledVersion(Iterable<String> versions) {
    String? highestVersion;
    for (final version in versions) {
      if (highestVersion == null ||
          VersionCompare.greaterThan(version, highestVersion)) {
        highestVersion = version;
      }
    }
    return highestVersion;
  }

  /// 构建评论表单可选择的去重版本列表。
  static List<String> commentVersionOptions({
    required String? currentVersion,
    required List<AppVersion> versions,
  }) {
    final result = <String>[];

    void addVersion(String? version) {
      if (version == null || version.isEmpty || result.contains(version)) {
        return;
      }
      result.add(version);
    }

    addVersion(currentVersion);
    for (final version in versions) {
      addVersion(version.versionNo);
    }
    return result;
  }

  /// 解析评论表单的有效当前选择。
  static String? selectedCommentVersion({
    required String? requestedVersion,
    required List<String> versionOptions,
    required String? fallbackVersion,
  }) {
    if (requestedVersion != null && versionOptions.contains(requestedVersion)) {
      return requestedVersion;
    }
    if (versionOptions.isNotEmpty) {
      return versionOptions.first;
    }
    return fallbackVersion;
  }

  /// 返回详情状态条可复制的完整命令输出。
  static String? installLogCopyText(InstallTask? installTask) {
    final output = installTask?.commandOutput.trim();
    if (output == null || output.isEmpty) {
      return null;
    }
    return output;
  }

  /// 计算折叠状态下需要展示的最新版本和已安装历史版本。
  static List<AppVersion> collapsedVersions(
    List<AppVersion> allVersions,
    Set<String> installedVersions,
  ) {
    if (allVersions.isEmpty) {
      return [];
    }

    final latestVersion = allVersions.first;
    final result = <AppVersion>[latestVersion];
    for (final version in allVersions) {
      final isInstalled = installedVersions.contains(version.versionNo);
      final isNotLatest = version.versionNo != latestVersion.versionNo;
      if (isInstalled && isNotLatest) {
        result.add(version);
      }
    }
    return result;
  }

  /// 解析与指定版本行对应的活跃安装或更新任务。
  static InstallTask? versionInstallTask({
    required InstallQueueState installState,
    required String appId,
    required List<AppVersion> versions,
    required String? currentVersion,
    required String version,
  }) {
    if (appId.isEmpty) {
      return null;
    }
    final latestVersion = versions.isNotEmpty
        ? versions.first.versionNo
        : currentVersion;
    for (final task in installState.getActiveTasksForApp(appId)) {
      if (versionTaskMatchesRow(task, version, latestVersion: latestVersion)) {
        return task;
      }
    }
    return null;
  }

  /// 判断任务是否属于某一版本行。
  ///
  /// 显式版本直接精确匹配；无版本的默认安装或更新只匹配最新版本行。
  static bool versionTaskMatchesRow(
    InstallTask task,
    String version, {
    String? latestVersion,
  }) {
    final taskVersion = task.version?.trim();
    if (taskVersion != null && taskVersion.isNotEmpty) {
      return taskVersion == version;
    }
    if (latestVersion == null || latestVersion.isEmpty) {
      return false;
    }
    return version == latestVersion &&
        (task.kind == InstallTaskKind.install ||
            task.kind == InstallTaskKind.update);
  }

  /// 为多安装实例选择计算详情上下文匹配分数。
  ///
  /// arch、channel、module 分别使用 4、2、1 权重，保持历史版本和头部卸载一致。
  static int installedInstanceScore(
    InstalledApp app, {
    String? preferredArch,
    String? preferredChannel,
    String? preferredModule,
  }) {
    var score = 0;
    if (preferredArch != null && app.arch == preferredArch) {
      score += 4;
    }
    if (preferredChannel != null && app.channel == preferredChannel) {
      score += 2;
    }
    if (preferredModule != null && app.module == preferredModule) {
      score += 1;
    }
    return score;
  }
}
