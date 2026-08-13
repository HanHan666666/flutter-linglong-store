/// 应用详情页的稳定内容区域。
///
/// 该文件承载截图、描述、应用信息和加载错误展示，只接收 Domain 模型和回调，
/// 不读取 Riverpod，也不执行安装、卸载或网络副作用。
library;

import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/utils/format_utils.dart';
import '../../../domain/models/app_detail.dart';
import '../../../domain/models/installed_app.dart';
import '../../widgets/app_detail_info_section.dart';

/// 判断描述文本是否真实超过折叠行数。
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

/// 展示应用截图横向列表。
class AppDetailScreenshotsSection extends StatelessWidget {
  /// 创建截图区域。
  const AppDetailScreenshotsSection({
    required this.screenshots,
    required this.onOpenPreview,
    super.key,
  });

  /// 详情接口返回的截图。
  final List<AppScreenshot> screenshots;

  /// 打开指定截图索引的灯箱回调。
  final ValueChanged<int> onOpenPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: context.appFontWeight(FontWeight.w700),
                ),
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
                      onTap: () => onOpenPreview(index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          screenshot.url,
                          width: 280,
                          height: 180,
                          fit: BoxFit.cover,
                          cacheWidth:
                              (280 * MediaQuery.devicePixelRatioOf(context))
                                  .toInt(),
                          cacheHeight:
                              (180 * MediaQuery.devicePixelRatioOf(context))
                                  .toInt(),
                          errorBuilder: (_, _, _) => Container(
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
}

/// 展示应用长描述并按真实文本行数提供展开入口。
class AppDetailDescriptionSection extends StatelessWidget {
  /// 创建描述区域。
  const AppDetailDescriptionSection({
    required this.app,
    required this.detail,
    required this.isExpanded,
    required this.onToggleExpanded,
    super.key,
  });

  /// 当前应用基础信息。
  final InstalledApp app;

  /// 详情接口的扩展信息。
  final AppDetail? detail;

  /// 当前是否展开完整描述。
  final bool isExpanded;

  /// 切换描述折叠状态的回调。
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final rawDescription = detail?.detailDescription?.isNotEmpty == true
        ? detail!.detailDescription!
        : (detail?.description ?? app.description ?? l10n.noDescription);
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
                l10n.appIntroduction,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: context.appFontWeight(FontWeight.w700),
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
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
              if (shouldShowExpandButton) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onToggleExpanded,
                  child: Text(isExpanded ? (l10n.collapse) : (l10n.expandAll)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 展示应用包信息、运行时、开发者和许可证。
class AppDetailMetadataSection extends StatelessWidget {
  /// 创建应用信息区域。
  const AppDetailMetadataSection({
    required this.app,
    required this.detail,
    super.key,
  });

  /// 当前应用基础信息。
  final InstalledApp app;

  /// 详情接口的扩展信息。
  final AppDetail? detail;

  @override
  Widget build(BuildContext context) {
    final formattedAppSize = app.size == null
        ? null
        : FormatUtils.formatFileSizeValue(app.size);
    final entries = <AppDetailInfoEntry>[
      AppDetailInfoEntry(
        label: AppLocalizations.of(context)!.packageName,
        value: app.appId,
        span: AppDetailInfoSpan.full,
        isCopyable: true,
      ),
      AppDetailInfoEntry(
        label: AppLocalizations.of(context)!.version,
        value: app.version,
      ),
      if (app.arch != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)!.architecture,
          value: app.arch!,
        ),
      if (app.channel != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)!.channelLabel,
          value: app.channel!,
        ),
      if (formattedAppSize != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)!.size,
          value: formattedAppSize,
        ),
      if (app.kind != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)!.appType,
          value: app.kind!,
        ),
      if (detail?.developerName != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)!.developer,
          value: detail!.developerName!,
        ),
      if (detail?.categoryName != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)!.categoryLabel,
          value: detail!.categoryName!,
        ),
      if (app.runtime != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)!.runtime,
          value: app.runtime!,
          span: AppDetailInfoSpan.full,
          isCopyable: true,
        ),
      if (detail?.license != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)!.license,
          value: detail!.license!,
          span: AppDetailInfoSpan.full,
        ),
      if (detail?.homePage != null)
        AppDetailInfoEntry(
          label: AppLocalizations.of(context)!.homepage,
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
            AppLocalizations.of(context)!.appInfo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: context.appFontWeight(FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          AppDetailInfoSection(entries: entries),
        ],
      ),
    );
  }
}

/// 展示详情首次加载失败状态和重试入口。
class AppDetailErrorView extends StatelessWidget {
  /// 创建详情错误视图。
  const AppDetailErrorView({
    required this.error,
    required this.onRetry,
    super.key,
  });

  /// 原始错误摘要。
  final String error;

  /// 重新加载详情的回调。
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loadFailed,
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
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}
