import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用间距系统
///
/// 基于设计规范中的间距令牌 (rem 转 px，基准 16px)
class AppSpacing {
  AppSpacing._();

  /// xs - 4px
  /// 用于: 菜单项间距、badge 偏移
  static const double xs = 4.0;

  /// sm - 8px
  /// 用于: 内容区内边距、标签间距、搜索框左边距
  static const double sm = 8.0;

  /// md - 12px (文档中的 spacing-md)
  /// 用于: Tab间距、速度指标间距、侧边栏菜单项水平内边距
  static const double md = 12.0;

  /// lg - 16px
  /// 用于: 标题栏左右内边距、卡片网格间距、图标右间距
  static const double lg = 16.0;

  /// xl - 24px
  /// 用于: 页面统一内边距（最常用）、轮播下方间距
  static const double xl = 24.0;

  /// 2xl - 32px
  /// 用于: 详情页顶部、轮播内边距、底部导航图标尺寸
  static const double x2l = 32.0;

  /// 3xl - 48px
  /// 注意: 文档中为 42px (2.625rem)，这里按用户要求使用 48px
  static const double x3l = 48.0;

  /// 4xl - 56px
  /// 注意: 文档中为 64px (4rem)，这里按用户要求使用 56px
  static const double x4l = 56.0;

  /// 5xl - 64px
  /// 文档中的 4rem
  static const double x5l = 64.0;

  // ==================== 便捷方法 ====================

  /// 页面标准内边距
  static const double pagePadding = xl; // 24px

  /// 列表项内边距
  static const double listItemPadding = lg; // 16px

  /// 卡片内边距
  static const double cardPadding = lg; // 16px

  /// 按钮内边距
  static const double buttonPadding = lg; // 16px

  /// 图标大小
  static const double iconSize = 16.0;

  /// 大图标大小
  static const double iconSizeLarge = 32.0;

  /// 窗口控制按钮图标大小
  static const double windowControlIconSize = 18.0;
}

/// 应用圆角系统
class AppRadius {
  AppRadius._();

  /// xs - 4px
  /// 用于: 菜单项、图标、下载项图标
  static const double xs = 4.0;

  /// sm - 8px
  /// 用于: 卡片、骨架屏、内容区左上角、详情页图标背景
  static const double sm = 8.0;

  /// md - 12px
  /// 用于: 截图卡片
  static const double md = 12.0;

  /// lg - 16px
  /// 用于: 搜索框、设置页按钮、浮动更新按钮、TabBar ink-bar
  static const double lg = 16.0;

  /// xl - 16px (与 lg 相同，文档中无单独 xl)
  static const double xl = 16.0;

  /// full - 圆形/胶囊形
  /// 用于: 按钮(shape=round)、头像、进度圆环
  static const double full = 9999.0;

  // ==================== 便捷 BorderRadius ====================

  /// 获取 xs 圆角
  static BorderRadius get xsRadius => BorderRadius.circular(xs);

  /// 获取 sm 圆角
  static BorderRadius get smRadius => BorderRadius.circular(sm);

  /// 获取 md 圆角
  static BorderRadius get mdRadius => BorderRadius.circular(md);

  /// 获取 lg 圆角
  static BorderRadius get lgRadius => BorderRadius.circular(lg);

  /// 获取 xl 圆角
  static BorderRadius get xlRadius => BorderRadius.circular(xl);

  /// 获取 full 圆角 (胶囊形)
  static BorderRadius get fullRadius => BorderRadius.circular(full);

  /// 获取左上圆角 (用于内容区)
  static BorderRadius get topLeftRadius =>
      const BorderRadius.only(topLeft: Radius.circular(sm));

  /// 获取顶部圆角
  static BorderRadius get topRadius =>
      const BorderRadius.vertical(top: Radius.circular(sm));

  /// 获取底部圆角
  static BorderRadius get bottomRadius =>
      const BorderRadius.vertical(bottom: Radius.circular(sm));
}

/// 应用阴影系统
class AppShadows {
  AppShadows._();

  /// Modal 阴影
  /// 值: 0 18px 48px rgba(15, 23, 42, 0.16)
  static List<BoxShadow> get modal => [
    const BoxShadow(
      color: AppColors.modalShadow,
      blurRadius: 48,
      offset: Offset(0, 18),
    ),
  ];

  /// 分类筛选栏阴影
  /// 值: 0 8px 32px rgba(31, 38, 135, 0.16)
  static List<BoxShadow> get category => [
    const BoxShadow(
      color: AppColors.categoryShadow,
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  /// 浮动更新按钮阴影
  /// 值: 0 4px 12px rgba(0, 0, 0, 0.15)
  static List<BoxShadow> get floatingButton => [
    const BoxShadow(
      color: AppColors.floatingButtonShadow,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// 无阴影
  static List<BoxShadow> get none => [];
}
