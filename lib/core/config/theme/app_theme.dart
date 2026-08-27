import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// 应用界面语言对应的 CJK 字形变体。
///
/// Noto/思源各地区 CJK 字库覆盖同一批汉字但笔形不同：简体字形给日文汉字和
/// 繁体用户阅读时观感明显错误。按应用 locale 把最贴近的地区字库排到字体
/// 回退栈首位，其余地区字库继续保留兜底缺字；纯西文语言维持原简体顺序。
enum AppCjkGlyphVariant {
  /// 简体中文与未识别语言的默认笔形。
  hans,

  /// 繁体中文（zh-Hant 或台/港/澳地区）笔形。
  hant,

  /// 日文假名与日式汉字笔形。
  ja,

  /// 韩文谚文与韩式汉字笔形。
  ko,
}

/// 应用主题
class AppTheme {
  AppTheme._();

  static const _tooltipTheme = TooltipThemeData(
    waitDuration: Duration(milliseconds: 800),
  );

  /// 解析应用 Locale 对应的 CJK 字形变体。
  ///
  /// script 子标签优先（Hant→繁体、Hans→简体）；中文无 script 时按
  /// 台/港/澳地区惯例归繁体；日韩按 language code 判定；其余语言沿用
  /// 产品默认的简体字形，保持历史渲染不变。
  static AppCjkGlyphVariant cjkGlyphVariantOf(Locale? locale) {
    if (locale == null) {
      return AppCjkGlyphVariant.hans;
    }
    switch (locale.scriptCode) {
      case 'Hant':
        return AppCjkGlyphVariant.hant;
      case 'Hans':
        return AppCjkGlyphVariant.hans;
    }
    switch (locale.languageCode) {
      case 'ja':
        return AppCjkGlyphVariant.ja;
      case 'ko':
        return AppCjkGlyphVariant.ko;
      case 'zh':
        return switch (locale.countryCode) {
          'TW' || 'HK' || 'MO' => AppCjkGlyphVariant.hant,
          _ => AppCjkGlyphVariant.hans,
        };
      default:
        return AppCjkGlyphVariant.hans;
    }
  }

  // Explicit Linux CJK/Arabic fallbacks avoid relying on distro-specific
  // defaults. Noto Sans Arabic 保证阿拉伯语（RTL）正文有确定性字体回退。
  //
  // 各字形变体的回退栈把目标地区字库排在首位，其余 CJK 字库继续兜底个别
  // 缺字；阿拉伯语与 Emoji 字库在所有变体中固定位于末尾。
  static List<String> _linuxFontFamilyFallback(AppCjkGlyphVariant variant) {
    return switch (variant) {
      AppCjkGlyphVariant.hant => <String>[
        'Noto Sans CJK TC',
        'Source Han Sans TC',
        // 繁体字库偶发缺字时退化到覆盖面最大的简体字库。
        'Noto Sans CJK SC',
        'Source Han Sans SC',
        'WenQuanYi Micro Hei',
        'WenQuanYi Zen Hei',
        'Noto Sans Arabic',
        'Noto Color Emoji',
      ],
      AppCjkGlyphVariant.ja => <String>[
        'Noto Sans CJK JP',
        'Source Han Sans JP',
        'Noto Sans CJK SC',
        'Source Han Sans SC',
        'WenQuanYi Micro Hei',
        'WenQuanYi Zen Hei',
        'Noto Sans Arabic',
        'Noto Color Emoji',
      ],
      AppCjkGlyphVariant.ko => <String>[
        'Noto Sans CJK KR',
        'Source Han Sans KR',
        'Noto Sans CJK SC',
        'Source Han Sans SC',
        'WenQuanYi Micro Hei',
        'WenQuanYi Zen Hei',
        'Noto Sans Arabic',
        'Noto Color Emoji',
      ],
      AppCjkGlyphVariant.hans => <String>[
        'Noto Sans CJK SC',
        'Source Han Sans SC',
        'WenQuanYi Micro Hei',
        'WenQuanYi Zen Hei',
        'Noto Sans Arabic',
        'Noto Color Emoji',
      ],
    };
  }

