import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/custom_category_provider.dart';
import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/recommend_models.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/widgets.dart';

/// 自定义分类页
class CustomCategoryPage extends ConsumerStatefulWidget {
  const CustomCategoryPage({required this.code, super.key});

  final String code;

  @override
  ConsumerState<CustomCategoryPage> createState() => _CustomCategoryPageState();
}

class _CustomCategoryPageState extends ConsumerState<CustomCategoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // family provider 会自动根据 code 参数初始化，无需手动调用 initCategory
  }

  @override
  void didUpdateWidget(CustomCategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // family provider 会自动根据 code 参数变化重新构建，无需手动处理
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
      ref.read(customCategoryProvider(widget.code).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final state = ref.watch(customCategoryProvider(widget.code));

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(customCategoryProvider(widget.code).notifier).refresh(),
      child: _buildBody(state, l10n),
    );
  }

  Widget _buildBody(CustomCategoryState state, AppLocalizations l10n) {
    // 加载中状态
    if (state.isLoading && state.data == null) {
      return _buildLoadingState(l10n);
    }

    // 错误状态
    if (state.error != null && state.data == null) {
      return ErrorState.generic(
        description: state.error,
        onRetry: () =>
            ref.read(customCategoryProvider(widget.code).notifier).loadData(),
      );
    }

    // 空数据状态
    if (state.data == null) {
      return EmptyState.noData(
        title: l10n.noApps,
        description: l10n.noAppsInCategory,
      );
    }

    // 正常显示
    return Semantics(
      label: l10n.a11yAppListArea,
      child: CustomScrollView(
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
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Semantics(
      label: l10n.loading,
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: AppGridShimmer(),
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

/// 应用网格（已迁移到共享 ResponsiveAppGrid）
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
    return ResponsiveAppGrid<RecommendAppInfo>(
      items: apps,
      isLoadingMore: isLoadingMore,
      hasMore: hasMore,
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
            version: app.version,
          ),
        );
      },
    );
  }
}
