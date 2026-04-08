import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../application/providers/all_apps_provider.dart';
import '../../../application/providers/application_card_state_provider.dart';
import '../../../core/config/page_visibility.dart';
import '../../../core/config/routes.dart';
import '../../../core/config/theme.dart';
import '../../../core/config/visibility_aware_mixin.dart';
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
    with AutomaticKeepAliveClientMixin, VisibilityAwareMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isCategoryExpanded = false;

  /// 页面是否可见（用于控制副作用）
  bool _isPageVisible = true;

  @override
  bool get wantKeepAlive => true;

  @override
  String get routePath => AppRoutes.allApps;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 可见性变更回调：隐藏时暂停滚动加载
  @override
  void onVisibilityChanged(PageVisibilityEvent event) {
    if (event.becameHidden) {
      _isPageVisible = false;
    } else if (event.becameVisible) {
      _isPageVisible = true;
    }
  }

  void _onScroll() {
    // 页面不可见时跳过滚动加载，避免无效网络请求和内存占用
    if (!_isPageVisible) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(allAppsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
      return const EmptyState.noData(title: '暂无应用', description: '请检查网络连接后重试');
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
            sliver: _AppsGrid(
              apps: state.data!.apps.items,
              isLoadingMore: state.isLoadingMore,
              hasMore: state.data!.apps.hasMore,
            ),
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
    return Semantics(
      label: AppLocalizations.of(context)?.loading ?? '加载中',
      child: Shimmer.fromColors(
        baseColor: context.appColors.skeletonBackground,
        highlightColor: context.appColors.skeletonHighlight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 3.5,
            ),
            itemCount: 12,
            itemBuilder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.smRadius,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 应用网格
class _AppsGrid extends ConsumerWidget {
  const _AppsGrid({
    required this.apps,
    required this.isLoadingMore,
    required this.hasMore,
  });

  final List<RecommendAppInfo> apps;
  final bool isLoadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (apps.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState.noData(title: '暂无应用', description: '该分类下暂无应用'),
      );
    }

    final cardStateIndex = ref.watch(applicationCardStateIndexProvider);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // 响应式列数计算
        final crossAxisCount = _calculateCrossAxisCount(
          constraints.crossAxisExtent,
        );

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: _calculateChildAspectRatio(
              constraints.crossAxisExtent,
            ),
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index < apps.length) {
              final app = apps[index];
              final cardState = cardStateIndex.resolve(
                appId: app.appId,
                latestVersion: app.version,
              );
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
                  version: app.version,
                ),
              );
            }
            // 加载更多指示器
            if (isLoadingMore) {
              return const _LoadingMoreItem();
            }
            // 没有更多数据提示
            if (!hasMore && apps.isNotEmpty) {
              return const _NoMoreDataItem();
            }
            return null;
          }, childCount: apps.length + (isLoadingMore || !hasMore ? 1 : 0)),
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  double _calculateChildAspectRatio(double width) {
    final crossAxisCount = _calculateCrossAxisCount(width);
    return (width - (crossAxisCount - 1) * AppSpacing.sm) /
        crossAxisCount /
        80; // 80 是卡片高度
  }
}

/// 加载更多指示器
class _LoadingMoreItem extends StatelessWidget {
  const _LoadingMoreItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// 没有更多数据提示
class _NoMoreDataItem extends StatelessWidget {
  const _NoMoreDataItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Text(
          '没有更多了',
          style: TextStyle(fontSize: 13, color: context.appColors.textTertiary),
        ),
      ),
    );
  }
}
