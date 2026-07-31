/// 应用 Locale 解析规则测试。
///
/// 这里只覆盖持久化值、系统语言和回退顺序，避免将平台环境差异带入 Provider 测试。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/app_locale.dart';

void main() {
  group('app locale resolution', () {
    test('合法持久化语言优先于系统语言', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: 'es_ES',
          platformLocales: const [Locale('en', 'US')],
        ),
        const Locale('es'),
      );
    });

    test('没有合法持久化语言时使用第一个受支持系统语言', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: 'unsupported',
          platformLocales: const [Locale('fr'), Locale('en', 'GB')],
        ),
        const Locale('en'),
      );
    });

    test('没有受支持语言时回退产品默认语言', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: null,
          platformLocales: const [Locale('fr'), Locale('de')],
        ),
        defaultAppLocale,
      );
    });

    test('语言选择顺序只把产品默认语言置顶且不产生重复项', () {
      expect(selectableAppLocales.first, defaultAppLocale);
      expect(
        selectableAppLocales.map((locale) => locale.languageCode).toSet(),
        hasLength(selectableAppLocales.length),
      );
    });
  });
}
