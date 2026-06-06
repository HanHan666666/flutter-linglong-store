import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/protocol/og_protocol_request.dart';

void main() {
  group('OgProtocolRequest', () {
    test('parses legacy host-form og url', () {
      final request = OgProtocolRequest.tryParse('og://org.example.App');

      expect(request, isNotNull);
      expect(request!.appId, 'org.example.App');
      expect(request.rawUrl, 'og://org.example.App');
    });

    test('parses slash-form og url used by some launchers', () {
      final request = OgProtocolRequest.tryParse('og:///org.example.App');

      expect(request, isNotNull);
      expect(request!.appId, 'org.example.App');
    });

    test('rejects unsupported scheme', () {
      final request = OgProtocolRequest.tryParse('https://example.com/app');

      expect(request, isNull);
    });

    test('rejects empty app id', () {
      final request = OgProtocolRequest.tryParse('og://');

      expect(request, isNull);
    });

    test('ignores query parameters because old protocol only carries appId', () {
      final request = OgProtocolRequest.tryParse(
        'og://org.example.App?version=1.0.0',
      );

      expect(request, isNotNull);
      expect(request!.appId, 'org.example.App');
    });
  });
}

