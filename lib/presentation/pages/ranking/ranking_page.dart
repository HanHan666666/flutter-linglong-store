import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../application/providers/application_card_state_provider.dart';
import '../../../application/providers/ranking_provider.dart';
import '../../../core/config/page_visibility.dart';
import '../../../core/config/routes.dart';
import '../../../core/config/theme.dart';
import '../../../core/config/visibility_aware_mixin.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/ranking_models.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/widgets.dart';

/// 排行榜页
class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage>
    with
        AutomaticKeepAliveClientMixin,
        SingleTickerProviderStateMixin,
        VisibilityAwareMixin {
  late TabController _tabController;

  /// 页面是否可见（用于控制副作用）
  bool _isPageVisible = true;

  @override
  bool get wantKeepAlive => true;

  @override
  String get routePath => AppRoutes.ranking;

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
    // 页面不可见时跳过 Tab 切换处理
    if (!_isPageVisible) return;
    if (!_tabController.indexIsChanging) {
      final type = RankingType.values[_tabController.index];
      ref.read(rankingProvider.notifier).selectType(type);
    }
  }

  /// 可见性变更回调
  @override
  void onVisibilityChanged(PageVisibilityEvent event) {
    if (event.becameHidden) {
      _isPageVisible = false;
    } else if (event.becameVisible) {
      _isPageVisible = true;
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
    final l10n = AppLocalizations.of(context)!;

    // 加载中状态
    if (state.isLoading && state.data == null) {
      return _buildLoadingState(context, l10n);
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
      child: Semantics(
        label: l10n.a11yAppListArea,
        child: _AppsGrid(apps: state.data!.apps),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, AppLocalizations l10n) {
    return Semantics(
      label: l10n.loading,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Semantics(
            label: l10n.loading,
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
        ),
      ),
    );
  }
}

/// 应用网格
class _AppsGrid extends ConsumerWidget {
  const _AppsGrid({required this.apps});

  final List<RankingAppInfo> apps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardStateIndex = ref.watch(applicationCardStateIndexProvider);

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
                    rank: app.rank,
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
