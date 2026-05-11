import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linglong_store/presentation/widgets/app_icon.dart';

const _svgResponse = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
  <rect x="4" y="4" width="12" height="12" fill="#2588F0"/>
</svg>
''';

void main() {
  group('AppIcon', () {
    testWidgets('renders svg urls with SvgPicture', (tester) async {
      final http.Client svgHttpClient = MockClient((request) async {
        return http.Response(
          _svgResponse,
          200,
          headers: const {'content-type': 'image/svg+xml'},
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppIcon(
              iconUrl: 'https://example.com/icon.svg',
              size: 48,
              appName: 'Demo',
              svgHttpClient: svgHttpClient,
            ),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('renders raster urls with CachedNetworkImage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIcon(
              iconUrl: 'https://example.com/icon.png',
              size: 48,
              appName: 'Demo',
            ),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('renders extensionless urls with direct Image path', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIcon(
              iconUrl: 'https://example.com/icon',
              size: 48,
              appName: 'Demo',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('renders placeholder when icon url is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIcon(iconUrl: '', size: 48, appName: 'Demo'),
          ),
        ),
      );

      expect(find.text('D'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(SvgPicture), findsNothing);
    });
  });
}
