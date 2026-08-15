import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;

import '../config/app_config.dart';
import 'app_xdg_paths.dart';

/// Hive 懒加载缓存封装服务
///
/// 使用 LazyBox：内存中只保留 key 索引，值留在磁盘按需读取，
/// 避免"应用详情 × 版本 × 语言"笛卡尔积级的缓存内容全量驻留内存
/// （旧版非 Lazy Box 会在启动时把整个 box 载入 RAM 且永不释放）。
///
/// 缓存目录遵守 XDG：`$XDG_CACHE_HOME/<app-id>/`。
/// 缓存属于"可重新生成、可删除"的数据，按规范应放 cache 而非 data。
class CacheService {
  CacheService._();

  static const String _cacheBoxName = 'cache';

  /// TTL 侧车 key 后缀。沿用旧版 `${key}_ttl` 方案，存量数据无需迁移。
  static const String _ttlKeySuffix = '_ttl';

  static LazyBox? _box;
  static bool _initialized = false;

  /// 容量清扫互斥锁，防止并发写入触发重叠的清扫任务。
  static bool _evicting = false;

  /// 初始化
  ///
  /// 显式指定 Hive 的存储路径到 `$XDG_CACHE_HOME/<app-id>/`，
  /// 而不是 Hive.initFlutter 默认的 `$XDG_DATA_HOME/<app-id>/`。
  /// 旧版用非 Lazy Box 写入的存量数据与 LazyBox 文件格式一致，可直接读取。
  static Future<void> init() async {
    if (_initialized) return;

    final cacheDir = AppXdgPaths.resolveAppCacheDirectory();
    if (cacheDir == null || cacheDir.isEmpty) {
      // XDG_CACHE_HOME 与 HOME 都缺失时，回退到系统临时目录。
      final fallback = path.join(Directory.systemTemp.path, 'linglong-store-cache');
      Hive.init(fallback);
    } else {
      Hive.init(cacheDir);
    }

    _box = await Hive.openLazyBox(_cacheBoxName);
    _initialized = true;

    // 启动清扫历史过期条目；纯磁盘整理，不阻塞启动路径，失败不影响使用。
    unawaited(_sweepExpired());
  }

  /// 获取已打开的 box；兜底场景（未 init 即读写）下按需打开。
  static Future<LazyBox> _openBox() async {
    return _box ??= await Hive.openLazyBox(_cacheBoxName);
  }

  /// 获取缓存
  ///
  /// 命中已过期条目时顺带删除（自清理），避免僵尸数据长期占据磁盘。
  /// LazyBox 读取是一次磁盘 IO，调用方应避免在紧循环中逐条串行读取。
  static Future<T?> get<T>(String key) async {
    final box = await _openBox();

    final expireTime = await box.get(_ttlKey(key)) as int?;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (expireTime != null && now > expireTime) {
      // 已过期：删除数据与 TTL 记录后按未命中返回。
      unawaited(_deleteEntry(box, key));
      return null;
    }

    return await box.get(key) as T?;
  }

  /// 设置缓存
  ///
  /// 写入后若逻辑条目数超过容量上限，后台先清过期、再淘汰带 TTL 的旧条目，
  /// 防止应用详情缓存随 应用×版本×语言 组合无限增长。
  static Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final box = await _openBox();
    await box.put(key, value);

    if (ttl != null) {
      final expireTime =
          DateTime.now().millisecondsSinceEpoch + ttl.inMilliseconds;
      await box.put(_ttlKey(key), expireTime);
    } else {
      // 无 TTL 时清理可能存在的旧 TTL 记录，避免残留导致条目被误判过期。
      await box.delete(_ttlKey(key));
    }

    // 容量检查只读内存中的 key 索引，无 IO；仅在超限时才做磁盘清扫。
    if (_isOverCapacity()) {
      unawaited(_evictOverCapacity());
    }
  }

  /// 删除缓存
  static Future<void> delete(String key) async {
    final box = await _openBox();
    await _deleteEntry(box, key);
  }

  /// 清空缓存
  static Future<void> clear() async {
    final box = await _openBox();
    await box.clear();
  }

  /// 删除数据 key 与其 TTL 侧车 key。
  static Future<void> _deleteEntry(LazyBox box, String key) async {
    await box.delete(key);
    await box.delete(_ttlKey(key));
  }

  static String _ttlKey(String key) => '$key$_ttlKeySuffix';

  /// 逻辑条目数是否超过容量上限。
  ///
  /// key 索引常驻内存，length 读取无 IO；侧车 TTL key 与数据 key 成对出现，
  /// 除以 2 近似逻辑条目数（孤立侧车 key 只会低估容量压力，无功能影响）。
  static bool _isOverCapacity() {
    final box = _box;
    if (box == null || !box.isOpen) return false;
    return box.length ~/ 2 > AppConfig.cacheMaxLogicalEntries;
  }

  /// 清扫全部过期条目。
  ///
  /// 启动时与容量淘汰前调用；逐条读取 TTL 侧车值（磁盘 IO），
  /// 只处理带 TTL 的条目，永久条目（如推荐页快照）不参与。
  static Future<void> _sweepExpired() async {
    final box = _box;
    if (box == null || !box.isOpen) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final keys = box.keys.cast<String>().toList(growable: false);
    for (final key in keys) {
      if (!key.endsWith(_ttlKeySuffix)) continue;
      final expireTime = await box.get(key) as int?;
      if (expireTime == null || now <= expireTime) continue;
      await _deleteEntry(
        box,
        key.substring(0, key.length - _ttlKeySuffix.length),
      );
    }
  }

  /// 超容量时执行淘汰：先清过期，仍超限则按写入顺序淘汰带 TTL 的条目。
  ///
  /// 带 TTL 的条目全部是可再生的短期数据（如 5 分钟详情缓存），
  /// 淘汰任意一条都无害；无 TTL 的永久条目（推荐页快照等）永不淘汰。
  static Future<void> _evictOverCapacity() async {
    if (_evicting) return;
    _evicting = true;
    try {
      await _sweepExpired();
      if (!_isOverCapacity()) return;

      final box = _box;
      if (box == null || !box.isOpen) return;
      final keys = box.keys.cast<String>().toList(growable: false);
      final ttlKeys = keys.where((k) => k.endsWith(_ttlKeySuffix)).toSet();
      for (final key in keys) {
        if (!_isOverCapacity()) break;
        if (key.endsWith(_ttlKeySuffix)) continue;
        if (!ttlKeys.contains(_ttlKey(key))) continue;
        await _deleteEntry(box, key);
      }
    } finally {
      _evicting = false;
    }
  }
}
