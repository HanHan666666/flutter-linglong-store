import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/application_card_state_provider.dart';
import '../../../application/providers/install_queue_provider.dart';
import '../../../application/providers/installed_apps_provider.dart';
import '../../../application/providers/update_apps_provider.dart';
import '../../../core/utils/version_compare.dart';
import '../../../domain/models/installed_app.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/widgets.dart';

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

  /// 合并同 appId 的多版本安装记录，只保留最高版本用于卡片展示。
  List<InstalledApp> _mergeApps(List<InstalledApp> apps) {
    final merged = <String, InstalledApp>{};

    for (final app in apps) {
      final current = merged[app.appId];
      if (current == null ||
          VersionCompare.greaterThan(app.version, current.version)) {
        merged[app.appId] = app;
      }
    }

    return merged.values.toList();
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
          // 乐观更新：从已安装列表中移除
          ref
              .read(installedAppsProvider.notifier)
              .removeApp(app.appId, app.version);
          // 后台重新检查更新列表（不 await，不阻塞 UI）
          ref.read(updateAppsProvider.notifier).checkUpdates();

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${app.name} 已卸载')));
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
    final cardStateIndex = ref.watch(applicationCardStateIndexProvider);
    final filteredApps = _filterApps(_mergeApps(state.apps));

    return Column(
      children: [
        // 搜索框
        _buildSearchBar(context),

        // 内容区域
        Expanded(
          child: _buildContent(context, state, filteredApps, cardStateIndex),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    ApplicationCardStateIndex cardStateIndex,
  ) {
    // 加载中状态
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
          final cardState = cardStateIndex.resolve(
            appId: app.appId,
            latestVersion: app.version,
          );
          return AppCard(
            appId: app.appId,
            name: app.name,
            description: app.description ?? 'v${app.version}',
            iconUrl: app.icon,
            buttonState: cardState.buttonState,
            progress: cardState.progress,
            isInstalling: cardState.isInstalling,
            onPrimaryPressed: () => handleAppCardPrimaryAction(
              context: context,
              ref: ref,
              buttonState: cardState.buttonState,
              appId: app.appId,
              appName: app.name,
              icon: app.icon,
              version: app.version,
            ),
            menuActions: [
              AppCardMenuAction(
                value: 'uninstall',
                label: '卸载',
                icon: Icons.delete_outline,
                onSelected: () => _uninstallApp(app),
              ),
            ],
          );
        },
      ),
    );
  }
}
