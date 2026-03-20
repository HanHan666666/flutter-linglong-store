import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/presentation/pages/app_detail/screenshot_preview_window_coordinator.dart';
import 'package:linglong_store/presentation/pages/app_detail/screenshot_preview_window_payload.dart';

void main() {
  group('ScreenshotPreviewWindowCoordinator', () {
    const payload = ScreenshotPreviewWindowPayload(
      screenshots: ['https://example.com/1.png'],
      initialIndex: 0,
      localeTag: 'zh',
      isDarkMode: true,
    );

    test('creates a preview window on first open', () async {
      final gateway = _FakeScreenshotPreviewWindowGateway();
      final coordinator = ScreenshotPreviewWindowCoordinator(gateway: gateway);

      await coordinator.showPreview(payload);

      expect(gateway.createCalls, hasLength(1));
      expect(gateway.createdHandles.single.showCount, 1);
    });

    test('reuses tracked preview window on second open', () async {
      final gateway = _FakeScreenshotPreviewWindowGateway();
      final coordinator = ScreenshotPreviewWindowCoordinator(gateway: gateway);

      await coordinator.showPreview(payload);
      await coordinator.showPreview(
        payload.copyWith(
          screenshots: ['https://example.com/2.png'],
          initialIndex: 0,
        ),
      );

      expect(gateway.createCalls, hasLength(1));
      expect(
        gateway.createdHandles.single.invocations.where(
          (record) => record.method == kScreenshotPreviewUpdateMethod,
        ),
        hasLength(1),
      );
    });

    test(
      'recreates the preview window when tracked update call is stale',
      () async {
        final gateway = _FakeScreenshotPreviewWindowGateway();
        final coordinator = ScreenshotPreviewWindowCoordinator(
          gateway: gateway,
        );

        await coordinator.showPreview(payload);
        gateway.createdHandles.single.failNextInvocation = true;

        await coordinator.showPreview(
          payload.copyWith(
            screenshots: ['https://example.com/3.png'],
            initialIndex: 0,
          ),
        );

        expect(gateway.createCalls, hasLength(2));
        expect(gateway.createdHandles.last.showCount, 1);
      },
    );
  });
}

class _FakeScreenshotPreviewWindowGateway
    implements ScreenshotPreviewWindowGateway {
  final List<String> createCalls = <String>[];
  final List<_FakeScreenshotPreviewWindowHandle> createdHandles =
      <_FakeScreenshotPreviewWindowHandle>[];

  @override
  Future<_FakeScreenshotPreviewWindowHandle> createWindow({
    required String arguments,
  }) async {
    createCalls.add(arguments);
    final handle = _FakeScreenshotPreviewWindowHandle(
      id: 'window-${createdHandles.length + 1}',
      arguments: arguments,
    );
    createdHandles.add(handle);
    return handle;
  }

  @override
  Future<List<_FakeScreenshotPreviewWindowHandle>> getAllWindows() async {
    return createdHandles;
  }
}

class _FakeScreenshotPreviewWindowHandle
    implements ScreenshotPreviewWindowHandle {
  _FakeScreenshotPreviewWindowHandle({
    required this.id,
    required this.arguments,
  });

  @override
  final String id;

  @override
  final String arguments;

  int showCount = 0;
  bool failNextInvocation = false;
  final List<_InvocationRecord> invocations = <_InvocationRecord>[];

  @override
  Future<void> invokeMethod(String method, [dynamic arguments]) async {
    if (failNextInvocation) {
      failNextInvocation = false;
      throw StateError('stale handle');
    }
    invocations.add(_InvocationRecord(method, arguments));
  }

  @override
  Future<void> show() async {
    showCount += 1;
  }
}

class _InvocationRecord {
  const _InvocationRecord(this.method, this.arguments);

  final String method;
  final dynamic arguments;

  @override
  bool operator ==(Object other) {
    return other is _InvocationRecord &&
        other.method == method &&
        other.arguments == arguments;
  }

  @override
  int get hashCode => Object.hash(method, arguments);
}
