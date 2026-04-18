import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../../domain/models/recommend_models.dart';

/// 推荐页/全部应用页通用分类筛选栏
class CategoryFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  CategoryFilterHeaderDelegate({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    this.showCount = false,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  final List<CategoryInfo> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool showCount;

  /// 分类栏是否展开（多行 Wrap 展示所有分类）
  final bool isExpanded;

  /// 切换展开/折叠回调
  final VoidCallback? onToggleExpand;

  @override
  double get minExtent => 64;

  /// 头部始终保持单行固定高度；展开内容由外层 sliver 承载。
  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final showShadow = overlapsContent || shrinkOffset > 0;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CategoryFilterHeaderBox(
        categories: categories,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
        showCount: showCount,
        isExpanded: isExpanded,
        onToggleExpand: onToggleExpand,
        showShadow: showShadow,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CategoryFilterHeaderDelegate oldDelegate) {
    return categories != oldDelegate.categories ||
        selectedIndex != oldDelegate.selectedIndex ||
        showCount != oldDelegate.showCount ||
        isExpanded != oldDelegate.isExpanded;
  }
}

/// 分类筛选栏可复用容器。
///
/// 折叠态与展开态共用同一套视觉外壳，避免展开后出现第二块重复分类面板。
class CategoryFilterHeaderBox extends StatelessWidget {
  const CategoryFilterHeaderBox({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    required this.showCount,
    required this.isExpanded,
    this.showShadow = false,
    this.onToggleExpand,
    super.key,
  });

  final List<CategoryInfo> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool showCount;
  final bool isExpanded;
  final bool showShadow;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: AnimatedContainer(
        key: const ValueKey('category-filter-container'),
        duration: AppAnimation.fast,
        curve: AppAnimation.ease,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE7EBF0),
          ),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppShadows.none,
        ),
        child: isExpanded
            ? _buildExpandedLayout(context)
            : _buildCollapsedLayout(context),
      ),
    );
  }

  /// 折叠态：横向滚动 + 末尾展开按钮
  Widget _buildCollapsedLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final category = categories[index];
              return Tooltip(
                message: category.name,
                child: _CategoryChip(
                  label: category.name,
                  count: showCount ? category.appCount : null,
                  isSelected: index == selectedIndex,
                  onTap: () => onSelected(index),
                ),
              );
            },
          ),
        ),
        // 展开按钮仅切换外层面板，头部本身保持固定高度。
        if (onToggleExpand != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Tooltip(
              message: isExpanded ? '收起分类' : '展开分类',
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onToggleExpand,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 展开态：复用顶部同一容器，直接在内部使用多行 Wrap 展示完整分类。
  Widget _buildExpandedLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: List.generate(categories.length, (index) {
                final category = categories[index];
                return Tooltip(
                  message: category.name,
                  child: _CategoryChip(
                    label: category.name,
                    count: showCount ? category.appCount : null,
                    isSelected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
                );
              }),
            ),
          ),
          if (onToggleExpand != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Tooltip(
                message: '收起分类',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onToggleExpand,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.expand_less,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.label,
    this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final showBadge = widget.count != null && widget.count! > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isSelected
        ? (isDark ? const Color(0xFF5A5A5A) : const Color(0xFFD7DEE8))
        : _isHovered
        ? (isDark ? const Color(0xFF4A4A4A) : const Color(0xFFCBD5E1))
        : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3E8EF));
    final backgroundColor = isSelected
        ? (isDark ? const Color(0xFF3B3B3B) : const Color(0xFFF0F4F8))
        : _isHovered
        ? (isDark ? const Color(0xFF353535) : Colors.white)
        : (isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFDFDFE));

    return Semantics(
      selected: isSelected,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          curve: AppAnimation.ease,
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.fullRadius,
            border: Border.all(color: borderColor),
            boxShadow: AppShadows.none,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.fullRadius,
              onTap: widget.onTap,
              hoverColor: Colors.transparent,
              splashColor: const Color(0x14000000),
              highlightColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: showBadge ? 108 : 92,
                  minHeight: 48,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            // 分类胶囊按钮使用紧凑行高，避免中文在按钮内视觉偏上。
                            // caption = 13px，明确用于胶囊标签
                            height: 1,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? (isDark
                                      ? const Color(0xFFE4E4E4)
                                      : const Color(0xFF334155))
                                : context.appColors.textPrimary,
                          ),
                        ),
                      ),
                      if (showBadge) ...[
                        const SizedBox(width: 10),
                        AnimatedContainer(
                          duration: AppAnimation.fast,
                          curve: AppAnimation.ease,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                      ? const Color(0xFF3A3A3A)
                                      : const Color(0xFFE2E8F0))
                                : (isDark
                                      ? const Color(0xFF313131)
                                      : const Color(0xFFF1F5F9)),
                            borderRadius: AppRadius.fullRadius,
                          ),
                          child: Text(
                            '${widget.count}',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF9A9A9A)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
