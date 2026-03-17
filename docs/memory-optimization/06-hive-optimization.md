# 06 - Hive 缓存优化

> **优先级：P2** | **预估节省：10~30 MB** | **风险：中**

---

## 6.1 现状分析

### 当前 CacheService 实现

```dart
// lib/core/storage/cache_service.dart

class CacheService {
  static T? get<T>(String key) {
    final box = Hive.box('cache');  // 同步访问，要求 Box 已打开
    // TTL 检查：过期返回 null，但不删除数据
    final expireTime = box.get('${key}_ttl') as int?;
    if (expireTime != null && DateTime.now().millisecondsSinceEpoch > expireTime) {
      return null;  // ⚠️ 过期数据仍占内存
    }
    return box.get(key) as T?;
  }

  static Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final box = await Hive.openBox('cache');  // openBox 全量加载
    await box.put(key, value);
    // 存 TTL 时间戳...
  }
}
```

### 问题

| 问题 | 影响 |
|------|------|
| `Hive.openBox()` 全量加载到内存 | Box 越大内存越高 |
| 过期数据不主动删除 | 僵尸数据持续累积 |
| 无 Box 条目/大小上限 | 长期运行后无上限增长 |
| 每个 key 额外存一个 `{key}_ttl` 条目 | 条目数翻倍 |

---

## 6.2 方案 A：改用 LazyBox（推荐）

### 原理

- `Hive.openBox()` → 启动时全量读入内存
- `Hive.openLazyBox()` → 按需读取，只在 `get()` 时才加载对应 value

### 改动

```dart
// ✅ 修改后的 CacheService

class CacheService {
  CacheService._();

  static bool _initialized = false;
  static LazyBox? _lazyBox;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _lazyBox = await Hive.openLazyBox('cache');
    _initialized = true;
  }

  /// 获取缓存（改为异步，因为 LazyBox.get 是 async）
  static Future<T?> get<T>(String key) async {
    final box = _lazyBox!;

    // 检查 TTL 过期
    final expireTime = await box.get('${key}_ttl') as int?;
    if (expireTime != null &&
        DateTime.now().millisecondsSinceEpoch > expireTime) {
      // 过期时主动删除
      await box.delete(key);
      await box.delete('${key}_ttl');
      return null;
    }

    return await box.get(key) as T?;
  }

  /// 设置缓存
  static Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final box = _lazyBox!;
    await box.put(key, value);
    if (ttl != null) {
      final expireTime =
          DateTime.now().millisecondsSinceEpoch + ttl.inMilliseconds;
      await box.put('${key}_ttl', expireTime);
    } else {
      await box.delete('${key}_ttl');
    }
  }

  // delete / clear 同理...
}
```

### 影响范围

- `CacheService.get()` 从同步变为异步（`Future<T?>`）
- 所有调用方需改为 `await CacheService.get(key)`
- 需检查所有调用点并适配

### 调用方排查

| 调用位置 | 当前调用方式 | 需要改动 |
|----------|-------------|---------|
| `setting_provider.dart` L88, L157 | 直接 `Hive.openBox('cache')` | 改为用 `CacheService` |
| 各 Repository 中的缓存读写 | `CacheService.get()` | 加 `await` |

### 预估节省

- 避免全量加载 = **10~20 MB**（取决于缓存累积量）

---

## 6.3 方案 B：添加过期数据清理（与 A 互补）

### 启动时清理

在 `CacheService.init()` 中添加启动时清理逻辑：

```dart
static Future<void> init() async {
  if (_initialized) return;
  await Hive.initFlutter();
  _lazyBox = await Hive.openLazyBox('cache');
  _initialized = true;

  // 启动时异步清理过期数据
  _cleanupExpired();
}

/// 清理所有过期缓存
static Future<void> _cleanupExpired() async {
  final box = _lazyBox!;
  final keysToDelete = <String>[];
  final now = DateTime.now().millisecondsSinceEpoch;

  for (final key in box.keys) {
    if (key is String && key.endsWith('_ttl')) {
      final expireTime = await box.get(key) as int?;
      if (expireTime != null && now > expireTime) {
        // 数据 key = 去掉 _ttl 后缀
        final dataKey = key.substring(0, key.length - 4);
        keysToDelete.addAll([key, dataKey]);
      }
    }
  }

  if (keysToDelete.isNotEmpty) {
    await box.deleteAll(keysToDelete);
    AppLogger.info('CacheService: cleaned ${keysToDelete.length ~/ 2} expired entries');
  }
}
```

### 预估节省

- 清理僵尸数据 = **5~10 MB**

---

## 6.4 方案 C：设置缓存条目上限

### 目的

防止缓存无限增长。

```dart
/// 缓存条目上限
static const int _maxEntries = 500; // 数据条目（不含 TTL 条目）

static Future<void> set<T>(String key, T value, {Duration? ttl}) async {
  final box = _lazyBox!;

  // 检查条目上限，超过时清理最老的数据
  final dataKeys = box.keys.where(
    (k) => k is String && !k.toString().endsWith('_ttl'),
  ).toList();

  if (dataKeys.length >= _maxEntries) {
    // 删除最早的 20% 条目（FIFO）
    final toRemove = dataKeys.take(dataKeys.length ~/ 5).toList();
    for (final k in toRemove) {
      await box.delete(k);
      await box.delete('${k}_ttl');
    }
    AppLogger.info('CacheService: evicted ${toRemove.length} oldest entries');
  }

  await box.put(key, value);
  // TTL 逻辑...
}
```

---

## 6.5 方案 D：统一 setting_provider 的缓存入口

### 问题

`setting_provider.dart` 绕过 `CacheService` 直接操作 Hive Box：

```dart
// setting_provider.dart L88
final cacheBox = await Hive.openBox('cache');
await cacheBox.clear();

// setting_provider.dart L157
final cacheBox = await Hive.openBox('cache');
```

### 方案

统一走 `CacheService.clear()` 和 `CacheService.set()`，避免绕过缓存管理。

---

## 6.6 本章改动汇总

| 编号 | 改动 | 文件数 | 风险 | 节省内存 |
|------|------|--------|------|----------|
| 6.2 | openBox → LazyBox | 3~5 | 中（接口变 async） | 10~20 MB |
| 6.3 | 启动时清理过期数据 | 1 | 低 | 5~10 MB |
| 6.4 | 缓存条目上限 | 1 | 低 | 防止增长 |
| 6.5 | 统一 Hive 访问入口 | 1 | 低 | 间接收益 |
| **合计** | | **4~6 文件** | | **15~30 MB** |
