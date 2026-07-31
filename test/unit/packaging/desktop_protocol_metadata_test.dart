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

    test('declares notification capability on the canonical desktop entry', () {
      final desktopTemplate = File(
        'build/packaging/linux/linglong-store.desktop.in',
      ).readAsStringSync();

      expect(desktopTemplate, contains('X-GNOME-UsesNotifications=true'));
      expect(desktopTemplate, isNot(contains('NoDisplay=true')));
    });

    test('delegates every localized field to the ARB metadata renderer', () {
      final desktopTemplate = File(
        'build/packaging/linux/linglong-store.desktop.in',
      ).readAsStringSync();

      expect(desktopTemplate, contains('@LOCALIZED_DESKTOP_NAME@'));
      expect(desktopTemplate, contains('@LOCALIZED_DESKTOP_GENERIC_NAME@'));
      expect(desktopTemplate, contains('@LOCALIZED_DESKTOP_COMMENT@'));
      expect(desktopTemplate, contains('@LOCALIZED_DESKTOP_KEYWORDS@'));
      expect(desktopTemplate, isNot(contains(RegExp(r'Name\[[^]]+\]='))));
    });

    test(
      'keeps the old desktop id as a hidden og protocol compatibility entry',
      () {
        final compatibilityTemplate = File(
          'build/packaging/linux/linglong-store-compat.desktop.in',
        ).readAsStringSync();

        expect(compatibilityTemplate, contains('NoDisplay=true'));
        expect(compatibilityTemplate, contains('Exec=@EXECUTABLE_NAME@ %u'));
        expect(
          compatibilityTemplate,
          contains('MimeType=x-scheme-handler/og;'),
        );
        expect(
          compatibilityTemplate,
          isNot(contains('X-GNOME-UsesNotifications=true')),
        );
      },
    );
  });
}
