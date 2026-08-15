import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../application/providers/application_card_state_provider.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import 'widgets.dart';

/// 卡片网格按 96px 视觉高度计算，给图标、按钮和 hover 安全区留出稳定空间，
/// 避免列表项在桌面端显得拥挤或上下贴边。
const kAppCardHeight = 96.0;

/// 单个物品的构建回调。
///
/// [ref] 为 Riverpod 引用，可用于触发 Provider 操作。
/// [index] 为物品索引，[cardState] 为预先解析的应用卡片状态。
typedef ResponsiveGridItemBuilder<T> =
    Widget Function(
      WidgetRef ref,
      int index,
      T item,
      ResolvedApplicationCardState cardState,
    );

/// 响应式应用网格组件。
///
/// 一个 `SliverGrid`，根据容器宽度自动计算响应式列数。
/// 使用 [SliverLayoutBuilder] 动态获取可用宽度，
/// 按硬编码断点计算列数：
/// - width < 600: 1列
/// - width < 900: 2列
/// - width < 1200: 3列
/// - width >= 1200: 4列
///
/// 支持两种模式：
/// 1. **简单模式**：仅传入 [items] 和 [itemBuilder]，渲染固定列表。
/// 2. **分页模式**：由页面层在 grid 后拼接 [PaginationFooterSliver]，
///    保证 loading 和 no-more footer 以整行 sliver 居中显示。
///
/// [itemBuilder] 会接收 [WidgetRef]，方便调用 Provider 相关操作。
class ResponsiveAppGrid<T> extends ConsumerWidget {
  const ResponsiveAppGrid({
    required this.items,
    required this.itemBuilder,
    this.mainAxisSpacing = AppSpacing.md,
    this.crossAxisSpacing = AppSpacing.md,
    this.childAspectRatio,
    this.emptyTitle,
    this.emptyDescription,
    super.key,
  });

  /// 数据列表。
  final List<T> items;

  /// 单个物品的构建回调。
  final ResponsiveGridItemBuilder<T> itemBuilder;

  /// 主轴线间距，默认 [AppSpacing.md]。
  final double mainAxisSpacing;

  /// 交叉轴间距，默认 [AppSpacing.md]。
  final double crossAxisSpacing;

  /// 自定义物品宽高比。
  ///
  /// 若为 null，则根据当前列数和卡片高度自动计算。
  final double? childAspectRatio;

  /// 空数据时的标题（简单模式下有效）。
  final String? emptyTitle;

  /// 空数据时的描述（简单模式下有效）。
  final String? emptyDescription;

  /// 根据宽度计算响应式列数。
  ///
  /// 使用硬编码断点：
  /// - width < 600: 1列
  /// - width < 900: 2列
  /// - width < 1200: 3列
  /// - width >= 1200: 4列
  static int calculateCrossAxisCount(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  /// 根据宽度计算物品宽高比。
  ///
  /// 若未传入自定义 [childAspectRatio]，则使用卡片高度计算。
  static double calculateChildAspectRatio(
    double width,
    int crossAxisCount, {
    double? childAspectRatio,
    double crossAxisSpacing = AppSpacing.md,
  }) {
    if (childAspectRatio != null) return childAspectRatio;
    final itemWidth =
        (width - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
    return itemWidth / kAppCardHeight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return SliverToBoxAdapter(
        child: EmptyState.noData(
          title: emptyTitle ?? l10n.noApps,
          description: emptyDescription ?? l10n.noAppsInCategory,
        ),
      );
    }

    // 卡片状态按单元格粒度订阅（见 _ResponsiveGridCell）：安装队列的
    // 高频进度事件只重建状态真实变化的卡片，网格本身不再全量重算。
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = calculateCrossAxisCount(
          constraints.crossAxisExtent,
        );
        final aspectRatio = calculateChildAspectRatio(
          constraints.crossAxisExtent,
          crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
        );

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: aspectRatio,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            return _ResponsiveGridCell<T>(
              item: items[index],
              index: index,
              itemBuilder: itemBuilder,
            );
          }, childCount: items.length),
        );
      },
    );
  }
}

/// 网格单元格：以卡片粒度订阅自己的卡片状态。
///
/// 通过 `select` + [ResolvedApplicationCardState] 的值相等实现：
/// 安装进度等高频事件只重建进度变化的那张卡片，其余卡片与网格容器
/// 均不重建，避免整个网格 O(n) 重算（IndexedStack 下是多页面同时重算）。
class _ResponsiveGridCell<T> extends ConsumerWidget {
  const _ResponsiveGridCell({
    required this.item,
    required this.index,
    required this.itemBuilder,
  });

  final T item;
  final int index;
  final ResponsiveGridItemBuilder<T> itemBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardState = ref.watch(
      applicationCardStateIndexProvider.select(
        (state) => state.resolve(appId: (item as dynamic).appId as String),
      ),
    );
    return itemBuilder(ref, index, item, cardState);
  }
}

/// 分页尾部 sliver。
///
/// footer 必须独立于 grid 渲染，避免被当成一个卡片格子占位。
class PaginationFooterSliver extends StatelessWidget {
  const PaginationFooterSliver({
    required this.isLoadingMore,
    required this.hasMore,
    required this.hasItems,
    this.bottomPadding = AppSpacing.xl,
    super.key,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final bool hasItems;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    if (!hasItems) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          width: double.infinity,
          child: Center(
            child: switch ((isLoadingMore, hasMore)) {
              (true, _) => SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  semanticsLabel: l10n.loading,
                ),
              ),
              (false, false) => Text(
                l10n.noMore,
                style: context.appTextStyles.caption.copyWith(
                  color: context.appColors.textTertiary,
                ),
              ),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }
}

/// 应用网格骨架屏。
///
/// 显示 Shimmer 加载效果的网格占位符，
/// 用于应用列表首次加载时的视觉反馈。
class AppGridShimmer extends StatelessWidget {
  const AppGridShimmer({this.itemCount = 12, super.key});

  /// 骨架屏物品数量。
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.loading,
      child: Shimmer.fromColors(
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
            itemCount: itemCount,
            itemBuilder: (_, _) {
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
