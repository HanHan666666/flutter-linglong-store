import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

/// 语言切换 Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// 语言状态管理
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('zh'));

  /// 切换语言
  void setLocale(String locale) {
    state = Locale(locale);
  }

  /// 切换到中文
  void setChinese() {
    state = const Locale('zh');
  }

  /// 切换到英文
  void setEnglish() {
    state = const Locale('en');
  }
}