/// 应用详情页的异步交互编排。
///
/// 该文件集中处理安装队列、重装/降级确认、两类卸载、评论、截图、分享和快捷方式。
/// 控制器不保存 `BuildContext`，只调用现有 Provider、Repository 和统一流程。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../application/providers/app_detail_provider.dart';
import '../../../application/providers/application_dependency_providers.dart'
    show linglongCliRepositoryProvider;
import '../../../application/providers/app_uninstall_provider.dart';
import '../../../application/providers/global_provider.dart';
import '../../../application/providers/installed_apps_provider.dart';
import '../../../application/providers/install_queue_provider.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/app_notification_helpers.dart';
import '../../../core/utils/version_compare.dart';
import '../../../domain/models/app_detail.dart' as dm;
import '../../../domain/models/install_button_state.dart';
import '../../../domain/models/install_task.dart';
import '../../../domain/models/installed_app.dart';
import '../../helpers/app_uninstall_flow.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/install_to_download_flyout.dart';
import 'app_detail_page_logic.dart';
import 'screenshot_preview_lightbox.dart';

/// 编排应用详情页所有异步用户动作。
class AppDetailPageActions {
  /// 创建详情页动作控制器。
  const AppDetailPageActions(this.ref);

  /// 当前详情页所属的 Riverpod 引用。
  final WidgetRef ref;

  /// 提交评论并展示成功或失败反馈。
  Future<bool> submitComment(
    BuildContext context, {
    required String appId,
    required String remark,
    String? version,
  }) async {
    try {
      await ref
          .read(appDetailProvider(appId).notifier)
          .submitComment(remark, version: version);
      if (!context.mounted) {
        return false;
      }
      showAppNotification(
        context,
        AppLocalizations.of(context)?.commentSubmitSuccess ?? '评论已提交',
      );
      return true;
    } catch (error) {
      if (!context.mounted) {
        return false;
      }
      showAppError(
        context,
        AppLocalizations.of(context)?.commentSubmitFailed(error.toString()) ??
            '评论提交失败: $error',
      );
      return false;
    }
  }

  /// 根据头部按钮状态执行默认安装、更新或打开应用。
  void handlePrimaryAction(
    BuildContext context, {
    required InstalledApp app,
    required InstallButtonState buttonState,
    required GlobalKey installSourceKey,
  }) {
    switch (buttonState) {
      case InstallButtonState.notInstalled:
        final taskId = ref
            .read(installQueueProvider.notifier)
            .enqueueInstall(
              appId: app.appId,
              appName: app.name,
              icon: app.icon,
            );
        _triggerInstallFlyout(
          context,
          app,
          taskId: taskId,
          installSourceKey: installSourceKey,
        );
        return;
      case InstallButtonState.update:
        final taskId = ref
            .read(installQueueProvider.notifier)
            .enqueueOperation(
              kind: InstallTaskKind.update,
              appId: app.appId,
              appName: app.name,
              icon: app.icon,
            );
        _triggerInstallFlyout(
          context,
          app,
          taskId: taskId,
          installSourceKey: installSourceKey,
        );
        return;
      case InstallButtonState.installed:
      case InstallButtonState.open:
        openApp(context, app);
        return;
      case InstallButtonState.installing:
      case InstallButtonState.pending:
        return;
      case InstallButtonState.uninstall:
        showHeaderUninstallDialog(context, app);
        return;
    }
  }

  /// 取消当前应用的安装或更新任务。
  void cancelInstall(InstalledApp app) {
    ref.read(installQueueProvider.notifier).cancelTask(app.appId);
  }

  /// 通过仓库端口打开应用并展示启动反馈。
  Future<void> openApp(BuildContext context, InstalledApp app) async {
    try {
      await ref.read(linglongCliRepositoryProvider).runApp(app.appId);
      if (context.mounted) {
        showAppLaunching(context, app.name);
      }
    } catch (error) {
      if (context.mounted) {
        showAppLaunchFailed(context, error.toString());
      }
    }
  }

