import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/custom_category_provider.dart';
import '../../../core/config/routes.dart';
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

class _CustomCategoryPageState extends ConsumerState<CustomCategoryPage>
    with AutoLoadWhenNotScrollable {
  final ScrollController _scrollController = ScrollController();

  // ==================== AutoLoadWhenNotScrollable 实现 ====================

  @override
  ScrollController get scrollController => _scrollController;

  @override
  bool get isPageVisible => true; // 自定义分类页不参与路由可见性管理

  @override
  bool get isLoading => ref.read(customCategoryProvider(widget.code)).isLoading;

  @override
  bool get isLoadingMore =>
      ref.read(customCategoryProvider(widget.code)).isLoadingMore;

  @override
  bool get hasMore =>
      ref.read(customCategoryProvider(widget.code)).data?.apps.hasMore ?? false;

  @override
  VoidCallback get onLoadMore =>
      () => ref.read(customCategoryProvider(widget.code).notifier).loadMore();

  @override
  void initState() {
    super.initState();
    initAutoLoad();
    _scrollController.addListener(onScroll);
    // family provider 会自动根据 code 参数初始化，无需手动调用 initCategory
  }

  @override
  void didUpdateWidget(CustomCategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // family provider 会自动根据 code 参数变化重新构建，无需手动处理
  }

  @override
  void dispose() {
    disposeAutoLoad();
    _scrollController.removeListener(onScroll);
    _scrollController.dispose();
    super.dispose();
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
          onTap: () => context.goToAppDetail(
            app.appId,
            appInfo: app.toInstalledApp(),
          ),
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
