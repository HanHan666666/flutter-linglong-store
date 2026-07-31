/// 应用详情页公共入口和 Provider 容器。
///
/// 该文件只管理页面生命周期、全局状态聚合、评论版本选择和区域组合。
/// 纯派生规则、异步动作以及头部、内容、评论和版本区域位于独立文件。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_detail_provider.dart';
import '../../../application/providers/installed_apps_provider.dart';
import '../../../application/providers/install_queue_provider.dart';
import '../../../application/providers/linglong_env_provider.dart';
import '../../../application/providers/network_speed_provider.dart';
import '../../../application/providers/update_apps_provider.dart';
import '../../../core/config/routes.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/install_button_state.dart';
import '../../../domain/models/install_queue_state.dart';
import '../../../domain/models/install_task.dart';
import '../../../domain/models/installed_app.dart';
import '../../../domain/models/linux_distribution.dart';
import 'app_detail_comments_panel.dart';
import 'app_detail_content_sections.dart';
import 'app_detail_header_section.dart';
import 'app_detail_page_actions.dart';
import 'app_detail_page_logic.dart';
import 'app_detail_version_section.dart';

export 'app_detail_content_sections.dart'
    show shouldShowDescriptionExpandButton;

/// 展示指定玲珑应用的完整详情。
class AppDetailPage extends ConsumerStatefulWidget {
  /// 创建应用详情页。
  const AppDetailPage({required this.appId, this.appInfo, super.key});

  /// 应用 ID。
  final String appId;

  /// 列表页可选传入的应用摘要，用于首屏快速展示。
  final InstalledApp? appInfo;

  @override
  ConsumerState<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends ConsumerState<AppDetailPage> {
  String? _selectedCommentVersion;
  final GlobalKey _installSourceKey = GlobalKey(
    debugLabel: 'app-detail-install-source',
  );
  late final AppDetailPageActions _actions;

  @override
  void initState() {
    super.initState();
    _actions = AppDetailPageActions(ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(appDetailProvider(widget.appId).notifier)
          .loadDetail(widget.appInfo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(appDetailProvider(widget.appId));
    final installState = ref.watch(installQueueProvider);
    final installedApps = ref
        .watch(installedAppsProvider)
        .apps
        .where((app) => app.appId == widget.appId)
        .toList(growable: false);
    final installedVersions = installedApps.map((app) => app.version).toSet();
    final hasInstalledInstance = installedVersions.isNotEmpty;
    final updateAppIds = hasInstalledInstance
        ? ref.watch(updateAppsProvider).apps.map((app) => app.appId).toSet()
        : const <String>{};
    final distribution = ref.watch(
      linglongEnvProvider.select(
        (state) => state.result?.distribution ?? LinuxDistribution.unknown,
      ),
    );
    final installTask = installState.getAppInstallStatus(widget.appId);
    final hasUpdate = AppDetailPageLogic.hasAvailableUpdate(
      appId: widget.appId,
      hasInstalledInstance: hasInstalledInstance,
      updateAppIds: updateAppIds,
      remoteVersion: detailState.appDetail?.version ?? detailState.app?.version,
      highestInstalledVersion: AppDetailPageLogic.highestInstalledVersion(
        installedVersions,
      ),
    );
    final buttonState = AppDetailPageLogic.installButtonState(
      installTask,
      hasInstalledInstance: hasInstalledInstance,
      hasUpdate: hasUpdate,
    );
    final statusMessage = installTask == null
        ? null
        : ref
              .watch(installMessagesProvider)
              .messageForTask(installTask, distribution: distribution);
    final downloadSpeed = buttonState == InstallButtonState.installing
        ? (installTask?.cliSpeed ?? ref.watch(networkSpeedProvider).formatted)
        : '';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: l10n.a11yAppDetailPage,
          child: Text(detailState.app?.name ?? l10n.appDetailTitle),
        ),
      ),
      body: _buildBody(
        context,
        detailState: detailState,
        installState: installState,
        installTask: installTask,
        installedVersions: installedVersions,
        installTaskStatusMessage: statusMessage,
        buttonState: buttonState,
        downloadSpeed: downloadSpeed,
        hasInstalledInstance: hasInstalledInstance,
      ),
    );
  }