  /// 零动画页面转场构建器
  static const _noTransitionTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.linux: _NoTransitionBuilder(),
      TargetPlatform.android: _NoTransitionBuilder(),
      TargetPlatform.iOS: _NoTransitionBuilder(),
      TargetPlatform.macOS: _NoTransitionBuilder(),
      TargetPlatform.windows: _NoTransitionBuilder(),
      TargetPlatform.fuchsia: _NoTransitionBuilder(),
    },
  );

  static AppTypographyStyles _withLinuxTypographyFallbacks(
    AppTypographyStyles typography,
    AppCjkGlyphVariant glyphVariant,
  ) {
    return typography.withFontFamilyFallback(
      _linuxFontFamilyFallback(glyphVariant),
    );
  }

  /// 构建浅色 ColorScheme。
  ///
  /// ColorScheme 的 surfaceContainer 系列会被部分页面直接读取，
  /// 这里必须和 AppColorPalette.light 同步，避免旧灰底绕过项目令牌回流。
  static ColorScheme _buildLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.error,
      onSurface: AppColors.textPrimary,
    ).copyWith(
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainerLow,
      surfaceContainerHigh: AppColors.surfaceContainerHighest,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      outlineVariant: AppColors.borderSecondary,
      primaryContainer: AppColors.primaryLight,
    );
  }

  /// 构建深色 ColorScheme。
  ///
  /// 深色主题本阶段只做令牌同步，不改变既有暗色层级，避免浅色改造
  /// 连带破坏深色模式的可读对比。
  static ColorScheme _buildDarkColorScheme(AppColorPalette palette) {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: palette.surface,
      error: AppColors.error,
      onSurface: palette.textPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      surfaceContainerLowest: palette.background,
      surfaceContainerLow: palette.surfaceContainerLow,
      surfaceContainer: palette.surfaceContainerLow,
      surfaceContainerHigh: palette.surfaceContainerHighest,
      surfaceContainerHighest: palette.surfaceContainerHighest,
      outlineVariant: palette.borderSecondary,
      primaryContainer: palette.primaryLight,
    );
  }

  /// 浅色主题
  static ThemeData get lightTheme => buildLightTheme();

  /// [appLocale] 决定 CJK 字形变体首选的地区字库；传 null 保持简体形态。
  static ThemeData buildLightTheme({
    AppFontWeightAdjustment fontWeightAdjustment =
        AppFontWeightAdjustment.normal,
    bool systemBoldText = false,
    Locale? appLocale,
  }) {
    final typography = _withLinuxTypographyFallbacks(
      AppTextStyles.resolveTypography(
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      cjkGlyphVariantOf(appLocale),
    );

    return ThemeData(
      useMaterial3: true,
      // 全局禁用页面路由转场动画
      pageTransitionsTheme: _noTransitionTheme,
      colorScheme: _buildLightColorScheme(),
      scaffoldBackgroundColor: AppColors.background,
      // 注意: 移除 fontFamily 配置，使用 Flutter 默认字体
      // Flutter 不支持 CSS 风格的逗号分隔字体列表
      // fontFamily: 'Inter, Avenir, Helvetica, Arial',

      // 文字主题
      textTheme: typography.textTheme,
      extensions: <ThemeExtension<dynamic>>[typography],

      // 应用栏主题
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.title2.copyWith(
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
        fillColor: AppColors.surfaceContainerHighest,
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
        hintStyle: typography.caption.copyWith(color: AppColors.textTertiary),
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

      tooltipTheme: _tooltipTheme,

      // TabBar 主题
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: typography.body.copyWith(
          fontWeight: typography.resolveFontWeight(FontWeight.w500),
        ),
        unselectedLabelStyle: typography.body,
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
            return typography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: typography.resolveFontWeight(FontWeight.w500),
            );
          }
          return typography.caption.copyWith(color: AppColors.textSecondary);
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
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.primaryLight,
        labelStyle: typography.caption,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
      ),

      // Snackbar 主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.titleDark,
        contentTextStyle: typography.body.copyWith(color: AppColors.textLight),
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
  }

  /// 深色主题
  static ThemeData get darkTheme => buildDarkTheme();

  /// [appLocale] 决定 CJK 字形变体首选的地区字库；传 null 保持简体形态。
  static ThemeData buildDarkTheme({
    AppFontWeightAdjustment fontWeightAdjustment =
        AppFontWeightAdjustment.normal,
    bool systemBoldText = false,
    Locale? appLocale,
  }) {
    const palette = AppColorPalette.dark;
    final typography = _withLinuxTypographyFallbacks(
      AppTextStyles.resolveTypography(
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      cjkGlyphVariantOf(appLocale),
    );

    return ThemeData(
      useMaterial3: true,
      // 全局禁用页面路由转场动画
      pageTransitionsTheme: _noTransitionTheme,
      colorScheme: _buildDarkColorScheme(palette),
      scaffoldBackgroundColor: palette.background,
      textTheme: typography.textTheme,
      extensions: <ThemeExtension<dynamic>>[typography],

      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.title2.copyWith(color: palette.textPrimary),
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
        fillColor: palette.surfaceContainerHighest,
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
        hintStyle: typography.caption.copyWith(color: palette.textTertiary),
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

      tooltipTheme: _tooltipTheme,

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: palette.textSecondary,
        labelStyle: typography.body.copyWith(
          fontWeight: typography.resolveFontWeight(FontWeight.w500),
        ),
        unselectedLabelStyle: typography.body,
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
            return typography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: typography.resolveFontWeight(FontWeight.w500),
            );
          }
          return typography.caption.copyWith(color: palette.textSecondary);
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
        labelStyle: typography.caption.copyWith(color: palette.textPrimary),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.titleDark,
        contentTextStyle: typography.body.copyWith(color: AppColors.textLight),
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

/// 零动画页面转场构建器
///
/// 所有路由切换瞬切，无 slide/fade 过渡
class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
