import 'dart:convert';

import 'package:flutter/services.dart';

/// 构建期 seed 数据读取服务
class SeedDataService {
  SeedDataService._();

  /// 加载推荐页 seed 数据
  static Future<Map<String, dynamic>?> loadRecommendSeed() async {
    return await _loadJson('assets/seeds/recommend_main.json');
  }

  /// 加载全部应用 seed 数据
  static Future<Map<String, dynamic>?> loadAllAppsSeed() async {
    return await _loadJson('assets/seeds/all_apps_main.json');
  }

  /// 加载排行榜 seed 数据
  static Future<Map<String, dynamic>?> loadRankingSeed() async {
    return await _loadJson('assets/seeds/ranking_new.json');
  }

  /// 加载 JSON 文件
  static Future<Map<String, dynamic>?> _loadJson(String path) async {
    try {
      final String jsonString = await rootBundle.loadString(path);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}