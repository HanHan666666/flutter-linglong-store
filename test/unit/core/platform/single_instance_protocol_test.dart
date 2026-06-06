import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/platform/single_instance.dart';

void main() {
  group('SingleInstanceMessage', () {
    test('keeps legacy activate command compatible', () {
      final message = SingleInstanceMessage.fromWire('ACTIVATE');

      expect(message.kind, SingleInstanceMessageKind.activate);
      expect(message.url, isNull);
      expect(message.toWire(), contains('"kind":"activate"'));
    });

    test('round trips open url command', () {
      const url = 'og://org.example.App';
      final encoded = SingleInstanceMessage.openUrl(url).toWire();
      final decoded = SingleInstanceMessage.fromWire(encoded);

      expect(decoded.kind, SingleInstanceMessageKind.openUrl);
      expect(decoded.url, url);
    });

    test('falls back to activate for malformed payload', () {
      final message = SingleInstanceMessage.fromWire('{broken');

      expect(message.kind, SingleInstanceMessageKind.activate);
      expect(message.url, isNull);
    });
  });
}

