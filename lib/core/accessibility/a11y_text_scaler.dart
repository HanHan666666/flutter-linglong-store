import 'package:flutter/material.dart';

import '../config/theme/app_typography.dart';

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
  return composeTextScaler(
    MediaQuery.textScalerOf(context),
    minScaleFactor: min,
    maxScaleFactor: max,
  );
}

/// 组合系统字号与用户手动字号倍率。
TextScaler composeAppTextScaler(
  BuildContext context, {
  double userScaleFactor = kDefaultUserFontScaleFactor,
  double minScaleFactor = kMinEffectiveTextScaleFactor,
  double maxScaleFactor = kMaxEffectiveTextScaleFactor,
}) {
  return composeTextScaler(
    MediaQuery.textScalerOf(context),
    userScaleFactor: userScaleFactor,
    minScaleFactor: minScaleFactor,
    maxScaleFactor: maxScaleFactor,
  );
}

/// 将系统字号与用户字号倍率组合后再做安全钳制。
TextScaler composeTextScaler(
  TextScaler systemScaler, {
  double userScaleFactor = kDefaultUserFontScaleFactor,
  double minScaleFactor = kMinEffectiveTextScaleFactor,
  double maxScaleFactor = kMaxEffectiveTextScaleFactor,
}) {
  final clampedUserScaleFactor = userScaleFactor.clamp(
    kMinUserFontScaleFactor,
    kMaxUserFontScaleFactor,
  );
  return _CompositeTextScaler(
    systemScaler: systemScaler,
    userScaleFactor: clampedUserScaleFactor,
  ).clamp(
    minScaleFactor: minScaleFactor,
    maxScaleFactor: maxScaleFactor,
  );
}

class _CompositeTextScaler extends TextScaler {
  const _CompositeTextScaler({
    required this.systemScaler,
    required this.userScaleFactor,
  });

  final TextScaler systemScaler;
  final double userScaleFactor;

  @override
  double scale(double fontSize) {
    return systemScaler.scale(fontSize) * userScaleFactor;
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => systemScaler.textScaleFactor * userScaleFactor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _CompositeTextScaler &&
        other.systemScaler == systemScaler &&
        other.userScaleFactor == userScaleFactor;
  }

  @override
  int get hashCode => Object.hash(systemScaler, userScaleFactor);
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
