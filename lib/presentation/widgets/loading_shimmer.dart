import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 应用卡片骨架屏组件
///
/// 用于在应用数据加载时显示占位效果
class LoadingShimmer extends StatelessWidget {
  /// 骨架屏类型
  final ShimmerType type;

  /// 骨架屏数量
  final int count;

  /// 是否激活动画
  final bool enabled;

  const LoadingShimmer({
    super.key,
    this.type = ShimmerType.card,
    this.count = 1,
    this.enabled = true,
  });

  /// 创建应用卡片骨架屏
  const LoadingShimmer.card({super.key, this.count = 1, this.enabled = true})
      : type = ShimmerType.card;

  /// 创建列表项骨架屏
  const LoadingShimmer.listItem({super.key, this.count = 1, this.enabled = true})
      : type = ShimmerType.listItem;

  /// 创建网格骨架屏
  const LoadingShimmer.grid({super.key, this.count = 1, this.enabled = true})
      : type = ShimmerType.grid;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: List.generate(count, (index) => _buildShimmerItem(context, index)),
    );
  }

  Widget _buildShimmerItem(BuildContext context, index) {
    switch (type) {
      case ShimmerType.card:
        return _buildCardShimmer(context);
      case ShimmerType.listItem:
        return _buildListItemShimmer(context);
      case ShimmerType.grid:
        return _buildGridShimmer(context);
    }
  }

  /// 构建卡片骨架屏
  Widget _buildCardShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 图标占位
          _buildShimmerBox(
            context,
            baseColor: baseColor,
            highlightColor: highlightColor,
            width: 64,
            height: 64,
            borderRadius: 12,
          ),
          const SizedBox(width: 12),
          // 内容占位
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题占位
                _buildShimmerBox(context, baseColor: baseColor, highlightColor: highlightColor, width: double.infinity, height: 16),
                const SizedBox(height: 8),
                // 描述占位
                _buildShimmerBox(context, baseColor: baseColor, highlightColor: highlightColor, width: double.infinity, height: 12),
                const SizedBox(height: 4),
                _buildShimmerBox(context, baseColor: baseColor, highlightColor: highlightColor, width: 200, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 按钮占位
          _buildShimmerBox(context, baseColor: baseColor, highlightColor: highlightColor, width: 60, height: 32, borderRadius: 16),
        ],
      ),
    );
  }

  /// 构建列表项骨架屏
  Widget _buildListItemShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildShimmerBox(context, baseColor: baseColor, highlightColor: highlightColor, width: 48, height: 48, borderRadius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(context, baseColor: baseColor, highlightColor: highlightColor, width: 150, height: 14),
                const SizedBox(height: 6),
                _buildShimmerBox(context, baseColor: baseColor, highlightColor: highlightColor, width: 200, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建网格骨架屏
  Widget _buildGridShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(context, baseColor: baseColor, highlightColor: highlightColor, width: double.infinity, height: 120, borderRadius: 8),
          const SizedBox(height: 8),
          _buildShimmerBox(context, baseColor: baseColor, highlightColor: highlightColor, width: 100, height: 14),
          const SizedBox(height: 4),
          _buildShimmerBox(context, baseColor: baseColor, highlightColor: highlightColor, width: 60, height: 12),
        ],
      ),
    );
  }

  /// 构建骨架屏占位盒子（带 shimmer 动画效果）
  Widget _buildShimmerBox(
    BuildContext context, {
    required Color baseColor,
    required Color highlightColor,
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// 骨架屏类型枚举
enum ShimmerType {
  /// 应用卡片
  card,

  /// 列表项
  listItem,

  /// 网格
  grid,
}