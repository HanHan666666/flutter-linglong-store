import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/cli_executor.dart';
import '../../core/storage/cache_service.dart';

part 'app_search_index_provider.g.dart';

/// 轻量候选条目，只保留跳转详情页所需的最小字段。
class SearchSuggestionEntry {
  const SearchSuggestionEntry({
    required this.appId,
    required this.name,
    this.version,
    this.arch,
    this.repoName,
    this.module,
  });

  /// 应用唯一标识，如 "org.example.browser"
  final String appId;

  /// 应用名称，用于候选展示和模糊匹配
  final String name;

  /// 候选进入详情页时用于精确匹配后端详情记录。
  final String? version;
  final String? arch;
  final String? repoName;
  final String? module;
}

/// 解析 `ll-cli search . --json` 的 JSON 输出。
///
/// 遍历所有 channel，按 appId 去重，只保留 id + name。
List<SearchSuggestionEntry> parseSearchIndexJson(String jsonStr) {
  try {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final seen = <String>{};
    final entries = <SearchSuggestionEntry>[];

    for (final entry in map.entries) {
      final fallbackRepoName = _normalizeString(entry.key);
      final channel = entry.value;
      if (channel is! List) continue;
      for (final item in channel) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id'];
        final name = item['name'];
        if (id is! String || name is! String) continue;
        if (seen.contains(id)) continue;
        seen.add(id);
        entries.add(
          SearchSuggestionEntry(
            appId: id,
            name: name,
            version: _normalizeString(item['version']),
            arch: _normalizeArch(item['arch']),
            repoName:
                _normalizeString(item['repoName']) ??
                _normalizeString(item['repo_name']) ??
                fallbackRepoName ??
                AppConfig.defaultStoreRepoName,
            module: _normalizeString(item['module']),
          ),
        );
      }
    }

    return entries;
  } catch (_) {
    return const [];
  }
}

String? _normalizeString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? _normalizeArch(Object? value) {
  if (value is List) {
    // `ll-cli search . --json` 可能返回架构数组；详情接口需要单个架构值。
    for (final item in value) {
      final text = _normalizeString(item);
      if (text != null) return text;
    }
    return null;
  }
  return _normalizeString(value);
}

