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

  /// 三级文字色
  static const Color textTertiary = Color(0xFF999999);

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

  /// "打开"按钮背景色 - #FFFFFF
  static const Color openButtonBackground = Color(0xFFFFFFFF);

  /// "打开"按钮边框色 - #D8D8D8
  static const Color openButtonBorder = Color(0xFFD8D8D8);

  /// "打开"按钮文字色 - #2C2C2C
  static const Color openButtonText = Color(0xFF2C2C2C);

  /// "精品/TOP" 标签颜色 - #CDA354
  static const Color topLabel = Color(0xFFCDA354);

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

/// 应用文字样式
///
/// 基于设计规范中的字体层级系统
class AppTextStyles {
  AppTextStyles._();

  // ==================== Display 层级 ====================

  /// Display - 32px, bold
  /// 用于: 启动页应用名
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700, // bold
    height: 1.5,
    letterSpacing: 0,
  );

  // ==================== Title 层级 ====================

  /// Title1 - 28px, bold
  /// 用于: 应用详情主标题、页面 Hero 标题
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700, // bold
    height: 1.4,
    letterSpacing: 0,
  );

  /// Title2 - 24px, semi-bold
  /// 用于: 推荐标题、搜索结果标题、大区块标题
  static const TextStyle title2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600, // semi-bold
    height: 1.4,
    letterSpacing: 0,
  );

  /// Title3 - 20px, medium
  /// 用于: 页面主标题、组件级标题
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600, // semi-bold
    height: 1.4,
    letterSpacing: 0,
  );

  // ==================== Body 层级 ====================

  /// Body - 16px, regular
  /// 用于: 主正文、应用介绍、设置页正文（桌面端主阅读体）
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400, // regular
    height: 1.5,
    letterSpacing: 0,
  );

  /// Body Medium - 14px, regular
  /// 用于: 常规说明文字、菜单文字、搜索输入、卡片描述
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400, // regular
    height: 1.5,
    letterSpacing: 0,
  );

  // ==================== Caption 层级 ====================

  /// Caption - 13px, regular
  /// 用于: 版本、仓库、辅助元信息、次级说明
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400, // regular
    height: 1.5,
    letterSpacing: 0,
  );

  // ==================== Tiny 层级 ====================

  /// Tiny - 12px, regular
  /// 用于: 标签、胶囊、角标、"精品/TOP" 极小提示（禁止用于承载主要可读信息）
  static const TextStyle tiny = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400, // regular
    height: 1.5,
    letterSpacing: 0,
  );

  // ==================== 辅助样式 ====================

  /// 菜单激活态文字 - 16px, medium（展开态侧边栏菜单）
  static const TextStyle menuActive = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500, // medium
    height: 1.5,
    letterSpacing: 0,
  );

  /// 链接文字
  static TextStyle get link => body.copyWith(
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );

  /// 次级文字 (带透明度)
  static TextStyle get secondary =>
      body.copyWith(color: AppColors.textSecondary);

  /// 三级文字 (带透明度)
  static TextStyle get tertiary => body.copyWith(color: AppColors.textTertiary);

  // ==================== Flutter TextTheme 映射 ====================

  /// 转换为 Flutter TextTheme（桌面端可读性规范）
  ///
  /// 映射关系:
  /// - displayLarge  -> 32px bold  （启动页超大标题）
  /// - headlineLarge -> 28px bold  （详情页主标题、页面 Hero）
  /// - headlineMedium-> 24px w600  （大区块标题）
  /// - headlineSmall -> 22px w600  （次级区块标题）
  /// - titleLarge    -> 20px w600  （页面主标题、重要列表标题）
  /// - titleMedium   -> 18px w600  （弹窗标题、分组标题）
  /// - titleSmall    -> 16px w500  （Tab、列表主文字、设置主标签）
  /// - bodyLarge     -> 16px w400  （正文、应用介绍、设置页正文）
  /// - bodyMedium    -> 14px w400  （菜单文字、搜索输入、卡片描述）
  /// - bodySmall     -> 13px w400  （版本、仓库、辅助元信息）
  /// - labelLarge    -> 14px w500  （常规按钮文字）
  /// - labelMedium   -> 13px w500  （紧凑按钮、次级操作）
  /// - labelSmall    -> 12px w500  （标签、胶囊、极小强调）
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.4,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.4,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
  );
}

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

/// 应用动画配置
class AppAnimation {
  AppAnimation._();

  /// 快速动画时长 - 200ms
  /// 用于: 侧边栏宽度切换、菜单项 hover 背景、分类栏折叠
  static const Duration fast = Duration(milliseconds: 200);

  /// 标准动画时长 - 300ms
  /// 用于: 卡片透明度过渡
  static const Duration normal = Duration(milliseconds: 300);

  /// Shimmer 动画时长 - 1500ms
  static const Duration shimmer = Duration(milliseconds: 1500);

