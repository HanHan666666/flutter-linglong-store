import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../application/providers/application_card_state_provider.dart';
import '../../../application/providers/recommend_provider.dart';
import '../../../core/config/theme.dart';
import '../../../core/config/page_visibility.dart';
import '../../../core/config/visibility_aware_mixin.dart';
import '../../../domain/models/recommend_models.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/widgets.dart';

/// 推荐页
///
/// 实现了可见性感知，在页面隐藏时自动暂停副作用：
/// - 滚动监听（自动加载更多）
/// - 轮播自动播放
/// - 网络轮询
class RecommendPage extends ConsumerStatefulWidget {
  const RecommendPage({super.key});

  @override
  ConsumerState<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends ConsumerState<RecommendPage>
    with AutomaticKeepAliveClientMixin, VisibilityAwareMixin {
  final ScrollController _scrollController = ScrollController();

  /// 页面是否可见（用于控制副作用）
  bool _isPageVisible = true;

  /// 是否已加载过数据（用于避免重复首屏加载）
  bool _hasLoadedData = false;

  @override
  bool get wantKeepAlive => true;

  @override
  String get routePath => '/';

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

  /// 可见性变更回调
  @override
  void onVisibilityChanged(PageVisibilityEvent event) {
    if (event.becameHidden) {
      // 页面隐藏：暂停所有副作用
      _pauseSideEffects();
    } else if (event.becameVisible) {
      // 页面可见：恢复副作用
      _resumeSideEffects();

      // 恢复时只进行轻量刷新，不重新加载首屏
      if (_hasLoadedData && !event.isFirstVisible) {
        performLightweightRefresh();
      }
    }
  }

  /// 暂停副作用
  void _pauseSideEffects() {
    _isPageVisible = false;
    // 滚动监听会通过 _isPageVisible 标志自动跳过
  }

  /// 恢复副作用
  void _resumeSideEffects() {
    _isPageVisible = true;
  }

  /// 轻量刷新
  ///
  /// 从隐藏状态恢复时，只进行轻量刷新：
  /// - 不重新加载首屏数据
  /// - 不重置滚动位置
  /// - 不显示骨架屏
  @override
  void performLightweightRefresh() {
    // 仅在需要时刷新（例如检查更新状态等轻量操作）
    // 当前实现：不做任何操作，保持现有状态
    // 如果需要，可以在这里添加轻量级检查逻辑
  }

  void _onScroll() {
    // 页面隐藏时跳过滚动处理
    if (!_isPageVisible) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(recommendProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final state = ref.watch(recommendProvider);

    // 标记已加载数据
    if (state.data != null && !_hasLoadedData) {
      _hasLoadedData = true;
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(recommendProvider.notifier).refresh(),
      child: _buildBody(state),
    );
  }

  Widget _buildBody(RecommendState state) {
    // 加载中状态（仅在首次加载且无数据时显示骨架屏）
    if (state.isLoading && state.data == null) {
      return _buildLoadingState();
    }

    // 错误状态
    if (state.error != null && state.data == null) {
      return ErrorState.generic(
        description: state.error,
        onRetry: () => ref.read(recommendProvider.notifier).loadData(),
      );
    }

    // 空数据状态
    if (state.data == null) {
      return const EmptyState.noData(title: '暂无推荐', description: '请检查网络连接后重试');
    }

    // 正常显示
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 轮播区
        SliverToBoxAdapter(
          child: _BannerSection(
            banners: state.data!.banners,
            isPageVisible: _isPageVisible,
          ),
        ),

        // 筛选栏
        SliverPersistentHeader(
          pinned: true,
          delegate: CategoryFilterHeaderDelegate(
            categories: state.data!.categories,
            selectedIndex: state.selectedCategoryIndex,
            onSelected: (index) {
              ref.read(recommendProvider.notifier).selectCategory(index);
            },
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
      child: Column(
        children: [
          // 轮播骨架屏
          _buildBannerSkeleton(),
          const SizedBox(height: AppSpacing.lg),
          // 分类骨架屏
          _buildCategorySkeleton(),
          const SizedBox(height: AppSpacing.lg),
          // 应用网格骨架屏
          _buildAppsSkeleton(),
        ],
      ),
    );
  }

  Widget _buildBannerSkeleton() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      height: 180,
      decoration: BoxDecoration(
        color: context.appColors.skeletonBackground,
        borderRadius: AppRadius.smRadius,
      ),
    );
  }

  Widget _buildCategorySkeleton() {
    return Shimmer.fromColors(
      baseColor: context.appColors.skeletonBackground,
      highlightColor: context.appColors.skeletonHighlight,
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, __) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Container(
                width: 88,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.fullRadius,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppsSkeleton() {
    return Shimmer.fromColors(
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
          itemCount: 8,
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
    );
  }
}

/// 轮播区组件
///
/// 支持可见性控制的自动播放暂停
class _BannerSection extends StatefulWidget {
  const _BannerSection({required this.banners, required this.isPageVisible});

  final List<BannerInfo> banners;
  final bool isPageVisible;

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _autoPlayEnabled = true;

  /// 自动播放定时器
  Timer? _autoPlayTimer;

  /// 标记是否已 disposed
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // 延迟到下一帧启动自动播放，避免在 build 期间调用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        _startAutoPlay();
      }
    });
  }

  @override
  void didUpdateWidget(_BannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 可见性变化时控制自动播放
    // 使用 addPostFrameCallback 避免在 build 期间调用
    if (widget.isPageVisible != oldWidget.isPageVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed) return;
        if (widget.isPageVisible) {
          _startAutoPlay();
        } else {
          _stopAutoPlay();
        }
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (_disposed || !_autoPlayEnabled || !widget.isPageVisible) return;

    // 取消已有的定时器
    _autoPlayTimer?.cancel();

    // 创建新的定时器
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _autoPlay();
    });
  }

  void _autoPlay() {
    // 严格检查状态，避免在 widget 已销毁时调用
    if (_disposed || !mounted || !_autoPlayEnabled || !widget.isPageVisible) {
      return;
    }
    if (widget.banners.isEmpty) return;
    if (!_pageController.hasClients) return;

    final nextIndex = (_currentIndex + 1) % widget.banners.length;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // 轮播图
          AspectRatio(
            aspectRatio: 16 / 6,
            child: ClipRRect(
              borderRadius: AppRadius.smRadius,
              child: GestureDetector(
                onHorizontalDragStart: (_) {
                  _stopAutoPlay();
                  _autoPlayEnabled = false;
                },
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemCount: widget.banners.length,
                      itemBuilder: (context, index) {
                        return _BannerItem(
                          banner: widget.banners[index],
                          onTap: () => _onBannerTap(widget.banners[index]),
                        );
                      },
                    ),
                    // 指示器
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: _BannerIndicators(
                        count: widget.banners.length,
                        currentIndex: _currentIndex,
                        onTap: (index) {
                          if (_disposed || !_pageController.hasClients) return;
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBannerTap(BannerInfo banner) {
    if (banner.targetAppId != null) {
      // 如果是应用链接，跳转到应用详情页
      context.push('/app/${banner.targetAppId}');
    } else if (banner.targetUrl != null) {
      // 如果是外部链接，使用系统浏览器打开
      _launchExternalUrl(banner.targetUrl!);
    }
  }

  /// 使用系统浏览器打开外部链接
  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // 无法打开链接时显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法打开链接: $url')));
      }
    }
  }
}

/// 轮播项
class _BannerItem extends StatelessWidget {
  const _BannerItem({required this.banner, this.onTap});

  final BannerInfo banner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图
          Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.primary,
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          // 渐变遮罩
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          // 文字内容
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (banner.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    banner.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 轮播指示器
class _BannerIndicators extends StatelessWidget {
  const _BannerIndicators({
    required this.count,
    required this.currentIndex,
    this.onTap,
  });

  final int count;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return GestureDetector(
          onTap: () => onTap?.call(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: AppRadius.fullRadius,
            ),
          ),
        );
      }),
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
          style: TextStyle(fontSize: 12, color: context.appColors.textTertiary),
        ),
      ),
    );
  }
}
