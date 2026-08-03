import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/accessibility/a11y_focus_traversal.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/utils/app_notification_helpers.dart';
import '../../domain/models/error_solution.dart';

/// 展示后端错误解决方案的 Markdown 对话框。
///
/// 对话框只负责可读展示和外链跳转；脚本审计与执行由独立流程注入，避免 Markdown
/// 展示组件接触提权命令、临时文件或签名验证细节。
class ErrorSolutionDialog extends StatelessWidget {
  /// 创建解决方案对话框。
  const ErrorSolutionDialog({
    super.key,
    required this.solution,
    this.onRepairRequested,
  });

  /// 后端返回并映射后的解决方案。
  final ErrorSolution solution;

  /// 用户请求进入脚本审计流程时的回调。
  final Future<void> Function()? onRepairRequested;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appColors = context.appColors;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2l,
        vertical: AppSpacing.xl,
      ),
      child: A11yFocusScope(
        debugLabel: 'ErrorSolutionDialog',
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 520,
            maxWidth: 760,
            minHeight: 420,
            maxHeight: 680,
          ),
          child: Column(
            children: [
              _DialogTitleBar(
                title: solution.title,
                closeLabel: l10n.errorSolutionClose,
              ),
              Divider(height: 1, color: appColors.divider),
              Expanded(
                child: Markdown(
                  key: const Key('errorSolutionMarkdown'),
                  data: solution.markdown,
                  selectable: true,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                        p: context.appTextStyles.body.copyWith(
                          color: appColors.textPrimary,
                          height: 1.55,
                        ),
                        code: context.appTextStyles.caption.copyWith(
                          color: appColors.textPrimary,
                          backgroundColor: appColors.surfaceContainerHighest,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: appColors.surfaceContainerLow,
                          border: Border(
                            left: BorderSide(
                              color: appColors.primary,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                  onTapLink: (_, href, _) => _openLink(context, href),
                  imageBuilder: (uri, title, alt) =>
                      _buildMarkdownImage(context, uri, alt),
                ),
              ),
              Divider(height: 1, color: appColors.divider),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.close),
                    ),
                    if (solution.hasRepairScript &&
                        onRepairRequested != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton.icon(
                        key: const Key('errorSolutionRepairButton'),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await onRepairRequested?.call();
                        },
                        icon: const ExcludeSemantics(
                          child: Icon(Icons.build_circle_outlined, size: 18),
                        ),
                        label: Text(l10n.errorSolutionRepair),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建 Markdown 远程图片。
  ///
  /// 只允许 HTTP/HTTPS，拒绝 file、resource 和 data URI，避免后端内容读取本地
  /// 资源或把大段内联数据直接交给图片解码器。解码宽度按对话框上限约束，降低
  /// 高分辨率远程图对桌面端内存和 UI 响应的影响。
  Widget _buildMarkdownImage(BuildContext context, Uri uri, String? alt) {
    final l10n = AppLocalizations.of(context)!;
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return _MarkdownImageFallback(
        icon: Icons.block_outlined,
        label: l10n.errorSolutionImageBlocked,
      );
    }

    final semanticLabel = alt?.trim().isNotEmpty == true
        ? alt!.trim()
        : l10n.errorSolutionRemoteImage;
    final cacheWidth = (720 * MediaQuery.devicePixelRatioOf(context)).round();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.network(
          uri.toString(),
          fit: BoxFit.contain,
          cacheWidth: cacheWidth,
          semanticLabel: semanticLabel,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return Semantics(
              label: l10n.loading,
              child: const SizedBox(
                height: 96,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          },
          errorBuilder: (_, _, _) => _MarkdownImageFallback(
            icon: Icons.broken_image_outlined,
            label: l10n.errorSolutionImageLoadFailed,
          ),
        ),
      ),
    );
  }

  /// 在系统默认程序中打开 Markdown 链接。
  ///
  /// 只允许 http/https，避免后端 Markdown 借助自定义 scheme 触发本地应用行为。
  Future<void> _openLink(BuildContext context, String? href) async {
    final uri = Uri.tryParse(href ?? '');
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      showLinkOpenError(context, href ?? '');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showLinkOpenError(context, href ?? '');
    }
  }
}

/// Markdown 图片无法安全展示时的可读占位。
class _MarkdownImageFallback extends StatelessWidget {
  /// 创建本地化图片占位。
  const _MarkdownImageFallback({required this.icon, required this.label});

  /// 状态图标。
  final IconData icon;

  /// 用户可见及屏幕阅读器文案。
  final String label;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: appColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: appColors.borderSecondary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 18, color: appColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                style: context.appTextStyles.caption.copyWith(
                  color: appColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 解决方案对话框标题栏。
class _DialogTitleBar extends StatelessWidget {
  /// 创建标题栏。
  const _DialogTitleBar({required this.title, required this.closeLabel});

  /// 解决方案标题。
  final String title;

  /// 关闭按钮无障碍文案。
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.appTextStyles.title3.copyWith(
                color: appColors.textPrimary,
                fontWeight: context.appFontWeight(FontWeight.w600),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: closeLabel,
            child: IconButton(
              tooltip: closeLabel,
              onPressed: () => Navigator.of(context).pop(),
              icon: const ExcludeSemantics(child: Icon(Icons.close)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 打开错误解决方案对话框。
Future<void> showErrorSolutionDialog(
  BuildContext context, {
  required ErrorSolution solution,
  Future<void> Function()? onRepairRequested,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ErrorSolutionDialog(
      solution: solution,
      onRepairRequested: onRepairRequested,
    ),
  );
}
