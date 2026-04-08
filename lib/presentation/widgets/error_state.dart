import 'package:flutter/material.dart';
import '../../core/i18n/l10n/app_localizations.dart';

/// 错误状态组件
///
/// 显示错误信息和重试按钮
class ErrorState extends StatelessWidget {
  /// 错误标题
  final String? title;

  /// 错误描述
  final String? description;

  /// 错误信息
  final String? errorMessage;

  /// 自定义图标
  final IconData? icon;

  /// 图标大小
  final double iconSize;

  /// 图标颜色
  final Color? iconColor;

  /// 重试按钮文本
  final String? retryText;

  /// 重试按钮回调
  final VoidCallback? onRetry;

  /// 是否显示详细错误信息
  final bool showDetails;

  const ErrorState({
    super.key,
    this.title,
    this.description,
    this.errorMessage,
    this.icon,
    this.iconSize = 64,
    this.iconColor,
    this.retryText,
    this.onRetry,
    this.showDetails = false,
  });

  /// 创建网络错误状态
  const ErrorState.network({
    super.key,
    this.title,
    this.description,
    this.errorMessage,
    this.iconSize = 64,
    this.iconColor,
    this.retryText,
    this.onRetry,
    this.showDetails = false,
  }) : icon = Icons.wifi_off;

  /// 创建服务器错误状态
  const ErrorState.server({
    super.key,
    this.title,
    this.description,
    this.errorMessage,
    this.iconSize = 64,
    this.iconColor,
    this.retryText,
    this.onRetry,
    this.showDetails = false,
  }) : icon = Icons.cloud_off;

  /// 创建通用错误状态
  const ErrorState.generic({
    super.key,
    this.title,
    this.description,
    this.errorMessage,
    this.iconSize = 64,
    this.iconColor,
    this.retryText,
    this.onRetry,
    this.showDetails = false,
  }) : icon = Icons.error_outline;

  /// 创建安装错误状态
  const ErrorState.install({
    super.key,
    this.title,
    this.description,
    this.errorMessage,
    this.iconSize = 64,
    this.iconColor,
    this.retryText,
    this.onRetry,
    this.showDetails = false,
  }) : icon = Icons.download_done_outlined;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defaultTitle = title ?? (l10n?.errorUnknown ?? '出错了');
    final defaultDescription = description ?? (l10n?.errorNetworkDetail ?? '请稍后重试');
    final defaultIcon = icon ?? Icons.error_outline;
    final defaultIconColor = iconColor ?? Theme.of(context).colorScheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 错误图标（装饰性）
            ExcludeSemantics(
              child: Icon(
                defaultIcon,
                size: iconSize,
                color: defaultIconColor.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 16),

            // 错误标题
            Text(
              defaultTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // 错误描述
            Text(
              defaultDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),

            // 详细错误信息
            if (showDetails && errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // 重试按钮
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? (l10n?.retry ?? '重试')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}