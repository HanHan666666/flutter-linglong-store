/// 应用语言解析与展示入口。
///
/// 该文件把持久化值、系统 Locale、设置页语言选项和无 BuildContext 场景统一到
/// `gen-l10n` 生成的支持列表，避免新增语言时在多个业务模块重复维护白名单。
library;

import 'dart:ui';

import 'l10n/app_localizations.dart';

/// 未命中用户选择或系统语言时使用的产品默认语言。
const Locale defaultAppLocale = Locale('zh');

/// 尝试把 Locale 或字符串解析为生成器声明的受支持语言。
///
/// 输入允许使用 `ru`、`ru_RU`、`ru-RU` 等形式，但当前产品只按 language code
/// 选择资源；未知值返回 `null`，由调用方决定采用系统语言还是产品默认语言。
Locale? tryResolveSupportedAppLocale(Object? localeOrString) {
  final rawLanguageCode = switch (localeOrString) {
    final Locale locale => locale.languageCode,
    final String value => value.trim().replaceAll('-', '_').split('_').first,
    _ => null,
  };
  final languageCode = rawLanguageCode?.trim().toLowerCase();
  if (languageCode == null || languageCode.isEmpty) {
    return null;
  }

  for (final supportedLocale in AppLocalizations.supportedLocales) {
    if (supportedLocale.languageCode.toLowerCase() == languageCode) {
      return supportedLocale;
    }
  }
  return null;
}

/// 把任意 Locale 输入归一到受支持语言，未知值回退产品默认语言。
Locale resolveSupportedAppLocale(Object? localeOrString) {
  return tryResolveSupportedAppLocale(localeOrString) ?? defaultAppLocale;
}

/// 根据持久化选择和系统首选语言解析应用首次显示语言。
///
/// 合法的用户选择始终优先；没有合法选择时依次匹配系统 Locale，最终回退中文。
/// 该函数只处理纯数据，便于启动 Provider 与原生窗口标题共享相同决策。
Locale resolveInitialAppLocale({
  required String? persistedLanguageCode,
  required Iterable<Locale> platformLocales,
}) {
  final persistedLocale = tryResolveSupportedAppLocale(persistedLanguageCode);
  if (persistedLocale != null) {
    return persistedLocale;
  }

  for (final platformLocale in platformLocales) {
    final supportedLocale = tryResolveSupportedAppLocale(platformLocale);
    if (supportedLocale != null) {
      return supportedLocale;
    }
  }
  return defaultAppLocale;
}

/// 返回设置页使用的语言顺序，产品默认语言置顶，其余语言使用生成顺序。
///
/// 列表仍完全来源于 `AppLocalizations.supportedLocales`；新增 ARB 后无需修改本文件。
List<Locale> get selectableAppLocales {
  return <Locale>[
    defaultAppLocale,
    for (final locale in AppLocalizations.supportedLocales)
      if (locale.languageCode != defaultAppLocale.languageCode) locale,
  ];
}

/// 在无 BuildContext 场景加载指定语言资源。
AppLocalizations appLocalizationsForLocale(Object? localeOrString) {
  return lookupAppLocalizations(resolveSupportedAppLocale(localeOrString));
}

/// 获取语言在选择器中展示的本族语名称。
String appLanguageSelfName(Locale locale) {
  return appLocalizationsForLocale(locale).languageSelfName;
}
