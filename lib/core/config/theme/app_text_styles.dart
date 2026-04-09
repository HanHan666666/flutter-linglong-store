import 'package:flutter/material.dart';
import 'app_colors.dart';

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