  /// 安装指定历史版本，并处理同版本重装和降级确认。
  Future<void> installVersion(
    BuildContext context, {
    required InstalledApp app,
    required String version,
    required GlobalKey installSourceKey,
  }) async {
    final installedVersions = ref
        .read(installedAppsListProvider)
        .where((candidate) => candidate.appId == app.appId)
        .map((candidate) => candidate.version)
        .toList();
    var shouldForceInstall = false;

    if (installedVersions.contains(version)) {
      final confirmed = await ConfirmDialog.showReinstallConfirm(
        context,
        appName: app.name,
        version: version,
      );
      if (confirmed != true || !context.mounted) return;
      shouldForceInstall = true;
    } else if (installedVersions.isNotEmpty) {
      final highestInstalled = installedVersions.reduce(
        (left, right) => VersionCompare.greaterThan(left, right) ? left : right,
      );
      if (VersionCompare.lessThan(version, highestInstalled)) {
        final confirmed = await ConfirmDialog.showDowngradeConfirm(
          context,
          appName: app.name,
          currentVersion: highestInstalled,
          targetVersion: version,
        );
        if (confirmed != true || !context.mounted) return;
        shouldForceInstall = true;
      }
    }

    final taskId = ref
        .read(installQueueProvider.notifier)
        .enqueueInstall(
          appId: app.appId,
          appName: app.name,
          icon: app.icon,
          version: version,
          force: shouldForceInstall,
        );
    _triggerInstallFlyout(
      context,
      app,
      taskId: taskId,
      installSourceKey: installSourceKey,
    );
  }

  /// 卸载版本列表中指定的本地安装实例。
  Future<void> uninstallVersion(
    BuildContext context, {
    required InstalledApp currentApp,
    required dm.AppDetail? detail,
    required String version,
  }) async {
    final targetApp = _resolveInstalledVersionTarget(
      currentApp: currentApp,
      detail: detail,
      version: version,
    );
    if (targetApp == null) {
      if (!context.mounted) return;
      showAppError(
        context,
        AppLocalizations.of(context)?.versionInstallTargetMissing ??
            '未找到对应已安装版本，请刷新后重试',
      );
      return;
    }
    await _showUninstallDialog(context, targetApp);
  }

  /// 解析真实已安装实例后执行头部整体卸载。
  ///
  /// 详情接口版本不代表本地版本，因此 ll-cli 命令必须 `includeVersion: false`。
  Future<void> showHeaderUninstallDialog(
    BuildContext context,
    InstalledApp app,
  ) async {
    final target = _resolvePrimaryInstalledInstance(app);
    if (target == null) {
      if (!context.mounted) return;
      showAppError(
        context,
        AppLocalizations.of(context)?.versionInstallTargetMissing ??
            '未找到对应已安装版本，请刷新后重试',
      );
      return;
    }
    await _showUninstallDialog(context, target, includeVersion: false);
  }

  /// 分享应用链接；系统分享不可用时回退到剪贴板。
  Future<void> shareApp(BuildContext context, InstalledApp app) async {
    final l10n = AppLocalizations.of(context);
    final arch = ref.read(globalAppProvider).arch ?? 'x86_64';
    final shareUrl =
        'https://store.linyaps.org.cn/apps/${app.appId}?arch=$arch';

    try {
      await Share.shareUri(Uri.parse(shareUrl));
      return;
    } catch (_) {
      // Linux 系统分享不可用时继续使用剪贴板回退。
    }

    try {
      await Clipboard.setData(ClipboardData(text: shareUrl));
      if (!context.mounted) return;
      showAppSuccess(context, l10n?.linkCopied ?? '链接已复制');
    } catch (_) {
      if (!context.mounted) return;
      showAppError(context, l10n?.shareFailed ?? '分享失败');
    }
  }

  /// 在主窗口内打开截图灯箱并处理加载异常。
  Future<void> showScreenshotPreview(
    BuildContext context, {
    required List<String> screenshots,
    required int initialIndex,
  }) async {
    try {
      await showScreenshotPreviewLightbox(
        context,
        screenshots: screenshots,
        initialIndex: initialIndex,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to open screenshot preview lightbox',
        error,
        stackTrace,
      );
      if (!context.mounted) return;
      showAppError(context, AppLocalizations.of(context)?.loadFailed ?? '加载失败');
    }
  }

