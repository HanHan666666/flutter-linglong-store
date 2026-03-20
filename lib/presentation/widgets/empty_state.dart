import 'package:flutter/material.dart';
import '../../core/i18n/l10n/app_localizations.dart';

/// 空状态组件
///
/// 显示空数据占位图和提示文字，可选的重试按钮
class EmptyState extends StatelessWidget {
  /// 标题文本
  final String? title;

  /// 描述文本
  final String? description;

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

  /// 自定义操作按钮
  final Widget? action;

  const EmptyState({
    super.key,
    this.title,
    this.description,
    this.icon,
    this.iconSize = 64,
    this.iconColor,
    this.retryText,
    this.onRetry,
    this.action,
  });

  /// 创建搜索无结果状态
  const EmptyState.search({
    super.key,
    this.title,
    this.description,
    this.iconSize = 64,
    this.iconColor,
    this.retryText,
    this.onRetry,
    this.action,
  }) : icon = Icons.search_off;

  /// 创建无数据状态
  const EmptyState.noData({
    super.key,
    this.title,
    this.description,
    this.iconSize = 64,
    this.iconColor,
    this.retryText,
    this.onRetry,
    this.action,
  }) : icon = Icons.inbox;

  /// 创建无网络状态
  const EmptyState.noNetwork({
    super.key,
    this.title,
    this.description,
    this.iconSize = 64,
    this.iconColor,
    this.retryText,
    this.onRetry,
    this.action,
  }) : icon = Icons.wifi_off;

  /// 创建无安装应用状态
  const EmptyState.noApps({
    super.key,
    this.title,
    this.description,
    this.iconSize = 64,
    this.iconColor,
    this.retryText,
    this.onRetry,
    this.action,
  }) : icon = Icons.apps_outage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defaultTitle = title ?? (l10n?.noData ?? '暂无数据');
    final defaultDescription = description ?? (l10n?.noDataDescription ?? '这里还没有任何内容');
    final defaultIcon = icon ?? Icons.inbox;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标
            Icon(
              defaultIcon,
              size: iconSize,
              color: iconColor ??
                  Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.3),
            ),

            const SizedBox(height: 16),

            // 标题
            Text(
              defaultTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
              textAlign: TextAlign.center,
            ),

            if (defaultDescription.isNotEmpty) ...[
              const SizedBox(height: 8),

              // 描述
              Text(
                defaultDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                textAlign: TextAlign.center,
              ),
            ],

            // 自定义操作按钮
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],

            // 重试按钮
            if (onRetry != null) ...[
              const SizedBox(height: 16),
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