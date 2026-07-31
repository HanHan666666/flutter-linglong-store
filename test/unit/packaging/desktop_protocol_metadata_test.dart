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

    test('declares Russian XDG desktop metadata', () {
      final desktopTemplate = File(
        'build/packaging/linux/linglong-store.desktop.in',
      ).readAsStringSync();

      expect(desktopTemplate, contains('Name[ru]=@DISPLAY_NAME_RU@'));
      expect(desktopTemplate, contains('GenericName[ru]=Магазин приложений'));
      expect(desktopTemplate, contains('Comment[ru]=@SUMMARY_RU@'));
      expect(desktopTemplate, contains('Keywords[ru]='));
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
