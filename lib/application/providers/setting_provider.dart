import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/app_logger.dart';

part 'setting_provider.freezed.dart';
part 'setting_provider.g.dart';

/// 设置状态
@freezed
sealed class SettingState with _$SettingState {
  const factory SettingState({
    /// 当前语言
    @Default(Locale('zh')) Locale locale,

    /// 主题模式
    @Default(ThemeMode.system) ThemeMode themeMode,

    /// 仓库名称
    @Default('repo:linglong') String repoName,

    /// 缓存大小（字节）
    @Default(0) int cacheSize,

    /// 应用版本
    String? appVersion,

    /// 是否正在清除缓存
    @Default(false) isClearingCache,
  }) = _SettingState;
}

/// 设置页面状态管理 Provider
@Riverpod(keepAlive: true)
class Setting extends _$Setting {
  late SharedPreferences _prefs;

  @override
  SettingState build() {
    return const SettingState();
  }

  /// 初始化设置
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await _loadSettings();
    await _calculateCacheSize();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      // 加载语言设置
      final languageCode = _prefs.getString('linglong-store-language');
      if (languageCode != null) {
        state = state.copyWith(locale: Locale(languageCode));
      }

      // 加载主题模式
      final themeModeIndex = _prefs.getInt('linglong-store-theme-mode');
      if (themeModeIndex != null && themeModeIndex < ThemeMode.values.length) {
        state = state.copyWith(themeMode: ThemeMode.values[themeModeIndex]);
      }

      // 加载仓库名称
      final repoName = _prefs.getString('repo_name');
      if (repoName != null && repoName.isNotEmpty) {
        state = state.copyWith(repoName: repoName);
      }

      AppLogger.info('Settings loaded');
    } catch (e, s) {
      AppLogger.error('Failed to load settings', e, s);
    }
  }

  /// 计算缓存大小
  Future<void> _calculateCacheSize() async {
    try {
      int totalSize = 0;

      // 计算 Hive 缓存大小
      final cacheBox = await Hive.openBox('cache');
      totalSize += _estimateHiveBoxSize(cacheBox);

      // 计算临时目录缓存
      final tempDir = Directory.systemTemp;
      if (await tempDir.exists()) {
        totalSize += await _calculateDirectorySize(tempDir);
      }

      state = state.copyWith(cacheSize: totalSize);
      AppLogger.info('Cache size calculated: $totalSize bytes');
    } catch (e, s) {
      AppLogger.error('Failed to calculate cache size', e, s);
    }
  }

  /// 估算 Hive Box 大小
  int _estimateHiveBoxSize(Box box) {
    // 简单估算：每个键值对平均 1KB
    return box.length * 1024;
  }

  /// 计算目录大小
  Future<int> _calculateDirectorySize(Directory dir) async {
    int size = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      // 忽略权限错误
    }
    return size;
  }

  /// 设置语言
  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _prefs.setString('linglong-store-language', locale.languageCode);
    AppLogger.info('Locale changed to: ${locale.languageCode}');
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt('linglong-store-theme-mode', mode.index);
    AppLogger.info('Theme mode changed to: ${mode.name}');
  }

  /// 设置仓库名称
  Future<void> setRepoName(String name) async {
    state = state.copyWith(repoName: name);
    await _prefs.setString('repo_name', name);
    AppLogger.info('Repo name changed to: $name');
  }

  /// 设置应用版本
  void setAppVersion(String version) {
    state = state.copyWith(appVersion: version);
  }

  /// 清除缓存
  Future<bool> clearCache() async {
    state = state.copyWith(isClearingCache: true);

    try {
      // 清除 Hive 缓存
      final cacheBox = await Hive.openBox('cache');
      await cacheBox.clear();

      // 清除临时目录中的应用缓存
      final tempDir = Directory.systemTemp;
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(followLinks: false)) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (e) {
            // 忽略删除失败
          }
        }
      }

      // 重新计算缓存大小
      await _calculateCacheSize();

      state = state.copyWith(isClearingCache: false);
      AppLogger.info('Cache cleared');
      return true;
    } catch (e, s) {
      AppLogger.error('Failed to clear cache', e, s);
      state = state.copyWith(isClearingCache: false);
      return false;
    }
  }

  /// 刷新缓存大小
  Future<void> refreshCacheSize() async {
    await _calculateCacheSize();
  }
}

/// 格式化字节大小为可读字符串
String formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  } else {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// 支持的语言列表
const List<Locale> supportedLocales = [
  Locale('zh'),
  Locale('en'),
];

/// 语言名称映射
const Map<String, String> languageNames = {
  'zh': '中文',
  'en': 'English',
};

/// 默认仓库列表
const List<String> defaultRepos = [
  'repo:linglong',
  'repo:deepin',
];