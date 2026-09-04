/// 应用详情页版本历史区域。
///
/// 该文件只展示版本列表、任务进度和版本操作入口。版本安装与卸载通过回调
/// 委托给动作控制器，不读取 Provider 或直接操作安装队列。
library;

import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/utils/format_utils.dart';
import '../../../domain/models/app_version.dart';
import '../../../domain/models/install_progress.dart';
import '../../../domain/models/install_task.dart';
import '../../../domain/models/installed_app.dart';
import 'app_detail_page_logic.dart';

/// 展示应用版本历史、已安装状态和对应任务操作。
class AppDetailVersionSection extends StatelessWidget {
  /// 创建版本历史区域。
  const AppDetailVersionSection({
    required this.app,
    required this.versions,
    required this.isLoading,
    required this.errorMessage,
    required this.isExpanded,
    required this.activeTasksForApp,
    required this.installedVersions,
    required this.onToggleExpanded,
    required this.onRetry,
    required this.onInstallVersion,
    required this.onUninstallVersion,
    super.key,
  });

  /// 当前详情页应用。
  final InstalledApp app;

  /// 服务端返回的版本列表。
  final List<AppVersion> versions;

  /// 版本列表是否正在加载。
  final bool isLoading;

  /// 版本列表加载错误。
  final String? errorMessage;

  /// 是否展开完整版本列表。
  final bool isExpanded;

  /// 当前应用在安装队列中的活跃任务（当前任务 + 排队任务）。
  ///
  /// 由页面容器按 appId select 后传入；组件保持纯展示，不直接订阅 Provider。
  final List<InstallTask> activeTasksForApp;

  /// 本机已安装的版本集合。
  final Set<String> installedVersions;

  /// 切换版本列表折叠状态。
  final VoidCallback onToggleExpanded;

  /// 重试加载版本列表。
  final VoidCallback onRetry;

  /// 安装指定版本。
  final ValueChanged<String> onInstallVersion;

