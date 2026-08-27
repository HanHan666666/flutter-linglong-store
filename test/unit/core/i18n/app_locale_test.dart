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

    test('俄罗斯区域 Locale 归一为俄语资源', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: null,
          platformLocales: const [Locale('ru', 'RU')],
        ),
        const Locale('ru'),
      );
      final l10n = appLocalizationsForLocale('ru_RU');
      expect(l10n.languageSelfName, 'Русский');
      expect(l10n.updateBatchAllSucceededTitle(1), 'Обновлено 1 приложение');
      expect(l10n.updateBatchAllSucceededTitle(5), 'Обновлено 5 приложений');
    });

    test('阿拉伯区域 Locale 归一为阿拉伯语资源', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: null,
          platformLocales: const [Locale('ar', 'SA')],
        ),
        const Locale('ar'),
      );
      final l10n = appLocalizationsForLocale('ar_SA');
      expect(l10n.languageSelfName, 'العربية');
      // 阿拉伯语复数六类：0→zero、1→one、2→two、3-10→few、11-99→many
      expect(l10n.updateBatchAllSucceededTitle(0), 'لم يتم تحديث أي تطبيق');
      expect(l10n.updateBatchAllSucceededTitle(1), 'تم تحديث تطبيق واحد');
      expect(l10n.updateBatchAllSucceededTitle(2), 'تم تحديث تطبيقين');
      // 数字用 LRI/PDI 隔离，避免与相邻阿拉伯语和标点发生双向重排。
      expect(
        l10n.updateBatchAllSucceededTitle(5),
        'تم تحديث \u20665\u2069 تطبيقات',
      );
      expect(
        l10n.updateBatchAllSucceededTitle(20),
        'تم تحديث \u206620\u2069 تطبيقًا',
      );
    });

    test('日语区域 Locale 归一为日语资源', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: null,
          platformLocales: const [Locale('ja', 'JP')],
        ),
        const Locale('ja'),
      );
      final l10n = appLocalizationsForLocale('ja_JP');
      expect(l10n.languageSelfName, '日本語');
      // 日语无名词复数屈折，计数消息使用直接插值即可。
      expect(l10n.updateBatchAllSucceededTitle(1), '1 件のアプリを更新しました');
      expect(l10n.updateBatchAllSucceededTitle(5), '5 件のアプリを更新しました');
    });

    test('韩语区域 Locale 归一为韩语资源', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: null,
          platformLocales: const [Locale('ko', 'KR')],
        ),
        const Locale('ko'),
      );
      final l10n = appLocalizationsForLocale('ko_KR');
      expect(l10n.languageSelfName, '한국어');
      // 韩语无名词复数屈折，计数消息使用直接插值即可。
      expect(l10n.updateBatchAllSucceededTitle(1), '1개 앱이 업데이트되었습니다');
      expect(l10n.updateBatchAllSucceededTitle(5), '5개 앱이 업데이트되었습니다');
    });

    test('德语区域 Locale 归一为德语资源并使用 one/other 复数', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: null,
          platformLocales: const [Locale('de', 'DE')],
        ),
        const Locale('de'),
      );
      final l10n = appLocalizationsForLocale('de_DE');
      expect(l10n.languageSelfName, 'Deutsch');
      // 德语名词计数语境使用 one/other 两类复数。
      expect(l10n.updateBatchAllSucceededTitle(1), '1 Anwendung aktualisiert');
      expect(l10n.updateBatchAllSucceededTitle(5), '5 Anwendungen aktualisiert');
      expect(l10n.searchResultCount(1), '1 Ergebnis gefunden');
      expect(l10n.searchResultCount(3), '3 Ergebnisse gefunden');
    });

    test('没有受支持语言时回退产品默认语言', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: null,
          // fr 与 de 已是正式发布语言，这里必须使用始终不支持的语言，
          // 才能验证“无受支持语言时回退产品默认语言”的兜底分支。
          platformLocales: const [Locale('it'), Locale('nl')],
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
