/// 阿拉伯语动态占位符的双向文本隔离测试。
///
/// 阿拉伯语句子会混入版本、URL、路径、错误和数字等 LTR/未知方向内容；本测试
/// 同时验证代表性生成结果与 ARB 全量约束，避免标点或相邻字段跨占位符重排。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';

/// Left-to-Right Isolate，用于数字等已知 LTR 片段。
const String _lri = '\u2066';

/// First Strong Isolate，用于名称、路径等方向未知的动态片段。
const String _fsi = '\u2068';

/// Pop Directional Isolate，结束当前隔离片段。
const String _pdi = '\u2069';

void main() {
  group('Arabic BiDi placeholders', () {
    test('版本、URL 与路径使用未知方向隔离', () {
      final l10n = lookupAppLocalizations(const Locale('ar'));

      expect(l10n.currentVersion('1.2.3'), 'الإصدار الحالي: \u20681.2.3\u2069');
      expect(
        l10n.cannotOpenLink('https://example.com?a=1'),
        'تعذّر فتح الرابط: \u2068https://example.com?a=1\u2069',
      );
      expect(
        l10n.cannotOpenDirectory('/tmp/Linglong Store'),
        'تعذّر فتح الدليل: \u2068/tmp/Linglong Store\u2069',
      );
    });

    test('数字占位符使用 LTR 隔离且保留百分号', () {
      final l10n = lookupAppLocalizations(const Locale('ar'));

      expect(l10n.fontScalePercent(125), '\u2066125%\u2069');
      expect(
        l10n.a11yRankingItem('12', 'تطبيق'),
        'المرتبة \u206612\u2069، \u2068تطبيق\u2069',
      );
    });

    test('ARB 中每个直接插值占位符都位于 isolate 内', () {
      final catalog =
          jsonDecode(File('lib/core/i18n/l10n/app_ar.arb').readAsStringSync())
              as Map<String, dynamic>;
      final directPlaceholder = RegExp(r'\{[A-Za-z][A-Za-z0-9_]*\}');

      for (final entry in catalog.entries) {
        if (entry.key.startsWith('@') || entry.value is! String) continue;
        final message = entry.value! as String;
        final isolateStartCount = RegExp(
          '[$_lri$_fsi]',
        ).allMatches(message).length;
        final isolateEndCount = RegExp(_pdi).allMatches(message).length;
        expect(
          isolateStartCount,
          isolateEndCount,
          reason: '${entry.key} 的 BiDi isolate 未成对闭合',
        );

        for (final match in directPlaceholder.allMatches(message)) {
          final prefix = message.substring(0, match.start);
          final lastIsolateStart = [
            prefix.lastIndexOf(_lri),
            prefix.lastIndexOf(_fsi),
          ].reduce((left, right) => left > right ? left : right);
          final lastIsolateEnd = prefix.lastIndexOf(_pdi);
          final nextIsolateEnd = message.indexOf(_pdi, match.end);

          expect(
            lastIsolateStart,
            greaterThan(lastIsolateEnd),
            reason: '${entry.key} 的 ${match.group(0)} 缺少起始 isolate',
          );
          expect(
            nextIsolateEnd,
            isNonNegative,
            reason: '${entry.key} 的 ${match.group(0)} 缺少结束 isolate',
          );
        }
      }
    });
  });
}
