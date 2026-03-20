import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/application_card_state_provider.dart';
import '../../../application/providers/installed_apps_provider.dart';
import '../../../core/di/providers.dart'
    show linglongCliRepositoryProvider, analyticsRepositoryProvider;
import '../../../application/providers/running_process_provider.dart';
import '../../../application/providers/update_apps_provider.dart';
import '../../../core/config/page_visibility.dart';
import '../../../core/config/routes.dart';
import '../../../core/config/theme.dart';
import '../../../core/config/visibility_aware_mixin.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/utils/version_compare.dart';
import '../../../domain/models/installed_app.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/linglong_process_panel.dart';
import '../../widgets/widgets.dart';

enum _MyAppsTab { app, process }

/// 我的应用页
class MyAppsPage extends ConsumerStatefulWidget {
  const MyAppsPage({super.key});

  @override
  ConsumerState<MyAppsPage> createState() => _MyAppsPageState();
}

class _MyAppsPageState extends ConsumerState<MyAppsPage>
    with AutomaticKeepAliveClientMixin, VisibilityAwareMixin {
  /// 搜索关键词
  String _searchQuery = '';

  /// 搜索控制器
  final _searchController = TextEditingController();

  _MyAppsTab _activeTab = _MyAppsTab.app;

  @override
  bool get wantKeepAlive => true;

  @override
  String get routePath => AppRoutes.myApps;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(installedAppsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    ref.read(runningProcessProvider.notifier).setProcessTabActive(false);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void onVisibilityChanged(PageVisibilityEvent event) {
    if (event.becameVisible) {
      ref.read(runningProcessProvider.notifier).setPageVisible(true);
      return;
    }

    if (event.becameHidden) {
      ref.read(runningProcessProvider.notifier).setPageVisible(false);
    }
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

  void _setActiveTab(_MyAppsTab tab) {
    if (_activeTab == tab) {
      return;
    }

    setState(() {
      _activeTab = tab;
    });

    ref
        .read(runningProcessProvider.notifier)
        .setProcessTabActive(tab == _MyAppsTab.process);
  }

  /// 卸载应用（含运行中检测）
  ///
  /// 若应用正在运行，先弹出「强制关闭并卸载」确认弹窗，
  /// 用户确认后依次 kill 所有运行实例再执行卸载。
  Future<void> _uninstallApp(InstalledApp app) async {
    // 检查应用是否正在运行
    final runningApps = ref.read(runningAppsListProvider);
    final runningInstances = runningApps
        .where((r) => r.appId == app.appId)
        .toList();

    bool? confirmed;
    if (runningInstances.isNotEmpty) {
      // 应用运行中，显示强制关闭确认弹窗
      confirmed = await ConfirmDialog.showUninstallRunning(
        context,
        appName: app.name,
      );
    } else {
      confirmed = await ConfirmDialog.showUninstall(context, appName: app.name);
    }

    if (confirmed != true || !mounted) return;

    // 若运行中，先强制关闭所有运行实例
    if (runningInstances.isNotEmpty) {
      for (final running in runningInstances) {
        await ref.read(runningProcessProvider.notifier).killApp(running);
      }
    }

    try {
      final repo = ref.read(linglongCliRepositoryProvider);
      final result = await repo.uninstallApp(app.appId, app.version);

      if (mounted) {
        if (result.contains('失败')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.uninstallFailed(result) ??
                    '卸载失败: $result',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else {
          ref
              .read(installedAppsProvider.notifier)
              .removeApp(app.appId, app.version);
          ref.read(updateAppsProvider.notifier).checkUpdates();

          // 上报卸载统计记录（fire-and-forget）
          ref
              .read(analyticsRepositoryProvider)
              .reportUninstall(app.appId, app.version, appName: app.name);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.uninstallSuccess(app.name) ??
                    '${app.name} 已卸载',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.uninstallError(e.toString()) ??
                  '卸载异常: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final state = ref.watch(installedAppsProvider);
    final cardStateIndex = ref.watch(applicationCardStateIndexProvider);
    final filteredApps = _filterApps(_mergeApps(state.apps));

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: _activeTab == _MyAppsTab.app
              ? Column(
                  children: [
                    // 只渲染当前激活的 Tab，避免两个复杂子树同时挂载时触发
                    // 重复 GlobalKey 和生命周期断言。
                    _buildSearchBar(context),
                    Expanded(
                      child: _buildAppsContent(
                        context,
                        state,
                        filteredApps,
                        cardStateIndex,
                      ),
                    ),
                  ],
                )
              : const LinglongProcessPanel(),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          _TabTitle(
            label: '我的应用',
            isActive: _activeTab == _MyAppsTab.app,
            onTap: () => _setActiveTab(_MyAppsTab.app),
          ),
          const SizedBox(width: 24),
          _TabTitle(
            label: '玲珑进程',
            isActive: _activeTab == _MyAppsTab.process,
            onTap: () => _setActiveTab(_MyAppsTab.process),
          ),
        ],
      ),
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

  Widget _buildAppsContent(
    BuildContext context,
    InstalledAppsState state,
    List<InstalledApp> filteredApps,
    ApplicationCardStateIndex cardStateIndex,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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

    if (state.apps.isEmpty) {
      return const EmptyState(
        icon: Icons.apps_outage,
        title: '暂无已安装应用',
        description: '您还没有安装任何玲珑应用，去推荐页看看吧',
      );
    }

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

class _TabTitle extends StatelessWidget {
  const _TabTitle({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isActive
                  ? context.appColors.textPrimary
                  : context.appColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: AppAnimation.fast,
            width: isActive ? 56 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
