import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 封装服务
///
/// 提供统一的本地存储访问接口
class PreferencesService {
  PreferencesService._();

  static late final SharedPreferences _prefs;
  static bool _initialized = false;

  /// 是否已初始化
  static bool get isInitialized => _initialized;

  /// 初始化
  static Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// 获取原始 SharedPreferences 实例
  static SharedPreferences get instance {
    if (!_initialized) {
      throw StateError('PreferencesService not initialized. Call init() first.');
    }
    return _prefs;
  }

  // ==================== 语言偏好 ====================

  /// 获取语言偏好
  static String getLanguagePreference() {
    return _prefs.getString('language') ?? 'zh';
  }

  /// 设置语言偏好
  static Future<void> setLanguagePreference(String locale) async {
    await _prefs.setString('language', locale);
  }

  // ==================== 仓库配置 ====================

  /// 获取仓库配置
  static String? getRepoName() {
    return _prefs.getString('repo_name');
  }

  /// 设置仓库配置
  static Future<void> setRepoName(String repoName) async {
    await _prefs.setString('repo_name', repoName);
  }

  // ==================== 主题配置 ====================

  /// 获取主题模式 (0: system, 1: light, 2: dark)
  static int getThemeMode() {
    return _prefs.getInt('theme_mode') ?? 0;
  }

  /// 设置主题模式
  static Future<void> setThemeMode(int mode) async {
    await _prefs.setInt('theme_mode', mode);
  }

  // ==================== 通用存储方法 ====================

  /// 存储字符串
  static Future<bool> setString(String key, String value) async {
    return _prefs.setString(key, value);
  }

  /// 获取字符串
  static String? getString(String key) {
    return _prefs.getString(key);
  }

  /// 存储整数
  static Future<bool> setInt(String key, int value) async {
    return _prefs.setInt(key, value);
  }

  /// 获取整数
  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  /// 存储布尔值
  static Future<bool> setBool(String key, bool value) async {
    return _prefs.setBool(key, value);
  }

  /// 获取布尔值
  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// 存储字符串列表
  static Future<bool> setStringList(String key, List<String> value) async {
    return _prefs.setStringList(key, value);
  }

  /// 获取字符串列表
  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  /// 存储 JSON 对象
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return _prefs.setString(key, jsonEncode(value));
  }

  /// 获取 JSON 对象
  static Map<String, dynamic>? getJson(String key) {
    final str = _prefs.getString(key);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 存储 JSON 列表
  static Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    return _prefs.setString(key, jsonEncode(value));
  }

  /// 获取 JSON 列表
  static List<Map<String, dynamic>>? getJsonList(String key) {
    final str = _prefs.getString(key);
    if (str == null) return null;
    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return null;
    }
  }

  /// 检查键是否存在
  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  /// 获取所有键
  static Set<String> getKeys() {
    return _prefs.getKeys();
  }

  /// 删除指定键
  static Future<bool> remove(String key) async {
    return _prefs.remove(key);
  }

  /// 清空所有数据
  static Future<bool> clear() async {
    return _prefs.clear();
  }

  // ==================== 安装队列相关 ====================

  /// 存储当前安装任务
  static Future<bool> setCurrentInstallTask(Map<String, dynamic> task) async {
    return setJson('linglong-store-current-install-task', task);
  }

  /// 获取当前安装任务
  static Map<String, dynamic>? getCurrentInstallTask() {
    return getJson('linglong-store-current-install-task');
  }

  /// 清除当前安装任务
  static Future<bool> clearCurrentInstallTask() async {
    return remove('linglong-store-current-install-task');
  }

  /// 存储安装队列
  static Future<bool> setInstallQueue(List<Map<String, dynamic>> queue) async {
    return setJsonList('linglong-store-install-queue', queue);
  }

  /// 获取安装队列
  static List<Map<String, dynamic>>? getInstallQueue() {
    return getJsonList('linglong-store-install-queue');
  }
}