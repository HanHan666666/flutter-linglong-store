import 'package:flutter/material.dart';

/// 将 Flutter locale 归一成后端 API 约定的语言值（zh_CN / en_US）。
///
/// 后端接口约定：
/// - `zh*` → `zh_CN`
/// - `en*` → `en_US`
/// - 其他/空 → `zh_CN`（默认）
///
/// [localeOrString] 可以是 `Locale` 对象或 locale 字符串（如 'zh-CN'、'en_US'）。
String resolveApiLang(Object? localeOrString) {
  String? raw;
  if (localeOrString is Locale) {
    raw = localeOrString.toString();
  } else if (localeOrString is String) {
    raw = localeOrString;
  }
  final norm = raw?.trim().replaceAll('-', '_').toLowerCase();
  if (norm == null || norm.isEmpty) return 'zh_CN';
  if (norm.startsWith('en')) return 'en_US';
  return 'zh_CN';
}
