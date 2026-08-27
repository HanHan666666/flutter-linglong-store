/// 应用语言解析与展示入口。
///
/// 该文件把持久化值、系统 Locale、设置页语言选项和无 BuildContext 场景统一到
/// `gen-l10n` 生成的支持列表，避免新增语言时在多个业务模块重复维护白名单。
library;

import 'dart:ui';

import 'l10n/app_localizations.dart';

/// 未命中用户选择或系统语言时使用的产品默认语言。
const Locale defaultAppLocale = Locale('zh');

/// 中文地区到默认文字的提示表。
///
/// 该表是 Unicode CLDR likelySubtags 的公共事实，不是第二份语言白名单：
/// 仅当输入只有"语言_地区"而没有 script 子标签时，用于在简体（zh）与
/// 繁体（zh-Hant）两个受支持资源之间消歧。台/港/澳惯用繁体，其余中文
/// 地区保持产品默认的简体资源。
const Map<String, String> _chineseRegionScriptHints = <String, String>{
  'tw': 'Hant',
  'hk': 'Hant',
  'mo': 'Hant',
};

/// 把任意 Locale 或 BCP47 字符串拆解为小写的语言/文字/地区三段。
///
/// 输入兼容 `zh`、`zh_Hant`、`zh-Hant-TW`、`pt_BR` 等写法；非法或空输入
/// 返回空段集合，由调用方决定回退行为。
({String language, String? script, String? region}) _splitLocaleParts(
  Object? localeOrString,
) {
  // Locale 对象直接读取命名字段：countryCode 与 scriptCode 是独立属性，
  // 位置化拆分会把 zh_TW 的地区误认成文字子标签。
  if (localeOrString is Locale) {
    return (
      language: localeOrString.languageCode.trim().toLowerCase(),
      script: localeOrString.scriptCode?.trim().toLowerCase(),
      region: localeOrString.countryCode?.trim().toLowerCase(),
    );
  }
  final raw = switch (localeOrString) {
    final String value => value.trim().replaceAll('-', '_').split('_'),
    _ => const <String>[],
  };
  if (raw.isEmpty || raw.first.trim().isEmpty) {
    return (language: '', script: null, region: null);
  }
  final nonEmpty = [
    for (final part in raw)
      if (part.trim().isNotEmpty) part.trim(),
  ];
  String? take(int index) =>
      nonEmpty.length > index ? nonEmpty[index].toLowerCase() : null;
  // 字符串输入遵循 BCP 47 顺序：language-script-region。
  return (language: take(0)!, script: take(1), region: take(2));
}

/// 计算一段受支持 Locale 与已拆解输入的匹配分值；不匹配返回 0。
///
/// 分值构成：命中语言记 1 分（基础），text 子标签完全一致加 4 分，
/// 地区子标签完全一致加 2 分。任何一项冲突不额外加分也不扣分，最终以
/// 最高分胜出，保证"完整匹配 > 文字匹配 > 地区匹配 > 纯语言"的优先级，
/// 且不再受生成列表顺序影响。
int _localeMatchScore(Locale candidate, ({String language, String? script, String? region}) input) {
  if (candidate.languageCode.toLowerCase() != input.language) {
    return 0;
  }
  var score = 1;

  // 输入未声明 script 时借助地区提示推断期望文字：这是 zh 与 zh-Hant
  // 并存后避免台/港/澳系统语言被首个同名候选抢先的关键。
  final expectedScript =
      input.script ??
      (input.language == 'zh'
          ? _chineseRegionScriptHints[input.region]
          : null);
  final candidateScript = candidate.scriptCode?.toLowerCase();
  if (expectedScript != null && candidateScript == expectedScript.toLowerCase()) {
    score += 4;
  }

  final candidateRegion = candidate.countryCode?.toLowerCase();
  if (input.region != null && candidateRegion == input.region) {
    score += 2;
  }
  return score;
}

/// 尝试把 Locale 或字符串解析为生成器声明的受支持语言。
///
/// 输入允许使用 `ru`、`ru_RU`、`zh-Hant`、`zh_Hant_TW` 等形式；当多个受
/// 支持资源共享同一 language code（如 zh 与 zh-Hant）时，按"完整匹配 >
/// 文字匹配 > 地区匹配 > 纯语言"打分取最优，未知值返回 `null`，由调用方
/// 决定采用系统语言还是产品默认语言。
Locale? tryResolveSupportedAppLocale(Object? localeOrString) {
  final parts = _splitLocaleParts(localeOrString);
  if (parts.language.isEmpty) {
    return null;
  }

  Locale? bestMatch;
  var bestScore = 0;
  var bestComplexity = 3;
  for (final supportedLocale in AppLocalizations.supportedLocales) {
    final score = _localeMatchScore(supportedLocale, parts);
    // 平局时偏好子标签更少的基础资源：例如输入 zh_SG 或裸 zh 时，命简体
    // 基础资源而非繁体变体；该规则不依赖生成列表顺序。
    final complexity =
        (supportedLocale.scriptCode != null ? 1 : 0) +
        (supportedLocale.countryCode != null ? 1 : 0);
    if (score == 0) {
      continue;
    }
    if (score > bestScore ||
        (score == bestScore && complexity < bestComplexity)) {
      bestScore = score;
      bestMatch = supportedLocale;
      bestComplexity = complexity;
    }
  }
  return bestMatch;
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
