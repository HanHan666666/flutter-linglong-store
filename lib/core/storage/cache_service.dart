import 'package:hive_flutter/hive_flutter.dart';

/// Hive 缓存封装服务
class CacheService {
  CacheService._();

  static const String _cacheBoxName = 'cache';
  static bool _initialized = false;

  /// 初始化
  static Future<void> init() async {
    if (_initialized) return;

    // 缓存读取路径包含同步的 Hive.box() 调用，因此启动阶段必须先完成 box 打开。
    await Hive.initFlutter();
    await Hive.openBox(_cacheBoxName);
    _initialized = true;
  }

  /// 获取缓存
  static T? get<T>(String key) {
    final box = Hive.box(_cacheBoxName);

    // 检查 TTL 过期
    final ttlKey = '${key}_ttl';
    final expireTime = box.get(ttlKey) as int?;
    if (expireTime != null) {
      if (DateTime.now().millisecondsSinceEpoch > expireTime) {
        // 已过期，返回 null（过期数据将在下次 set 或 clear 时清理）
        return null;
      }
    }

    return box.get(key) as T?;
  }

  /// 设置缓存
  static Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(key, value);

    // 存储 TTL 过期时间戳
    if (ttl != null) {
      final expireTime =
          DateTime.now().millisecondsSinceEpoch + ttl.inMilliseconds;
      await box.put('${key}_ttl', expireTime);
    } else {
      // 无 TTL 时清理可能存在的旧 TTL 记录
      await box.delete('${key}_ttl');
    }
  }

  /// 删除缓存
  static Future<void> delete(String key) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.delete(key);
    // 同时删除 TTL 记录
    await box.delete('${key}_ttl');
  }

  /// 清空缓存
  static Future<void> clear() async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.clear();
  }
}
