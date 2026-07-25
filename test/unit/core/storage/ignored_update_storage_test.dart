import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/storage/ignored_update_storage.dart';
import 'package:linglong_store/domain/models/ignored_update.dart';

void main() {
  setUpAll(AppLogger.init);

  group('SharedPreferencesIgnoredUpdateStorage', () {
    test(
      'restores valid records, skips invalid entries, and deduplicates',
      () async {
        SharedPreferences.setMockInitialValues({
          SharedPreferencesIgnoredUpdateStorage.storageKey: jsonEncode([
            {
              'appId': 'org.example.demo',
              'appName': 'Old Demo',
              'ignoredVersion': '1.0.0',
              'ignoredAt': 100,
            },
            {'broken': true},
            {
              'appId': 'org.example.demo',
              'appName': 'Demo',
              'icon': 'https://example.com/demo.png',
              'ignoredVersion': '2.0.0',
              'ignoredAt': 200,
            },
            {
              'appId': 'org.example.other',
              'appName': 'Other',
              'ignoredVersion': '3.0.0',
              'ignoredAt': 150,
            },
          ]),
        });
        final preferences = await SharedPreferences.getInstance();
        final storage = SharedPreferencesIgnoredUpdateStorage(preferences);

        final records = storage.load();

        expect(records.map((record) => record.appId), [
          'org.example.demo',
          'org.example.other',
        ]);
        expect(records.first.appName, 'Demo');
        expect(records.first.ignoredVersion, '2.0.0');
        expect(records.first.icon, 'https://example.com/demo.png');
      },
    );

    test('returns an empty list when the stored root is malformed', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesIgnoredUpdateStorage.storageKey: '{"items":[]}',
      });
      final preferences = await SharedPreferences.getInstance();
      final storage = SharedPreferencesIgnoredUpdateStorage(preferences);

      expect(storage.load(), isEmpty);
    });

    test('returns an empty list when the stored JSON is corrupted', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesIgnoredUpdateStorage.storageKey: '{broken-json',
      });
      final preferences = await SharedPreferences.getInstance();
      final storage = SharedPreferencesIgnoredUpdateStorage(preferences);

      expect(storage.load(), isEmpty);
    });

    test('writes a stable JSON snapshot sorted by ignored time', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final storage = SharedPreferencesIgnoredUpdateStorage(preferences);

      final saved = await storage.save(const [
        IgnoredUpdate(
          appId: 'org.example.old',
          appName: 'Old',
          ignoredVersion: '1.0.0',
          ignoredAt: 100,
        ),
        IgnoredUpdate(
          appId: 'org.example.new',
          appName: 'New',
          ignoredVersion: '2.0.0',
          ignoredAt: 200,
        ),
      ]);

      expect(saved, isTrue);
      final rawValue = preferences.getString(
        SharedPreferencesIgnoredUpdateStorage.storageKey,
      );
      final decoded = jsonDecode(rawValue!) as List<dynamic>;
      expect(
        (decoded.first as Map<String, dynamic>)['appId'],
        'org.example.new',
      );
      expect(storage.load().map((record) => record.appId), [
        'org.example.new',
        'org.example.old',
      ]);
    });
  });
}
