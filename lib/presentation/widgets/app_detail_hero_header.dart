import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../domain/models/installed_app.dart';
import 'app_detail_secondary_actions.dart';
import 'app_icon.dart';
import 'install_button.dart';

/// 应用详情页头部操作区。
///
/// 该组件只负责详情页头部的视觉编排：应用身份信息、主操作、次级操作、
/// 分享入口和安装状态条。安装态判断、队列入队、卸载流程和快捷方式创建都由页面层完成，
/// 避免头部组件直接订阅全局 Provider 导致重建范围扩大。
class AppDetailHeroHeader extends StatelessWidget {
  const AppDetailHeroHeader({
    required this.app,
    required this.installSourceKey,
    required this.buttonState,
    required this.progress,
    required this.showInstalledActions,
    required this.onPrimaryPressed,
    required this.onCancel,
    required this.onCreateShortcut,
    required this.onUninstall,
    required this.onShare,
    this.description,
    this.tags = const [],
    this.downloadSpeed,
    this.statusMessage,
    this.statusCopyText,
    this.isStatusFailed = false,
    super.key,
  });

  /// 当前详情页展示的应用。
  final InstalledApp app;

  /// 安装飞入下载中心动画的图标锚点。
  final GlobalKey installSourceKey;

  /// 页面层计算好的详情页主按钮状态。
  final InstallButtonState buttonState;

  /// 当前安装或更新任务进度。
  final double progress;

  /// 安装中展示的下载速度文本。
  final String? downloadSpeed;

  /// 是否展示仅已安装态可见的快捷方式和卸载入口。
  final bool showInstalledActions;

  /// 页面层提供的简短描述。
  final String? description;

  /// 页面层归一后的标签名称。
  final List<String> tags;

  /// 安装或更新状态条展示文案。
  final String? statusMessage;

  /// 状态条复制按钮使用的完整文案。
  final String? statusCopyText;

  /// 状态条是否为失败态。
  final bool isStatusFailed;

  /// 主按钮点击回调。
  final VoidCallback onPrimaryPressed;

  /// 安装或排队取消回调。
  final VoidCallback onCancel;

  /// 创建桌面快捷方式回调。
  final VoidCallback onCreateShortcut;

  /// 卸载回调。
  final VoidCallback onUninstall;

  /// 分享回调。
  final VoidCallback onShare;

  static const double _wideLayoutThreshold = 920;
  static const double _iconSize = 96;
  static const double _panelWidth = 420;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        key: const Key('app-detail-hero-header'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useWideLayout = constraints.maxWidth >= _wideLayoutThreshold;
            final headerBody = useWideLayout
                ? _buildWideLayout(context)
                : _buildCompactLayout(context);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerBody,
                if (_hasStatusMessage) ...[
                  const SizedBox(height: 16),
                  _buildStatusBar(context),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// 是否存在需要展示的状态条文案。
  bool get _hasStatusMessage => statusMessage?.isNotEmpty == true;

  /// 构建桌面宽屏布局。
  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIcon(),
        const SizedBox(width: 20),
        Expanded(child: _buildInfo(context)),
        const SizedBox(width: 24),
        SizedBox(width: _panelWidth, child: _buildActionPanel(context)),
      ],
    );
  }

  /// 构建中窄宽度布局。
  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(child: _buildInfo(context)),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionPanel(context, alignEnd: false),
      ],
    );
  }

  /// 构建作为安装动画源点的应用图标。
  Widget _buildIcon() {
    return SizedBox(
      key: installSourceKey,
      width: _iconSize,
      height: _iconSize,
      child: AppIcon(
        iconUrl: app.icon,
        size: _iconSize,
        borderRadius: 16,
        appName: app.name,
      ),
    );
  }

  /// 构建应用身份信息。
  Widget _buildInfo(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final trimmedDescription = description?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          app.name,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: context.appFontWeight(FontWeight.w700),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (trimmedDescription != null && trimmedDescription.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            trimmedDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTags(context),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _buildMetaText(context, '${l10n.version} ${app.version}'),
            if (app.repoName?.isNotEmpty == true)
              _buildMetaText(context, app.repoName!, emphasized: true),
            if (app.arch?.isNotEmpty == true)
              _buildMetaText(context, app.arch!),
          ],
        ),
      ],
    );
  }

  /// 构建应用标签。
  Widget _buildTags(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: AppRadius.fullRadius,
              ),
              child: Text(
                tag,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  /// 构建一条头部元信息。
  Widget _buildMetaText(
    BuildContext context,
    String text, {
    bool emphasized = false,
  }) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: emphasized
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建右侧或换行后的操作面板。
  Widget _buildActionPanel(BuildContext context, {bool alignEnd = true}) {
    final crossAxisAlignment = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Column(
      key: const Key('app-detail-hero-action-panel'),
      crossAxisAlignment: crossAxisAlignment,
      children: [
        KeyedSubtree(
          key: const Key('app-detail-hero-primary-action'),
          child: InstallButton(
            appName: app.name,
            state: buttonState,
            progress: progress,
            downloadSpeed: downloadSpeed,
            onPressed: onPrimaryPressed,
            onCancel: onCancel,
            size: ButtonSize.hero,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            AppDetailSecondaryActions(
              isVisible: showInstalledActions,
              onCreateShortcut: onCreateShortcut,
              onUninstall: onUninstall,
            ),
            _buildShareButton(context),
          ],
        ),
      ],
    );
  }

  /// 构建分享入口。
  Widget _buildShareButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      label: l10n.shareLink,
      child: IconButton(
        onPressed: onShare,
        tooltip: l10n.shareLink,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: const ExcludeSemantics(
          child: Icon(Icons.share_outlined, size: 20),
        ),
      ),
    );
  }

  /// 构建安装或更新状态条。
  Widget _buildStatusBar(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = statusMessage ?? '';
    final copyText = statusCopyText?.isNotEmpty == true
        ? statusCopyText!
        : statusText;
    final borderColor = isStatusFailed
        ? theme.colorScheme.error.withValues(alpha: 0.45)
        : theme.colorScheme.primary.withValues(alpha: 0.22);
    final backgroundColor = isStatusFailed
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.28)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.22);

    return Container(
      key: const Key('app-detail-hero-status-bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: isStatusFailed
          ? _buildFailedStatusContent(context, statusText, copyText)
          : _buildNormalStatusContent(context, statusText, copyText),
    );
  }

  /// 构建普通安装状态条内容。
  Widget _buildNormalStatusContent(
    BuildContext context,
    String statusText,
    String copyText,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Tooltip(
            message: statusText,
            child: Text(
              statusText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusCopyButton(context, copyText, isFailed: false),
      ],
    );
  }

  /// 构建失败安装状态条内容。
  Widget _buildFailedStatusContent(
    BuildContext context,
    String statusText,
    String copyText,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Tooltip(
                message: statusText,
                child: Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: _buildStatusCopyButton(context, copyText, isFailed: true),
        ),
      ],
    );
  }

  /// 构建状态条复制按钮。
  Widget _buildStatusCopyButton(
    BuildContext context,
    String copyText, {
    required bool isFailed,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final label = isFailed ? l10n.copyErrorMessage : l10n.copy;

    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: copyText));
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.copy,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
