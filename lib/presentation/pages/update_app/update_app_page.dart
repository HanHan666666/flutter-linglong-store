import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_operation_queue_provider.dart';
import '../../../application/providers/install_queue_provider.dart';
import '../../../application/providers/network_speed_provider.dart';
import '../../../application/providers/update_apps_provider.dart';
// 更新页位于 presentation/pages/update_app，下列跨层依赖必须回退到 lib 根目录，
// 否则 clean checkout / CI 构建时会错误解析到 lib/presentation/** 虚假路径。
import '../../../core/config/routes.dart';
import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/install_progress.dart';
import '../../../domain/models/install_queue_state.dart';
import '../../../domain/models/install_task.dart';
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

  /// 手动检查更新
  void _checkUpdates() {
    ref.read(updateAppsProvider.notifier).checkUpdates();
  }

  /// 全部更新
  void _updateAll() {
    final installState = ref.read(installQueueProvider);
    final apps = ref
        .read(updateAppsProvider)
        .apps
        .where((app) => !installState.isAppInQueue(app.appId))
        .toList();
    if (apps.isEmpty) {
      return;
    }

    final operations = apps
        .map(
          (app) => EnqueueAppOperationParams(
            kind: InstallTaskKind.update,
            appId: app.appId,
            appName: app.name,
            icon: app.icon,
          ),
        )
        .toList();
    ref
        .read(appOperationQueueControllerProvider)
        .enqueueBatchOperations(operations);
  }

  /// 更新单个应用
  void _updateApp(UpdatableApp app) {
    final installState = ref.read(installQueueProvider);
    final installTask = installState.getAppInstallStatus(app.appId);
    if (_shouldDisableUpdateAction(installState, installTask)) {
      return;
    }

    ref
        .read(appOperationQueueControllerProvider)
        .enqueueAppOperation(
          EnqueueAppOperationParams(
            kind: InstallTaskKind.update,
            appId: app.appId,
            appName: app.name,
            icon: app.icon,
          ),
        );
  }

  /// 取消应用安装/更新
  Future<void> _cancelAppInstall(String appId) async {
    await ref.read(installQueueProvider.notifier).cancelTask(appId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateAppsProvider);
    final installState = ref.watch(installQueueProvider);

    return Column(
      children: [
        // 头部区域：更新按钮
        _buildHeader(context, state, installState),

        // 内容区域
        Expanded(child: _buildContent(context, state, installState)),
      ],
    );
  }

  /// 构建头部区域
  Widget _buildHeader(
    BuildContext context,
    UpdateAppsState state,
    InstallQueueState installState,
  ) {
    final isUpdating = installState.hasActiveTasks();
    final isChecking = state.isLoading;
    final l10n = AppLocalizations.of(context);

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
              _buildHeaderSummaryText(context, state),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: isChecking ? null : _checkUpdates,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  isChecking
                      ? (l10n?.checkingUpdate ?? '检查更新中...')
                      : (l10n?.checkUpdate ?? '检查更新'),
                ),
              ),
              if (state.apps.isNotEmpty) ...[
                const SizedBox(width: 8),
                // 全部更新按钮
                FilledButton.icon(
                  onPressed: isUpdating ? null : _updateAll,
                  icon: isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.update, size: 18),
                  label: Text(
                    isUpdating
                        ? (l10n?.updating ?? '正在更新...')
                        : (l10n?.updateAll ?? '全部更新'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _buildHeaderSummaryText(BuildContext context, UpdateAppsState state) {
    final l10n = AppLocalizations.of(context);
    if (state.apps.isNotEmpty) {
      return l10n?.updateCount(state.count) ?? '共 ${state.count} 个应用可更新';
    }

    if (state.error != null) {
      return l10n?.updateCheckFailed ?? '检查更新失败';
    }

    if (state.isLoading && !state.hasLoadedOnce) {
      return l10n?.checkingUpdate ?? '检查更新中...';
    }

    return l10n?.noUpdate ?? '暂无更新';
  }

  /// 构建内容区域
  Widget _buildContent(
    BuildContext context,
    UpdateAppsState state,
    InstallQueueState installState,
  ) {
    final l10n = AppLocalizations.of(context);

    // 加载中状态 — 仅在首次加载（列表为空且尚无历史结果）时显示全屏 loading。
    if (state.isLoading && state.apps.isEmpty && !state.hasLoadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }

    // 错误状态 — 仅在列表为空时显示
    if (state.error != null && state.apps.isEmpty) {
      return _buildRefreshOverlay(
        isRefreshing: state.isLoading,
        child: EmptyState(
          icon: Icons.error_outline,
          title: l10n?.updateCheckFailed ?? '检查更新失败',
          description: state.error,
          retryText: l10n?.retry ?? '重试',
          onRetry: () {
            ref.read(updateAppsProvider.notifier).checkUpdates();
          },
        ),
      );
    }

    // 空状态
    if (state.apps.isEmpty) {
      return _buildRefreshOverlay(
        isRefreshing: state.isLoading,
        child: EmptyState(
          icon: Icons.update,
          title: l10n?.noUpdate ?? '暂无更新',
          description: l10n?.allAppsUpToDate ?? '您的所有应用都是最新版本',
        ),
      );
    }

    // 可更新应用列表
    return _buildRefreshOverlay(
      isRefreshing: state.isLoading,
      child: RefreshIndicator(
        onRefresh: () => ref.read(updateAppsProvider.notifier).refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: state.apps.length,
          itemBuilder: (context, index) {
            final app = state.apps[index];
            final installTask = installState.getAppInstallStatus(app.appId);
            return _UpdatableAppItem(
              key: ValueKey(app.appId),
              app: app,
              installTask: installTask,
              isUpdateDisabled: _shouldDisableUpdateAction(
                installState,
                installTask,
              ),
              onTap: () =>
                  context.goToAppDetail(app.appId, appInfo: app.installedApp),
              onUpdate: () => _updateApp(app),
              onCancel: installTask != null
                  ? () => _cancelAppInstall(app.appId)
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildRefreshOverlay({
    required bool isRefreshing,
    required Widget child,
  }) {
    if (!isRefreshing) {
      return child;
    }

    return Stack(
      children: [
        Positioned.fill(child: child),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(minHeight: 2),
        ),
      ],
    );
  }

  bool _shouldDisableUpdateAction(
    InstallQueueState installState,
    InstallTask? installTask,
  ) {
    // 队列仍在处理其他任务时，如果当前列表项只是历史成功任务残留，
    // 说明这是一条等待后台刷新剔除的脏数据，必须阻止再次入队。
    return installState.hasActiveTasks() && (installTask?.isSuccess ?? false);
  }
}

/// 可更新应用列表项
class _UpdatableAppItem extends ConsumerStatefulWidget {
  const _UpdatableAppItem({
    super.key,
    required this.app,
    required this.installTask,
    required this.isUpdateDisabled,
    required this.onTap,
    required this.onUpdate,
    required this.onCancel,
  });

  final UpdatableApp app;
  final InstallTask? installTask;
  final bool isUpdateDisabled;
  final VoidCallback onTap;
  final VoidCallback onUpdate;
  final VoidCallback? onCancel;

  @override
  ConsumerState<_UpdatableAppItem> createState() =>
      _UpdatableAppItemState();
}

class _UpdatableAppItemState extends ConsumerState<_UpdatableAppItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 确定按钮状态：仅处理活跃任务，其余均显示"更新"
    final buttonState = _getButtonState();
    final progress = widget.installTask?.progress ?? 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        margin: const EdgeInsets.all(4.0),
        elevation: 0,
        color: Colors.transparent,
        clipBehavior: Clip.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadius.smRadius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // 应用图标
                    AppIcon(
                      iconUrl: widget.app.icon,
                      size: 48,
                      borderRadius: AppRadius.sm,
                      appName: widget.app.name,
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // 应用信息（名称 + 版本）
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.app.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${widget.app.currentVersion} → ${widget.app.latestVersion}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // 更新按钮
                    InstallButton(
                      appName: widget.app.name,
                      state: buttonState,
                      progress: progress,
                      downloadSpeed:
                          buttonState == InstallButtonState.installing
                              ? ref.watch(networkSpeedProvider).formatted
                              : null,
                      onPressed: widget.isUpdateDisabled
                          ? () {}
                          : widget.onUpdate,
                      onCancel: widget.onCancel,
                      size: ButtonSize.small,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 获取按钮状态
  ///
  /// 仅处理活跃任务状态（pending/installing），其余情况均显示"更新"。
  /// 已完成的任务会通过乐观移除从列表中清除，不会走到这里。
  InstallButtonState _getButtonState() {
    final status = widget.installTask?.status;
    if (status == InstallStatus.pending) {
      return InstallButtonState.pending;
    }
    if (status == InstallStatus.downloading || status == InstallStatus.installing) {
      return InstallButtonState.installing;
    }
    return InstallButtonState.update;
  }
}
