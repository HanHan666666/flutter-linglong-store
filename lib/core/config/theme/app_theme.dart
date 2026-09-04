import 'package:flutter/material.dart';
import '../../../domain/models/system_accent_color.dart';
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
  //
  // 简体栈以 MiSans 打头（社区反馈的界面字体偏好，GitHub issue #22）：字体
  // 不入包、不增加下载体积，仅声明家族名——系统装有 MiSans 的用户中文自动
  // 以 MiSans 渲染，未安装时 fontconfig 匹配不到该家族会自然落到后续
  // Noto/文泉驿字库，行为与现状一致。
  //
  // 日文与繁中栈同样前插 MiSans（日文为同一用户明确要求；繁中为 issue #22
  // 讨论后的方案 A 决定）：实测 MiSans 的 cmap 覆盖平/片假名、促音、JIS
  // 专属汉字（峠/辻/働）及全部繁体码位（門轉龍發麥體），整体渲染不会混排；
  // 但假名与汉字均为中式/简体笔形，对地区字形纯正度敏感的用户可移除系统
  // MiSans 自动回落 Noto 地区字库。
  //
  // 韩文栈不前插 MiSans：实测其 cmap 不含任何谚文字符（한국어 等全部缺失），
  // 前插对韩文文本无效果，谚文本来就会全部落到 Noto Sans CJK KR 兜底。
  static List<String> _linuxFontFamilyFallback(AppCjkGlyphVariant variant) {
    return switch (variant) {
      AppCjkGlyphVariant.hant => <String>[
        // 方案 A（issue #22 讨论）：繁中码位实测全覆盖、不会混排，装了
        // MiSans 的繁中用户优先 MiSans 观感；缺字由后续 Noto TC 兜底。
        'MiSans',
        'MiSans VF',
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
        // 与简体栈同理由前插 MiSans（两个家族名均实测自字体 name 表）。
        // MiSans 覆盖假名与常用汉字，个别缺字由后续 Noto JP/思源 JP 兜底。
        'MiSans',
        'MiSans VF',
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
        // 两个家族名均取自官方字体文件的 name 表（nameID=1）而非臆测：
        // 静态 10 字重包安装的家族是 MiSans，仅安装可变字体文件的用户
        // 家族是 MiSans VF，两条都声明才能覆盖两种安装方式。
        'MiSans',
        'MiSans VF',
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

  /// 用系统强调色种子派生基础 ColorScheme（docs/48 §7.5）。
  ///
  /// 使用 `DynamicSchemeVariant.fidelity`：在尽量保留种子色相与饱和度的
  /// 同时，由算法生成可读的 primary/onPrimary、primaryContainer/
  /// onPrimaryContainer 配对。与品牌回退路径不同，这里刻意不覆盖 primary
  /// 系列角色——外部桌面允许近白/近黑/亮黄等极端种子，强制套用原始 RGB
  /// 会破坏配对对比度；项目中性表面色、错误色与边框令牌仍随后续 copyWith
  /// 固定，保证系统强调色只染强调角色、不重染整个界面。
  static ColorScheme _fromSystemSeed(
    SystemAccentColor accent,
    Brightness brightness,
  ) {
    // 8-bit 分量直接映射为不透明 sRGB；归一化已在 Platform 边界完成。
    return ColorScheme.fromSeed(
      seedColor: Color.fromARGB(0xFF, accent.red, accent.green, accent.blue),
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      brightness: brightness,
    );
  }

  /// 构建浅色 ColorScheme。
  ///
  /// [systemAccentColor] 为 XDG Portal 提供的系统强调色种子：
  /// - null（loading、能力不可用或未设置）走品牌回退路径，关键令牌与既有
  ///   外观逐位一致（primary #016FFD、primaryContainer #E6F0FF），这是
  ///   Golden 与兼容性验收的硬性要求；
  /// - 非 null 走 fidelity 派生路径，primary 系列随系统强调色流动。
  ///
  /// ColorScheme 的 surfaceContainer 系列会被部分页面直接读取，
  /// 这里必须和 AppColorPalette.light 同步，避免旧灰底绕过项目令牌回流。
  static ColorScheme _buildLightColorScheme({
    SystemAccentColor? systemAccentColor,
  }) {
    if (systemAccentColor != null) {
      return _fromSystemSeed(systemAccentColor, Brightness.light).copyWith(
        surface: AppColors.surface,
        error: AppColors.error,
        onSurface: AppColors.textPrimary,
        surfaceContainerLowest: AppColors.background,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainerLow,
        surfaceContainerHigh: AppColors.surfaceContainerHighest,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        outlineVariant: AppColors.borderSecondary,
      );
    }
    return ColorScheme.fromSeed(
      // 品牌回退只允许读取 brandPrimary 系列令牌（docs/48 §7.5）；
      // 组件强调色一律走下方 scheme 角色，不直接引用静态品牌蓝。
      seedColor: AppColors.brandPrimary,
      primary: AppColors.brandPrimary,
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
      primaryContainer: AppColors.brandPrimaryLight,
      // 历史兼容：当前 SDK 的 fromSeed 会为覆盖后的 primary 派生深蓝
      // onPrimary（#152E60），而既有按钮/FAB 前景一直是纯白（textLight）。
      // 回退路径必须显式固定，否则组件前景迁移到 scheme.onPrimary 后
      // 无声改变现状外观（阶段二硬性要求：回退逐位一致）。
      onPrimary: AppColors.textLight,
    );
  }

  /// 构建深色 ColorScheme。
  ///
  /// [systemAccentColor] 语义与浅色一致：null 走品牌回退（primaryContainer
  /// 固定为 #0D2040），非 null 走 fidelity 派生。深色主题本阶段只做令牌
  /// 同步，不改变既有暗色层级，避免浅色改造连带破坏深色模式的可读对比。
  static ColorScheme _buildDarkColorScheme(
    AppColorPalette palette, {
    SystemAccentColor? systemAccentColor,
  }) {
    if (systemAccentColor != null) {
      return _fromSystemSeed(systemAccentColor, Brightness.dark).copyWith(
        surface: palette.surface,
        error: AppColors.error,
        onSurface: palette.textPrimary,
        surfaceContainerLowest: palette.background,
        surfaceContainerLow: palette.surfaceContainerLow,
        surfaceContainer: palette.surfaceContainerLow,
        surfaceContainerHigh: palette.surfaceContainerHighest,
        surfaceContainerHighest: palette.surfaceContainerHighest,
        outlineVariant: palette.borderSecondary,
      );
    }
    return ColorScheme.fromSeed(
      // 与浅色回退同构：品牌回退只读取 brandPrimary 系列令牌（docs/48 §7.5）。
      seedColor: AppColors.brandPrimary,
      primary: AppColors.brandPrimary,
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
      // 深色品牌回退容器色即深色调色板历史上的主色浅色变体取值 #0D2040。
      primaryContainer: AppColors.brandPrimaryContainerDark,
      // 历史兼容：与浅色回退同因，深色既有按钮/FAB 前景为纯白，
      // 显式固定 onPrimary 避免迁移到 scheme 角色后改变现状外观。
      onPrimary: AppColors.textLight,
    );
  }

  /// 浅色主题
  static ThemeData get lightTheme => buildLightTheme();

  /// [appLocale] 决定 CJK 字形变体首选的地区字库；传 null 保持简体形态。
  ///
  /// [systemAccentColor] 为 XDG 系统强调色种子；null（默认）走品牌蓝回退，
  /// 关键令牌与既有外观逐位一致（docs/48 §7.5）。
  static ThemeData buildLightTheme({
    AppFontWeightAdjustment fontWeightAdjustment =
        AppFontWeightAdjustment.normal,
    bool systemBoldText = false,
    Locale? appLocale,
    SystemAccentColor? systemAccentColor,
  }) {
    final typography = _withLinuxTypographyFallbacks(
      AppTextStyles.resolveTypography(
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      cjkGlyphVariantOf(appLocale),
    );

    // 先构建 ColorScheme 再组装组件主题：组件主题统一引用 scheme 的
    // primary/onPrimary/primaryContainer 角色，系统强调色变化才能让按钮、
    // Tab、进度、焦点等组件一起换色，而不是残留静态品牌蓝（docs/48 §7.5）。
    final scheme = _buildLightColorScheme(systemAccentColor: systemAccentColor);

    return ThemeData(
      useMaterial3: true,
      // 全局禁用页面路由转场动画
      pageTransitionsTheme: _noTransitionTheme,
      colorScheme: scheme,
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
          // 强调色随系统种子流动；前景取 scheme.onPrimary 而非固定白色，
          // 亮黄等高明度系统色下算法会派生深色前景保证对比度（docs/48 §11）。
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
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
          foregroundColor: scheme.primary,
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
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
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
        labelColor: scheme.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: typography.body.copyWith(
          fontWeight: typography.resolveFontWeight(FontWeight.w500),
        ),
        unselectedLabelStyle: typography.body,
        indicator: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: AppRadius.lgRadius,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: scheme.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // 导航栏主题
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return typography.caption.copyWith(
              color: scheme.primary,
              fontWeight: typography.resolveFontWeight(FontWeight.w500),
            );
          }
          return typography.caption.copyWith(color: AppColors.textSecondary);
        }),
      ),

      // 导航抽屉主题
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: scheme.primaryContainer,
        tileHeight: 48,
      ),

      // 悬浮按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
      ),

      // Chip 主题
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
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
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: AppColors.cardBackground,
        circularTrackColor: AppColors.cardBackground,
      ),
    );
  }

  /// 深色主题
  static ThemeData get darkTheme => buildDarkTheme();

  /// [appLocale] 决定 CJK 字形变体首选的地区字库；传 null 保持简体形态。
  ///
  /// [systemAccentColor] 语义与浅色构建一致：null（默认）走品牌蓝回退，
  /// 非 null 走 fidelity 派生（docs/48 §7.5）。
  static ThemeData buildDarkTheme({
    AppFontWeightAdjustment fontWeightAdjustment =
        AppFontWeightAdjustment.normal,
    bool systemBoldText = false,
    Locale? appLocale,
    SystemAccentColor? systemAccentColor,
  }) {
    const palette = AppColorPalette.dark;
    final typography = _withLinuxTypographyFallbacks(
      AppTextStyles.resolveTypography(
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      cjkGlyphVariantOf(appLocale),
    );

    // 与浅色构建同构：组件主题统一引用 scheme 强调角色，随系统种子流动。
    final scheme = _buildDarkColorScheme(
      palette,
      systemAccentColor: systemAccentColor,
    );

    return ThemeData(
      useMaterial3: true,
      // 全局禁用页面路由转场动画
      pageTransitionsTheme: _noTransitionTheme,
      colorScheme: scheme,
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
          // 强调色随系统种子流动；前景取 scheme.onPrimary 保证配对对比度。
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
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
          foregroundColor: scheme.primary,
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
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
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
        labelColor: scheme.primary,
        unselectedLabelColor: palette.textSecondary,
        labelStyle: typography.body.copyWith(
          fontWeight: typography.resolveFontWeight(FontWeight.w500),
        ),
        unselectedLabelStyle: typography.body,
        indicator: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: AppRadius.lgRadius,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.background,
        selectedItemColor: scheme.primary,
        unselectedItemColor: palette.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.background,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return typography.caption.copyWith(
              color: scheme.primary,
              fontWeight: typography.resolveFontWeight(FontWeight.w500),
            );
          }
          return typography.caption.copyWith(color: palette.textSecondary);
        }),
      ),

      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: palette.background,
        indicatorColor: scheme.primaryContainer,
        tileHeight: 48,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: palette.cardBackground,
        selectedColor: scheme.primaryContainer,
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
        color: scheme.primary,
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