  /// 卸载指定已安装版本。
  final ValueChanged<String> onUninstallVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayVersions = isExpanded
        ? versions
        : AppDetailPageLogic.collapsedVersions(versions, installedVersions);
    final shouldShowToggle = versions.length > 2;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      l10n.versionHistory,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: context.appFontWeight(FontWeight.w700),
                      ),
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
              if (shouldShowToggle)
                TextButton(
                  onPressed: onToggleExpanded,
                  child: Text(isExpanded ? l10n.collapse : l10n.expandAll),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (errorMessage != null && versions.isEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.versionListLoadFailed,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                TextButton(onPressed: onRetry, child: Text(l10n.retry)),
              ],
            )
          else if (errorMessage != null)
            Text(
              l10n.versionListUpdateFailed,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          if (errorMessage != null) const SizedBox(height: 12),
          if (displayVersions.isEmpty && !isLoading)
            Text(l10n.noVersionHistory)
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
                final activeTask = AppDetailPageLogic.versionInstallTask(
                  activeTasksForApp: activeTasksForApp,
                  versions: versions,
                  currentVersion: app.version,
                  version: version.versionNo,
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
                  key: Key('app-detail-version-row-${version.versionNo}'),
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
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Align(
                      // 版本操作区随文本方向镜像（RTL 下靠左）
                      alignment: AlignmentDirectional.centerEnd,
                      child: _buildVersionActionArea(
                        context,
                        version.versionNo,
                        activeTask: activeTask,
                        isInstalledVersion: isInstalledVersion,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// 根据活跃任务和本地安装状态构建版本行操作区域。
  Widget _buildVersionActionArea(
    BuildContext context,
    String version, {
    InstallTask? activeTask,
    required bool isInstalledVersion,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (activeTask != null) {
      return _buildVersionActionButton(
        context,
        key: Key('app-detail-version-progress-$version'),
        label: _resolveVersionActionLabel(context, activeTask),
        progress: activeTask.progressValue,
        isLoading:
            activeTask.status == InstallStatus.downloading ||
            activeTask.status == InstallStatus.installing,
        isPending: activeTask.status == InstallStatus.pending,
      );
    }

    if (!isInstalledVersion) {
      return _buildVersionActionButton(
        context,
        key: Key('app-detail-version-install-$version'),
        label: l10n.install,
        onPressed: () => onInstallVersion(version),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInstalledVersionBadge(context, version),
        const SizedBox(width: 8),
        _buildVersionActionButton(
          context,
          key: Key('app-detail-version-uninstall-$version'),
          label: l10n.uninstall,
          isDestructive: true,
          onPressed: () => onUninstallVersion(version),
        ),
      ],
    );
  }

  /// 构建已安装版本徽章。
  Widget _buildInstalledVersionBadge(BuildContext context, String version) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      key: Key('app-detail-version-installed-badge-$version'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        l10n.installedBadge,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: context.appFontWeight(FontWeight.w600),
        ),
      ),
    );
  }

  /// 构建安装、卸载、排队或进度按钮。
  Widget _buildVersionActionButton(
    BuildContext context, {
    required Key key,
    required String label,
    VoidCallback? onPressed,
    bool isDestructive = false,
    bool isLoading = false,
    bool isPending = false,
    double progress = 0.0,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    const buttonHeight = 32.0;

    if (isLoading || isPending) {
      final progressTask = InstallTask(
        id: 'app-detail-version-progress',
        appId: app.appId,
        appName: app.appId,
        progress: progress,
        createdAt: 0,
      );
      final displayLabel = isLoading
          ? (progressTask.progressValue > 0
                ? progressTask.progressPercentLabel
                : l10n.installing)
          : l10n.waitingForInstall;

      return SizedBox(
        height: buttonHeight,
        child: FilledButton(
          key: key,
          onPressed: null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(72, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: const StadiumBorder(),
            // 进度/等待态按钮强调色迁移到 scheme.primary/onPrimary 配对
            // （docs/48 §7.5）；回退路径 onPrimary 为纯白，外观逐位不变。
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.72),
            foregroundColor: theme.colorScheme.onPrimary,
            disabledBackgroundColor: theme.colorScheme.primary.withValues(
              alpha: 0.72,
            ),
            disabledForegroundColor: theme.colorScheme.onPrimary,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: context.appFontWeight(FontWeight.w600),
            ),
          ),
          child: isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          value: progressTask.progressValue > 0
                              ? progressTask.progressValue
                              : null,
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(displayLabel),
                  ],
                )
              : Text(displayLabel),
        ),
      );
    }

    final buttonStyle = isDestructive
        ? OutlinedButton.styleFrom(
            minimumSize: const Size(72, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: theme.colorScheme.error),
            foregroundColor: theme.colorScheme.error,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: context.appFontWeight(FontWeight.w600),
            ),
          )
        : FilledButton.styleFrom(
            minimumSize: const Size(72, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: context.appFontWeight(FontWeight.w600),
            ),
          );

    final button = isDestructive
        ? OutlinedButton(
            key: key,
            onPressed: onPressed,
            style: buttonStyle,
            child: Text(label),
          )
        : FilledButton(
            key: key,
            onPressed: onPressed,
            style: buttonStyle,
            child: Text(label),
          );

    return SizedBox(height: buttonHeight, child: button);
  }

  /// 返回活跃版本任务对应的按钮文案。
  String _resolveVersionActionLabel(BuildContext context, InstallTask task) {
    final l10n = AppLocalizations.of(context)!;
    return switch (task.status) {
      InstallStatus.pending => l10n.waitingForInstall,
      InstallStatus.downloading || InstallStatus.installing =>
        task.progressValue > 0 ? task.progressPercentLabel : l10n.installing,
      InstallStatus.success => l10n.open,
      InstallStatus.failed => l10n.install,
      InstallStatus.cancelled => l10n.install,
      InstallStatus.interrupted => l10n.install,
    };
  }
}
