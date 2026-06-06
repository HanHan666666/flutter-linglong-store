import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('desktop protocol metadata', () {
    test('declares og scheme handler and passes url argument', () {
      final desktopTemplate = File(
        'build/packaging/linux/linglong-store.desktop.in',
      ).readAsStringSync();

      expect(
        desktopTemplate,
        contains('Exec=@EXECUTABLE_NAME@ %u'),
        reason: 'XDG desktop entry needs %u so og://appId reaches Dart args.',
      );
      expect(
        desktopTemplate,
        contains('MimeType=x-scheme-handler/og;'),
        reason: 'Custom URL schemes are registered through x-scheme-handler.',
      );
    });
  });
}
