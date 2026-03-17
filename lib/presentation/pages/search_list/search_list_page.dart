import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../application/providers/application_card_state_provider.dart';
import '../../../application/providers/search_provider.dart';
import '../../../core/config/theme.dart';
import '../../../domain/models/recommend_models.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/widgets.dart';

/// 搜索结果页
class SearchListPage extends ConsumerStatefulWidget {
  const SearchListPage({this.initialQuery, super.key});

  /// 初始搜索关键词
  final String? initialQuery;

  @override
  ConsumerState<SearchListPage> createState() => _SearchListPageState();
}

class _SearchListPageState extends ConsumerState<SearchListPage>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _scrollController.addListener(_onScroll);

    // 如果有初始查询，自动触发搜索
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchProvider.notifier).search(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(searchProvider.notifier).search(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final state = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchField(),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSearch,
              tooltip: '清除搜索',
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _onSearch,
            tooltip: '搜索',
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索应用...',
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: context.appColors.textTertiary,
          fontSize: 14,
        ),
      ),
      style: TextStyle(fontSize: 14, color: context.appColors.textPrimary),
      onSubmitted: (_) => _onSearch(),
      textInputAction: TextInputAction.search,
    );
  }

  Widget _buildBody(SearchState state) {
    // 未搜索状态
    if (state.query.isEmpty) {
      return _buildEmptySearch();
    }

    // 首次加载中
    if (state.isLoading && state.results.isEmpty) {
      return _buildLoadingState();
    }

    // 错误状态
    if (state.error != null && state.results.isEmpty) {
      return ErrorState.generic(description: state.error, onRetry: _onSearch);
    }

    // 无结果状态
    if (state.results.isEmpty) {
      return const EmptyState.search(
        title: '未找到相关应用',
        description: '尝试使用其他关键词搜索',
      );
    }

    // 搜索结果列表
    return RefreshIndicator(
      onRefresh: () => ref.read(searchProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 结果统计
          SliverToBoxAdapter(child: _buildResultHeader(state)),

          // 搜索结果网格
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: _AppsGrid(
              apps: state.results,
              isLoadingMore: state.isLoadingMore,
              hasMore: state.hasMore,
              total: state.total,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: context.appColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '输入关键词搜索应用',
            style: TextStyle(
              fontSize: 16,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持按名称、描述、开发者搜索',
            style: TextStyle(
              fontSize: 14,
              color: context.appColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(SearchState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '找到 ${state.total} 个结果',
            style: TextStyle(
              fontSize: 14,
              color: context.appColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (state.query.isNotEmpty)
            Text(
              '"${state.query}"',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // 加载提示
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
            // 骨架屏
            ...List.generate(3, (_) => _buildSkeletonCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: context.appColors.skeletonBackground,
      highlightColor: context.appColors.skeletonHighlight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.smRadius,
        ),
        child: Row(
          children: [
            // 图标占位
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.xsRadius,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 内容占位
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.xsRadius,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.xsRadius,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 按钮占位
            Container(
              width: 56,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.fullRadius,
              ),
            ),
          ],
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
    required this.total,
  });

  final List<RecommendAppInfo> apps;
  final bool isLoadingMore;
  final bool hasMore;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (apps.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState.search(title: '未找到相关应用', description: '尝试使用其他关键词搜索'),
      );
    }

    final cardStateIndex = ref.watch(applicationCardStateIndexProvider);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
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
    return (width - (crossAxisCount - 1) * AppSpacing.sm) / crossAxisCount / 80;
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
          style: TextStyle(fontSize: 12, color: context.appColors.textTertiary),
        ),
      ),
    );
  }
}
