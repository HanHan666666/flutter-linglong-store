import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/installed_apps_provider.dart';
import '../../../application/providers/install_queue_provider.dart';
import '../../../domain/models/installed_app.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';

/// 我的应用页
class MyAppsPage extends ConsumerStatefulWidget {
  const MyAppsPage({super.key});

  @override
  ConsumerState<MyAppsPage> createState() => _MyAppsPageState();
}

class _MyAppsPageState extends ConsumerState<MyAppsPage> {
  /// 搜索关键词
  String _searchQuery = '';

  /// 搜索控制器
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 页面加载时获取已安装应用列表
    Future.microtask(() {
      ref.read(installedAppsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 过滤应用列表
  List<InstalledApp> _filterApps(List<InstalledApp> apps) {
    if (_searchQuery.isEmpty) {
      return apps;
    }

    final query = _searchQuery.toLowerCase();
    return apps.where((app) {
      final name = app.name.toLowerCase();
      final appId = app.appId.toLowerCase();
      return name.contains(query) || appId.contains(query);
    }).toList();
  }

  /// 打开应用
  Future<void> _openApp(InstalledApp app) async {
    try {
      final repo = ref.read(linglongCliRepositoryProvider);
      await repo.runApp(app.appId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('正在启动 ${app.name}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('启动失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 卸载应用
  Future<void> _uninstallApp(InstalledApp app) async {
    final confirmed = await ConfirmDialog.showUninstall(
      context,
      appName: app.name,
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(linglongCliRepositoryProvider);
      final result = await repo.uninstallApp(app.appId, app.version);

      if (mounted) {
        if (result.contains('失败')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('卸载失败: $result'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else {
          // 从列表中移除
          ref.read(installedAppsProvider.notifier).removeApp(app.appId);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${app.name} 已卸载'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('卸载异常: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(installedAppsProvider);
    final filteredApps = _filterApps(state.apps);

    return Column(
      children: [
        // 搜索框
        _buildSearchBar(context),

        // 内容区域
        Expanded(
          child: _buildContent(context, state, filteredApps),
        ),
      ],
    );
  }

  /// 构建搜索框
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: '搜索已安装的应用',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(
    BuildContext context,
    InstalledAppsState state,
    List<InstalledApp> filteredApps,
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
        title: '加载失败',
        description: state.error,
        retryText: '重试',
        onRetry: () {
          ref.read(installedAppsProvider.notifier).refresh();
        },
      );
    }

    // 空状态
    if (state.apps.isEmpty) {
      return const EmptyState(
        icon: Icons.apps_outage,
        title: '暂无已安装应用',
        description: '您还没有安装任何玲珑应用，去推荐页看看吧',
      );
    }

    // 搜索无结果
    if (filteredApps.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: '未找到匹配的应用',
        description: '没有找到 "$_searchQuery" 相关的应用',
        retryText: '清除搜索',
        onRetry: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
          });
        },
      );
    }

    // 应用列表
    return RefreshIndicator(
      onRefresh: () => ref.read(installedAppsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filteredApps.length,
        itemBuilder: (context, index) {
          final app = filteredApps[index];
          return _AppListItem(
            app: app,
            onOpen: () => _openApp(app),
            onUninstall: () => _uninstallApp(app),
          );
        },
      ),
    );
  }
}

/// 应用列表项
class _AppListItem extends StatelessWidget {
  const _AppListItem({
    required this.app,
    required this.onOpen,
    required this.onUninstall,
  });

  final InstalledApp app;
  final VoidCallback onOpen;
  final VoidCallback onUninstall;

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

                  // 版本号和大小
                  Row(
                    children: [
                      Text(
                        'v${app.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                      ),
                      if (app.size != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          app.size!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 操作按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 打开按钮
                ElevatedButton(
                  onPressed: onOpen,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('打开'),
                ),

                const SizedBox(width: 8),

                // 更多菜单
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'uninstall':
                        onUninstall();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'uninstall',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20),
                          SizedBox(width: 12),
                          Text('卸载'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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