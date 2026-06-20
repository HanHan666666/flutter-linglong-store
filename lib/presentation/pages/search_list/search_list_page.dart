import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/search_provider.dart';
import '../../../core/config/routes.dart';
import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/app_detail.dart';
import '../../../domain/models/recommend_models.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/widgets.dart';

/// 搜索结果页
///
/// 支持两种进入条件：普通文本关键词（[initialQuery]）或标签（[initialTag]）。
/// 标签优先级高于关键词：当两者同时提供时以标签为准，禁止把标签伪装成普通关键词。
class SearchListPage extends ConsumerStatefulWidget {
  const SearchListPage({this.initialQuery, this.initialTag, super.key});

  /// 初始搜索关键词（普通文本搜索模式）
  final String? initialQuery;

  /// 初始标签条件（标签搜索模式），优先级高于 [initialQuery]
  final AppTag? initialTag;

  @override
  ConsumerState<SearchListPage> createState() => _SearchListPageState();
}

class _SearchListPageState extends ConsumerState<SearchListPage>
    with AutoLoadWhenNotScrollable {
  final ScrollController _scrollController = ScrollController();

  // ==================== AutoLoadWhenNotScrollable 实现 ====================

  @override
  ScrollController get scrollController => _scrollController;

  @override
  bool get isPageVisible => true; // 搜索页不参与路由可见性管理

  @override
  bool get isLoading => ref.read(searchProvider).isLoading;

  @override
  bool get isLoadingMore => ref.read(searchProvider).isLoadingMore;

  @override
  bool get hasMore => ref.read(searchProvider).hasMore;

  @override
  VoidCallback get onLoadMore =>
      () => ref.read(searchProvider.notifier).loadMore();

  @override
  void initState() {
    super.initState();
    initAutoLoad();
    _scrollController.addListener(onScroll);
    _syncSearchQuery();
  }

  @override
  void didUpdateWidget(covariant SearchListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 关键词或标签任一变化都需重新同步搜索条件
    if (oldWidget.initialQuery != widget.initialQuery ||
        oldWidget.initialTag != widget.initialTag) {
      _syncSearchQuery();
    }
  }

  @override
  void dispose() {
    disposeAutoLoad();
    _scrollController.removeListener(onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _syncSearchQuery() {
    final tag = widget.initialTag;
    final query = widget.initialQuery?.trim() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final notifier = ref.read(searchProvider.notifier);
      // 标签优先级高于关键词：有标签走标签搜索
      if (tag != null) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        notifier.searchByTag(tag);
        return;
      }
      if (query.isEmpty) {
        notifier.clear();
        return;
      }
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      notifier.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(body: _buildBody(state));
  }

  Widget _buildBody(SearchState state) {
    // 未搜索状态：既无关键词也无标签
    if (!state.hasCriteria) {
      return _buildEmptySearch();
    }

    // 首次加载中
    if (state.isLoading && state.results.isEmpty) {
      return _buildLoadingState();
    }

    // 错误状态
    if (state.error != null && state.results.isEmpty) {
      return ErrorState.generic(
        description: state.error,
        onRetry: _syncSearchQuery,
      );
    }

    // 无结果状态
    if (state.results.isEmpty) {
      return EmptyState.search(
        title: AppLocalizations.of(context)?.searchNotFound ?? '未找到相关应用',
        description:
            AppLocalizations.of(context)?.searchTryOtherKeywords ??
            '尝试使用其他关键词搜索',
      );
    }

    // 搜索结果存在后，安排自动补页检查
    scheduleAutoLoadCheckAfterLayout();

    // 搜索结果列表
    return RefreshIndicator(
      onRefresh: () => ref.read(searchProvider.notifier).refresh(),
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: onScrollMetricsNotification,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 结果统计
            SliverToBoxAdapter(child: _buildResultHeader(state)),

            // 搜索结果网格
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: _AppsGrid(apps: state.results),
            ),
            // 搜索结果分页 footer 独立成整行 sliver，避免占一个卡片坑位。
            PaginationFooterSliver(
              isLoadingMore: state.isLoadingMore,
              hasMore: state.hasMore,
              hasItems: state.results.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearch() {
    final l10n = AppLocalizations.of(context);
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
            l10n?.searchInputHint ?? '在顶部搜索框输入关键词',
            style: context.appTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.searchPressEnter ?? '按 Enter 开始搜索应用',
            style: context.appTextStyles.bodyMedium.copyWith(
              color: context.appColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(SearchState state) {
    final l10n = AppLocalizations.of(context);
    // 结果标题统一读取当前条件（标签名称优先，回退到文本关键词），
    // 避免标签搜索时因 query 为空被误判为未搜索状态
    final displayTerm = state.tag?.name ?? state.query;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            l10n?.searchResultCount(state.total) ?? '找到 ${state.total} 个结果',
            style: context.appTextStyles.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (displayTerm.isNotEmpty)
            Text(
              '"$displayTerm"',
              style: context.appTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: context.appFontWeight(FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n?.loading ?? '加载中',
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
              AppGridShimmer(itemCount: 3),
            ],
          ),
        ),
      ),
    );
  }
}

/// 应用网格（已迁移到共享 ResponsiveAppGrid）
class _AppsGrid extends StatelessWidget {
  const _AppsGrid({required this.apps});

  final List<RecommendAppInfo> apps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ResponsiveAppGrid<RecommendAppInfo>(
      items: apps,
      emptyTitle: l10n?.searchNotFound ?? '未找到相关应用',
      emptyDescription: l10n?.searchTryOtherKeywords ?? '尝试使用其他关键词搜索',
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
