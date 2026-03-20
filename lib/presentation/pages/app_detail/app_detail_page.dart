import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/utils/version_compare.dart';
import '../../../domain/models/installed_app.dart';
import '../../../domain/models/install_task.dart';
import '../../../domain/models/install_progress.dart';
import '../../../data/models/api_dto.dart';
import '../../../data/repositories/app_repository_impl.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_detail_secondary_actions.dart';
import '../../widgets/app_detail_info_section.dart';
import '../../widgets/install_button.dart';
import '../../widgets/confirm_dialog.dart';
import '../../../core/di/providers.dart';
import '../../../application/providers/installed_apps_provider.dart';
import '../../../application/providers/network_speed_provider.dart';
import '../../../application/providers/running_process_provider.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/utils/format_utils.dart';

part 'app_detail_page.g.dart';

/// 应用详情状态
class AppDetailState {
  const AppDetailState({
    this.app,
    this.appDetail,
    this.screenshots = const [],
    this.versions = const [],
    this.isLoading = false,
    this.isLoadingVersions = false,
    this.versionsError,
    this.error,
    this.isDescriptionExpanded = false,
  });

  final InstalledApp? app;
  final AppDetailDTO? appDetail;
  final List<AppScreenshotDTO> screenshots;
  final List<AppVersionDTO> versions;
  final bool isLoading;
  final bool isLoadingVersions;
  final String? versionsError;
  final String? error;
  final bool isDescriptionExpanded;

  /// 获取截图 URL 列表
  List<String> get screenshotUrls =>
      screenshots.map((s) => s.screenshotUrl).toList();

  AppDetailState copyWith({
    InstalledApp? app,
    AppDetailDTO? appDetail,
    List<AppScreenshotDTO>? screenshots,
    List<AppVersionDTO>? versions,
    bool? isLoading,
    bool? isLoadingVersions,
    String? versionsError,
    String? error,
    bool? isDescriptionExpanded,
    bool clearError = false,
    bool clearVersionsError = false,
    bool clearAppDetail = false,
  }) {
    return AppDetailState(
      app: app ?? this.app,
      appDetail: clearAppDetail ? null : (appDetail ?? this.appDetail),
      screenshots: screenshots ?? this.screenshots,
      versions: versions ?? this.versions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingVersions: isLoadingVersions ?? this.isLoadingVersions,
      versionsError: clearVersionsError
          ? null
          : (versionsError ?? this.versionsError),
      error: clearError ? null : (error ?? this.error),
      isDescriptionExpanded:
          isDescriptionExpanded ?? this.isDescriptionExpanded,
    );
  }
}

/// 应用详情 Provider
@riverpod
class AppDetail extends _$AppDetail {
  @override
  AppDetailState build(String appId) {
    return const AppDetailState();
  }