  /// 根据详情加载状态组合页面各区域。
  Widget _buildBody(
    BuildContext context, {
    required AppDetailState detailState,
    required InstallQueueState installState,
    required InstallTask? installTask,
    required Set<String> installedVersions,
    required String? installTaskStatusMessage,
    required InstallButtonState buttonState,
    required String downloadSpeed,
    required bool hasInstalledInstance,
  }) {
    if (detailState.isLoading && detailState.app == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (detailState.error != null && detailState.app == null) {
      return AppDetailErrorView(
        error: detailState.error!,
        onRetry: () {
          ref
              .read(appDetailProvider(widget.appId).notifier)
              .loadDetail(widget.appInfo);
        },
      );
    }
    if (detailState.app == null) {
      return Center(child: Text(AppLocalizations.of(context)!.appNotFound));
    }

    final app = detailState.app!;
    final commentVersionOptions = AppDetailPageLogic.commentVersionOptions(
      currentVersion: app.version,
      versions: detailState.versions,
    );
    final selectedCommentVersion = AppDetailPageLogic.selectedCommentVersion(
      requestedVersion: _selectedCommentVersion,
      versionOptions: commentVersionOptions,
      fallbackVersion: app.version,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDetailHeaderSection(
            app: app,
            installSourceKey: _installSourceKey,
            buttonState: buttonState,
            installTask: installTask,
            downloadSpeed: downloadSpeed,
            showInstalledActions: hasInstalledInstance,
            description: detailState.appDetail?.description,
            tags: detailState.appDetail?.tags ?? const [],
            statusMessage: installTaskStatusMessage,
            onTagPressed: context.goToTagSearch,
            onPrimaryPressed: () {
              _actions.handlePrimaryAction(
                context,
                app: app,
                buttonState: buttonState,
                installSourceKey: _installSourceKey,
              );
            },
            onCancel: () => _actions.cancelInstall(app),
            onCreateShortcut: () => _actions.createShortcut(context, app),
            onUninstall: () {
              _actions.showHeaderUninstallDialog(context, app);
            },
            onShare: () => _actions.shareApp(context, app),
          ),
          const Divider(height: 1),
          AppDetailScreenshotsSection(
            screenshots: detailState.screenshots,
            onOpenPreview: (initialIndex) {
              _actions.showScreenshotPreview(
                context,
                screenshots: detailState.screenshotUrls,
                initialIndex: initialIndex,
              );
            },
          ),
          const Divider(height: 1),
          AppDetailDescriptionSection(
            app: app,
            detail: detailState.appDetail,
            isExpanded: detailState.isDescriptionExpanded,
            onToggleExpanded: () {
              ref
                  .read(appDetailProvider(widget.appId).notifier)
                  .toggleDescription();
            },
          ),
          const Divider(height: 1),
          AppDetailMetadataSection(app: app, detail: detailState.appDetail),
          const Divider(height: 1),
          AppDetailCommentsPanel(
            comments: detailState.comments,
            versionOptions: commentVersionOptions,
            selectedVersion: selectedCommentVersion,
            isLoading: detailState.isLoadingComments,
            canSubmitComment: hasInstalledInstance,
            errorMessage: detailState.commentsError,
            onVersionChanged: (value) {
              setState(() {
                _selectedCommentVersion = value;
              });
            },
            onRetry: () {
              ref
                  .read(appDetailProvider(widget.appId).notifier)
                  .retryComments();
            },
            onSubmit: (remark, version) => _actions.submitComment(
              context,
              appId: widget.appId,
              remark: remark,
              version: version,
            ),
          ),
          const Divider(height: 1),
          AppDetailVersionSection(
            app: app,
            versions: detailState.versions,
            isLoading: detailState.isLoadingVersions,
            errorMessage: detailState.versionsError,
            isExpanded: detailState.isVersionListExpanded,
            installState: installState,
            installedVersions: installedVersions,
            onToggleExpanded: () {
              ref
                  .read(appDetailProvider(widget.appId).notifier)
                  .toggleVersionList();
            },
            onRetry: () {
              ref
                  .read(appDetailProvider(widget.appId).notifier)
                  .retryVersions();
            },
            onInstallVersion: (version) {
              _actions.installVersion(
                context,
                app: app,
                version: version,
                installSourceKey: _installSourceKey,
              );
            },
            onUninstallVersion: (version) {
              _actions.uninstallVersion(
                context,
                currentApp: app,
                detail: detailState.appDetail,
                version: version,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
