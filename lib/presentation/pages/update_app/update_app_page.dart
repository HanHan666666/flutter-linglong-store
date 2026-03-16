import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/install_queue_provider.dart';
import '../../../application/providers/update_apps_provider.dart';
import '../../../domain/models/install_task.dart';
import '../../../domain/models/install_progress.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/install_button.dart';

/// 应用更新页
class UpdateAppPage extends ConsumerStatefulWidget {
  const UpdateAppPage({super.key});

  @override
  ConsumerState<UpdateAppPage> createState() => _UpdateAppPageState();
}

class _UpdateAppPageState extends ConsumerState<UpdateAppPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时检查更新
    Future.microtask(() {
      ref.read(updateAppsProvider.notifier).checkUpdates();
    });
  }

  /// 全部更新
  void _updateAll() {
    ref.read(updateAppsProvider.notifier).updateAll();
  }

  /// 更新单个应用
  void _updateApp(String appId) {
    ref.read(updateAppsProvider.notifier).updateApp(appId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateAppsProvider);
    final installState = ref.watch(installQueueProvider);

    return Column(
      children: [
        // 头部区域：更新按钮
        _buildHeader(context, state),

        // 内容区域
        Expanded(
          child: _buildContent(context, state, installState),
        ),
      ],
    );
  }

  /// 构建头部区域
  Widget _buildHeader(BuildContext context, UpdateAppsState state) {
    // 如果没有可更新应用，不显示头部
    if (state.apps.isEmpty || state.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 更新数量提示
          Expanded(
            child: Text(
              '共 ${state.count} 个应用可更新',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),

          // 全部更新按钮
          FilledButton.icon(
            onPressed: _updateAll,
            icon: const Icon(Icons.system_update, size: 18),
            label: const Text('全部更新'),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(
    BuildContext context,
    UpdateAppsState state,
    InstallQueueState installState,
  ) {
    // 加载中状态
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 错误状态
    if (state.error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: '检查更新失败',
        description: state.error,
        retryText: '重试',
        onRetry: () {
          ref.read(updateAppsProvider.notifier).checkUpdates();
        },
      );
    }

    // 空状态
    if (state.apps.isEmpty) {
      return const EmptyState(
        icon: Icons.system_update_alt,
        title: '暂无更新',
        description: '您的所有应用都是最新版本',
      );
    }

    // 可更新应用列表
    return RefreshIndicator(
      onRefresh: () => ref.read(updateAppsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.apps.length,
        itemBuilder: (context, index) {
          final app = state.apps[index];
          final installTask = installState.getAppInstallStatus(app.appId);
          return _UpdatableAppItem(
            app: app,
            installTask: installTask,
            onUpdate: () => _updateApp(app.appId),
          );
        },
      ),
    );
  }
}

/// 可更新应用列表项
class _UpdatableAppItem extends StatelessWidget {
  const _UpdatableAppItem({
    required this.app,
    required this.installTask,
    required this.onUpdate,
  });

  final UpdatableApp app;
  final InstallTask? installTask;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 确定按钮状态
    final buttonState = _getButtonState();
    final progress = installTask?.progress ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主行：图标、信息、按钮
            Row(
              children: [
                // 应用图标
                AppIcon(
                  iconUrl: app.icon,
                  size: 48,
                  borderRadius: 8,
                  appName: app.name,
                ),

                const SizedBox(width: 12),

                // 应用信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 应用名称
                      Text(
                        app.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // 版本信息
                      Text(
                        '${app.currentVersion} → ${app.latestVersion}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // 更新按钮
                InstallButton(
                  state: buttonState,
                  progress: progress,
                  onPressed: onUpdate,
                  onCancel: installTask != null
                      ? () {
                          // 取消安装
                        }
                      : null,
                  size: ButtonSize.small,
                ),
              ],
            ),

            // 安装进度消息
            if (installTask != null && installTask!.message != null) ...[
              const SizedBox(height: 8),
              Text(
                installTask!.message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: installTask!.isFailed
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            // 更新说明
            if (app.latestVersionDescription != null &&
                installTask == null) ...[
              const SizedBox(height: 8),
              Text(
                app.latestVersionDescription!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 获取按钮状态
  InstallButtonState _getButtonState() {
    if (installTask != null) {
      switch (installTask!.status) {
        case InstallStatus.pending:
        case InstallStatus.downloading:
        case InstallStatus.installing:
          return InstallButtonState.installing;
        case InstallStatus.success:
        case InstallStatus.failed:
        case InstallStatus.cancelled:
          break;
      }
    }
    return InstallButtonState.update;
  }
}