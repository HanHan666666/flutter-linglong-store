import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import '../../application/providers/app_collection_sync_provider.dart';
import '../../core/config/keepalive_visibility_sync.dart';
import '../../core/config/theme.dart';
import '../../core/di/providers.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/window_service.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_task.dart';
import 'sidebar.dart';
import 'title_bar.dart';

/// 应用外壳 - 主布局框架
///
/// 包含：TitleBar（顶部）+ Sidebar（左侧）+ Content（右侧）
/// 支持响应式布局和窗口控制
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WindowListener {
  /// 窗口是否最大化
  bool _isMaximized = false;
  ProviderSubscription<InstallQueueState>? _installQueueSubscription;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
    _installQueueSubscription = ref.listenManual<InstallQueueState>(
      installQueueProvider,
      (previous, next) {
        if (previous?.currentTask != null && next.currentTask == null) {
          final completedTask = next.history.firstOrNull;
          if (completedTask?.status == InstallStatus.success) {
            ref
                .read(appCollectionSyncServiceProvider)
                .syncAfterSuccessfulOperation();

            // 如果开启了『安装后自动打开』，且是安装任务（不是更新），自动启动应用
            final prefs = ref.read(globalAppProvider).userPreferences;
            if (prefs.autoRunAfterInstall &&
                completedTask!.kind == InstallTaskKind.install) {
              _tryRunApp(completedTask.appId);
            }
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _installQueueSubscription?.close();
    windowManager.removeListener(this);
    super.dispose();
  }

  /// WindowListener 回调 - 窗口最大化
  @override
  void onWindowMaximize() {
    if (mounted && !_isMaximized) {
      setState(() => _isMaximized = true);
    }
  }

  /// WindowListener 回调 - 窗口取消最大化
  @override
  void onWindowUnmaximize() {
    if (mounted && _isMaximized) {
      setState(() => _isMaximized = false);
    }
  }

  /// 检查窗口最大化状态
  Future<void> _checkMaximized() async {
    final isMaximized = await WindowService.isMaximized();
    if (mounted && _isMaximized != isMaximized) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  /// 安装成功后自动启动应用（autoRunAfterInstall=true 时触发）
  Future<void> _tryRunApp(String appId) async {
    try {
      await ref.read(linglongCliRepositoryProvider).runApp(appId);
    } catch (e) {
      AppLogger.warning('自动启动应用失败: $appId, 错误: $e');
    }
  }

  /// 处理窗口最小化
  void _onMinimize() {
    WindowService.minimize();
  }

  /// 处理窗口最大化/还原
  void _onMaximize() {
    WindowService.toggleMaximize();
    // 延迟检查状态，确保窗口动画完成
    Future.delayed(const Duration(milliseconds: 100), _checkMaximized);
  }

  /// 处理窗口关闭
  void _onClose() {
    // 检查是否有正在进行的安装任务
    final hasActiveTasks = ref.read(hasActiveInstallTasksProvider);
    if (hasActiveTasks) {
      // 如果有任务，显示确认对话框
      _showCloseConfirmDialog();
    } else {
      WindowService.close();
    }
  }

  /// 显示关闭确认对话框
  void _showCloseConfirmDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n?.confirmExit ?? '确认退出'),
          content: Text(l10n?.exitWithInstalling ?? '有正在进行的安装任务，确定要退出吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n?.cancel ?? '取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                WindowService.close();
              },
              child: Text(l10n?.exitBtn ?? '退出'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final routerState = GoRouterState.of(context);
    final currentPath = routerState.matchedLocation;
    final currentSearchQuery = currentPath == '/search_list'
        ? (routerState.uri.queryParameters['q'] ?? '')
        : '';
    final updateCount = ref.watch(updatableAppsCountProvider);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // 自定义标题栏
              CustomTitleBar(
                isMaximized: _isMaximized,
                onMinimize: _onMinimize,
                onMaximize: _onMaximize,
                onClose: _onClose,
                currentSearchQuery: currentSearchQuery,
              ),
              // 主内容区域
              Expanded(
                child: Row(
                  children: [
                    // 左侧导航栏
                    Sidebar(
                      currentPath: currentPath,
                      updateCount: updateCount,
                    ),
                    // 右侧内容区域，背景跟随主题
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.appColors.surfaceContainerLow,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppRadius.sm),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppRadius.sm),
                          ),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          KeepAliveVisibilitySync(currentPath: currentPath),
        ],
      ),
    );
  }
}
