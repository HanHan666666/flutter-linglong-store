import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../application/providers/install_queue_provider.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_task.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import 'app_icon.dart';
import 'install_button.dart';

/// 应用卡片组件
///
/// 显示应用的基本信息，包括图标、名称、描述和安装按钮
class AppCard extends ConsumerWidget {
  /// 应用ID
  final String? appId;

  /// 应用名称
  final String? name;

  /// 应用描述
  final String? description;

  /// 应用图标URL
  final String? iconUrl;

  /// 应用版本
  final String? version;

  /// 是否已安装
  final bool isInstalled;

  /// 是否有更新
  final bool hasUpdate;

  /// 是否正在安装
  final bool isInstalling;

  /// 安装进度 (0.0 - 1.0)
  final double installProgress;

  /// 卡片点击回调
  final VoidCallback? onTap;

  /// 安装按钮点击回调
  final VoidCallback? onInstall;

  /// 打开按钮点击回调
  final VoidCallback? onOpen;

  /// 卸载按钮点击回调
  final VoidCallback? onUninstall;

  /// 取消安装回调
  final VoidCallback? onCancelInstall;

  /// 卡片类型
  final AppCardType type;

  /// 是否显示骨架屏
  final bool isLoading;

  const AppCard({
    super.key,
    this.appId,
    this.name,
    this.description,
    this.iconUrl,
    this.version,
    this.isInstalled = false,
    this.hasUpdate = false,
    this.isInstalling = false,
    this.installProgress = 0.0,
    this.onTap,
    this.onInstall,
    this.onOpen,
    this.onUninstall,
    this.onCancelInstall,
    this.type = AppCardType.default_,
    this.isLoading = false,
  });

  /// 创建骨架屏卡片
  const AppCard.skeleton({
    super.key,
    this.type = AppCardType.default_,
  })  : appId = null,
        name = null,
        description = null,
        iconUrl = null,
        version = null,
        isInstalled = false,
        hasUpdate = false,
        isInstalling = false,
        installProgress = 0.0,
        onTap = null,
        onInstall = null,
        onOpen = null,
        onUninstall = null,
        onCancelInstall = null,
        isLoading = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return _buildSkeletonCard(context);
    }

    return _buildCard(context, ref);
  }

  /// 构建卡片主体
  Widget _buildCard(BuildContext context, WidgetRef ref) {
    // 从 Provider 获取安装状态（如果提供了 appId）
    InstallButtonState installState;
    double progress = installProgress;

    if (appId != null) {
      // 检查应用是否在安装队列中
      final installQueue = ref.watch(installQueueProvider);
      final task = installQueue.getAppInstallStatus(appId!);

      if (task != null) {
        // 使用队列中的状态
        installState = _getInstallButtonStateFromTask(task);
        progress = task.progress;
      } else {
        // 使用传入的状态
        installState = _getInstallButtonState();
      }
    } else {
      installState = _getInstallButtonState();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 应用图标 - 使用 AppIcon 组件
              AppIcon(
                iconUrl: iconUrl,
                size: 64,
                borderRadius: 12,
                appName: name,
              ),
              const SizedBox(width: 12),

              // 应用信息
              Expanded(child: _buildContent(context)),

              const SizedBox(width: 12),

              // 操作按钮 - 使用 InstallButton 组件
              InstallButton(
                state: installState,
                progress: progress,
                onPressed: () => _handleButtonPress(installState),
                onCancel: onCancelInstall,
                size: ButtonSize.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 应用名称
        Text(
          name ?? (l10n?.noApps ?? '未知应用'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // 应用描述
        if (description != null)
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

        // 推荐类型显示版本号
        if (type == AppCardType.recommend && version != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'v$version',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n?.linglongRecommend ?? '推荐',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 获取安装按钮状态（基于传入参数）
  InstallButtonState _getInstallButtonState() {
    if (isInstalling) {
      return InstallButtonState.installing;
    }
    if (!isInstalled) {
      return InstallButtonState.notInstalled;
    }
    if (hasUpdate) {
      return InstallButtonState.update;
    }
    return InstallButtonState.open;
  }

  /// 从安装任务获取安装按钮状态
  InstallButtonState _getInstallButtonStateFromTask(InstallTask task) {
    switch (task.status) {
      case InstallStatus.pending:
      case InstallStatus.downloading:
      case InstallStatus.installing:
        return InstallButtonState.installing;
      case InstallStatus.success:
        return InstallButtonState.open;
      case InstallStatus.failed:
      case InstallStatus.cancelled:
        return InstallButtonState.notInstalled;
    }
  }

  /// 处理按钮点击
  void _handleButtonPress(InstallButtonState state) {
    switch (state) {
      case InstallButtonState.notInstalled:
      case InstallButtonState.update:
        onInstall?.call();
        break;
      case InstallButtonState.open:
        onOpen?.call();
        break;
      case InstallButtonState.uninstall:
        onUninstall?.call();
        break;
      case InstallButtonState.installing:
        // 安装中，不做处理或显示进度详情
        break;
      case InstallButtonState.installed:
        onOpen?.call();
        break;
    }
  }

  /// 构建骨架屏卡片（使用 shimmer 动画）
  Widget _buildSkeletonCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Row(
            children: [
              // 图标占位
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              // 内容占位
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 按钮占位
              Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 应用卡片类型枚举
enum AppCardType {
  /// 默认类型
  default_,

  /// 推荐类型（显示版本号和推荐标签）
  recommend,

  /// 列表类型
  list,

  /// 网格类型
  grid,
}