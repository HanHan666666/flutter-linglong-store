import 'package:flutter/material.dart';

/// 应用动画配置
class AppAnimation {
  AppAnimation._();

  /// 快速动画时长 - 瞬切（全局零动画模式）
  /// 用于: 侧边栏宽度切换、菜单项 hover 背景、分类栏折叠
  static const Duration fast = Duration.zero;

  /// 标准动画时长 - 瞬切（全局零动画模式）
  /// 用于: 卡片透明度过渡
  static const Duration normal = Duration.zero;

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
