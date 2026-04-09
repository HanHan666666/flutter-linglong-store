import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../domain/models/recommend_models.dart';
import 'category_filter_header.dart';

/// 分类筛选区公共封装。
///
/// 统一推荐页与全部应用页的 sliver 接线；展开态交给页面主滚动容器承载。
class CategoryFilterSection extends StatelessWidget {
  const CategoryFilterSection({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    this.showCount = false,
    this.isExpanded = false,
    this.onToggleExpand,
    super.key,
  });

  final List<CategoryInfo> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool showCount;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    if (isExpanded) {
      // 展开时直接复用顶部同一容器，避免额外插入第二块独立分类面板。
      return SliverToBoxAdapter(
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: CategoryFilterHeaderBox(
            categories: categories,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
            showCount: showCount,
            isExpanded: true,
            onToggleExpand: onToggleExpand,
          ),
        ),
      );
    }

    return SliverPersistentHeader(
      pinned: true,
      delegate: CategoryFilterHeaderDelegate(
        categories: categories,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
        showCount: showCount,
        isExpanded: false,
        onToggleExpand: onToggleExpand,
      ),
    );
  }
}

/// 分类筛选栏骨架屏。
class CategoryFilterSkeleton extends StatelessWidget {
  const CategoryFilterSkeleton({
    this.itemCount = 6,
    this.chipWidth = 88,
    super.key,
  });

  final int itemCount;
  final double chipWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.loading,
      child: Shimmer.fromColors(
        baseColor: context.appColors.skeletonBackground,
        highlightColor: context.appColors.skeletonHighlight,
        child: SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, __) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Container(
                  width: chipWidth,
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
      ),
    );
  }
}
