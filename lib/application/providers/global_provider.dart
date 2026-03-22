import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/app_logger.dart';
import 'all_apps_provider.dart';
import 'install_queue_provider.dart';
import 'ranking_provider.dart';
import 'recommend_provider.dart';
import 'search_provider.dart';
import 'sidebar_config_provider.dart';

part 'global_provider.freezed.dart';
part 'global_provider.g.dart';

/// 本地存储 keys
const String _kLanguageKey = 'linglong-store-language';
const String _kThemeModeKey = 'linglong-store-theme-mode';
const String _kUserPreferencesKey = 'linglong-store-user-preferences';

/// 用户偏好设置
@freezed
sealed class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    /// 是否自动检查更新
    @Default(true) bool autoCheckUpdate,

    /// 是否显示Beta版本应用
    @Default(false) bool showBetaApps,

    /// 是否显示系统应用
    @Default(false) bool showSystemApps,

    /// 是否启用通知
    @Default(true) bool enableNotifications,

    /// 是否启用桌面快捷方式创建
    @Default(true) bool autoCreateShortcut,

    /// 下载并发数
    @Default(3) int downloadConcurrency,

    /// 安装后自动运行
    @Default(false) bool autoRunAfterInstall,

    /// 是否精简模式
    @Default(false) bool compactMode,

    /// 首页自定义配置
    @Default([]) List<String> customCategories,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}

/// 全局应用状态
class GlobalAppState {
  const GlobalAppState({
    this.locale = const Locale('zh'),
    this.themeMode = ThemeMode.system,
    this.userPreferences = const UserPreferences(),
    this.isInitialized = false,
    this.arch,
    this.appVersion,
    this.checking = false,
    this.installing = false,
    this.checked = false,
    this.envReady = false,
    this.reason,
    this.osVersion,
    this.llVersion,
    this.llBinVersion,
  });

  /// 当前语言
  final Locale locale;

  /// 主题模式
  final ThemeMode themeMode;

  /// 用户偏好设置
  final UserPreferences userPreferences;

  /// 是否已初始化
  final bool isInitialized;

  /// 系统架构
  final String? arch;

  /// 应用版本
  final String? appVersion;

  /// 是否正在检查环境
  final bool checking;

  /// 是否正在安装
  final bool installing;

  /// 是否已检查环境
  final bool checked;

  /// 环境是否就绪
  final bool envReady;

  /// 环境检查失败原因
  final String? reason;

  /// 操作系统版本
  final String? osVersion;

  /// 玲珑版本
  final String? llVersion;

  /// ll-cli 版本
  final String? llBinVersion;

  /// 复制并更新
  GlobalAppState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    UserPreferences? userPreferences,
    bool? isInitialized,
    String? arch,
    String? appVersion,
    bool? checking,
    bool? installing,
    bool? checked,
    bool? envReady,
    String? reason,
    String? osVersion,
    String? llVersion,
    String? llBinVersion,
    bool clearReason = false,
  }) {
    return GlobalAppState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      userPreferences: userPreferences ?? this.userPreferences,
      isInitialized: isInitialized ?? this.isInitialized,
      arch: arch ?? this.arch,
      appVersion: appVersion ?? this.appVersion,
      checking: checking ?? this.checking,
      installing: installing ?? this.installing,
      checked: checked ?? this.checked,
      envReady: envReady ?? this.envReady,
      reason: clearReason ? null : (reason ?? this.reason),
      osVersion: osVersion ?? this.osVersion,
      llVersion: llVersion ?? this.llVersion,
      llBinVersion: llBinVersion ?? this.llBinVersion,
    );
  }
}

/// 全局应用状态 Provider
///
/// 管理应用级别的状态，包括：
/// - 语言设置
/// - 主题模式
/// - 用户偏好设置
/// - 环境信息
@Riverpod(keepAlive: true)
class GlobalApp extends _$GlobalApp {
  late SharedPreferences _prefs;

  @override
  GlobalAppState build() {
    _prefs = _readSharedPreferences();
    return _restorePersistedSettings();
  }

