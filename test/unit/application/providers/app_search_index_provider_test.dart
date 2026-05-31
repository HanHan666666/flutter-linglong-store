import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:linglong_store/application/providers/app_search_index_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';

void main() {
  late String hiveTestPath;

  setUpAll(() async {
    await AppLogger.init();
    final tempDir = await Directory.systemTemp.createTemp(
      'app_search_index_cache_test',
    );
    hiveTestPath = tempDir.path;
    Hive.init(hiveTestPath);
    await Hive.openBox('cache');
  });

  tearDown(() async {
    await Hive.box('cache').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await Directory(hiveTestPath).delete(recursive: true);
  });

  group('parseSearchIndexJson', () {
    test('parses ll-cli search JSON and deduplicates by appId', () {
      final json = jsonEncode({
        'stable': [
          {
            'id': 'org.example.browser',
            'name': '浏览器',
            'version': '1.0.0',
            'arch': ['x86_64'],
            'module': 'binary',
            'repoName': 'stable',
          },
          {
            'id': 'org.example.browser',
            'name': '浏览器',
            'arch': ['arm64'],
          },
          {
            'id': 'org.example.editor',
            'name': '编辑器',
            'arch': ['x86_64'],
          },
        ],
      });

      final entries = parseSearchIndexJson(json);

      // 同 id 去重，只保留第一条
      expect(entries.length, 2);
      expect(entries[0].appId, 'org.example.browser');
      expect(entries[0].name, '浏览器');
      expect(entries[0].version, '1.0.0');
      expect(entries[0].arch, 'x86_64');
      expect(entries[0].module, 'binary');
      expect(entries[0].repoName, 'stable');
      expect(entries[1].appId, 'org.example.editor');
    });

    test('handles empty JSON object', () {
      const json = '{}';
      final entries = parseSearchIndexJson(json);
      expect(entries, isEmpty);
    });

    test('handles malformed JSON gracefully', () {
      final entries = parseSearchIndexJson('not valid json');
      expect(entries, isEmpty);
    });
  });

  group('searchSuggestions', () {
    final entries = [
      const SearchSuggestionEntry(
        appId: 'org.mozilla.firefox',
        name: 'Firefox 浏览器',
      ),
      const SearchSuggestionEntry(appId: 'org.chromium', name: 'Chromium 浏览器'),
      const SearchSuggestionEntry(appId: 'org.deepin.browser', name: '浏览器'),
      const SearchSuggestionEntry(appId: 'org.deepin.editor', name: '文本编辑器'),
      const SearchSuggestionEntry(appId: 'org.deepin.music', name: '音乐播放器'),
      const SearchSuggestionEntry(
        appId: 'com.visualstudio.code',
        name: 'Visual Studio Code',
      ),
    ];

    test('empty query returns empty list', () {
      expect(searchSuggestions(entries, ''), isEmpty);
      expect(searchSuggestions(entries, '   '), isEmpty);
    });

    test('returns matching entries, prefix matches first', () {
      final results = searchSuggestions(entries, '浏览');

      // "浏览器" 以 "浏览" 开头 → 前缀匹配排前面
      // "Firefox 浏览器" 包含但非前缀 → 排后面
      expect(results.length, 3);
      expect(results[0].appId, 'org.deepin.browser');
    });

    test('respects maxResults limit', () {
      final manyEntries = List.generate(
        20,
        (i) => SearchSuggestionEntry(appId: 'app.$i', name: '测试应用$i'),
      );

      final results = searchSuggestions(manyEntries, '测试', maxResults: 5);
      expect(results.length, 5);
    });

    test('case-insensitive matching', () {
      final results = searchSuggestions(entries, 'firefox');
      expect(results.length, 1);
      expect(results[0].appId, 'org.mozilla.firefox');
    });

    test('no match returns empty list', () {
      final results = searchSuggestions(entries, '不存在');
      expect(results, isEmpty);
    });
  });

  group('AppSearchIndex', () {
    test('returns cached index synchronously on first read', () async {
      final cachedJson = jsonEncode({
        'stable': [
          {
            'id': 'org.example.camera',
            'name': '相机',
            'version': '1.0.0',
            'arch': ['x86_64'],
            'module': 'binary',
          },
        ],
      });
      await Hive.box('cache').put('search_index_json', cachedJson);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(appSearchIndexProvider);

      expect(state, isA<AsyncData<List<SearchSuggestionEntry>>>());
      final entries = (state as AsyncData<List<SearchSuggestionEntry>>).value;
      expect(entries.single.appId, 'org.example.camera');
    });
  });
}
