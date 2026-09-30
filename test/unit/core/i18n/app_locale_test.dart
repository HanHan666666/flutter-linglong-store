/// 应用 Locale 解析规则测试。
///
/// 这里只覆盖持久化值、系统语言和回退顺序，避免将平台环境差异带入 Provider 测试。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/app_locale.dart';

/// 验证语言优先级和国际环境回退契约，不依赖测试机器的真实系统语言。
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
          // fr 已是正式发布语言；用始终不支持的 it 验证“跳过不支持语言、
          // 命中第一个受支持系统语言”的顺序逻辑。
          platformLocales: const [Locale('it'), Locale('en', 'GB')],
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

    test('法语区域 Locale 归一为法语资源并使用 one/many/other 复数', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: null,
          platformLocales: const [Locale('fr', 'FR')],
        ),
        const Locale('fr'),
      );
      final l10n = appLocalizationsForLocale('fr_FR');
      expect(l10n.languageSelfName, 'Français');
      // 法语按 CLDR 规则使用三类：one（含 0 与 1）、many（百万级）、other。
      expect(l10n.updateBatchAllSucceededTitle(1), '1 application mise à jour');
      expect(
        l10n.updateBatchAllSucceededTitle(5),
        '5 applications mises à jour',
      );
      expect(
        l10n.updateBatchAllSucceededTitle(1000000),
        '1000000 d\'applications mises à jour',
      );
    });

    // 英文兜底只用于无法命中的输入，避免覆盖中文系统的首次启动语言。
    test('中文系统首次启动仍使用对应的简体或繁体资源', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: null,
          platformLocales: const [Locale('zh', 'CN')],
        ),
        const Locale('zh'),
      );
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: null,
          platformLocales: const [Locale('zh', 'TW')],
        ),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      );
    });

    // AppImageHub 在 C locale 下启动应用；这里直接模拟 Flutter 提供的
    // Locale 数据，独立验证决策规则，实际 LANG 解析由发布包验收覆盖。
    test('C 和 POSIX 系统语言首次启动回退英文', () {
      for (final platformLocale in const [Locale('C'), Locale('POSIX')]) {
        expect(
          resolveInitialAppLocale(
            persistedLanguageCode: null,
            platformLocales: [platformLocale],
          ),
          const Locale('en'),
          reason: '$platformLocale 没有对应的发布资源，应使用英文',
        );
      }
    });

    test('系统没有提供语言且用户未设置语言时回退英文', () {
      for (final persistedLanguageCode in [null, '', '   ']) {
        expect(
          resolveInitialAppLocale(
            persistedLanguageCode: persistedLanguageCode,
            platformLocales: const [],
          ),
          const Locale('en'),
        );
      }
    });

    test('没有受支持系统语言时回退英文', () {
      expect(
        resolveInitialAppLocale(
          persistedLanguageCode: null,
          // fr 与 de 已是正式发布语言，这里必须使用始终不支持的语言，
          // 才能验证国际用户没有匹配资源时的英文兜底。
          platformLocales: const [Locale('it'), Locale('nl')],
        ),
        const Locale('en'),
      );
    });

    test('无上下文的窗口标题和通知也对未知或空语言使用英文资源', () {
      for (final input in [null, '', '   ', 'C', 'C.UTF-8', 'POSIX', 'it']) {
        expect(resolveSupportedAppLocale(input), const Locale('en'));
        expect(appLocalizationsForLocale(input).languageSelfName, 'English');
      }
    });

    // 菜单展示顺序是独立的 UI 约定，不能随运行时兜底语言变更而重排。
    test('语言选择顺序仍把中文置顶且不产生重复项', () {
      expect(selectableAppLocales.first, const Locale('zh'));
      // 必须用完整语言标签判重：zh 与 zh-Hant 共享 languageCode，
      // 按 languageCode 判重会把繁体误当重复项剔除。
      expect(
        selectableAppLocales.map((locale) => locale.toLanguageTag()).toSet(),
        hasLength(selectableAppLocales.length),
      );
    });

    group('zh 与 zh-Hant 并存时的文字消歧', () {
      test('持久化的完整标签 zh-Hant 命中繁体资源', () {
        expect(
          tryResolveSupportedAppLocale('zh-Hant'),
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        );
        expect(
          appLocalizationsForLocale('zh-Hant').languageSelfName,
          '繁體中文',
        );
      });

      test('台/港/澳系统语言按 CLDR 惯例归繁体', () {
        for (final region in const ['TW', 'HK', 'MO']) {
          expect(
            tryResolveSupportedAppLocale(Locale('zh', region)),
            const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
            reason: 'zh_$region 应归繁体',
          );
        }
      });

      test('大陆/新加坡与裸 zh 保持简体基础资源', () {
        expect(tryResolveSupportedAppLocale('zh'), const Locale('zh'));
        expect(
          tryResolveSupportedAppLocale(const Locale('zh', 'CN')),
          const Locale('zh'),
        );
        expect(
          tryResolveSupportedAppLocale(const Locale('zh', 'SG')),
          const Locale('zh'),
        );
      });

      test('未受支持的纯语言输入返回 null 而非首个候选', () {
        expect(tryResolveSupportedAppLocale('xx'), isNull);
        expect(tryResolveSupportedAppLocale(''), isNull);
        expect(tryResolveSupportedAppLocale(null), isNull);
      });
    });
  });
}