  /// 从 ProviderScope 注入的 SharedPreferences 中恢复首帧配置。
  ///
  /// 这里直接在 build 阶段同步读取，确保 MaterialApp 首帧就使用用户上次保存
  /// 的语言和主题，而不是先展示默认值再切换。
  GlobalAppState _restorePersistedSettings() {
    try {
      var restoredState = const GlobalAppState(isInitialized: true);

      // 加载语言设置
      final languageCode = _prefs.getString(_kLanguageKey);
      if (languageCode != null) {
        restoredState = restoredState.copyWith(locale: Locale(languageCode));
      }

      // 加载主题模式
      final themeModeIndex = _prefs.getInt(_kThemeModeKey);
      if (themeModeIndex != null && themeModeIndex < ThemeMode.values.length) {
        restoredState = restoredState.copyWith(
          themeMode: ThemeMode.values[themeModeIndex],
        );
      }

      // 加载用户偏好
      final prefsJson = _prefs.getString(_kUserPreferencesKey);
      if (prefsJson != null) {
        final userPreferences = UserPreferences.fromJson(
          jsonDecode(prefsJson) as Map<String, dynamic>,
        );
        restoredState = restoredState.copyWith(
          userPreferences: userPreferences,
        );
      }

      AppLogger.info('Loaded persisted settings');
      return restoredState;
    } catch (e, s) {
      AppLogger.error('Failed to load persisted settings', e, s);
      return const GlobalAppState(isInitialized: true);
    }
  }

  SharedPreferences _readSharedPreferences() {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (e, s) {
      AppLogger.error('SharedPreferences is not available for GlobalApp', e, s);
      rethrow;
    }
  }

  // ==================== 语言设置 ====================

  /// 设置语言
  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _prefs.setString(_kLanguageKey, locale.languageCode);
    AppLogger.info('Locale changed to: ${locale.languageCode}');

