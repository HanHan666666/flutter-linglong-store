import 'package:flutter/material.dart';

/// 应用颜色系统
///
/// 基于 docs/03a-ui-design-tokens.md 设计规范
class AppColors {
  AppColors._();

  // ==================== 品牌色 ====================

  /// 主色 - #016FFD
  /// 用于: 按钮、链接、激活态、侧边栏选中、indicator 竖条
  static const Color primary = Color(0xFF016FFD);

  /// 主色 - 浅色变体 (用于 hover 状态等)
  static const Color primaryLight = Color(0xFFE6F0FF);

  /// 主色 - 深色变体
  static const Color primaryDark = Color(0xFF0052CC);

  // ==================== 背景色 ====================

  /// 页面背景色 - #FFFFFF
  static const Color background = Color(0xFFFFFFFF);

  /// 卡片背景色 - #F6F6F6
  static const Color cardBackground = Color(0xFFF6F6F6);

  /// 卡片边框色 - #F6F6F6
  static const Color cardBorder = Color(0xFFF6F6F6);

  /// 布局背景色 (Ant Design color-bg-layout)
  static const Color surfaceContainerLow = Color(0xFFF5F5F5);

  /// 主内容区背景 (Ant Design color-bg-container)
  static const Color surface = Color(0xFFFFFFFF);

  /// 搜索框 focus 背景 (Ant Design color-bg-elevated)
  static const Color surfaceContainerHighest = Color(0xFFF0F0F0);

  // ==================== 文字色 ====================

  /// 主文字色 - #1A1A1A
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// 次级文字色 - #666666
  static const Color textSecondary = Color(0xFF666666);

  /// 三级文字色 - #767676（对比度 4.54:1，满足 WCAG AA 4.5:1 要求）
  static const Color textTertiary = Color(0xFF767676);

  /// 标题深色 (推荐页标题)
  static const Color titleDark = Color(0xFF383838);

  /// 白色文字 (按钮内)
  static const Color textLight = Color(0xFFFFFFFF);

  // ==================== 功能色 ====================

  /// 错误色 - #FF4D4F
  /// 用于: 卸载按钮、关闭 hover、取消安装 hover
  static const Color error = Color(0xFFFF4D4F);

  /// 警告色 - #FAAD14
  /// 用于: 取消下载按钮默认态、Alert warning
  static const Color warning = Color(0xFFFAAD14);

  /// 成功色 - #52C41A
  /// 用于: 安装进度渐变终点
  static const Color success = Color(0xFF52C41A);

  /// 信息色 - #016FFD
  /// 用于: 关于页竖条 indicator
  static const Color info = Color(0xFF016FFD);

  // ==================== 特殊色 ====================

  /// "打开" 按钮背景色 - #FFFFFF
  static const Color openButtonBackground = Color(0xFFFFFFFF);

  /// "打开" 按钮边框色 - #D8D8D8
  static const Color openButtonBorder = Color(0xFFD8D8D8);

  /// "打开" 按钮文字色 - #2C2C2C
  static const Color openButtonText = Color(0xFF2C2C2C);

  /// "精品/TOP" 标签颜色 - #8B6914（对比度 4.6:1，满足 WCAG AA 要求）
  static const Color topLabel = Color(0xFF8B6914);

  /// SVG Logo 蓝色方块背景 - #025BFF
  static const Color logoBlue = Color(0xFF025BFF);

  // ==================== 分隔线/边框 ====================

  /// 分隔线颜色
  static const Color divider = Color(0xFFE5E5E5);

  /// 边框颜色
  static const Color border = Color(0xFFD9D9D9);

  /// 次级边框颜色
  static const Color borderSecondary = Color(0xFFE5E5E5);

  // ==================== 阴影色 ====================

  /// Modal 阴影色
  static const Color modalShadow = Color.fromRGBO(15, 23, 42, 0.16);

  /// Modal 边框色
  static const Color modalBorder = Color.fromRGBO(15, 23, 42, 0.08);

  /// 浮动按钮阴影色
  static const Color floatingButtonShadow = Color.fromRGBO(0, 0, 0, 0.15);

  /// 分类筛选栏阴影色
  static const Color categoryShadow = Color.fromRGBO(31, 38, 135, 0.16);

  // ==================== 骨架屏 ====================

  /// 骨架屏背景色
  static const Color skeletonBackground = Color(0xFFEEEEEE);

  /// 骨架屏高亮色
  static const Color skeletonHighlight = Color(0xFFF5F5F5);
}

/// 上下文感知颜色调色板
///
/// 提供浅色 (light) 和深色 (dark) 两套颜色方案。
/// 通过 [BuildContext.appColors] 扩展方法访问，自动跟随系统/用户主题。
///
/// 品牌固定色（主色、功能色）直接从 [AppColors] 获取，不随主题变化。
/// 背景色、表面色、文字色等语义色才随主题切换。
class AppColorPalette {
  const AppColorPalette._({
    required this.background,
    required this.surface,
    required this.cardBackground,
    required this.cardBorder,
    required this.surfaceContainerLow,
    required this.surfaceContainerHighest,
    required this.primaryLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.titleDark,
    required this.openButtonBackground,
    required this.openButtonBorder,
    required this.openButtonText,
    required this.divider,
    required this.border,
    required this.borderSecondary,
    required this.skeletonBackground,
    required this.skeletonHighlight,
  });

