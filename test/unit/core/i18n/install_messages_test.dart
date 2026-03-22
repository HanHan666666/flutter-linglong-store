import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/install_messages.dart';

void main() {
  group('InstallMessages', () {
    test('extracts plain message text from unknown json progress lines', () {
      final messages = InstallMessages.fromLocale(const Locale('zh'));

      expect(
        messages.getStatusFromMessage(
          '{"message":"Beginning to pull data","percentage":5}',
        ),
        equals('Beginning to pull data'),
      );
    });

    test('extracts plain message text from unknown json message lines', () {
      final messages = InstallMessages.fromLocale(const Locale('zh'));

      expect(
        messages.getStatusFromMessage(
          '{"message":"Preparing sandbox permissions"}',
        ),
        equals('Preparing sandbox permissions'),
      );
    });
  });
}