  /// 创建符合 XDG 目录规则的桌面快捷方式并展示结果。
  Future<void> createShortcut(BuildContext context, InstalledApp app) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(linglongCliRepositoryProvider)
          .createDesktopShortcut(app.appId);
      if (!context.mounted) return;
      showAppSuccess(context, l10n?.shortcutCreated ?? '快捷方式已创建');
    } catch (error) {
      if (!context.mounted) return;
      showAppError(
        context,
        l10n?.shortcutCreateFailed(error.toString()) ?? '创建失败: $error',
      );
    }
  }

  /// 在任务成功入队后从头部锚点触发下载中心飞入动画。
  void _triggerInstallFlyout(
    BuildContext context,
    InstalledApp app, {
    required String taskId,
    required GlobalKey installSourceKey,
  }) {
    if (taskId.isEmpty) {
      return;
    }
    final flyoutController = InstallToDownloadFlyoutLayer.maybeOf(context);
    final launched = flyoutController?.launch(
      sourceKey: installSourceKey,
      appId: app.appId,
      appName: app.name,
      iconUrl: app.icon,
    );
    if (launched != true) {
      flyoutController?.pulseDownloadCenter();
    }
  }

  /// 从真实已安装列表解析指定版本的上下文最优实例。
  InstalledApp? _resolveInstalledVersionTarget({
    required InstalledApp currentApp,
    required dm.AppDetail? detail,
    required String version,
  }) {
    final matches = ref
        .read(installedAppsProvider)
        .apps
        .where((app) => app.appId == currentApp.appId && app.version == version)
        .toList();
    if (matches.isEmpty) {
      AppLogger.warning(
        '[AppDetail] 版本卸载失败：未找到目标安装实例 ${currentApp.appId}@$version',
      );
      return null;
    }
    if (matches.length == 1) {
      return matches.first;
    }

    _sortInstalledInstances(
      matches,
      preferredArch: detail?.arch ?? currentApp.arch,
      preferredChannel: detail?.channel ?? currentApp.channel,
      preferredModule: detail?.module ?? currentApp.module,
    );
    AppLogger.warning(
      '[AppDetail] 版本卸载命中多个安装实例，已选择上下文最优实例: '
      '${currentApp.appId}@$version (${matches.length} candidates)',
    );
    return matches.first;
  }

  /// 从真实已安装列表解析头部整体卸载使用的主实例。
  InstalledApp? _resolvePrimaryInstalledInstance(InstalledApp app) {
    final matches = ref
        .read(installedAppsProvider)
        .apps
        .where((installed) => installed.appId == app.appId)
        .toList();
    if (matches.isEmpty) {
      AppLogger.warning('[AppDetail] 头部卸载失败：未找到已安装实例 ${app.appId}');
      return null;
    }
    if (matches.length == 1) {
      return matches.first;
    }

    _sortInstalledInstances(
      matches,
      preferredArch: app.arch,
      preferredChannel: app.channel,
      preferredModule: app.module,
    );
    AppLogger.warning(
      '[AppDetail] 头部卸载命中多个安装实例，已选择上下文最优实例: '
      '${app.appId} (${matches.length} candidates)',
    );
    return matches.first;
  }

  /// 按统一的 arch/channel/module 匹配分数原地排序候选实例。
  void _sortInstalledInstances(
    List<InstalledApp> matches, {
    String? preferredArch,
    String? preferredChannel,
    String? preferredModule,
  }) {
    matches.sort((left, right) {
      final leftScore = AppDetailPageLogic.installedInstanceScore(
        left,
        preferredArch: preferredArch,
        preferredChannel: preferredChannel,
        preferredModule: preferredModule,
      );
      final rightScore = AppDetailPageLogic.installedInstanceScore(
        right,
        preferredArch: preferredArch,
        preferredChannel: preferredChannel,
        preferredModule: preferredModule,
      );
      return rightScore.compareTo(leftScore);
    });
  }

  /// 通过统一卸载流程执行运行中检测、确认、进程终止和卸载。
  Future<void> _showUninstallDialog(
    BuildContext context,
    InstalledApp app, {
    bool includeVersion = true,
  }) async {
    final service = ref.read(appUninstallServiceProvider);
    final success = await AppUninstallFlow.run(
      context,
      app,
      service,
      includeVersion: includeVersion,
    );
    if (!context.mounted) return;
    if (success) {
      showAppSuccess(context, '${app.name} 已卸载');
    }
  }
}
