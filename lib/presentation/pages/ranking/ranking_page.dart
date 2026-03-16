import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../application/providers/ranking_provider.dart';
import '../../../core/config/theme.dart';
import '../../../domain/models/ranking_models.dart';
import '../../widgets/widgets.dart';

/// 排行榜页
class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: RankingType.values.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final type = RankingType.values[_tabController.index];
      ref.read(rankingProvider.notifier).selectType(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final state = ref.watch(rankingProvider);

    return Column(
      children: [
        // Tab 栏
        _buildTabBar(),

        // Tab 内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: RankingType.values.map((type) {
              return _RankingTabContent(type: type, state: state);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    // Tab 内容区和分隔线颜色跟随主题
    final palette = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(bottom: BorderSide(color: palette.divider, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: AppColors.primary,
        unselectedLabelColor: palette.textSecondary,
        labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
        unselectedLabelStyle: AppTextStyles.body,
        indicator: BoxDecoration(
          color: palette.primaryLight,
          borderRadius: AppRadius.lgRadius,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        dividerColor: Colors.transparent,
        tabs: RankingType.values.map((type) {
          return Tab(text: type.label);
        }).toList(),
      ),
    );
  }
}

/// 排行榜 Tab 内容
class _RankingTabContent extends ConsumerWidget {
  const _RankingTabContent({required this.type, required this.state});

  final RankingType type;
  final RankingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 加载中状态
    if (state.isLoading && state.data == null) {
      return _buildLoadingState(context);
    }

    // 错误状态
    if (state.error != null && state.data == null) {
      return ErrorState.generic(
        description: state.error,
        onRetry: () => ref.read(rankingProvider.notifier).loadData(),
      );
    }

    // 空数据状态
    if (state.data == null || state.data!.apps.isEmpty) {
      return const EmptyState.noData(title: '暂无排行', description: '请检查网络连接后重试');
    }

    // 正常显示
    return RefreshIndicator(
      onRefresh: () => ref.read(rankingProvider.notifier).refresh(),
      child: _AppsGrid(apps: state.data!.apps),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
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
      ),
    );
  }
}

/// 应用网格
class _AppsGrid extends StatelessWidget {
  const _AppsGrid({required this.apps});

  final List<RankingAppInfo> apps;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverLayoutBuilder(
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
                  return _AppCard(app: apps[index]);
                }, childCount: apps.length),
              );
            },
          ),
        ),
      ],
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

  final RankingAppInfo app;

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
            // 卡片背景色跟随主题
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
                // 排名数字
                _buildRankBadge(),

                const SizedBox(width: AppSpacing.sm),

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

  Widget _buildRankBadge() {
    // 前三名特殊颜色
    Color bgColor;
    Color textColor;

    if (widget.app.rank == 1) {
      bgColor = const Color(0xFFFFD700); // 金色
      textColor = Colors.white;
    } else if (widget.app.rank == 2) {
      bgColor = const Color(0xFFC0C0C0); // 银色
      textColor = Colors.white;
    } else if (widget.app.rank == 3) {
      bgColor = const Color(0xFFCD7F32); // 铜色
      textColor = Colors.white;
    } else {
      bgColor = context.appColors.cardBackground;
      textColor = context.appColors.textTertiary;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.xsRadius,
      ),
      child: Center(
        child: Text(
          '${widget.app.rank}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
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
        // 打开按钮背景色跟随主题
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
