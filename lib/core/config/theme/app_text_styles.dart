import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

@immutable
class AppTypographyStyles extends ThemeExtension<AppTypographyStyles> {
  const AppTypographyStyles({
    required this.display,
    required this.title1,
    required this.title2,
    required this.title3,
    required this.body,
    required this.bodyMedium,
    required this.caption,
    required this.tiny,
    required this.menuActive,
    required this.textTheme,
    required this.fontWeightAdjustment,
    required this.systemBoldText,
  });

  final TextStyle display;
  final TextStyle title1;
  final TextStyle title2;
  final TextStyle title3;
  final TextStyle body;
  final TextStyle bodyMedium;
  final TextStyle caption;
  final TextStyle tiny;
  final TextStyle menuActive;
  final TextTheme textTheme;
  final AppFontWeightAdjustment fontWeightAdjustment;
  final bool systemBoldText;

  FontWeight resolveFontWeight(FontWeight baseWeight) {
    return resolveAppFontWeight(
      baseWeight,
      adjustment: fontWeightAdjustment,
      systemBoldText: systemBoldText,
    );
  }

  AppTypographyStyles withFontFamilyFallback(List<String> fontFamilyFallback) {
    TextStyle applyFallback(TextStyle style) {
      return style.copyWith(fontFamilyFallback: fontFamilyFallback);
    }

    TextTheme applyThemeFallback(TextTheme theme) {
      return theme.copyWith(
        displayLarge: theme.displayLarge == null
            ? null
            : applyFallback(theme.displayLarge!),
        headlineLarge: theme.headlineLarge == null
            ? null
            : applyFallback(theme.headlineLarge!),
        headlineMedium: theme.headlineMedium == null
            ? null
            : applyFallback(theme.headlineMedium!),
        headlineSmall: theme.headlineSmall == null
            ? null
            : applyFallback(theme.headlineSmall!),
        titleLarge: theme.titleLarge == null
            ? null
            : applyFallback(theme.titleLarge!),
        titleMedium: theme.titleMedium == null
            ? null
            : applyFallback(theme.titleMedium!),
        titleSmall: theme.titleSmall == null
            ? null
            : applyFallback(theme.titleSmall!),
        bodyLarge: theme.bodyLarge == null ? null : applyFallback(theme.bodyLarge!),
        bodyMedium: theme.bodyMedium == null
            ? null
            : applyFallback(theme.bodyMedium!),
        bodySmall: theme.bodySmall == null ? null : applyFallback(theme.bodySmall!),
        labelLarge: theme.labelLarge == null
            ? null
            : applyFallback(theme.labelLarge!),
        labelMedium: theme.labelMedium == null
            ? null
            : applyFallback(theme.labelMedium!),
        labelSmall: theme.labelSmall == null
            ? null
            : applyFallback(theme.labelSmall!),
      );
    }

    return copyWith(
      display: applyFallback(display),
      title1: applyFallback(title1),
      title2: applyFallback(title2),
      title3: applyFallback(title3),
      body: applyFallback(body),
      bodyMedium: applyFallback(bodyMedium),
      caption: applyFallback(caption),
      tiny: applyFallback(tiny),
      menuActive: applyFallback(menuActive),
      textTheme: applyThemeFallback(textTheme),
    );
  }

  @override
  AppTypographyStyles copyWith({
    TextStyle? display,
    TextStyle? title1,
    TextStyle? title2,
    TextStyle? title3,
    TextStyle? body,
    TextStyle? bodyMedium,
    TextStyle? caption,
    TextStyle? tiny,
    TextStyle? menuActive,
    TextTheme? textTheme,
    AppFontWeightAdjustment? fontWeightAdjustment,
    bool? systemBoldText,
  }) {
    return AppTypographyStyles(
      display: display ?? this.display,
      title1: title1 ?? this.title1,
      title2: title2 ?? this.title2,
      title3: title3 ?? this.title3,
      body: body ?? this.body,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      caption: caption ?? this.caption,
      tiny: tiny ?? this.tiny,
      menuActive: menuActive ?? this.menuActive,
      textTheme: textTheme ?? this.textTheme,
      fontWeightAdjustment:
          fontWeightAdjustment ?? this.fontWeightAdjustment,
      systemBoldText: systemBoldText ?? this.systemBoldText,
    );
  }

