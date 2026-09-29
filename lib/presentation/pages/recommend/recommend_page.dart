/// 推荐页聚合推荐内容、轮播生命周期与详情路由。
///
/// Banner 的展台视觉独立封装，页面仅处理当前条目、可见性与用户操作。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../application/providers/recommend_provider.dart';
import '../../../core/accessibility/accessibility.dart';
import '../../../core/config/routes.dart';
import '../../../core/config/theme.dart';
import '../../../core/config/shell_primary_route.dart';
import '../../../core/config/shell_branch_visibility.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/utils/app_notification_helpers.dart';
import '../../../domain/models/recommend_models.dart';
import 'widgets/recommend_banner.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/widgets.dart';

/// 默认字号下保留首页既有的轮播高度，放大字体时按需扩展。
const double _recommendBannerHeight = 236;

/// 指示器的点击区域下方保留边距，与展台内容分离。
const double _recommendBannerIndicatorBottom = 4;

/// 加载占位与真实轮播共用高度，系统大字号下仍为双行文案保留空间。
double _recommendBannerHeightFor(BuildContext context) {
  final extraHeight =
      (MediaQuery.textScalerOf(context).scale(32) - 32).clamp(
        0.0,
        double.infinity,
      ) *
      5;
  return _recommendBannerHeight + extraHeight;
}

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
    with ShellBranchVisibilityMixin<RecommendPage>, AutoLoadWhenNotScrollable {
  final ScrollController _scrollController = ScrollController();

  /// 页面是否可见（用于控制副作用）
  bool _isPageVisible = true;

  /// 是否已加载过数据（用于避免重复首屏加载）
  bool _hasLoadedData = false;

  @override
  ShellPrimaryRoute get watchedPrimaryRoute => ShellPrimaryRoute.recommend;

  // ==================== AutoLoadWhenNotScrollable 实现 ====================

  @override
  ScrollController get scrollController => _scrollController;

  @override
  bool get isPageVisible => _isPageVisible;

  @override
  bool get isLoading => ref.read(recommendProvider).isLoading;

  @override
  bool get isLoadingMore => ref.read(recommendProvider).isLoadingMore;

  @override
  bool get hasMore => ref.read(recommendProvider).data?.apps.hasMore ?? false;

  @override
  VoidCallback get onLoadMore =>
      () => ref.read(recommendProvider.notifier).loadMore();

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
    onVisibilityChanged(false);
  }

  /// 恢复副作用
  void _resumeSideEffects() {
    _isPageVisible = true;
    onVisibilityChanged(true);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendProvider);
    final l10n = AppLocalizations.of(context)!;

    // 标记已加载数据
    if (state.data != null && !_hasLoadedData) {
      _hasLoadedData = true;
    }

    // 数据加载完成后，安排自动补页检查
    // mixin 内部的 _shouldAutoLoadWhenNotScrollable 会检查实际的 isPageVisible
    // 当页面不可见时会自动短路，不会重复安排
    if (state.data != null) {
      scheduleAutoLoadCheckAfterLayout();
    }

    return Semantics(
      label: l10n.a11yRecommendPage,
      child: RefreshIndicator(
        onRefresh: () => ref.read(recommendProvider.notifier).refresh(),
        child: _buildBody(state, context),
      ),
    );
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
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: onScrollMetricsNotification,
      child: CustomScrollView(
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
                  fontWeight: context.appFontWeight(FontWeight.w500),
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
          PaginationFooterSliver(
            isLoadingMore: state.isLoadingMore,
            hasMore: state.data!.apps.hasMore,
            hasItems: state.data!.apps.items.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.loading,
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

  /// 占位与展台保持相同外框，避免首屏数据到达时改变页面节奏。
  Widget _buildBannerSkeleton() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      height: _recommendBannerHeightFor(context),
      decoration: BoxDecoration(
        color: context.appColors.skeletonBackground,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildTitleSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Align(
        // 骨架屏标题占位随文本方向镜像
        alignment: AlignmentDirectional.centerStart,
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
      height: _recommendBannerHeightFor(context),
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
                  return RecommendBanner(
                    banner: widget.banners[index],
                    onTap: () => _onBannerTap(widget.banners[index]),
                  );
                },
              ),
              // 上一项位于阅读起始侧，RTL 下自动移动到右侧。
              if (widget.banners.length > 1)
                PositionedDirectional(
                  start: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _BannerNavigationButton(
                      label: l10n.a11yPrevious,
                      icon: Icons.chevron_left,
                      onTap: _goToPrevious,
                    ),
                  ),
                ),
              // 下一项位于阅读结束侧，RTL 下自动移动到左侧。
              if (widget.banners.length > 1)
                PositionedDirectional(
                  end: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _BannerNavigationButton(
                      label: l10n.a11yNext,
                      icon: Icons.chevron_right,
                      onTap: _goToNext,
                    ),
                  ),
                ),
              PositionedDirectional(
                start: 0,
                end: 0,
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
      context.goToAppDetail(
        banner.targetAppId!,
        appInfo: banner.toInstalledApp(),
      );
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

/// 两种主题下都保持克制且可辨识的轮播按钮。
class _BannerNavigationButton extends StatelessWidget {
  /// 使用统一无障碍入口承接鼠标、键盘和读屏操作。
  const _BannerNavigationButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  /// 来自当前语言的上一项或下一项说明。
  final String label;

  /// Material 方向图标会根据 Directionality 自动镜像。
  final IconData icon;

  /// 复用页面已有的轮播控制。
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF303640) : const Color(0xFFFAFBFC),
      shape: CircleBorder(
        side: BorderSide(
          color: isDark ? const Color(0xFF484F5A) : const Color(0xFFD8DDE4),
        ),
      ),
      child: A11yIconButton(
        semanticsLabel: label,
        tooltip: label,
        onTap: onTap,
        iconSize: 20,
        icon: Icon(
          icon,
          color: isDark ? const Color(0xFFDCE0E6) : const Color(0xFF56606D),
        ),
      ),
    );
  }
}

/// 与中性背景保持对比度的轮播位置提示。
class _BannerIndicators extends StatelessWidget {
  /// 按钮尺寸稳定，选中态只改变内部短线。
  const _BannerIndicators({
    required this.count,
    required this.currentIndex,
    this.onTap,
  });

  /// 服务端返回的实际轮播条目数。
  final int count;

  /// PageView 当前已显示的条目。
  final int currentIndex;

  /// 由页面控制器负责切换。
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return Material(
          type: MaterialType.transparency,
          child: Semantics(
            selected: isActive,
            child: A11yButton(
              onTap: () => onTap?.call(index),
              semanticsLabel: '${l10n.a11yRecommendPage} ${index + 1} / $count',
              enabled: onTap != null,
              child: SizedBox(
                width: 32,
                height: 24,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 20 : 6,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? (isActive
                                ? const Color(0xFFDCE0E6)
                                : const Color(0xFF636D7B))
                          : (isActive
                                ? const Color(0xFF535F70)
                                : const Color(0xFFA4ACB8)),
                      borderRadius: AppRadius.fullRadius,
                    ),
                  ),
                ),
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
          onTap: () =>
              context.goToAppDetail(app.appId, appInfo: app.toInstalledApp()),
          onPrimaryPressed: (sourceIconKey) => handleAppCardPrimaryAction(
            context: context,
            ref: ref,
            buttonState: cardState.buttonState,
            appId: app.appId,
            appName: app.name,
            sourceIconKey: sourceIconKey,
            icon: app.icon,
          ),
        );
      },
    );
  }
}
