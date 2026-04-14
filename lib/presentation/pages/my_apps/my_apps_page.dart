import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/app_uninstall_provider.dart';
import '../../../application/providers/application_card_state_provider.dart';
import '../../../application/providers/installed_apps_provider.dart';
import '../../../application/providers/running_process_provider.dart';
import '../../../core/config/shell_primary_route.dart';
import '../../../core/config/shell_branch_visibility.dart';
import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/utils/app_notification_helpers.dart';
import '../../../core/utils/version_compare.dart';
import '../../../domain/models/installed_app.dart';
import '../../helpers/app_uninstall_flow.dart';
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
    with ShellBranchVisibilityMixin<MyAppsPage> {
  /// 搜索关键词
  String _searchQuery = '';

  /// 搜索控制器
  final _searchController = TextEditingController();

  /// 缓存 Provider notifier，避免在 dispose 阶段再通过 ref.read 访问已卸载的上下文。
  late final InstalledApps _installedAppsNotifier;
  late final RunningProcess _runningProcessNotifier;

  _MyAppsTab _activeTab = _MyAppsTab.app;

  @override
  ShellPrimaryRoute get watchedPrimaryRoute => ShellPrimaryRoute.myApps;

  @override
  void initState() {
    super.initState();
    _installedAppsNotifier = ref.read(installedAppsProvider.notifier);
    _runningProcessNotifier = ref.read(runningProcessProvider.notifier);
    Future.microtask(() {
      _installedAppsNotifier.refresh();
    });
  }

  @override
  void dispose() {
    _runningProcessNotifier.setProcessTabActive(false);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void onPrimaryRouteVisibilityChanged({
    required bool isActive,
    required bool isInitial,
  }) {
    _runningProcessNotifier.setPageVisible(isActive);
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

  /// 卸载应用（使用统一的卸载流程）
  Future<void> _uninstallApp(InstalledApp app) async {
    final service = ref.read(appUninstallServiceProvider);
    final success = await AppUninstallFlow.run(context, app, service);
    if (!context.mounted) return;

    if (success) {
      showAppSuccess(context, '${app.name} 已卸载');
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Semantics(
            label: l10n.a11yMyAppsPage,
            child: _TabTitle(
              label: l10n.myApps,
              isActive: _activeTab == _MyAppsTab.app,
              onTap: () => _setActiveTab(_MyAppsTab.app),
            ),
          ),
          const SizedBox(width: 24),
          _TabTitle(
            label: l10n.linglongProcess,
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
          hintText:
              AppLocalizations.of(context)?.searchInstalledApps ?? '搜索已安装的应用',
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
        title: AppLocalizations.of(context)?.loadFailed ?? '加载失败',
        description: state.error,
        retryText: AppLocalizations.of(context)?.retry ?? '重试',
        onRetry: () {
          ref.read(installedAppsProvider.notifier).refresh();
        },
      );
    }

    if (state.apps.isEmpty) {
      return EmptyState(
        icon: Icons.apps_outage,
        title: AppLocalizations.of(context)?.noInstalledApps ?? '暂无已安装应用',
        description:
            AppLocalizations.of(context)?.noInstalledAppsHint ??
            '您还没有安装任何玲珑应用，去推荐页看看吧',
      );
    }

    if (filteredApps.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.noMatchingApp,
        description: l10n.noMatchingAppHint(_searchQuery),
        retryText: l10n.clearSearch,
        onRetry: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
          });
        },
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.a11yAppListArea,
      child: RefreshIndicator(
        onRefresh: () => ref.read(installedAppsProvider.notifier).refresh(),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredApps.length,
          // 为卡片 hover 阴影和圆角留出稳定呼吸感，避免视觉上像上下粘连。
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final app = filteredApps[index];
            final cardState = cardStateIndex.resolve(
              appId: app.appId,
            );
            return AppCard(
              appId: app.appId,
              name: app.name,
              description: app.description ?? 'v${app.version}',
              iconUrl: app.icon,
              buttonState: cardState.buttonState,
              progress: cardState.progress,
              isInstalling: cardState.isInstalling,
              onTap: () => context.push('/app/${app.appId}'),
              onPrimaryPressed: () => handleAppCardPrimaryAction(
                context: context,
                ref: ref,
                buttonState: cardState.buttonState,
                appId: app.appId,
                appName: app.name,
                icon: app.icon,
              ),
              menuActions: [
                AppCardMenuAction(
                  value: 'uninstall',
                  label: l10n.uninstall,
                  icon: Icons.delete_outline,
                  onSelected: () => _uninstallApp(app),
                ),
              ],
            );
          },
        ),
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