  /// 截图 shimmer 动画时长 - 1400ms
  static const Duration screenshotShimmer = Duration(milliseconds: 1400);

  /// 轮播自动切换时长 - 4000ms
  static const Duration carousel = Duration(milliseconds: 4000);

  // ==================== 缓动曲线 ====================

  /// 默认缓动曲线
  static const Curve defaultCurve = Curves.easeInOut;

  /// 线性曲线
  static const Curve linear = Curves.linear;

  /// ease 曲线
  static const Curve ease = Curves.ease;
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
    textTertiary: Color(0xFF999999),
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

  /// "打开"按钮背景色
  final Color openButtonBackground;

  /// "打开"按钮边框色
  final Color openButtonBorder;

  /// "打开"按钮文字色
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

/// 应用主题
class AppTheme {
  AppTheme._();

  /// 浅色主题
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.error,
      onSurface: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    // 注意: 移除 fontFamily 配置，使用 Flutter 默认字体
    // Flutter 不支持 CSS 风格的逗号分隔字体列表
    // fontFamily: 'Inter, Avenir, Helvetica, Arial',

    // 文字主题
    textTheme: AppTextStyles.textTheme,

    // 应用栏主题
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.title2.copyWith(
        color: AppColors.textPrimary,
      ),
    ),

    // 卡片主题
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.smRadius,
        side: const BorderSide(color: AppColors.cardBorder),
      ),
    ),

    // 按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        shape: const StadiumBorder(),
        minimumSize: const Size(68, 28),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        elevation: 0,
      ),
    ),

    // 文字按钮主题
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
    ),

    // 输入框主题
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.lgRadius,
        borderSide: const BorderSide(color: AppColors.borderSecondary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgRadius,
        borderSide: const BorderSide(color: AppColors.borderSecondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
    ),

    // 对话框主题
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.smRadius,
        side: const BorderSide(color: AppColors.modalBorder),
      ),
      elevation: 0,
      backgroundColor: AppColors.surface,
      shadowColor: AppColors.modalShadow,
    ),

    // 分隔线主题
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: AppSpacing.lg,
    ),

    // 图标主题
    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
      size: AppSpacing.iconSize,
    ),

    // TabBar 主题
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
      unselectedLabelStyle: AppTextStyles.body,
      indicator: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.lgRadius,
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
    ),

    // 底部导航栏主题
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // 导航栏主题
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.primaryLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          );
        }
        return AppTextStyles.caption.copyWith(color: AppColors.textSecondary);
      }),
    ),

    // 导航抽屉主题
    navigationDrawerTheme: const NavigationDrawerThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.primaryLight,
      tileHeight: 48,
    ),

    // 悬浮按钮主题
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textLight,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
    ),

    // Chip 主题
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.cardBackground,
      selectedColor: AppColors.primaryLight,
      labelStyle: AppTextStyles.caption,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
    ),

    // Snackbar 主题
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.titleDark,
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.textLight),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
      behavior: SnackBarBehavior.floating,
    ),

    // 进度指示器主题
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.cardBackground,
      circularTrackColor: AppColors.cardBackground,
    ),
  );

  /// 深色主题
  static ThemeData get darkTheme {
    const palette = AppColorPalette.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: palette.surface,
        error: AppColors.error,
        onSurface: palette.textPrimary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: palette.background,
      textTheme: AppTextStyles.textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title2.copyWith(
          color: palette.textPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: palette.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smRadius,
          side: BorderSide(color: palette.cardBorder),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          shape: const StadiumBorder(),
          minimumSize: const Size(68, 28),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: BorderSide(color: palette.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: BorderSide(color: palette.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        hintStyle: AppTextStyles.caption.copyWith(color: palette.textTertiary),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smRadius,
          side: BorderSide(color: palette.cardBorder),
        ),
        elevation: 0,
        backgroundColor: palette.surface,
        shadowColor: AppColors.modalShadow,
      ),

      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: AppSpacing.lg,
      ),

      iconTheme: IconThemeData(
        color: palette.textSecondary,
        size: AppSpacing.iconSize,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: palette.textSecondary,
        labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
        unselectedLabelStyle: AppTextStyles.body,
        indicator: BoxDecoration(
          color: palette.primaryLight,
          borderRadius: AppRadius.lgRadius,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: palette.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.background,
        indicatorColor: palette.primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            );
          }
          return AppTextStyles.caption.copyWith(color: palette.textSecondary);
        }),
      ),

      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: palette.background,
        indicatorColor: palette.primaryLight,
        tileHeight: 48,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: palette.cardBackground,
        selectedColor: palette.primaryLight,
        labelStyle: AppTextStyles.caption.copyWith(color: palette.textPrimary),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.titleDark,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.textLight,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
        behavior: SnackBarBehavior.floating,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: palette.cardBackground,
        circularTrackColor: palette.cardBackground,
      ),
    );
  }
}
