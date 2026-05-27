import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/platform/cli_executor.dart';

part 'app_search_index_provider.g.dart';

/// 轻量候选条目，只保留跳转详情页所需的最小字段。
class SearchSuggestionEntry {
  const SearchSuggestionEntry({required this.appId, required this.name});

  /// 应用唯一标识，如 "org.example.browser"
  final String appId;

  /// 应用名称，用于候选展示和模糊匹配
  final String name;
}

/// 解析 `ll-cli search . --json` 的 JSON 输出。
///
/// 遍历所有 channel，按 appId 去重，只保留 id + name。
List<SearchSuggestionEntry> parseSearchIndexJson(String jsonStr) {
  try {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final seen = <String>{};
    final entries = <SearchSuggestionEntry>[];

    for (final channel in map.values) {
      if (channel is! List) continue;
      for (final item in channel) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id'];
        final name = item['name'];
        if (id is! String || name is! String) continue;
        if (seen.contains(id)) continue;
        seen.add(id);
        entries.add(SearchSuggestionEntry(appId: id, name: name));
      }
    }

    return entries;
  } catch (_) {
    return const [];
  }
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

/// 应用搜索索引 Provider。
///
/// 启动时异步执行 `ll-cli search . --json`，解析后常驻内存。
/// 加载失败时静默回退为空列表，不阻塞启动。
@riverpod
class AppSearchIndex extends _$AppSearchIndex {
  @override
  AsyncValue<List<SearchSuggestionEntry>> build() {
    _loadIndex();
    return const AsyncLoading();
  }

  Future<void> _loadIndex() async {
    try {
      final output = await CliExecutor.execute(
        ['search', '.', '--json'],
        timeout: const Duration(seconds: 30),
      );
      if (!output.success) {
        state = const AsyncData([]);
        return;
      }
      final entries = parseSearchIndexJson(output.stdout);
      AppLogger.info('[SearchIndex] 加载完成: ${entries.length} 条应用');
      state = AsyncData(entries);
    } catch (e, stack) {
      AppLogger.warning('[SearchIndex] 加载失败，候选功能不可用', e, stack);
      state = const AsyncData([]);
    }
  }
}
