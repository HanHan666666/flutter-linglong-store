import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('share localizations arb', () {
    test('defines share strings in both zh and en arb sources', () {
      final zh = jsonDecode(
        File('lib/core/i18n/l10n/app_zh.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      final en = jsonDecode(
        File('lib/core/i18n/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;

      const requiredKeys = <String>[
        'shareLink',
        'shareMessage',
        'linkCopied',
        'shareFailed',
      ];

      for (final key in requiredKeys) {
        expect(zh, containsPair(key, isA<String>()), reason: 'zh arb missing $key');
        expect(en, containsPair(key, isA<String>()), reason: 'en arb missing $key');
      }
    });
  });
}
