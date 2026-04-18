import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/all_apps_provider.dart';
import '../../../core/config/shell_primary_route.dart';
import '../../../core/config/shell_branch_visibility.dart';
import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/recommend_models.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/widgets.dart';

/// 全部应用页
class AllAppsPage extends ConsumerStatefulWidget {
  const AllAppsPage({super.key});

  @override
  ConsumerState<AllAppsPage> createState() => _AllAppsPageState();
}

class _AllAppsPageState extends ConsumerState<AllAppsPage>
    with ShellBranchVisibilityMixin<AllAppsPage>, AutoLoadWhenNotScrollable {
  final ScrollController _scrollController = ScrollController();
  bool _isCategoryExpanded = false;

  /// 页面是否可见（用于控制副作用）
  bool _isPageVisible = true;

  @override
  ShellPrimaryRoute get watchedPrimaryRoute => ShellPrimaryRoute.allApps;

  // ==================== AutoLoadWhenNotScrollable 实现 ====================

  @override
  ScrollController get scrollController => _scrollController;

  @override
  bool get isPageVisible => _isPageVisible;

  @override
  bool get isLoading => ref.read(allAppsProvider).isLoading;

  @override
  bool get isLoadingMore => ref.read(allAppsProvider).isLoadingMore;

  @override
  bool get hasMore => ref.read(allAppsProvider).data?.apps.hasMore ?? false;

  @override
  VoidCallback get onLoadMore =>
      () => ref.read(allAppsProvider.notifier).loadMore();

  @override
  void initState() {
    super.initState();
    initAutoLoad();
    _scrollController.addListener(onScroll);
  }

  @override
  void dispose() {
    disposeAutoLoad();
    _scrollController.removeListener(onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 可见性变更回调：隐藏时暂停滚动加载
  @override
  void onPrimaryRouteVisibilityChanged({
    required bool isActive,
    required bool isInitial,
  }) {
    if (isActive) {
      _isPageVisible = true;
      onVisibilityChanged(true);
      return;
    }
    _isPageVisible = false;
    onVisibilityChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final state = ref.watch(allAppsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(allAppsProvider.notifier).refresh(),
      child: _buildBody(state, l10n),
    );
  }

  Widget _buildBody(AllAppsState state, AppLocalizations l10n) {
    // 加载中状态
    if (state.isLoading && state.data == null) {
      return _buildLoadingState(l10n);
    }

    // 错误状态
    if (state.error != null && state.data == null) {
      return ErrorState.generic(
        description: state.error,
        onRetry: () => ref.read(allAppsProvider.notifier).loadData(),
      );
    }

    // 空数据状态
    if (state.data == null) {
      return EmptyState.noData(
        title: l10n.noApps,
        description: l10n.errorNetworkDetail,
      );
    }

    // 正常显示
    return Semantics(
      label: l10n.a11yAppListArea,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 分类筛选栏
          CategoryFilterSection(
            categories: state.data!.categories,
            selectedIndex: state.selectedCategoryIndex,
            onSelected: (index) {
              ref.read(allAppsProvider.notifier).selectCategory(index);
            },
            showCount: true,
            isExpanded: _isCategoryExpanded,
            onToggleExpand: () => setState(() {
              _isCategoryExpanded = !_isCategoryExpanded;
            }),
          ),

          // 应用卡片网格
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: _AppsGrid(apps: state.data!.apps.items),
          ),
          // 分页 footer 必须独立成整行 sliver，不能占用卡片格子。
          PaginationFooterSliver(
            isLoadingMore: state.isLoadingMore,
            hasMore: state.data!.apps.hasMore,
            hasItems: state.data!.apps.items.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Semantics(
      label: l10n.loading,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 分类骨架屏
            const CategoryFilterSkeleton(itemCount: 8, chipWidth: 96),
            const SizedBox(height: AppSpacing.lg),
            // 应用网格骨架屏
            _buildAppsSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsSkeleton() {
    return const AppGridShimmer();
  }
}

/// 应用网格（已迁移到共享 ResponsiveAppGrid）
class _AppsGrid extends StatelessWidget {
  const _AppsGrid({required this.apps});

  final List<RecommendAppInfo> apps;

  @override
  Widget build(BuildContext context) {
    return ResponsiveAppGrid<RecommendAppInfo>(
      items: apps,
      itemBuilder: (ref, index, app, cardState) {
        return AppCard(
          appId: app.appId,
          name: app.name,
          description: app.description,
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
        );
      },
    );
  }
}