/// 在候选列表中做模糊匹配，返回 top N 结果。
///
/// 排序策略：前缀匹配优先 → 按出现位置排序 → 按 name 字母序。
List<SearchSuggestionEntry> searchSuggestions(
  List<SearchSuggestionEntry> entries,
  String query, {
  int maxResults = 8,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return const [];

  final scored = <_ScoredEntry>[];

  for (final entry in entries) {
    final lowerName = entry.name.toLowerCase();
    final idx = lowerName.indexOf(normalizedQuery);
    if (idx == -1) continue;

    // 前缀匹配 priority=0（最高），包含匹配 priority=1
    final priority = idx == 0 ? 0 : 1;
    scored.add(_ScoredEntry(entry: entry, priority: priority, position: idx));
  }

  scored.sort((a, b) {
    final cmp = a.priority.compareTo(b.priority);
    if (cmp != 0) return cmp;
    return a.position.compareTo(b.position);
  });

  return scored.take(maxResults).map((s) => s.entry).toList();
}

class _ScoredEntry {
  const _ScoredEntry({
    required this.entry,
    required this.priority,
    required this.position,
  });

  final SearchSuggestionEntry entry;
  final int priority;
  final int position;
}

/// Hive 缓存 key：精简后的搜索索引（紧凑 JSON）。
///
/// 旧版把 `ll-cli search . --json` 的完整原始 JSON（数 MB）整串存入
/// `search_index_json`，导致 Hive 中同一份索引"原始串 + 解析对象"双份驻留；
/// 现在只落盘候选所需的最小字段，并在水合时清理旧 key。
const _kCacheKey = 'search_index_compact_v1';

/// 旧版原始 JSON 缓存 key，仅用于一次性迁移兜底，读取后立即删除。
const _kLegacyCacheKey = 'search_index_json';

/// 索引缓存新鲜期。
///
/// 索引来自远端仓库目录，变化频率低；新鲜期内启动跳过 ll-cli 重跑，
/// 过期后按未命中处理并重新拉取。候选点击后仍按 appId 精确查详情，
/// 索引略旧只影响候选列表内容，不影响跳转正确性。
const _kIndexFreshTtl = Duration(hours: 24);

/// 将精简条目编码为紧凑 JSON（位置数组，字段顺序与 [decodeCompactIndex] 对应）。
String encodeCompactIndex(List<SearchSuggestionEntry> entries) => jsonEncode([
      for (final e in entries)
        [
          e.appId,
          e.name,
          e.version ?? '',
          e.arch ?? '',
          e.repoName ?? '',
          e.module ?? '',
        ],
    ]);

/// 解码 [encodeCompactIndex] 生成的紧凑 JSON；格式损坏时返回空列表（视为未命中）。
List<SearchSuggestionEntry> decodeCompactIndex(String jsonStr) {
  try {
    final list = jsonDecode(jsonStr) as List;
    return [
      for (final item in list)
        if (item is List && item.length >= 6)
          SearchSuggestionEntry(
            appId: item[0] as String,
            name: item[1] as String,
            version: _orEmptyToNull(item[2]),
            arch: _orEmptyToNull(item[3]),
            repoName: _orEmptyToNull(item[4]),
            module: _orEmptyToNull(item[5]),
          ),
    ];
  } catch (_) {
    return const [];
  }
}

String? _orEmptyToNull(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

/// 应用搜索索引 Provider。
///
/// 启动时优先从 Hive 本地缓存读取精简索引（毫秒级）；新鲜期（24h）内命中
/// 则直接使用，不再重跑 ll-cli，过期或未命中才执行 `ll-cli search . --json`
/// 刷新。落盘只存候选所需的最小字段，避免原始 JSON 整串常驻。
///
/// keepAlive: true — 搜索索引是应用级全局数据，不应被 auto-dispose 回收。
@Riverpod(keepAlive: true)
class AppSearchIndex extends _$AppSearchIndex {
  @override
  AsyncValue<List<SearchSuggestionEntry>> build() {
    // CacheService 为 LazyBox，缓存读取是异步磁盘 IO：先返回 loading，
    // 水合完成后命中则立即回填，未命中则直接拉取 ll-cli。
    _hydrateFromCache();
    return const AsyncLoading();
  }

  Future<void> _hydrateFromCache() async {
    // 新鲜期内的精简缓存直接可用，本轮启动跳过 ll-cli 重跑（TTL 过期即未命中）。
    final cached = await CacheService.get<String>(_kCacheKey);
    if (cached != null && cached.isNotEmpty) {
      final entries = decodeCompactIndex(cached);
      if (entries.isNotEmpty) {
        AppLogger.info('[SearchIndex] 命中本地缓存: ${entries.length} 条应用');
        if (!ref.mounted) return;
        state = AsyncData(entries);
        return;
      }
    }

    // 精简缓存未命中：用旧版原始 JSON 缓存兜底水合一次，保证升级后首轮
    // 仍有候选可用；读取后立即删除旧 key 释放 Hive 空间，再后台刷新。
    final legacyEntries = await _readAndDropLegacyEntries();
    if (!ref.mounted) return;
    if (legacyEntries != null) {
      state = AsyncData(legacyEntries);
    }
    await _fetchFromCli();
  }

  /// 读取并删除旧版原始 JSON 缓存；未存或解析失败返回 null。
  Future<List<SearchSuggestionEntry>?> _readAndDropLegacyEntries() async {
    try {
      final legacy = await CacheService.get<String>(_kLegacyCacheKey);
      if (legacy == null || legacy.isEmpty) return null;
      await CacheService.delete(_kLegacyCacheKey);
      final entries = parseSearchIndexJson(legacy);
      return entries.isEmpty ? null : entries;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchFromCli() async {
    try {
      final output = await CliExecutor.execute([
        'search',
        '.',
        '--json',
      ], timeout: const Duration(seconds: 30));
      if (!ref.mounted) return;
      if (!output.success) {
        // 首次加载且无缓存时回退空列表
        if (state is! AsyncData) {
          state = const AsyncData([]);
        }
        return;
      }
      final entries = parseSearchIndexJson(output.stdout);
      AppLogger.info('[SearchIndex] ll-cli 加载完成: ${entries.length} 条应用');
      if (!ref.mounted) return;
      state = AsyncData(entries);
      // 写入精简格式缓存供下次启动使用；TTL 控制新鲜期，过期后重新拉取
      await CacheService.set(
        _kCacheKey,
        encodeCompactIndex(entries),
        ttl: _kIndexFreshTtl,
      );
    } catch (e, stack) {
      if (!ref.mounted) return;
      AppLogger.warning('[SearchIndex] ll-cli 加载失败', e, stack);
      // 首次加载且无缓存时回退空列表
      if (state is! AsyncData) {
        state = const AsyncData([]);
      }
    }
  }
}
