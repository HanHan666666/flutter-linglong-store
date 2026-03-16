import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../application/providers/custom_category_provider.dart';
import '../../../core/config/theme.dart';
import '../../../domain/models/recommend_models.dart';
import '../../widgets/widgets.dart';

/// 自定义分类页
class CustomCategoryPage extends ConsumerStatefulWidget {
  const CustomCategoryPage({required this.code, super.key});

  final String code;

  @override
  ConsumerState<CustomCategoryPage> createState() => _CustomCategoryPageState();
}

class _CustomCategoryPageState extends ConsumerState<CustomCategoryPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 初始化分类
    Future.microtask(() {
      ref.read(customCategoryProvider.notifier).initCategory(widget.code);
    });
  }

  @override
  void didUpdateWidget(CustomCategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 code 改变时重新初始化
    if (oldWidget.code != widget.code) {
      ref.read(customCategoryProvider.notifier).initCategory(widget.code);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(customCategoryProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final state = ref.watch(customCategoryProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(customCategoryProvider.notifier).refresh(),
      child: _buildBody(state),
    );
  }

  Widget _buildBody(CustomCategoryState state) {
    // 加载中状态
    if (state.isLoading && state.data == null) {
      return _buildLoadingState();
    }

    // 错误状态
    if (state.error != null && state.data == null) {
      return ErrorState.generic(
        description: state.error,
        onRetry: () => ref.read(customCategoryProvider.notifier).loadData(),
      );
    }

    // 空数据状态
    if (state.data == null) {
      return const EmptyState.noData(title: '暂无应用', description: '该分类下暂无应用');
    }

    // 正常显示
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 标题栏
        SliverPersistentHeader(
          pinned: true,
          delegate: _CategoryHeaderDelegate(
            categoryName: state.data!.categoryInfo.name,
            appCount: state.data!.categoryInfo.appCount,
          ),
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
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Shimmer.fromColors(
          baseColor: context.appColors.skeletonBackground,
          highlightColor: context.appColors.skeletonHighlight,
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

/// 分类标题栏委托
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CategoryHeaderDelegate({required this.categoryName, required this.appCount});

  final String categoryName;
  final int? appCount;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  // 分类名称
                  Text(
                    categoryName,
                    style: AppTextStyles.title2.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // 应用数量
                  if (appCount != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '($appCount)',
                      style: AppTextStyles.body.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(height: 1, color: context.appColors.divider),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return categoryName != oldDelegate.categoryName ||
        appCount != oldDelegate.appCount;
  }
}

/// 应用网格
class _AppsGrid extends StatelessWidget {
  const _AppsGrid({
    required this.apps,
    required this.isLoadingMore,
    required this.hasMore,
  });

  final List<RecommendAppInfo> apps;
  final bool isLoadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState.noData(title: '暂无应用', description: '该分类下暂无应用'),
      );
    }

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
              return _AppCard(app: apps[index]);
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

/// 应用卡片
class _AppCard extends StatefulWidget {
  const _AppCard({required this.app});

  final RecommendAppInfo app;

  @override
  State<_AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<_AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push('/app/${widget.app.appId}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: AppRadius.smRadius,
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
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                // 应用图标
                _buildIcon(),
                const SizedBox(width: AppSpacing.sm),

                // 应用信息
                Expanded(child: _buildInfo()),

                const SizedBox(width: AppSpacing.sm),

                // 操作按钮
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建应用图标
  ///
  /// 使用 AppIcon 组件统一处理图标加载、缓存和错误处理
  Widget _buildIcon() {
    return AppIcon(
      iconUrl: widget.app.icon,
      size: 48,
      borderRadius: 8,
      appName: widget.app.name,
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 应用名称
        Text(
          widget.app.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 2),

        // 描述
        Text(
          widget.app.description ?? '',
          style: TextStyle(fontSize: 12, color: context.appColors.textTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    String label;
    Color bgColor;
    Color textColor;
    bool showBorder = false;

    if (widget.app.isInstalled) {
      if (widget.app.hasUpdate) {
        label = '更新';
        bgColor = AppColors.primary;
        textColor = Colors.white;
      } else {
        label = '打开';
        bgColor = context.appColors.openButtonBackground;
        textColor = context.appColors.openButtonText;
        showBorder = true;
      }
    } else {
      label = '安装';
      bgColor = AppColors.primary;
      textColor = Colors.white;
    }

    return Container(
      height: 28,
      constraints: const BoxConstraints(minWidth: 56),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.fullRadius,
        border: showBorder
            ? Border.all(color: context.appColors.openButtonBorder)
            : null,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
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