  /// 浅色方案
  static const AppColorPalette light = AppColorPalette._(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFF6F6F6),
    cardBorder: Color(0xFFF6F6F6),
    surfaceContainerLow: Color(0xFFF5F5F5),
    surfaceContainerHighest: Color(0xFFF0F0F0),
    primaryLight: Color(0xFFE6F0FF),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF666666),
    textTertiary: Color(0xFF767676),
    titleDark: Color(0xFF383838),
    openButtonBackground: Color(0xFFFFFFFF),
    openButtonBorder: Color(0xFFD8D8D8),
    openButtonText: Color(0xFF2C2C2C),
    divider: Color(0xFFE5E5E5),
    border: Color(0xFFD9D9D9),
    borderSecondary: Color(0xFFE5E5E5),
    skeletonBackground: Color(0xFFEEEEEE),
    skeletonHighlight: Color(0xFFF5F5F5),
  );

  /// 深色方案
  static const AppColorPalette dark = AppColorPalette._(
    background: Color(0xFF111111),
    surface: Color(0xFF1E1E1E),
    cardBackground: Color(0xFF272727),
    cardBorder: Color(0xFF333333),
    surfaceContainerLow: Color(0xFF161616),
    surfaceContainerHighest: Color(0xFF2A2A2A),
    primaryLight: Color(0xFF0D2040),
    textPrimary: Color(0xFFE4E4E4),
    textSecondary: Color(0xFF9A9A9A),
    textTertiary: Color(0xFF666666),
    titleDark: Color(0xFF2A2A2A),
    openButtonBackground: Color(0xFF272727),
    openButtonBorder: Color(0xFF444444),
    openButtonText: Color(0xFFE4E4E4),
    divider: Color(0xFF333333),
    border: Color(0xFF3A3A3A),
    borderSecondary: Color(0xFF333333),
    skeletonBackground: Color(0xFF2A2A2A),
    skeletonHighlight: Color(0xFF383838),
  );

  // ==================== 主题相关颜色 ====================

  /// 页面背景色
  final Color background;

  /// 主内容区背景色（面板/卡片容器）
  final Color surface;

  /// 卡片背景色
  final Color cardBackground;

  /// 卡片边框色
  final Color cardBorder;

  /// 布局背景色（比 surface 稍暗的底层容器）
  final Color surfaceContainerLow;

  /// 高亮表面色（搜索框 focus 等）
  final Color surfaceContainerHighest;

  /// 主色浅色变体（Tab indicator、选中背景）
  final Color primaryLight;

  /// 主文字色
  final Color textPrimary;

  /// 次级文字色
  final Color textSecondary;

  /// 三级文字色
  final Color textTertiary;

  /// 深色标题背景色（浅色为 #383838，深色为 #2A2A2A）
  final Color titleDark;

  /// "打开" 按钮背景色
  final Color openButtonBackground;

  /// "打开" 按钮边框色
  final Color openButtonBorder;

  /// "打开" 按钮文字色
  final Color openButtonText;

  /// 分隔线颜色
  final Color divider;

  /// 边框颜色
  final Color border;

  /// 次级边框颜色
  final Color borderSecondary;

  /// 骨架屏背景色
  final Color skeletonBackground;

  /// 骨架屏高亮色
  final Color skeletonHighlight;

  // ==================== 品牌固定色（不随主题变化）====================

  /// 主色 - #016FFD
  Color get primary => AppColors.primary;

  /// 主色深色变体
  Color get primaryDark => AppColors.primaryDark;

  /// 错误色 - #FF4D4F
  Color get error => AppColors.error;

  /// 警告色 - #FAAD14
  Color get warning => AppColors.warning;

  /// 成功色 - #52C41A
  Color get success => AppColors.success;

  /// 信息色 - #016FFD
  Color get info => AppColors.info;

  /// "精品/TOP" 标签颜色
  Color get topLabel => AppColors.topLabel;

  /// Logo 蓝色
  Color get logoBlue => AppColors.logoBlue;

  /// 白色文字（用于有色背景上）
  Color get textLight => AppColors.textLight;

  /// Modal 阴影色
  Color get modalShadow => AppColors.modalShadow;

  /// Modal 边框色
  Color get modalBorder => AppColors.modalBorder;

  /// 浮动按钮阴影色
  Color get floatingButtonShadow => AppColors.floatingButtonShadow;

  /// 分类筛选栏阴影色
  Color get categoryShadow => AppColors.categoryShadow;
}

/// BuildContext 扩展 - 获取上下文感知颜色
///
/// 使用方式：`context.appColors.background`
/// 自动根据当前 [ThemeData] 亮度返回浅色或深色调色板。
extension AppColorsExtension on BuildContext {
  /// 获取当前主题对应的颜色调色板
  AppColorPalette get appColors => Theme.of(this).brightness == Brightness.dark
      ? AppColorPalette.dark
      : AppColorPalette.light;
}
