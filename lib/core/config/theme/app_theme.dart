import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

/// 应用主题
class AppTheme {
  AppTheme._();

  static const _tooltipTheme = TooltipThemeData(
    waitDuration: Duration(milliseconds: 800),
  );

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

  /// 浅色主题
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    // 全局禁用页面路由转场动画
    pageTransitionsTheme: _noTransitionTheme,
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

    tooltipTheme: _tooltipTheme,

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
      // 全局禁用页面路由转场动画
      pageTransitionsTheme: _noTransitionTheme,
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

      tooltipTheme: _tooltipTheme,

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