  /// 加载应用详情
  ///
  /// [initialApp] 可选的初始应用信息，从列表页传递时可用于快速显示
  Future<void> loadDetail(InstalledApp? initialApp) async {
    // 如果有初始数据，先显示
    if (initialApp != null) {
      state = AppDetailState(app: initialApp);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final repository = ref.read(appRepositoryProvider);

      // 调用真实 API 获取应用详情
      final appDetail = await repository.getAppDetail(appId);

      // 将详情转换为 InstalledApp 模型
      final repo = ref.read(appRepositoryProvider) as AppRepositoryImpl;
      final app = repo.mapDetailToInstalledApp(appDetail);

      // 更新状态，包含截图列表
      state = state.copyWith(
        app: app,
        appDetail: appDetail,
        screenshots: appDetail.screenshotList ?? [],
        isLoading: false,
        clearVersionsError: true,
      );

      // 异步加载版本列表
      _loadVersions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 加载版本历史列表
  Future<void> _loadVersions() async {
    state = state.copyWith(isLoadingVersions: true, clearVersionsError: true);

    try {
      final repository = ref.read(appRepositoryProvider);
      final versions = await repository.getVersions(
        appId,
        // 版本列表接口必须沿用详情页当前应用的仓库与架构，避免后端默认值查到错误仓库。
        repoName: state.appDetail?.repoName ?? state.app?.repoName,
        arch: state.appDetail?.arch ?? state.app?.arch,
      );

      state = state.copyWith(
        versions: versions,
        isLoadingVersions: false,
        clearVersionsError: true,
      );
    } catch (e) {
      // 版本列表失败不阻塞详情页主体，但要保留轻量错误态供用户重试和排查。
      AppLogger.warning('[AppDetail] 版本历史加载失败: $appId - $e');
      state = state.copyWith(
        isLoadingVersions: false,
        versionsError: e.toString(),
      );
    }
  }

  /// 刷新详情
  Future<void> refresh() async {
    await loadDetail(null);
  }

  /// 仅重试版本列表，避免因为局部失败重置整个详情页主体。
  Future<void> retryVersions() async {
    await _loadVersions();
  }

  /// 切换描述展开状态
  void toggleDescription() {
    state = state.copyWith(isDescriptionExpanded: !state.isDescriptionExpanded);
  }
}

/// 应用详情页
class AppDetailPage extends ConsumerStatefulWidget {
  const AppDetailPage({required this.appId, this.appInfo, super.key});

  /// 应用 ID
  final String appId;

  /// 可选的应用信息（从列表页传递）
  final InstalledApp? appInfo;

  @override
  ConsumerState<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends ConsumerState<AppDetailPage> {
  @override
  void initState() {
    super.initState();
    // 延迟加载详情
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(appDetailProvider(widget.appId).notifier)
          .loadDetail(widget.appInfo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(appDetailProvider(widget.appId));
    final installState = ref.watch(installQueueProvider);
    final installTask = installState.getAppInstallStatus(widget.appId);
    final installedVersions = ref
        .watch(installedAppsProvider)
        .apps
        .where((app) => app.appId == widget.appId)
        .map((app) => app.version)
        .toSet();
    final hasInstalledInstance = installedVersions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(detailState.app?.name ?? '应用详情')),
      body: _buildBody(
        context,
        detailState,
        installTask,
        installedVersions,
        hasInstalledInstance: hasInstalledInstance,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppDetailState detailState,
    InstallTask? installTask,
    Set<String> installedVersions, {
    required bool hasInstalledInstance,
  }) {
    // 加载中
    if (detailState.isLoading && detailState.app == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 错误状态
    if (detailState.error != null && detailState.app == null) {
      return _buildErrorView(context, detailState.error!);
    }

    // 空状态
    if (detailState.app == null) {
      return Center(
        child: Text(AppLocalizations.of(context)?.appNotFound ?? '未找到应用信息'),
      );
    }

    final app = detailState.app!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部信息区
          _buildHeader(
            context,
            app,
            installTask,
            hasInstalledInstance: hasInstalledInstance,
          ),

          const Divider(height: 1),

          // 截图轮播区
          _buildScreenshots(context, detailState),

          const Divider(height: 1),

          // 描述区
          _buildDescription(context, detailState, app),

          const Divider(height: 1),

          // 应用信息表格
          _buildAppInfoTable(context, detailState),

          const Divider(height: 1),

          // 版本列表
          _buildVersionList(
            context,
            detailState,
            installTask,
            installedVersions,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 构建头部信息区
  Widget _buildHeader(
    BuildContext context,
    InstalledApp app,
    InstallTask? installTask, {
    required bool hasInstalledInstance,
  }) {
    final theme = Theme.of(context);

    // 确定安装按钮状态
    final buttonState = _getInstallButtonState(
      installTask,
      hasInstalledInstance: hasInstalledInstance,
    );
    final progress = installTask?.progress ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 应用图标
          AppIcon(
            iconUrl: app.icon,
            size: 80,
            borderRadius: 16,
            appName: app.name,
          ),
          const SizedBox(width: 16),
          // 应用信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 应用名称
                Text(
                  app.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 版本信息
                Text(
                  '${AppLocalizations.of(context)?.version ?? '版本'} ${app.version}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                // 开发者/仓库信息
                if (app.repoName != null)
                  Text(
                    app.repoName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                const SizedBox(height: 12),
                // 主动作与次级动作统一编排，优先同一行展示，不足时再整体换行。
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InstallButton(
                      state: buttonState,
                      progress: progress,
                      // 下载中显示实时网络速度
                      downloadSpeed:
                          buttonState == InstallButtonState.installing
                          ? ref.watch(networkSpeedProvider).formatted
                          : null,
                      onPressed: () => _handleInstallAction(app, buttonState),
                      onCancel: () => _handleCancelInstall(app),
                      size: ButtonSize.large,
                    ),
                    AppDetailSecondaryActions(
                      isVisible: hasInstalledInstance,
                      onCreateShortcut: () => _createShortcut(app),
                      onUninstall: () => _showUninstallDialog(app),
                    ),
                  ],
                ),
                // 安装状态消息
                if (installTask != null && installTask.message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    installTask.message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: installTask.isFailed
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建截图轮播区（使用真实截图数据）
  Widget _buildScreenshots(BuildContext context, AppDetailState detailState) {
    final l10n = AppLocalizations.of(context);
    final screenshots = detailState.screenshots;

    if (screenshots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              l10n?.screenShots ?? '屏幕截图',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: screenshots.length,
              itemBuilder: (context, index) {
                final screenshot = screenshots[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _showScreenshotPreview(
                      context,
                      detailState.screenshotUrls,
                      index,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        screenshot.screenshotUrl,
                        width: 280,
                        height: 180,
                        fit: BoxFit.cover,
                        // 限制解码尺寸，避免原图 1920x1080 全量解码到内存
                        cacheWidth: (280 * MediaQuery.devicePixelRatioOf(context)).toInt(),
                        cacheHeight: (180 * MediaQuery.devicePixelRatioOf(context)).toInt(),
                        errorBuilder: (_, __, ___) => Container(
                          width: 280,
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建描述区
  Widget _buildDescription(
    BuildContext context,
    AppDetailState detailState,
    InstalledApp app,
  ) {
    final theme = Theme.of(context);
    // 优先使用详情中的完整描述
    final description =
        detailState.appDetail?.appDesc ?? app.description ?? AppLocalizations.of(context)?.noDescription ?? '暂无描述';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.appIntroduction ?? '应用介绍',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              description,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(description, style: theme.textTheme.bodyMedium),
            crossFadeState: detailState.isDescriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          const SizedBox(height: 8),
          // 展开/收起按钮（超过3行时显示）
          if (_shouldShowExpandButton(description))
            TextButton(
              onPressed: () {
                ref
                    .read(appDetailProvider(widget.appId).notifier)
                    .toggleDescription();
              },
              child: Text(detailState.isDescriptionExpanded
                  ? (AppLocalizations.of(context)?.collapse ?? '收起')
                  : (AppLocalizations.of(context)?.expandAll ?? '展开全部')),
            ),
        ],
      ),
    );
  }

  /// 构建应用信息表格（使用详情数据）
  Widget _buildAppInfoTable(BuildContext context, AppDetailState detailState) {
    final app = detailState.app;
    final detail = detailState.appDetail;
    final formattedAppSize = app?.size == null
        ? null
        : FormatUtils.formatFileSizeValue(app!.size);

    if (app == null) return const SizedBox.shrink();

    // 长字段独占整行，短字段按三列栅格排布，避免继续把所有信息竖着堆成表格。
    final entries = <AppDetailInfoEntry>[
      AppDetailInfoEntry(
        label: AppLocalizations.of(context)?.packageName ?? '包名',
        value: app.appId,
        span: AppDetailInfoSpan.full,
        isCopyable: true,
      ),
      AppDetailInfoEntry(
        label: AppLocalizations.of(context)?.version ?? '版本',
        value: app.version,
      ),
      if (app.arch != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)?.architecture ?? '架构',
          value: app.arch!,
        ),
      if (app.channel != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)?.channelLabel ?? '渠道',
          value: app.channel!,
        ),
      if (formattedAppSize != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)?.size ?? '大小',
          value: formattedAppSize,
        ),
      if (app.kind != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)?.appType ?? '类型',
          value: app.kind!,
        ),
      if (detail?.developerName != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)?.developer ?? '开发者',
          value: detail!.developerName!,
        ),
      if (detail?.categoryName != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)?.categoryLabel ?? '分类',
          value: detail!.categoryName!,
        ),
      if (app.runtime != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)?.runtime ?? '运行时',
          value: app.runtime!,
          span: AppDetailInfoSpan.full,
        ),
      if (detail?.license != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)?.license ?? '许可证',
          value: detail!.license!,
          span: AppDetailInfoSpan.full,
        ),
      if (detail?.homePage != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)?.homepage ?? '主页',
          value: detail!.homePage!,
          span: AppDetailInfoSpan.full,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.appInfo ?? '应用信息',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          AppDetailInfoSection(entries: entries),
        ],
      ),
    );
  }

  /// 构建版本列表（使用真实版本数据）
  Widget _buildVersionList(
    BuildContext context,
    AppDetailState detailState,
    InstallTask? currentInstallTask,
    Set<String> installedVersions,
  ) {
    final versions = detailState.versions;
    final isLoading = detailState.isLoadingVersions;
    final versionsError = detailState.versionsError;
    final currentApp = detailState.app;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)?.versionHistory ?? '版本历史',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (isLoading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (versionsError != null && versions.isEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)?.versionListLoadFailed ??
                        '版本列表加载失败，请重试',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(appDetailProvider(widget.appId).notifier)
                        .retryVersions();
                  },
                  child: Text(AppLocalizations.of(context)?.retry ?? '重试'),
                ),
              ],
            )
          else if (versionsError != null)
            Text(
              AppLocalizations.of(context)?.versionListUpdateFailed ??
                  '版本列表更新失败，显示最近一次结果',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            )
          else
            const SizedBox.shrink(),
          if (versionsError != null) const SizedBox(height: 12),
          if (versions.isEmpty && !isLoading)
            Text(AppLocalizations.of(context)?.noVersionHistory ?? '暂无版本历史')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: versions.length,
              itemBuilder: (context, index) {
                final version = versions[index];
                final isInstalledVersion = installedVersions.contains(
                  version.versionNo,
                );
                final formattedPackageSize = FormatUtils.formatFileSizeValue(
                  version.packageSize,
                );
                final subtitleParts = <String>[
                  if (version.releaseTime?.isNotEmpty ?? false)
                    version.releaseTime!,
                  if (formattedPackageSize != '--') formattedPackageSize,
                ];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isInstalledVersion ? Icons.check_circle : Icons.history,
                    color: isInstalledVersion
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  title: Text('v${version.versionNo}'),
                  subtitle: Text(
                    subtitleParts.isEmpty ? '--' : subtitleParts.join(' · '),
                  ),
                  trailing: isInstalledVersion
                      ? Text(
                          AppLocalizations.of(context)?.installedBadge ?? '已安装',
                        )
                      : TextButton(
                          onPressed: () =>
                              _installVersion(currentApp!, version.versionNo),
                          child: Text(
                            AppLocalizations.of(context)?.install ?? '安装',
                          ),
                        ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.loadFailed ?? '加载失败',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(appDetailProvider(widget.appId).notifier)
                    .loadDetail(widget.appInfo);
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)?.retry ?? '重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取安装按钮状态
  InstallButtonState _getInstallButtonState(
    InstallTask? installTask, {
    required bool hasInstalledInstance,
  }) {
    // 如果有安装任务，根据任务状态返回
    if (installTask != null) {
      switch (installTask.status) {
        case InstallStatus.pending:
        case InstallStatus.downloading:
        case InstallStatus.installing:
          return InstallButtonState.installing;
        case InstallStatus.success:
          return InstallButtonState.open;
        case InstallStatus.failed:
        case InstallStatus.cancelled:
          // 任务失败或取消后，检查是否已安装
          break;
      }
    }

    // 主按钮与次级操作共用同一份本地安装态判断，避免页面内规则漂移。
    if (hasInstalledInstance) {
      return InstallButtonState.open;
    }

    return InstallButtonState.notInstalled;
  }

  /// 判断是否显示展开按钮
  bool _shouldShowExpandButton(String text) {
    // 超过150个字符时显示展开按钮
    return text.length > 150;
  }

  /// 处理安装操作
  void _handleInstallAction(InstalledApp app, InstallButtonState currentState) {
    switch (currentState) {
      case InstallButtonState.notInstalled:
        // 添加到安装队列
        ref
            .read(installQueueProvider.notifier)
            .enqueueInstall(
              appId: app.appId,
              appName: app.name,
              icon: app.icon,
              version: app.version,
            );
        break;
      case InstallButtonState.update:
        // 更新应用
        ref
            .read(installQueueProvider.notifier)
            .enqueueInstall(
              appId: app.appId,
              appName: app.name,
              icon: app.icon,
              version: app.version,
            );
        break;
      case InstallButtonState.installed:
      case InstallButtonState.open:
        // 打开应用
        _openApp(app);
        break;
      case InstallButtonState.installing:
        // 安装中，不做操作
        break;
      case InstallButtonState.uninstall:
        // 卸载应用
        _showUninstallDialog(app);
        break;
    }
  }

  /// 处理取消安装
  void _handleCancelInstall(InstalledApp app) {
    ref.read(installQueueProvider.notifier).cancelInstall(app.appId);
  }

  /// 打开应用
  Future<void> _openApp(InstalledApp app) async {
    try {
      final cliRepo = ref.read(linglongCliRepositoryProvider);
      await cliRepo.runApp(app.appId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.launching(app.name) ??
                  '正在启动 ${app.name}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.launchFailed(e.toString()) ??
                  '启动失败: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 安装指定版本（含降级确认和强制重装确认）
  ///
  /// - 已安装相同版本 → 役 [showReinstallConfirm]
  /// - 目标版本低于已安装版本 → 役 [showDowngradeConfirm]
  /// - 其余情况 → 直接入队
  Future<void> _installVersion(InstalledApp app, String version) async {
    // 检查当前已安装的此应用的所有版本
    final installedList = ref.read(installedAppsListProvider);
    final installedVersions = installedList
        .where((a) => a.appId == app.appId)
        .map((a) => a.version)
        .toList();

    final isSameVersionInstalled = installedVersions.contains(version);
    if (isSameVersionInstalled) {
      // 安装版本已存在，弹出强制重装确认
      final confirmed = await ConfirmDialog.showReinstallConfirm(
        context,
        appName: app.name,
        version: version,
      );
      if (confirmed != true || !mounted) return;
    } else {
      // 检查是否为降级（目标版本低于已安装的最高版本）
      if (installedVersions.isNotEmpty) {
        final highestInstalled = installedVersions.reduce(
          (a, b) => VersionCompare.greaterThan(a, b) ? a : b,
        );
        final isDowngrade = VersionCompare.lessThan(version, highestInstalled);
        if (isDowngrade) {
          final confirmed = await ConfirmDialog.showDowngradeConfirm(
            context,
            appName: app.name,
            currentVersion: highestInstalled,
            targetVersion: version,
          );
          if (confirmed != true || !mounted) return;
        }
      }
    }

    // 入安装队列
    ref
        .read(installQueueProvider.notifier)
        .enqueueInstall(
          appId: app.appId,
          appName: app.name,
          icon: app.icon,
          version: version,
        );
  }

  /// 显示卸载确认对话框（PC-native 风格）
  ///
  /// 若应用正在运行中，会先弹出「强制关闭并卸载」警告；
  /// 否则显示常规 PC-native 卸载确认对话框。
  Future<void> _showUninstallDialog(InstalledApp app) async {
    // 检查应用是否正在运行
    final runningApps = ref.read(runningAppsListProvider);
    final runningInstances = runningApps
        .where((r) => r.appId == app.appId)
        .toList();

    if (runningInstances.isNotEmpty) {
      // 应用运行中，显示强制关闭确认弹窗
      final confirmed = await ConfirmDialog.showUninstallRunning(
        context,
        appName: app.name,
      );
      if (confirmed != true || !mounted) return;
      // 先强制关闭所有运行实例
      for (final running in runningInstances) {
        await ref.read(runningProcessProvider.notifier).killApp(running);
      }
      _uninstallApp(app);
      return;
    }

    // 正常卸载：显示 PC-native 风格确认对话框
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 警告图标 + 标题行
                  Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: colorScheme.error,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)?.uninstallApp ?? '卸载应用',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 描述信息
                  RichText(
                    text: TextSpan(
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: AppLocalizations.of(context)
                                  ?.uninstallConfirmMessage(app.name) ??
                              '确定要卸载 ${app.name} 吗？\n卸载后应用数据将被删除，此操作不可恢复。',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 操作按钮行，取消在左，危险卸载按钮在右
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(AppLocalizations.of(context)?.cancel ?? '取消'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _uninstallApp(app);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                        child: Text(AppLocalizations.of(context)?.uninstall ?? '卸载'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 卸载应用
  Future<void> _uninstallApp(InstalledApp app) async {
    try {
      final cliRepo = ref.read(linglongCliRepositoryProvider);
      await cliRepo.uninstallApp(app.appId, app.version);

      // 乐观更新：从已安装列表中移除
      ref
          .read(installedAppsProvider.notifier)
          .removeApp(app.appId, app.version);
      // 后台重新检查更新列表（不 await，不阻塞 UI）
      ref.read(updateAppsProvider.notifier).checkUpdates();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.uninstallSuccess(app.name) ??
                  '${app.name} 已卸载',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.uninstallError(e.toString()) ??
                  '卸载失败: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 显示截图预览（独立浮动窗口）
  void _showScreenshotPreview(
    BuildContext context,
    List<String> screenshots,
    int initialIndex,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'screenshot_preview',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.93, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => _ScreenshotPreviewWindow(
        screenshots: screenshots,
        initialIndex: initialIndex,
      ),
    );
  }

  /// 创建快捷方式
  Future<void> _createShortcut(InstalledApp app) async {
    try {
      final cliRepo = ref.read(linglongCliRepositoryProvider);
      await cliRepo.createDesktopShortcut(app.appId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.shortcutCreated ?? '快捷方式已创建',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.shortcutCreateFailed(e.toString()) ??
                  '创建失败: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// 截图预览浮动窗口
///
/// 通过 [showGeneralDialog] 展示，覆盖于主界面之上，形态类似独立窗口：
/// - 标题栏含截图计数和关闭按钮
/// - 内容区支持缩放和翻页
/// - 底部缩略图导航（多张时显示）
/// - 键盘：ESC 关闭，←→ 切换图片
class _ScreenshotPreviewWindow extends StatefulWidget {
  const _ScreenshotPreviewWindow({
    required this.screenshots,
    required this.initialIndex,
  });

  final List<String> screenshots;
  final int initialIndex;

  @override
  State<_ScreenshotPreviewWindow> createState() =>
      _ScreenshotPreviewWindowState();
}

class _ScreenshotPreviewWindowState extends State<_ScreenshotPreviewWindow> {
  late final PageController _pageController;
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.screenshots.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Material(
      color: Colors.transparent,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _goTo(_currentIndex - 1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _goTo(_currentIndex + 1);
          }
        },
        child: Center(
          child: Container(
            width: (size.width * 0.84).clamp(560.0, 1200.0),
            height: (size.height * 0.82).clamp(400.0, 900.0),
            decoration: BoxDecoration(
              // 深色窗口背景，独立于应用主题
              color: const Color(0xFF1C1C28),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 48,
                  spreadRadius: 0,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  _buildTitleBar(context),
                  Expanded(child: _buildImageArea()),
                  if (widget.screenshots.length > 1) _buildThumbnailBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 标题栏：图标 + 标题 + 计数器 + 关闭按钮
  Widget _buildTitleBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF15151F),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.photo_library_outlined,
            color: Colors.white54,
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)?.screenShots ?? '截图预览',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // 快捷键提示
          const _KeyHint(label: 'ESC'),
          const SizedBox(width: 4),
          const _KeyHint(label: '←  →'),
          const SizedBox(width: 16),
          // 计数器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentIndex + 1} / ${widget.screenshots.length}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          // 关闭按钮
          _CloseButton(onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  /// 图片区：PageView + InteractiveViewer + 左右箭头
  Widget _buildImageArea() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.screenshots.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Image.network(
                  widget.screenshots[index],
                  fit: BoxFit.contain,
                  // 限制解码宽度避免超大图撑爆内存
                  cacheWidth: (MediaQuery.sizeOf(context).width *
                          MediaQuery.devicePixelRatioOf(context) *
                          0.84)
                      .toInt(),
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white24,
                      size: 64,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // 左侧箭头
        if (_currentIndex > 0)
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrow(
                icon: Icons.chevron_left_rounded,
                onTap: () => _goTo(_currentIndex - 1),
              ),
            ),
          ),
        // 右侧箭头
        if (_currentIndex < widget.screenshots.length - 1)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrow(
                icon: Icons.chevron_right_rounded,
                onTap: () => _goTo(_currentIndex + 1),
              ),
            ),
          ),
      ],
    );
  }

  /// 底部缩略图导航栏
  Widget _buildThumbnailBar() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF15151F),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.screenshots.length,
        itemBuilder: (context, index) {
          final selected = index == _currentIndex;
          return GestureDetector(
            onTap: () => _goTo(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.75)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.network(
                  widget.screenshots[index],
                  width: 82,
                  height: 60,
                  fit: BoxFit.cover,
                  cacheWidth: 164,
                  cacheHeight: 120,
                  errorBuilder: (_, __, ___) => Container(
                    width: 82,
                    height: 60,
                    color: Colors.white10,
                    child: const Icon(
                      Icons.image_outlined,
                      color: Colors.white24,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 左右导航箭头按钮（悬停高亮）
class _NavArrow extends StatefulWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_NavArrow> createState() => _NavArrowState();
}

class _NavArrowState extends State<_NavArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white
                .withValues(alpha: _hovered ? 0.22 : 0.10),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

/// 键盘快捷键提示标签
class _KeyHint extends StatelessWidget {
  const _KeyHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// 关闭按钮（悬停时高亮）
class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _hovered
                ? const Color(0xFFE5534B).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.08),
          ),
          child: Icon(
            Icons.close_rounded,
            color: _hovered ? Colors.white : Colors.white54,
            size: 16,
          ),
        ),
      ),
    );
  }
}
