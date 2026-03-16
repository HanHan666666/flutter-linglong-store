import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/running_process_provider.dart';
import '../../../domain/models/running_app.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/empty_state.dart';

/// 进程管理页
class ProcessPage extends ConsumerStatefulWidget {
  const ProcessPage({super.key});

  @override
  ConsumerState<ProcessPage> createState() => _ProcessPageState();
}

class _ProcessPageState extends ConsumerState<ProcessPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时启动自动刷新
    Future.microtask(() {
      ref.read(runningProcessProvider.notifier).startAutoRefresh();
    });
  }

  @override
  void dispose() {
    // 页面销毁时停止自动刷新
    ref.read(runningProcessProvider.notifier).stopAutoRefresh();
    super.dispose();
  }

  /// 停止应用
  Future<void> _killApp(RunningApp app) async {
    final confirmed = await _showKillConfirmDialog(app.name);
    if (confirmed != true || !mounted) return;

    try {
      final success =
          await ref.read(runningProcessProvider.notifier).killApp(app.name);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${app.name} 已停止'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('停止 ${app.name} 失败'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('停止异常: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 显示停止确认对话框
  Future<bool?> _showKillConfirmDialog(String appName) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认停止'),
        content: Text('确定要停止 "$appName" 吗？\n未保存的数据可能会丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('停止'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(runningProcessProvider);

    return Column(
      children: [
        // 标题栏
        _buildHeader(context),

        // 内容区域
        Expanded(
          child: _buildContent(context, state),
        ),
      ],
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context) {
    final count = ref.watch(runningAppsCountProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 标题和计数
          Expanded(
            child: Row(
              children: [
                Text(
                  '运行中应用',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // 自动刷新指示器
          StreamBuilder(
            stream: _getAutoRefreshStream(),
            builder: (context, snapshot) {
              final isAutoRefreshing =
                  ref.read(runningProcessProvider.notifier).isAutoRefreshing;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAutoRefreshing) ...[
                    Text(
                      '自动刷新',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.sync,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),

          // 刷新按钮
          IconButton(
            onPressed: () => ref.read(runningProcessProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),

          // 自动刷新开关
          IconButton(
            onPressed: () =>
                ref.read(runningProcessProvider.notifier).toggleAutoRefresh(),
            icon: Icon(
              ref.read(runningProcessProvider.notifier).isAutoRefreshing
                  ? Icons.pause
                  : Icons.play_arrow,
            ),
            tooltip: ref.read(runningProcessProvider.notifier).isAutoRefreshing
                ? '暂停自动刷新'
                : '开始自动刷新',
          ),
        ],
      ),
    );
  }

  /// 获取自动刷新状态流
  Stream<void> _getAutoRefreshStream() {
    // 创建一个周期性流来触发重建
    return Stream.periodic(const Duration(seconds: 1));
  }

  /// 构建内容区域
  Widget _buildContent(
    BuildContext context,
    RunningProcessState state,
  ) {
    // 加载中状态
    if (state.isLoading && state.apps.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 错误状态
    if (state.error != null && state.apps.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: '加载失败',
        description: state.error,
        retryText: '重试',
        onRetry: () => ref.read(runningProcessProvider.notifier).refresh(),
      );
    }

    // 空状态
    if (state.apps.isEmpty) {
      return const EmptyState(
        icon: Icons.layers_clear,
        title: '没有运行中的应用',
        description: '当前没有玲珑应用在运行中',
      );
    }

    // 进程列表
    return RefreshIndicator(
      onRefresh: () => ref.read(runningProcessProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.apps.length,
        itemBuilder: (context, index) {
          final app = state.apps[index];
          return _ProcessListItem(
            app: app,
            onStop: () => _killApp(app),
          );
        },
      ),
    );
  }
}

/// 进程列表项
class _ProcessListItem extends StatelessWidget {
  const _ProcessListItem({
    required this.app,
    required this.onStop,
  });

  final RunningApp app;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 运行状态指示器
            Container(
              width: 8,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(width: 12),

            // 应用图标
            _buildIcon(context),

            const SizedBox(width: 12),

            // 应用信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 应用名称
                  Text(
                    app.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // PID
                  Row(
                    children: [
                      Icon(
                        Icons.memory,
                        size: 14,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PID: ${app.pid}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 停止按钮
            IconButton(
              onPressed: onStop,
              icon: const Icon(Icons.stop_circle_outlined),
              color: Theme.of(context).colorScheme.error,
              tooltip: '停止应用',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建应用图标
  ///
  /// 使用 AppIcon 组件统一处理图标加载、缓存和错误处理
  Widget _buildIcon(BuildContext context) {
    return AppIcon(
      iconUrl: app.icon,
      size: 48,
      borderRadius: 8,
      appName: app.name,
    );
  }
}