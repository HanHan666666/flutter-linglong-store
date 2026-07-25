/// 应用持续忽略更新的本地存储边界。
///
/// 该文件只负责 SharedPreferences JSON 的读取、校验、去重和写入，
/// 不持有界面状态，也不参与远端更新检查。
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/ignored_update.dart';
import '../logging/app_logger.dart';

/// 忽略更新存储接口。
///
/// 抽象接口让应用状态测试可以注入可控存储，同时把 SharedPreferences
/// 的具体格式限制在数据边界内。
abstract interface class IgnoredUpdateStorage {
  /// 同步读取已忽略记录；SharedPreferences 已在应用启动前载入内存。
  List<IgnoredUpdate> load();

  /// 原子写入当前完整快照，并返回底层持久化是否成功。
  Future<bool> save(List<IgnoredUpdate> records);
}

/// 基于 SharedPreferences 的忽略更新存储实现。
class SharedPreferencesIgnoredUpdateStorage implements IgnoredUpdateStorage {
  /// 创建使用指定 SharedPreferences 实例的存储。
  const SharedPreferencesIgnoredUpdateStorage(this._preferences);

  /// 版本化存储键；不兼容的数据结构变更应使用新键并显式迁移。
  static const String storageKey = 'linglong-store-ignored-updates-v1';

  /// 已由应用入口初始化并注入的 SharedPreferences 实例。
  final SharedPreferences _preferences;

  @override
  List<IgnoredUpdate> load() {
    final rawValue = _preferences.getString(storageKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      return const <IgnoredUpdate>[];
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! List<dynamic>) {
        AppLogger.warning('Ignored update storage root is not a JSON list');
        return const <IgnoredUpdate>[];
      }

      final recordsByAppId = <String, IgnoredUpdate>{};
      for (final rawRecord in decoded) {
        final record = IgnoredUpdate.tryFromJson(rawRecord);
        if (record == null) {
          AppLogger.warning('Skipped an invalid ignored update record');
          continue;
        }

        final existing = recordsByAppId[record.appId];
        if (existing == null || record.ignoredAt >= existing.ignoredAt) {
          recordsByAppId[record.appId] = record;
        }
      }

      final records = recordsByAppId.values.toList()
        ..sort(IgnoredUpdate.compareForDisplay);
      return List<IgnoredUpdate>.unmodifiable(records);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to restore ignored update records',
        error,
        stackTrace,
      );
      return const <IgnoredUpdate>[];
    }
  }

  @override
  Future<bool> save(List<IgnoredUpdate> records) async {
    try {
      final sortedRecords = List<IgnoredUpdate>.from(records)
        ..sort(IgnoredUpdate.compareForDisplay);
      final encoded = jsonEncode(
        sortedRecords.map((record) => record.toJson()).toList(),
      );
      return await _preferences.setString(storageKey, encoded);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to persist ignored update records',
        error,
        stackTrace,
      );
      return false;
    }
  }
}
