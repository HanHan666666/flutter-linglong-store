import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../application/providers/app_detail_provider.dart';
import '../../../application/providers/app_uninstall_provider.dart';
import '../../../application/providers/installed_apps_provider.dart';
import '../../../application/providers/network_speed_provider.dart';
import '../../../domain/models/installed_app.dart';
import '../../../domain/models/install_task.dart';
import '../../../domain/models/install_progress.dart';
import '../../../domain/models/app_version.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/models/app_detail.dart' as dm;
import '../../helpers/app_uninstall_flow.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_detail_comment_section.dart';
import '../../widgets/app_detail_secondary_actions.dart';
import '../../widgets/app_detail_info_section.dart';
import '../../widgets/install_button.dart';
import '../../widgets/confirm_dialog.dart';
import '../../../core/di/providers.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/app_notification_helpers.dart';
import '../../../core/config/theme.dart';
import '../../../core/utils/version_compare.dart';
import 'screenshot_preview_lightbox.dart';

bool shouldShowDescriptionExpandButton({
  required String text,
  required double maxWidth,
  required TextStyle? style,
  required TextDirection textDirection,
  int maxLines = 3,
}) {
  if (text.trim().isEmpty || maxWidth <= 0) {
    return false;
  }

  final textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    maxLines: maxLines,
  )..layout(maxWidth: maxWidth);

  return textPainter.didExceedMaxLines;
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
  String? _selectedCommentVersion;

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
            detailState,
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

          // 评论区
          _buildCommentSection(
            context,
            detailState,
            hasInstalledInstance: hasInstalledInstance,
          ),

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

  Widget _buildCommentSection(
    BuildContext context,
    AppDetailState detailState, {
    required bool hasInstalledInstance,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final versionOptions = _buildCommentVersionOptions(detailState);
    final selectedVersion = _resolveSelectedCommentVersion(
      detailState,
      versionOptions,
    );

    return Semantics(
      label: l10n.a11yCommentSection,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AppDetailCommentSection(
          comments: detailState.comments,
          versionOptions: versionOptions,
          selectedVersion: selectedVersion,
          isLoading: detailState.isLoadingComments,
          isSubmitting: detailState.isSubmittingComment,
          canSubmitComment: hasInstalledInstance,
          errorMessage: detailState.commentsError,
          onVersionChanged: (value) {
            setState(() {
              _selectedCommentVersion = value;
            });
          },
          onRetry: () {
            ref.read(appDetailProvider(widget.appId).notifier).retryComments();
          },
          onSubmit: (remark, version) =>
              _submitComment(context, remark, version),
        ),
      ),
    );
  }

  /// 构建头部信息区
  Widget _buildHeader(
    BuildContext context,
    AppDetailState detailState,
    InstalledApp app,
    InstallTask? installTask, {
    required bool hasInstalledInstance,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final appDetail = detailState.appDetail;

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
                // 应用名称 - 使用 headlineLarge(28px) 作为详情页主标题
                Text(
                  app.name,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 简短描述（在应用名称下方）
                if (appDetail?.description != null &&
                    appDetail!.description!.isNotEmpty)
                  Text(
                    appDetail.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                // 标签列表（Chip 样式）
                if (appDetail?.tags.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  _buildTags(context, appDetail!.tags),
                ],
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
                      appName: app.name,
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
                    // 分享按钮：始终可见，不受安装状态影响
                    _buildShareButton(context, app),
                  ],
                ),
                // 安装状态消息
                if (installTask != null &&
                    installTask.displayMessage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: installTask.displayMessage!,
                          waitDuration: const Duration(milliseconds: 500),
                          child: Text(
                            installTask.displayMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: installTask.isFailed
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        label: l10n?.copyErrorMessage ?? 'Copy error message',
                        button: true,
                        child: Tooltip(
                          message:
                              l10n?.copyErrorMessage ?? 'Copy error message',
                          waitDuration: const Duration(milliseconds: 500),
                          child: TextButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: installTask.displayMessage!,
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l10n?.copy ?? 'Copy',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签列表（Chip 样式）
  Widget _buildTags(BuildContext context, List<dm.AppTag> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) => _buildTag(context, tag.name)).toList(),
    );
  }

  /// 构建单个标签 Chip
  Widget _buildTag(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  /// 构建截图轮播区（使用真实截图数据）
  Widget _buildScreenshots(BuildContext context, AppDetailState detailState) {
    final l10n = AppLocalizations.of(context)!;
    final screenshots = detailState.screenshots;

    if (screenshots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: l10n.a11yScreenshotArea,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                l10n.screenShots,
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
                          screenshot.url,
                          width: 280,
                          height: 180,
                          fit: BoxFit.cover,
                          // 限制解码尺寸，避免原图 1920x1080 全量解码到内存
                          cacheWidth:
                              (280 * MediaQuery.devicePixelRatioOf(context))
                                  .toInt(),
                          cacheHeight:
                              (180 * MediaQuery.devicePixelRatioOf(context))
                                  .toInt(),
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
    final l10n = AppLocalizations.of(context);

    // 优先使用长描述（detailDescription），为空时降级为简短描述
    // 将 HTML <br> 标签转换为换行符，保证换行正确渲染
    final rawDescription =
        detailState.appDetail?.detailDescription?.isNotEmpty == true
        ? detailState.appDetail!.detailDescription!
        : (detailState.appDetail?.description ??
              app.description ??
              l10n?.noDescription ??
              '暂无描述');
    final description = rawDescription.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldShowExpandButton = shouldShowDescriptionExpandButton(
            text: description,
            maxWidth: constraints.maxWidth,
            style: theme.textTheme.bodyMedium,
            textDirection: Directionality.of(context),
          );

          return Column(
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
                secondChild: Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
                crossFadeState: detailState.isDescriptionExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
              if (shouldShowExpandButton) ...[
                const SizedBox(height: 8),
                // 展开/收起按钮只在文本真实超过三行时显示，避免短文本被字符阈值误判。
                TextButton(
                  onPressed: () {
                    ref
                        .read(appDetailProvider(widget.appId).notifier)
                        .toggleDescription();
                  },
                  child: Text(
                    detailState.isDescriptionExpanded
                        ? (AppLocalizations.of(context)?.collapse ?? '收起')
                        : (AppLocalizations.of(context)?.expandAll ?? '展开全部'),
                  ),
                ),
              ],
            ],
          );
        },
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
    final allVersions = detailState.versions;
    final isLoading = detailState.isLoadingVersions;
    final versionsError = detailState.versionsError;
    final currentApp = detailState.app;
    final isExpanded = detailState.isVersionListExpanded;
    final l10n = AppLocalizations.of(context)!;

    // 根据折叠状态计算展示列表
    final displayVersions = isExpanded
        ? allVersions
        : _computeCollapsedVersions(allVersions, installedVersions);

    // 判断是否需要显示折叠按钮（版本数 > 2 时才显示）
    final shouldShowToggle = allVersions.length > 2;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行：左侧标题 + 右侧折叠按钮
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      l10n.versionHistory,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
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
              ),
              // 折叠按钮在右上角
              if (shouldShowToggle)
                TextButton(
                  onPressed: () {
                    ref
                        .read(appDetailProvider(widget.appId).notifier)
                        .toggleVersionList();
                  },
                  child: Text(
                    isExpanded
                        ? (l10n.collapse ?? '收起')
                        : (l10n.expandAll ?? '展开全部'),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // 错误提示区域
          if (versionsError != null && allVersions.isEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.versionListLoadFailed ?? '版本列表加载失败，请重试',
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
                  child: Text(l10n.retry ?? '重试'),
                ),
              ],
            )
          else if (versionsError != null)
            Text(
              l10n.versionListUpdateFailed ?? '版本列表更新失败，显示最近一次结果',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),

          if (versionsError != null) const SizedBox(height: 12),

          // 版本列表（使用计算后的 displayVersions）
          if (displayVersions.isEmpty && !isLoading)
            Text(l10n.noVersionHistory ?? '暂无版本历史')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayVersions.length,
              itemBuilder: (context, index) {
                final version = displayVersions[index];
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
                      ? Text(l10n.installedBadge ?? '已安装')
                      : TextButton(
                          onPressed: () =>
                              _installVersion(currentApp!, version.versionNo),
                          child: Text(l10n.install ?? '安装'),
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
          return InstallButtonState.pending;
        case InstallStatus.downloading:
        case InstallStatus.installing:
          return InstallButtonState.installing;
        case InstallStatus.success:
          // 任务成功后，需再次检查实际安装状态（用户可能已卸载）
          if (hasInstalledInstance) {
            return InstallButtonState.open;
          }
          // 已卸载，显示为安装状态
          return InstallButtonState.notInstalled;
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

  List<String> _buildCommentVersionOptions(AppDetailState detailState) {
    final versions = <String>[];

    void addVersion(String? version) {
      if (version == null || version.isEmpty || versions.contains(version)) {
        return;
      }
      versions.add(version);
    }

    addVersion(detailState.app?.version);
    for (final version in detailState.versions) {
      addVersion(version.versionNo);
    }

    return versions;
  }

  String? _resolveSelectedCommentVersion(
    AppDetailState detailState,
    List<String> versionOptions,
  ) {
    final currentSelection = _selectedCommentVersion;
    if (currentSelection != null && versionOptions.contains(currentSelection)) {
      return currentSelection;
    }
    if (versionOptions.isNotEmpty) {
      return versionOptions.first;
    }
    return detailState.app?.version;
  }

  Future<void> _submitComment(
    BuildContext context,
    String remark,
    String? version,
  ) async {
    try {
      await ref
          .read(appDetailProvider(widget.appId).notifier)
          .submitComment(remark, version: version);
      if (!context.mounted) {
        return;
      }
      showAppNotification(
        context,
        AppLocalizations.of(context)?.commentSubmitSuccess ?? '评论已提交',
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppError(
        context,
        AppLocalizations.of(context)?.commentSubmitFailed(e.toString()) ??
            '评论提交失败: $e',
      );
    }
  }

  /// 处理安装操作
  void _handleInstallAction(InstalledApp app, InstallButtonState currentState) {
    switch (currentState) {
      case InstallButtonState.notInstalled:
        // 详情页主按钮走默认安装，不指定版本；只有版本列表入口才允许传版本。
        ref
            .read(installQueueProvider.notifier)
            .enqueueInstall(
              appId: app.appId,
              appName: app.name,
              icon: app.icon,
            );
        break;
      case InstallButtonState.update:
        // 详情页更新统一走 update 队列，不再伪装成带版本安装。
        ref
            .read(installQueueProvider.notifier)
            .enqueueOperation(
              kind: InstallTaskKind.update,
              appId: app.appId,
              appName: app.name,
              icon: app.icon,
            );
        break;
      case InstallButtonState.installed:
      case InstallButtonState.open:
        // 打开应用
        _openApp(app);
        break;
      case InstallButtonState.installing:
      case InstallButtonState.pending:
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
    ref.read(installQueueProvider.notifier).cancelTask(app.appId);
  }

  /// 打开应用
  Future<void> _openApp(InstalledApp app) async {
    try {
      final cliRepo = ref.read(linglongCliRepositoryProvider);
      await cliRepo.runApp(app.appId);

      if (mounted) {
        showAppLaunching(context, app.name);
      }
    } catch (e) {
      if (mounted) {
        showAppLaunchFailed(context, e.toString());
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

  /// 构建分享按钮。
  ///
  /// 始终可见，不受应用安装状态影响。
  /// 图标按钮风格，视觉上轻量不抢主操作焦点。
  Widget _buildShareButton(BuildContext context, InstalledApp app) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      onPressed: () => _shareApp(context, app),
      tooltip: l10n?.shareLink ?? '分享',
      icon: const Icon(Icons.share_outlined, size: 20),
      // 与 InstallButton.large (40px) 高度对齐
      constraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
    );
  }

  /// 分享应用链接。
  ///
  /// 优先调用系统原生分享（通过 XDG portal），
  /// 不可用时 fallback 到复制链接到剪贴板。
  Future<void> _shareApp(BuildContext context, InstalledApp app) async {
    final l10n = AppLocalizations.of(context);
    // 从全局状态获取当前系统架构，不写死
    final arch = ref.read(globalAppProvider).arch ?? 'x86_64';
    final shareUrl =
        'https://store.linyaps.org.cn/apps/${app.appId}?arch=$arch';

    try {
      await Share.shareUri(Uri.parse(shareUrl));
      // Share.shareUri 在 Linux 上可能静默失败（无分享面板），
      // 不抛异常但也不执行任何操作，所以需要额外检查
      return;
    } catch (_) {
      // 原生分享不可用，fallback 到剪贴板
    }

    // Fallback：复制到剪贴板
    try {
      await Clipboard.setData(ClipboardData(text: shareUrl));
      if (!context.mounted) return;
      showAppSuccess(context, l10n?.linkCopied ?? '链接已复制');
    } catch (_) {
      if (!context.mounted) return;
      showAppError(context, l10n?.shareFailed ?? '分享失败');
    }
  }

  /// 显示卸载确认对话框
  ///
  /// 使用统一的卸载流程处理所有逻辑：
  /// - 运行中检测
  /// - 确认弹窗
  /// - kill 进程
  /// - 执行卸载
  Future<void> _showUninstallDialog(InstalledApp app) async {
    final currentContext = context;
    final service = ref.read(appUninstallServiceProvider);
    final success = await AppUninstallFlow.run(currentContext, app, service);
    if (!currentContext.mounted) return;

    if (success) {
      showAppSuccess(currentContext, '${app.name} 已卸载');
    }
  }

  /// 在主窗口内以灯箱形式预览截图
  Future<void> _showScreenshotPreview(
    BuildContext context,
    List<String> screenshots,
    int initialIndex,
  ) async {
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
      if (!context.mounted) {
        return;
      }
      showAppError(context, AppLocalizations.of(context)?.loadFailed ?? '加载失败');
    }
  }

  /// 创建快捷方式
  Future<void> _createShortcut(InstalledApp app) async {
    final currentContext = context;
    final l10n = AppLocalizations.of(currentContext);

    try {
      final cliRepo = ref.read(linglongCliRepositoryProvider);
      await cliRepo.createDesktopShortcut(app.appId);

      if (!currentContext.mounted) return;
      showAppSuccess(
        currentContext,
        l10n?.shortcutCreated ?? '快捷方式已创建',
      );
    } catch (e) {
      if (!currentContext.mounted) return;
      showAppError(
        currentContext,
        l10n?.shortcutCreateFailed(e.toString()) ??
            '创建失败: $e',
      );
    }
  }

  /// 计算折叠状态下的版本列表
  ///
  /// 规则：
  /// 1. 始终包含最新版本（列表第一条）
  /// 2. 如果已安装版本 ≠ 最新版本，添加已安装版本
  /// 3. 去重：最新版本恰好是已安装版本时只显示一条
  List<AppVersion> _computeCollapsedVersions(
    List<AppVersion> allVersions,
    Set<String> installedVersions,
  ) {
    if (allVersions.isEmpty) {
      return [];
    }

    final latestVersion = allVersions.first;
    final result = <AppVersion>[latestVersion];

    // 查找已安装但不是最新版本的其他版本
    for (final version in allVersions) {
      final isInstalled = installedVersions.contains(version.versionNo);
      final isNotLatest = version.versionNo != latestVersion.versionNo;

      if (isInstalled && isNotLatest) {
        result.add(version);
      }
    }

    return result;
  }
}
