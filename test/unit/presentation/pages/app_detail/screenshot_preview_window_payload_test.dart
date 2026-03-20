import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/presentation/pages/app_detail/screenshot_preview_window_payload.dart';

void main() {
  group('ScreenshotPreviewWindowPayload', () {
    test('serializes and parses a valid payload', () {
      const payload = ScreenshotPreviewWindowPayload(
        screenshots: ['https://example.com/1.png', 'https://example.com/2.png'],
        initialIndex: 1,
        localeTag: 'en',
        isDarkMode: true,
      );

      final encoded = payload.toArguments();
      final parsed = ScreenshotPreviewWindowPayload.tryParseArguments(encoded);

      expect(parsed, isNotNull);
      expect(parsed, payload);
      expect(parsed!.type, kScreenshotPreviewWindowType);
    });

    test('preserves locale and theme fields', () {
      const payload = ScreenshotPreviewWindowPayload(
        screenshots: ['https://example.com/light.png'],
        initialIndex: 0,
        localeTag: 'zh',
        isDarkMode: false,
      );

      final parsed = ScreenshotPreviewWindowPayload.tryParseArguments(
        payload.toArguments(),
      );

      expect(parsed, isNotNull);
      expect(parsed!.locale, const Locale('zh'));
      expect(parsed.isDarkMode, isFalse);
    });

    test('returns null for malformed payload json', () {
      final parsed = ScreenshotPreviewWindowPayload.tryParseArguments(
        '{not-json}',
      );

      expect(parsed, isNull);
    });

    test('returns null for payload with invalid screenshots field', () {
      final parsed = ScreenshotPreviewWindowPayload.tryParseArguments('''
{"type":"$kScreenshotPreviewWindowType","screenshots":"bad","initialIndex":0,"localeTag":"zh","isDarkMode":true}
''');

      expect(parsed, isNull);
    });
  });
}
