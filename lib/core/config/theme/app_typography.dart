import 'package:flutter/material.dart';

/// 用户手动字号缩放最小值。
const double kMinUserFontScaleFactor = 0.85;

/// 用户手动字号缩放最大值。
const double kMaxUserFontScaleFactor = 1.30;

/// 用户手动字号缩放默认值。
const double kDefaultUserFontScaleFactor = 1.0;

/// 应用最终字号缩放最小值。
const double kMinEffectiveTextScaleFactor = 0.8;

/// 应用最终字号缩放最大值。
const double kMaxEffectiveTextScaleFactor = 1.5;

/// 系统启用粗体文字时，额外上调一个字重档位。
const int kSystemBoldTextWeightDelta = 100;

/// 用户手动字重微调档位。
enum AppFontWeightAdjustment {
  lighter(-100),
  normal(0),
  bolder(100);

  const AppFontWeightAdjustment(this.delta);

  /// 基于设计 token 的字重偏移值。
  final int delta;
}

/// 将 [FontWeight] 转换为数值权重。
int fontWeightToValue(FontWeight fontWeight) {
  return fontWeight.value;
}

/// 将数值权重转换为最近的 [FontWeight]。
FontWeight fontWeightFromValue(int value) {
  final normalizedValue = value.clamp(100, 900);
  final weightIndex = (normalizedValue ~/ 100) - 1;
  return FontWeight.values[weightIndex.clamp(0, FontWeight.values.length - 1)];
}

/// 解析应用内最终字重。
///
/// 默认尊重系统粗体设置，并在其基础上叠加用户手动调整档位。
FontWeight resolveAppFontWeight(
  FontWeight baseWeight, {
  AppFontWeightAdjustment adjustment = AppFontWeightAdjustment.normal,
  bool systemBoldText = false,
}) {
  final systemDelta = systemBoldText ? kSystemBoldTextWeightDelta : 0;
  final resolvedValue =
      fontWeightToValue(baseWeight) + systemDelta + adjustment.delta;
  return fontWeightFromValue(resolvedValue);
}