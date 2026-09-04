import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/domain/models/system_accent_color.dart';

/// AppTheme 系统强调色种子测试（docs/48 §7.5/§11/§12.2）。
///
/// 只保留能防真回归的三类用例：
/// 1. 品牌回退路径关键令牌逐位锁定——portal 不可用的环境必须与现状像素级
///    一致（这是 Golden 基线与「无 portal 回退」验收的回归防线），同时锁定
///    静态主色迁移到 ColorScheme 角色后的接线（按钮前景、Tab indicator）；
/// 2. 同一系统种子派生浅/深两套 ColorScheme 的正确性：primary 携带种子
///    色相（防系统种子被静默忽略走错回退路径）、亮度正确、容器色随明暗
///    分化、中性表面与 error 保持项目令牌不被种子重染；
/// 3. 极端种子（亮黄/近白/近黑）的角色配对对比度 ≥ WCAG 4.5:1——验证
///    「fidelity 派生 + 不强制覆盖 primary」这一集成决策真能兜住不可信的
///    外部桌面颜色（docs/48 §11）。
void main() {
  group('品牌回退路径关键令牌锁定（systemAccentColor == null）', () {
    test('浅色与深色 primary 均为品牌蓝 #016FFD', () {
      expect(AppTheme.buildLightTheme().colorScheme.primary, AppColors.primary);
      expect(AppTheme.buildDarkTheme().colorScheme.primary, AppColors.primary);
    });

    test('primaryContainer 回退到品牌容器色（浅 #E6F0FF / 深 #0D2040）', () {
      expect(
        AppTheme.buildLightTheme().colorScheme.primaryContainer,
        AppColors.primaryLight,
      );
      expect(
        AppTheme.buildDarkTheme().colorScheme.primaryContainer,
        AppColorPalette.dark.primaryLight,
      );
    });

    test('回退 onPrimary 为纯白 #FFFFFF（按钮/FAB 前景与现状逐位一致）', () {
      // 组件前景已从固定白色 textLight 迁移到 scheme.onPrimary；SDK 的
      // fromSeed 会为覆盖后的品牌 primary 派生深蓝 onPrimary，回退路径
      // 必须显式固定纯白，否则现有按钮文字色被无声改变。
      expect(
        AppTheme.buildLightTheme().colorScheme.onPrimary,
        const Color(0xFFFFFFFF),
      );
      expect(
        AppTheme.buildDarkTheme().colorScheme.onPrimary,
        const Color(0xFFFFFFFF),
      );
    });

    test('elevatedButton 背景取 scheme.primary、前景为纯白', () {
      // 验证静态 AppColors.primary/textLight 迁移到 ColorScheme 角色后的
      // 组件级接线：回退时解析值必须与迁移前完全一致。
      for (final theme in [AppTheme.buildLightTheme(), AppTheme.buildDarkTheme()]) {
        final style = theme.elevatedButtonTheme.style!;
        expect(style.backgroundColor?.resolve({}), theme.colorScheme.primary);
        expect(style.backgroundColor?.resolve({}), AppColors.primary);
        expect(style.foregroundColor?.resolve({}), const Color(0xFFFFFFFF));
      }
    });

    test('tabBar indicator 取各自 scheme.primaryContainer 角色', () {
      // indicator 从静态 primaryLight 迁移到 primaryContainer 角色；断言
      // 「等于各自 scheme 的角色值」验证的是角色流动接线，具体回退数值
      // （#E6F0FF/#0D2040）已由上面的容器色锁定用例覆盖。
      final light = AppTheme.buildLightTheme();
      expect(
        (light.tabBarTheme.indicator! as BoxDecoration).color,
        light.colorScheme.primaryContainer,
      );
      final dark = AppTheme.buildDarkTheme();
      expect(
        (dark.tabBarTheme.indicator! as BoxDecoration).color,
        dark.colorScheme.primaryContainer,
      );
    });
  });

  group('同一系统种子派生浅/深主题（橙 0xFFE8590C）', () {
    const orangeSeed = SystemAccentColor(red: 232, green: 89, blue: 12);
    // 种子 sRGB 的 HSV 色相（实测 21.0）；fidelity 派生保留色相，允许
    // 少量量化抖动。近白/近黑种子饱和度过低、色相无意义，仅在橙色组断言。
    const seedHue = 21.0;

    test('浅/深 primary 都携带种子色相（种子被真实使用，而非品牌回退）', () {
      final light = AppTheme.buildLightTheme(systemAccentColor: orangeSeed);
      final dark = AppTheme.buildDarkTheme(systemAccentColor: orangeSeed);

      final lightHue = HSVColor.fromColor(light.colorScheme.primary).hue;
      final darkHue = HSVColor.fromColor(dark.colorScheme.primary).hue;
      // 品牌蓝 hue≈212，与橙色相差悬殊；该断言同时拦截「系统种子被忽略、
      // 静默走了回退路径」的接线回归。
      expect((lightHue - seedHue).abs(), lessThan(8));
      expect((darkHue - seedHue).abs(), lessThan(8));
    });

    test('亮度正确且 primaryContainer 浅深分化', () {
      final light = AppTheme.buildLightTheme(systemAccentColor: orangeSeed);
      final dark = AppTheme.buildDarkTheme(systemAccentColor: orangeSeed);

      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(
        light.colorScheme.primaryContainer,
        isNot(dark.colorScheme.primaryContainer),
      );
    });

    test('中性表面与 error 保持项目令牌，不被种子重染', () {
      final fallback = AppTheme.buildLightTheme();
      final derived = AppTheme.buildLightTheme(systemAccentColor: orangeSeed);

      // 系统强调色只染强调角色；页面底色、卡片表面、错误语义必须与回退
      // 路径共享同一套固定令牌（docs/48 §7.5 令牌语义表）。
      expect(derived.colorScheme.surface, fallback.colorScheme.surface);
      expect(derived.colorScheme.onSurface, fallback.colorScheme.onSurface);
      expect(
        derived.colorScheme.surfaceContainerHighest,
        fallback.colorScheme.surfaceContainerHighest,
      );
      expect(derived.colorScheme.error, AppColors.error);
      expect(
        AppTheme.buildDarkTheme(systemAccentColor: orangeSeed).colorScheme.error,
        AppColors.error,
      );
    });
  });

  group('极端种子对比度（docs/48 §11）', () {
    // 三个代表性极端：高明度高饱和（黄）、无饱和近白、无饱和近黑。
    // 每种 × 浅/深，只断言两组文字承载配对 ≥ WCAG AA 4.5:1。
    const extremeSeeds = <String, SystemAccentColor>{
      '亮黄 0xFFFFEB00': SystemAccentColor(red: 255, green: 235, blue: 0),
      '近白 0xFFF2F2F2': SystemAccentColor(red: 242, green: 242, blue: 242),
      '近黑 0xFF111111': SystemAccentColor(red: 17, green: 17, blue: 17),
    };

    for (final entry in extremeSeeds.entries) {
      for (final brightness in Brightness.values) {
        test('${entry.key} 在 $brightness 下 primary/primaryContainer 配对 ≥ 4.5:1', () {
          final scheme = switch (brightness) {
            Brightness.light => AppTheme.buildLightTheme(
                systemAccentColor: entry.value,
              ).colorScheme,
            Brightness.dark => AppTheme.buildDarkTheme(
                systemAccentColor: entry.value,
              ).colorScheme,
          };
          final primaryPair = _contrastRatio(scheme.primary, scheme.onPrimary);
          final containerPair = _contrastRatio(
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
          );
          // 实测基线（SDK fromSeed/fidelity 确定性输出）：最低为近白深色
          // 容器配对 4.53:1。若未来 SDK 升级导致低于门槛，应在这里失败并
          // 重新评审前景策略，而不是放松断言。
          expect(
            primaryPair,
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}（$brightness）primary/onPrimary '
                '对比度 ${primaryPair.toStringAsFixed(2)}:1 低于 4.5:1',
          );
          expect(
            containerPair,
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}（$brightness）primaryContainer/'
                'onPrimaryContainer 对比度 ${containerPair.toStringAsFixed(2)}:1 '
                '低于 4.5:1',
          );
        });
      }
    }
  });
}

/// WCAG 对比度：基于 Color.computeLuminance 的相对亮度手算比值，不引第三方包。
double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
