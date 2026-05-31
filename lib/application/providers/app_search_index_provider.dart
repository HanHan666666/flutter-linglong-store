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

/// Hive 缓存 key：ll-cli search 原始 JSON
const _kCacheKey = 'search_index_json';

/// 应用搜索索引 Provider。
///
/// 启动时优先从 Hive 本地缓存读取（毫秒级），再后台执行 `ll-cli search . --json`
/// 刷新缓存。下次启动直接命中缓存，无需等待 ll-cli。
///
/// keepAlive: true — 搜索索引是应用级全局数据，不应被 auto-dispose 回收。
@Riverpod(keepAlive: true)
class AppSearchIndex extends _$AppSearchIndex {
  @override
  AsyncValue<List<SearchSuggestionEntry>> build() {
    final cachedEntries = _readCachedEntries();
    if (cachedEntries != null) {
      _refreshInBackground();
      return AsyncData(cachedEntries);
    }

    _fetchFromCli();
    return const AsyncLoading();
  }

  List<SearchSuggestionEntry>? _readCachedEntries() {
    final cached = CacheService.get<String>(_kCacheKey);
    if (cached == null || cached.isEmpty) {
      return null;
    }

    final entries = parseSearchIndexJson(cached);
    if (entries.isEmpty) {
      return null;
    }

    AppLogger.info('[SearchIndex] 命中本地缓存: ${entries.length} 条应用');
    return entries;
  }

  /// 后台执行 ll-cli 刷新索引并更新缓存。
  Future<void> _refreshInBackground() async {
    await _fetchFromCli();
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
      // 写入本地缓存供下次启动使用
      await CacheService.set(_kCacheKey, output.stdout);
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