  @override
  AppTypographyStyles lerp(
    covariant ThemeExtension<AppTypographyStyles>? other,
    double t,
  ) {
    if (other is! AppTypographyStyles) {
      return this;
    }

    return AppTypographyStyles(
      display: TextStyle.lerp(display, other.display, t) ?? display,
      title1: TextStyle.lerp(title1, other.title1, t) ?? title1,
      title2: TextStyle.lerp(title2, other.title2, t) ?? title2,
      title3: TextStyle.lerp(title3, other.title3, t) ?? title3,
      body: TextStyle.lerp(body, other.body, t) ?? body,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t) ?? bodyMedium,
      caption: TextStyle.lerp(caption, other.caption, t) ?? caption,
      tiny: TextStyle.lerp(tiny, other.tiny, t) ?? tiny,
      menuActive: TextStyle.lerp(menuActive, other.menuActive, t) ?? menuActive,
      textTheme: TextTheme.lerp(textTheme, other.textTheme, t),
      fontWeightAdjustment: t < 0.5
          ? fontWeightAdjustment
          : other.fontWeightAdjustment,
      systemBoldText: t < 0.5 ? systemBoldText : other.systemBoldText,
    );
  }
}

/// 应用文字样式
///
/// 基于设计规范中的字体层级系统
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle _displayBase = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle _title1Base = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle _title2Base = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle _title3Base = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle _bodyBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle _bodyMediumBase = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle _captionBase = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle _tinyBase = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle _menuActiveBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );

  static final AppTypographyStyles _defaultTypography = resolveTypography();

  static TextStyle _resolveTextStyle(
    TextStyle baseStyle, {
    AppFontWeightAdjustment fontWeightAdjustment =
        AppFontWeightAdjustment.normal,
    bool systemBoldText = false,
  }) {
    final baseWeight = baseStyle.fontWeight ?? FontWeight.w400;
    return baseStyle.copyWith(
      fontWeight: resolveAppFontWeight(
        baseWeight,
        adjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
    );
  }

  static AppTypographyStyles resolveTypography({
    AppFontWeightAdjustment fontWeightAdjustment =
        AppFontWeightAdjustment.normal,
    bool systemBoldText = false,
  }) {
    final display = _resolveTextStyle(
      _displayBase,
      fontWeightAdjustment: fontWeightAdjustment,
      systemBoldText: systemBoldText,
    );
    final title1 = _resolveTextStyle(
      _title1Base,
      fontWeightAdjustment: fontWeightAdjustment,
      systemBoldText: systemBoldText,
    );
    final title2 = _resolveTextStyle(
      _title2Base,
      fontWeightAdjustment: fontWeightAdjustment,
      systemBoldText: systemBoldText,
    );
    final title3 = _resolveTextStyle(
      _title3Base,
      fontWeightAdjustment: fontWeightAdjustment,
      systemBoldText: systemBoldText,
    );
    final body = _resolveTextStyle(
      _bodyBase,
      fontWeightAdjustment: fontWeightAdjustment,
      systemBoldText: systemBoldText,
    );
    final bodyMedium = _resolveTextStyle(
      _bodyMediumBase,
      fontWeightAdjustment: fontWeightAdjustment,
      systemBoldText: systemBoldText,
    );
    final caption = _resolveTextStyle(
      _captionBase,
      fontWeightAdjustment: fontWeightAdjustment,
      systemBoldText: systemBoldText,
    );
    final tiny = _resolveTextStyle(
      _tinyBase,
      fontWeightAdjustment: fontWeightAdjustment,
      systemBoldText: systemBoldText,
    );
    final menuActive = _resolveTextStyle(
      _menuActiveBase,
      fontWeightAdjustment: fontWeightAdjustment,
      systemBoldText: systemBoldText,
    );

    final textTheme = TextTheme(
      displayLarge: _resolveTextStyle(
        const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.4),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      headlineLarge: _resolveTextStyle(
        const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.4),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      headlineMedium: _resolveTextStyle(
        const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.4),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      headlineSmall: _resolveTextStyle(
        const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.4),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      titleLarge: _resolveTextStyle(
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      titleMedium: _resolveTextStyle(
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.5),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      titleSmall: _resolveTextStyle(
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      bodyLarge: _resolveTextStyle(
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      bodyMedium: _resolveTextStyle(
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      bodySmall: _resolveTextStyle(
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      labelLarge: _resolveTextStyle(
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      labelMedium: _resolveTextStyle(
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.5),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
      labelSmall: _resolveTextStyle(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.5),
        fontWeightAdjustment: fontWeightAdjustment,
        systemBoldText: systemBoldText,
      ),
    );

    return AppTypographyStyles(
      display: display,
      title1: title1,
      title2: title2,
      title3: title3,
      body: body,
      bodyMedium: bodyMedium,
      caption: caption,
      tiny: tiny,
      menuActive: menuActive,
      textTheme: textTheme,
      fontWeightAdjustment: fontWeightAdjustment,
      systemBoldText: systemBoldText,
    );
  }

  static AppTypographyStyles of(BuildContext context) {
    return Theme.of(context).extension<AppTypographyStyles>() ??
        _defaultTypography;
  }

  static FontWeight resolveFontWeight(
    BuildContext context,
    FontWeight baseWeight,
  ) {
    return of(context).resolveFontWeight(baseWeight);
  }

  // ==================== Display 层级 ====================

  /// Display - 32px, bold
  /// 用于: 启动页应用名
  static TextStyle get display => _defaultTypography.display;

  // ==================== Title 层级 ====================

  /// Title1 - 28px, bold
  /// 用于: 应用详情主标题、页面 Hero 标题
  static TextStyle get title1 => _defaultTypography.title1;

  /// Title2 - 24px, semi-bold
  /// 用于: 推荐标题、搜索结果标题、大区块标题
  static TextStyle get title2 => _defaultTypography.title2;

  /// Title3 - 20px, medium
  /// 用于: 页面主标题、组件级标题
  static TextStyle get title3 => _defaultTypography.title3;

  // ==================== Body 层级 ====================

  /// Body - 16px, regular
  /// 用于: 主正文、应用介绍、设置页正文（桌面端主阅读体）
  static TextStyle get body => _defaultTypography.body;

  /// Body Medium - 14px, regular
  /// 用于: 常规说明文字、菜单文字、搜索输入、卡片描述
  static TextStyle get bodyMedium => _defaultTypography.bodyMedium;

  // ==================== Caption 层级 ====================

  /// Caption - 13px, regular
  /// 用于: 版本、仓库、辅助元信息、次级说明
  static TextStyle get caption => _defaultTypography.caption;

  // ==================== Tiny 层级 ====================

  /// Tiny - 12px, regular
  /// 用于: 标签、胶囊、角标、"精品/TOP" 极小提示（禁止用于承载主要可读信息）
  static TextStyle get tiny => _defaultTypography.tiny;

  // ==================== 辅助样式 ====================

  /// 菜单激活态文字 - 16px, medium（展开态侧边栏菜单）
  static TextStyle get menuActive => _defaultTypography.menuActive;

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
  static TextTheme get textTheme => _defaultTypography.textTheme;
}

/// BuildContext 扩展 - 获取当前主题下的动态文字样式。
extension AppTypographyContextExtension on BuildContext {
  AppTypographyStyles get appTextStyles => AppTextStyles.of(this);

  FontWeight appFontWeight(FontWeight baseWeight) {
    return AppTextStyles.resolveFontWeight(this, baseWeight);
  }
}
