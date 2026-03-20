import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screenshot_preview_window_payload.dart';

final screenshotPreviewWindowCoordinatorProvider =
    Provider<ScreenshotPreviewWindowCoordinator>((ref) {
      return ScreenshotPreviewWindowCoordinator(
        gateway: const DesktopMultiWindowScreenshotPreviewWindowGateway(),
      );
    });

/// 统一协调截图预览子窗口，避免页面直接操作多窗口插件。
class ScreenshotPreviewWindowCoordinator {
  ScreenshotPreviewWindowCoordinator({
    required ScreenshotPreviewWindowGateway gateway,
  }) : _gateway = gateway;

  final ScreenshotPreviewWindowGateway _gateway;
  ScreenshotPreviewWindowHandle? _trackedHandle;

  Future<void> showPreview(ScreenshotPreviewWindowPayload payload) async {
    if (payload.screenshots.isEmpty) {
      return;
    }

    final existing = _trackedHandle ?? await _findExistingPreviewWindow();
    if (existing != null) {
      final reused = await _tryReuseWindow(existing, payload);
      if (reused) {
        _trackedHandle = existing;
        return;
      }
    }

    final created = await _gateway.createWindow(
      arguments: payload.toArguments(),
    );
    _trackedHandle = created;
    await created.show();
  }

  Future<bool> _tryReuseWindow(
    ScreenshotPreviewWindowHandle handle,
    ScreenshotPreviewWindowPayload payload,
  ) async {
    try {
      await handle.invokeMethod(
        kScreenshotPreviewUpdateMethod,
        payload.toJson(),
      );
      await handle.show();
      await handle.invokeMethod(kScreenshotPreviewActivateMethod);
      return true;
    } catch (_) {
      _trackedHandle = null;
      return false;
    }
  }

  Future<ScreenshotPreviewWindowHandle?> _findExistingPreviewWindow() async {
    final allWindows = await _gateway.getAllWindows();
    for (final window in allWindows) {
      final payload = ScreenshotPreviewWindowPayload.tryParseArguments(
        window.arguments,
      );
      if (payload?.type == kScreenshotPreviewWindowType) {
        return window;
      }
    }
    return null;
  }
}

abstract class ScreenshotPreviewWindowGateway {
  Future<ScreenshotPreviewWindowHandle> createWindow({
    required String arguments,
  });

  Future<List<ScreenshotPreviewWindowHandle>> getAllWindows();
}

abstract class ScreenshotPreviewWindowHandle {
  String get id;

  String get arguments;

  Future<void> show();

  Future<void> invokeMethod(String method, [dynamic arguments]);
}

class DesktopMultiWindowScreenshotPreviewWindowGateway
    implements ScreenshotPreviewWindowGateway {
  const DesktopMultiWindowScreenshotPreviewWindowGateway();

  @override
  Future<ScreenshotPreviewWindowHandle> createWindow({
    required String arguments,
  }) async {
    final controller = await WindowController.create(
      WindowConfiguration(hiddenAtLaunch: true, arguments: arguments),
    );
    return DesktopMultiWindowScreenshotPreviewWindowHandle(controller);
  }

  @override
  Future<List<ScreenshotPreviewWindowHandle>> getAllWindows() async {
    final controllers = await WindowController.getAll();
    return controllers
        .map(DesktopMultiWindowScreenshotPreviewWindowHandle.new)
        .toList(growable: false);
  }
}

class DesktopMultiWindowScreenshotPreviewWindowHandle
    implements ScreenshotPreviewWindowHandle {
  const DesktopMultiWindowScreenshotPreviewWindowHandle(this._controller);

  final WindowController _controller;

  @override
  String get id => _controller.windowId;

  @override
  String get arguments => _controller.arguments;

  @override
  Future<void> invokeMethod(String method, [dynamic arguments]) {
    return _controller.invokeMethod<void>(method, arguments);
  }

  @override
  Future<void> show() => _controller.show();
}
