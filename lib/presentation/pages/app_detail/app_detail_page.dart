import 'package:flutter/material.dart';
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
import '../../widgets/install_button.dart';
import '../../widgets/confirm_dialog.dart';
import '../../../core/di/providers.dart';
import '../../../application/providers/installed_apps_provider.dart';
import '../../../application/providers/running_process_provider.dart';
import '../../../core/i18n/l10n/app_localizations.dart';

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
      return const Center(child: Text('未找到应用信息'));
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
                  '版本 ${app.version}',
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
        detailState.appDetail?.appDesc ?? app.description ?? '暂无描述';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '应用介绍',
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
              child: Text(detailState.isDescriptionExpanded ? '收起' : '展开全部'),
            ),
        ],
      ),
    );
  }

  /// 构建应用信息表格（使用详情数据）
  Widget _buildAppInfoTable(BuildContext context, AppDetailState detailState) {
    final app = detailState.app;
    final detail = detailState.appDetail;

    if (app == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '应用信息',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {0: FixedColumnWidth(80), 1: FlexColumnWidth()},
            children: [
              _buildTableRow('包名', app.appId),
              _buildTableRow('版本', app.version),
              if (app.arch != null) _buildTableRow('架构', app.arch!),
              if (app.channel != null) _buildTableRow('渠道', app.channel!),
              if (app.size != null) _buildTableRow('大小', app.size!),
              if (app.kind != null) _buildTableRow('类型', app.kind!),
              if (app.runtime != null) _buildTableRow('运行时', app.runtime!),
              // 从详情获取的额外信息
              if (detail?.developerName != null)
                _buildTableRow('开发者', detail!.developerName!),
              if (detail?.categoryName != null)
                _buildTableRow('分类', detail!.categoryName!),
              if (detail?.license != null)
                _buildTableRow('许可证', detail!.license!),
              if (detail?.homePage != null)
                _buildTableRow('主页', detail!.homePage!),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建表格行
  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(label, style: TextStyle(color: Colors.grey[600])),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(value),
        ),
      ],
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
                '版本历史',
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
                  child: const Text('重试'),
                ),
              ],
            )
          else if (versionsError != null)
            Text(
              '版本列表更新失败，显示最近一次结果',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            )
          else
            const SizedBox.shrink(),
          if (versionsError != null) const SizedBox(height: 12),
          if (versions.isEmpty && !isLoading)
            const Text('暂无版本历史')
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
                final subtitleParts = [
                  version.releaseTime,
                  version.packageSize,
                ].whereType<String>().where((item) => item.isNotEmpty).toList();

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
                      ? const Text('已安装')
                      : TextButton(
                          onPressed: () =>
                              _installVersion(currentApp!, version.versionNo),
                          child: const Text('安装'),
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
            Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
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
              label: const Text('重试'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('正在启动 ${app.name}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('启动失败: $e'),
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
    final runningInstances =
        runningApps.where((r) => r.appId == app.appId).toList();

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
                        '卸载应用',
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
                        const TextSpan(text: '确定要卸载 '),
                        TextSpan(
                          text: app.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' 吗？\n卸载后应用数据将被删除，此操作不可恢复。'),
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
                        child: const Text('取消'),
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
                        child: const Text('卸载'),
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
        ).showSnackBar(SnackBar(content: Text('${app.name} 已卸载')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('卸载失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 显示截图预览
  void _showScreenshotPreview(
    BuildContext context,
    List<String> screenshots,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ScreenshotPreviewPage(
          screenshots: screenshots,
          initialIndex: initialIndex,
        ),
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
        ).showSnackBar(const SnackBar(content: Text('快捷方式已创建')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// 截图预览页面
class _ScreenshotPreviewPage extends StatefulWidget {
  const _ScreenshotPreviewPage({
    required this.screenshots,
    required this.initialIndex,
  });

  final List<String> screenshots;
  final int initialIndex;

  @override
  State<_ScreenshotPreviewPage> createState() => _ScreenshotPreviewPageState();
}

class _ScreenshotPreviewPageState extends State<_ScreenshotPreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.screenshots.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.screenshots.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.screenshots[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
