import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/presentation/pages/app_detail/screenshot_preview_app.dart';
import 'package:linglong_store/presentation/pages/app_detail/screenshot_preview_window_payload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenshotPreviewApp', () {
    late _FakeScreenshotPreviewWindowBinding binding;

    setUp(() {
      binding = _FakeScreenshotPreviewWindowBinding();
    });

    testWidgets('uses localized title from payload locale', (tester) async {
      await tester.pumpWidget(
        ScreenshotPreviewApp(
          initialPayload: const ScreenshotPreviewWindowPayload(
            screenshots: ['https://example.com/1.png'],
            initialIndex: 0,
            localeTag: 'en',
            isDarkMode: true,
          ),
          windowBinding: binding,
        ),
      );

      await tester.pump();

      expect(find.text('Screenshots'), findsOneWidget);
    });

    testWidgets('uses light theme when payload requests light mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        ScreenshotPreviewApp(
          initialPayload: const ScreenshotPreviewWindowPayload(
            screenshots: ['https://example.com/light.png'],
            initialIndex: 0,
            localeTag: 'zh',
            isDarkMode: false,
          ),
          windowBinding: binding,
        ),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
    });

    testWidgets('updates screenshot state when preview_update is received', (
      tester,
    ) async {
      await tester.pumpWidget(
        ScreenshotPreviewApp(
          initialPayload: const ScreenshotPreviewWindowPayload(
            screenshots: ['https://example.com/1.png'],
            initialIndex: 0,
            localeTag: 'zh',
            isDarkMode: true,
          ),
          windowBinding: binding,
        ),
      );

      await binding.dispatch(
        kScreenshotPreviewUpdateMethod,
        const ScreenshotPreviewWindowPayload(
          screenshots: [
            'https://example.com/1.png',
            'https://example.com/2.png',
          ],
          initialIndex: 1,
          localeTag: 'en',
          isDarkMode: false,
        ).toJson(),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('Screenshots'), findsOneWidget);
    });

    testWidgets('close button only calls sub-window binding close', (
      tester,
    ) async {
      await tester.pumpWidget(
        ScreenshotPreviewApp(
          initialPayload: const ScreenshotPreviewWindowPayload(
            screenshots: ['https://example.com/1.png'],
            initialIndex: 0,
            localeTag: 'en',
            isDarkMode: true,
          ),
          windowBinding: binding,
        ),
      );

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();

      expect(binding.closeCalls, 1);
    });
  });
}

class _FakeScreenshotPreviewWindowBinding
    implements ScreenshotPreviewWindowBinding {
  Future<dynamic> Function(MethodCall call)? _handler;
  int closeCalls = 0;

  @override
  Future<void> closeWindow() async {
    closeCalls += 1;
  }

  Future<void> dispatch(String method, [dynamic arguments]) async {
    final handler = _handler;
    if (handler == null) {
      throw StateError('Handler not registered');
    }
    await handler(MethodCall(method, arguments));
  }

  @override
  Future<void> focusWindow() async {}

  @override
  Future<void> registerMethodHandler(
    Future<dynamic> Function(MethodCall call)? handler,
  ) async {
    _handler = handler;
  }

  @override
  Future<void> startDragging() async {}
}
