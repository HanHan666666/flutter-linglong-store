import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../application/providers/recommend_provider.dart';
import '../../../core/config/theme.dart';
import '../../../core/config/shell_primary_route.dart';
import '../../../core/config/shell_branch_visibility.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/utils/app_notification_helpers.dart';
import '../../../domain/models/recommend_models.dart';
import 'widgets/recommend_banner_background.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/widgets.dart';

// 推荐页轮播保持略高于当前信息卡内容，给底部指示器预留稳定安全区。
const double _recommendBannerHeight = 236;
const double _recommendBannerIndicatorBottom = 4;
// 为左侧轮播切换按钮预留安全距离，避免与信息区图标发生重叠。
const double _recommendBannerInfoDockLeftInset = 72;

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
    with ShellBranchVisibilityMixin<RecommendPage> {
  final ScrollController _scrollController = ScrollController();

  /// 避免同一帧重复安排“内容不足一屏自动补页”检查。
  bool _autoLoadCheckScheduled = false;

  /// 页面是否可见（用于控制副作用）
  bool _isPageVisible = true;

  /// 是否已加载过数据（用于避免重复首屏加载）
  bool _hasLoadedData = false;

  @override
  ShellPrimaryRoute get watchedPrimaryRoute => ShellPrimaryRoute.recommend;

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
  void onPrimaryRouteVisibilityChanged({
    required bool isActive,
    required bool isInitial,
  }) {
    if (isActive) {
      // 页面可见：恢复副作用
      _resumeSideEffects();
      // 恢复时只进行轻量刷新，不重新加载首屏
      if (_hasLoadedData && !isInitial) {
        performLightweightRefresh();
      }
      return;
    }
    // 页面隐藏：暂停所有副作用
    _pauseSideEffects();
  }

  /// 暂停副作用
  void _pauseSideEffects() {
    _isPageVisible = false;
    // 滚动监听会通过 _isPageVisible 标志自动跳过
  }

  /// 恢复副作用
  void _resumeSideEffects() {
    _isPageVisible = true;
    _scheduleAutoLoadCheck(ref.read(recommendProvider));
  }

  /// 轻量刷新
  ///
  /// 从隐藏状态恢复时，只进行轻量刷新：
  /// - 不重新加载首屏数据
  /// - 不重置滚动位置
  /// - 不显示骨架屏
  void performLightweightRefresh() {
    // 仅在需要时刷新（例如检查更新状态等轻量操作）
    // 当前实现：不做任何操作，保持现有状态
    // 如果需要，可以在这里添加轻量级检查逻辑
  }

  void _onScroll() {
    // 页面隐藏时跳过滚动处理
    if (!_isPageVisible) return;
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(recommendProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendProvider);
    final l10n = AppLocalizations.of(context)!;

    // 标记已加载数据
    if (state.data != null && !_hasLoadedData) {
      _hasLoadedData = true;
    }

    _scheduleAutoLoadCheck(state);

    return Semantics(
      label: l10n.a11yRecommendPage,
      child: RefreshIndicator(
        onRefresh: () => ref.read(recommendProvider.notifier).refresh(),
        child: _buildBody(state, context),
      ),
    );
  }

  void _scheduleAutoLoadCheck(RecommendState state) {
    if (_autoLoadCheckScheduled || !_shouldAutoLoadWhenNotScrollable(state)) {
      return;
    }

    _autoLoadCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLoadCheckScheduled = false;
      if (!mounted) {
        return;
      }
      _maybeLoadMoreWhenNotScrollable(ref.read(recommendProvider));
    });
  }

  bool _shouldAutoLoadWhenNotScrollable(RecommendState state) {
    return _isPageVisible &&
        !state.isLoading &&
        !state.isLoadingMore &&
        state.data != null &&
        state.data!.apps.hasMore;
  }

  void _maybeLoadMoreWhenNotScrollable(RecommendState state) {
    if (!_shouldAutoLoadWhenNotScrollable(state)) {
      return;
    }

    if (!_scrollController.hasClients) {
      _scheduleAutoLoadCheck(state);
      return;
    }

    final position = _scrollController.position;
    if (!position.hasContentDimensions || position.viewportDimension <= 0) {
      _scheduleAutoLoadCheck(state);
      return;
    }

    final notScrollable = position.maxScrollExtent <= 1;
    if (notScrollable) {
      ref.read(recommendProvider.notifier).loadMore();
    }
  }

  Widget _buildBody(RecommendState state, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      return EmptyState.noData(
        title: l10n.noRecommend,
        description: l10n.errorNetworkDetail,
      );
    }

    // 正常显示
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: _BannerSection(
            banners: state.data!.banners,
            isPageVisible: _isPageVisible,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              AppLocalizations.of(context)!.linglongRecommend,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
        ),
        // 推荐列表区
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: _AppsGrid(apps: state.data!.apps.items),
        ),
        SliverToBoxAdapter(
          child: _RecommendListFooter(
            isLoadingMore: state.isLoadingMore,
            hasMore: state.data!.apps.hasMore,
            hasItems: state.data!.apps.items.isNotEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n?.loading ?? 'Loading',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildBannerSkeleton(),
            const SizedBox(height: AppSpacing.lg),
            _buildTitleSkeleton(),
            const SizedBox(height: AppSpacing.md),
            _buildAppsSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSkeleton() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      height: 220,
      decoration: BoxDecoration(
        color: context.appColors.skeletonBackground,
        borderRadius: AppRadius.smRadius,
      ),
    );
  }

  Widget _buildTitleSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 112,
          height: 20,
          decoration: BoxDecoration(
            color: context.appColors.skeletonBackground,
            borderRadius: AppRadius.smRadius,
          ),
        ),
      ),
    );
  }

  Widget _buildAppsSkeleton() {
    return const AppGridShimmer(itemCount: 8);
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

    // 创建新的定时器，每30秒自动切换一次轮播图
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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

    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: _recommendBannerHeight,
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: AppRadius.smRadius,
      ),
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
              // 左侧切换按钮
              if (widget.banners.length > 1)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: l10n.a11yPrevious,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: AppRadius.fullRadius,
                          child: InkWell(
                            borderRadius: AppRadius.fullRadius,
                            onTap: _goToPrevious,
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // 右侧切换按钮
              if (widget.banners.length > 1)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: l10n.a11yNext,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: AppRadius.fullRadius,
                          child: InkWell(
                            borderRadius: AppRadius.fullRadius,
                            onTap: _goToNext,
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: _recommendBannerIndicatorBottom,
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
    );
  }

  /// 切换到上一张轮播图
  void _goToPrevious() {
    if (_disposed || !mounted || !_pageController.hasClients) return;
    final previousIndex =
        (_currentIndex - 1 + widget.banners.length) % widget.banners.length;
    _pageController.animateToPage(
      previousIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 切换到下一张轮播图
  void _goToNext() {
    if (_disposed || !mounted || !_pageController.hasClients) return;
    final nextIndex = (_currentIndex + 1) % widget.banners.length;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
        showLinkOpenError(context, url);
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dockBackground = isDark
        ? Colors.black.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.16);
    final dockBorder = Colors.white.withValues(alpha: isDark ? 0.10 : 0.18);

    return RecommendBannerBackground(
      banner: banner,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg + _recommendBannerInfoDockLeftInset,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                key: const Key('recommend-banner-info-dock'),
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: dockBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dockBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppIcon(
                      iconUrl: banner.imageUrl,
                      size: 72,
                      borderRadius: 18,
                      appName: banner.title,
                      placeholderColor: Colors.white.withValues(
                        alpha: isDark ? 0.20 : 0.24,
                      ),
                      errorColor: Colors.white.withValues(
                        alpha: isDark ? 0.16 : 0.20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            banner.description?.trim().isNotEmpty == true
                                ? banner.description!
                                : l10n.appDescriptionPlaceholder,
                            style: TextStyle(
                              // banner 描述：14px 常规说明文字
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.86),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _BannerDetailButton(
                            label: l10n.viewDetail,
                            onPressed: onTap,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerDetailButton extends StatelessWidget {
  const _BannerDetailButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: const StadiumBorder(),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
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
          child: Semantics(
            button: true,
            label: '${index + 1}',
            selected: isActive,
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
          ),
        );
      }),
    );
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

class _RecommendListFooter extends StatelessWidget {
  const _RecommendListFooter({
    required this.isLoadingMore,
    required this.hasMore,
    required this.hasItems,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!hasItems) {
      return const SizedBox.shrink();
    }

    if (isLoadingMore) {
      return Container(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Center(
          child: Text(
            l10n.loading,
            style: TextStyle(
              fontSize: 14,
              color: context.appColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (hasMore) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Center(
        child: Text(
          l10n.noMoreData,
          style: TextStyle(fontSize: 14, color: context.appColors.textTertiary),
        ),
      ),
    );
  }
}