    // 刷新所有依赖语言的数据 Provider
    _invalidateLocaleDependentProviders();
  }

  /// 刷新所有依赖语言的数据 Provider
  ///
  /// 语言切换后，需要刷新以下 Provider 以获取对应语言的数据：
  /// - 推荐列表
  /// - 全部应用列表
  /// - 排行榜
  /// - 搜索结果
  /// - 侧边栏菜单配置（驱动自定义分类 family 重新加载）
  void _invalidateLocaleDependentProviders() {
    ref.invalidate(recommendProvider);
    ref.invalidate(allAppsProvider);
    ref.invalidate(rankingProvider);
    ref.invalidate(searchProvider);
    ref.invalidate(sidebarConfigProvider);
  }

  /// 设置中文
  Future<void> setChinese() => setLocale(const Locale('zh'));

  /// 设置英文
  Future<void> setEnglish() => setLocale(const Locale('en'));

  // ==================== 主题设置 ====================

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt(_kThemeModeKey, mode.index);
    AppLogger.info('Theme mode changed to: ${mode.name}');
  }

  /// 切换浅色主题
  Future<void> setLightTheme() => setThemeMode(ThemeMode.light);

  /// 切换深色主题
  Future<void> setDarkTheme() => setThemeMode(ThemeMode.dark);

  /// 切换系统主题
  Future<void> setSystemTheme() => setThemeMode(ThemeMode.system);

  /// 切换主题
  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(newMode);
  }

  // ==================== 用户偏好设置 ====================

  /// 更新用户偏好
  Future<void> updateUserPreferences(UserPreferences prefs) async {
    state = state.copyWith(userPreferences: prefs);
    await _prefs.setString(_kUserPreferencesKey, jsonEncode(prefs.toJson()));
    AppLogger.info('User preferences updated');
  }

  /// 设置自动检查更新
  Future<void> setAutoCheckUpdate(bool value) async {
    await updateUserPreferences(
      state.userPreferences.copyWith(autoCheckUpdate: value),
    );
  }

  /// 设置显示Beta应用
  Future<void> setShowBetaApps(bool value) async {
    await updateUserPreferences(
      state.userPreferences.copyWith(showBetaApps: value),
    );
  }

  /// 设置显示系统应用
  Future<void> setShowSystemApps(bool value) async {
    await updateUserPreferences(
      state.userPreferences.copyWith(showSystemApps: value),
    );
  }

  /// 设置启用通知
  Future<void> setEnableNotifications(bool value) async {
    await updateUserPreferences(
      state.userPreferences.copyWith(enableNotifications: value),
    );
  }

  /// 设置自动创建快捷方式
  Future<void> setAutoCreateShortcut(bool value) async {
    await updateUserPreferences(
      state.userPreferences.copyWith(autoCreateShortcut: value),
    );
  }

  /// 设置下载并发数
  Future<void> setDownloadConcurrency(int value) async {
    await updateUserPreferences(
      state.userPreferences.copyWith(downloadConcurrency: value),
    );
  }

  /// 设置安装后自动运行
  Future<void> setAutoRunAfterInstall(bool value) async {
    await updateUserPreferences(
      state.userPreferences.copyWith(autoRunAfterInstall: value),
    );
  }

  /// 设置精简模式
  Future<void> setCompactMode(bool value) async {
    await updateUserPreferences(
      state.userPreferences.copyWith(compactMode: value),
    );
  }

  /// 设置自定义分类
  Future<void> setCustomCategories(List<String> categories) async {
    await updateUserPreferences(
      state.userPreferences.copyWith(customCategories: categories),
    );
  }

  // ==================== 环境信息 ====================

  /// 设置架构
  void setArch(String arch) => state = state.copyWith(arch: arch);

  /// 设置应用版本
  void setAppVersion(String version) =>
      state = state.copyWith(appVersion: version);

  /// 设置检查状态
  void setChecking(bool checking) => state = state.copyWith(checking: checking);

  /// 设置安装状态
  void setInstalling(bool installing) =>
      state = state.copyWith(installing: installing);

  /// 设置已检查状态
  void setChecked(bool checked) => state = state.copyWith(checked: checked);

  /// 设置环境就绪状态
  void setEnvReady(bool ready) => state = state.copyWith(envReady: ready);

  /// 设置失败原因
  void setReason(String? reason) =>
      state = state.copyWith(reason: reason, clearReason: reason == null);

  /// 设置OS版本
  void setOsVersion(String version) =>
      state = state.copyWith(osVersion: version);

  /// 设置玲珑版本
  void setLlVersion(String version) =>
      state = state.copyWith(llVersion: version);

  /// 设置ll-cli版本
  void setLlBinVersion(String version) =>
      state = state.copyWith(llBinVersion: version);

  /// 重置环境状态
  void resetEnvironmentState() {
    state = state.copyWith(
      checking: false,
      installing: false,
      checked: false,
      envReady: false,
      clearReason: true,
    );
  }
}

/// 便捷访问 Provider

/// 当前语言
@riverpod
Locale currentLocale(Ref ref) {
  return ref.watch(globalAppProvider).locale;
}

/// 当前主题模式
@riverpod
ThemeMode currentThemeMode(Ref ref) {
  return ref.watch(globalAppProvider).themeMode;
}

/// 用户偏好设置
@riverpod
UserPreferences userPreferences(Ref ref) {
  return ref.watch(globalAppProvider).userPreferences;
}

/// 是否深色模式
@riverpod
bool isDarkMode(Ref ref) {
  final themeMode = ref.watch(globalAppProvider).themeMode;
  if (themeMode == ThemeMode.system) {
    // 需要在 Widget 层获取系统主题
    return false;
  }
  return themeMode == ThemeMode.dark;
}

/// 环境是否就绪
@riverpod
bool isEnvReady(Ref ref) {
  return ref.watch(globalAppProvider).envReady;
}

/// 是否已初始化
@riverpod
bool isAppInitialized(Ref ref) {
  return ref.watch(globalAppProvider).isInitialized;
}
