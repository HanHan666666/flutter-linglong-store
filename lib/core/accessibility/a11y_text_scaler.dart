import 'package:flutter/material.dart';

/// 约束 TextScaler 范围
///
/// 防止系统字体缩放过大导致布局破裂。
/// - 最小缩放：0.8x
/// - 最大缩放：1.5x
///
/// 用法：
/// ```dart
/// final scaler = clampTextScaler(context);
/// Text('文本', textScaler: scaler)
/// ```
TextScaler clampTextScaler(
  BuildContext context, {
  double min = 0.8,
  double max = 1.5,
}) {
  final systemScaler = MediaQuery.textScalerOf(context);
  return systemScaler.clamp(
    minScaleFactor: min,
    maxScaleFactor: max,
  );
}

/// 无障碍文本 Widget
///
/// 自动应用系统字体缩放，并限制在安全范围内。
/// 用法：
/// ```dart
/// A11yText(
///   '应用介绍',
///   style: AppTextStyles.body,
/// )
/// ```
class A11yText extends StatelessWidget {
  const A11yText(
    this.data, {
    super.key,
    this.style,
    this.minScale = 0.8,
    this.maxScale = 1.5,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  final String data;
  final TextStyle? style;
  final double minScale;
  final double maxScale;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: minScale,
      maxScaleFactor: maxScale,
    );

    return Text(
      data,
      style: style,
      textScaler: scaler,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
