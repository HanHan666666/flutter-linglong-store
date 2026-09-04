import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/generated/application_identity.g.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/system_accent_color.dart';
import 'package:linglong_store/platform/appearance/linux_system_accent_color_gateway.dart';

/// LinuxSystemAccentColorGateway 平台契约测试（docs/48 §12.1）。
///
/// 覆盖：合法事件转换、unavailable 转 null、损坏事件（缺字段/错类型/
/// 越界）拒绝、去重、取消订阅、流错误不产生未处理异步错误、非 Linux
/// 宿主守卫。事件通过 setMockStreamHandler 直接注入 EventChannel。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // 网关在拒绝损坏事件与记录流错误时写入 AppLogger，
    // 未初始化会触发 LateInitializationError。
    await AppLogger.init();
  });

  group('LinuxSystemAccentColorGateway', () {
    late _AccentChannelFixture fixture;

    setUp(() {
      fixture = _AccentChannelFixture(ApplicationIdentity.systemAccentColorChannel);
    });

    tearDown(() {
      fixture.dispose();
    });

    test('合法 RGB 事件转换为 SystemAccentColor', () async {
      final received = await fixture.collect((gateway) {
        gateway.emit(<String, Object>{
          'available': true,
          'red': 255,
          'green': 128,
          'blue': 0,
        });
      });

      expect(received, [
        const SystemAccentColor(red: 255, green: 128, blue: 0),
      ]);
    });

    test('unavailable 事件转换为 null', () async {
      final received = await fixture.collect((gateway) {
        gateway.emit(<String, Object>{'available': false});
      });

      expect(received, [isNull]);
    });

    test('非 Map 事件被拒绝且不影响后续合法事件', () async {
      final received = await fixture.collect((gateway) {
        gateway.emit('not-a-map');
        gateway.emit(<String, Object>{
          'available': true,
          'red': 1,
          'green': 2,
          'blue': 3,
        });
      });

      expect(received, [
        const SystemAccentColor(red: 1, green: 2, blue: 3),
      ]);
    });

    test('缺少 available 字段的事件被拒绝', () async {
      final received = await fixture.collect((gateway) {
        gateway.emit(<String, Object>{
          'red': 1,
          'green': 2,
          'blue': 3,
        });
      });

      expect(received, isEmpty);
    });

    test('available 不是布尔值的事件被拒绝', () async {
      final received = await fixture.collect((gateway) {
        gateway.emit(<String, Object>{
          'available': 1,
          'red': 1,
          'green': 2,
          'blue': 3,
        });
      });

      expect(received, isEmpty);
    });

    test('available 为 true 但缺少任一颜色分量的事件被拒绝', () async {
      final received = await fixture.collect((gateway) {
        gateway.emit(<String, Object>{
          'available': true,
          'green': 2,
          'blue': 3,
        });
      });

      expect(received, isEmpty);
    });

    test('颜色分量类型错误（double、字符串）的事件被拒绝', () async {
      final received = await fixture.collect((gateway) {
        gateway.emit(<String, Object>{
          'available': true,
          'red': 1.5,
          'green': 2,
          'blue': 3,
        });
        gateway.emit(<String, Object>{
          'available': true,
          'red': 1,
          'green': '2',
          'blue': 3,
        });
      });

      expect(received, isEmpty);
    });

    test('颜色分量越界（负数、大于 255）的事件被拒绝', () async {
      final received = await fixture.collect((gateway) {
        gateway.emit(<String, Object>{
          'available': true,
          'red': -1,
          'green': 2,
          'blue': 3,
        });
        gateway.emit(<String, Object>{
          'available': true,
          'red': 1,
          'green': 256,
          'blue': 3,
        });
      });

      expect(received, isEmpty);
    });

    test('连续相同事件去重，包括 null', () async {
      final received = await fixture.collect((gateway) {
        gateway.emit(<String, Object>{
          'available': true,
          'red': 10,
          'green': 20,
          'blue': 30,
        });
        gateway.emit(<String, Object>{
          'available': true,
          'red': 10,
          'green': 20,
          'blue': 30,
        });
        gateway.emit(<String, Object>{'available': false});
        gateway.emit(<String, Object>{'available': false});
        gateway.emit(<String, Object>{
          'available': true,
          'red': 10,
          'green': 20,
          'blue': 30,
        });
      });

      expect(received, [
        const SystemAccentColor(red: 10, green: 20, blue: 30),
        isNull,
        const SystemAccentColor(red: 10, green: 20, blue: 30),
      ]);
    });

    test('取消订阅后流结束且不再接收事件', () async {
      final gateway = fixture.createGateway();
      final received = <Object?>[];

      final subscription = gateway.watchAccentColor().listen(received.add);
      await pumpEventQueue();

      await subscription.cancel();
      fixture.emit(<String, Object>{
        'available': true,
        'red': 1,
        'green': 2,
        'blue': 3,
      });
      await pumpEventQueue();

      expect(received, isEmpty, reason: '取消订阅后事件不得再进入已结束的流');
    });

    test('平台流错误不产生未处理异步错误，且流保持存活', () async {
      final unhandled = <Object>[];
      final received = <Object?>[];

      await runZonedGuarded(() async {
        final gateway = fixture.createGateway();
        // 网关链路内的 handleError 会吞掉流错误，订阅本身不挂 onError，
        // 未处理错误只能经 zone 冒泡，由外层收集断言。
        final subscription = gateway.watchAccentColor().listen(received.add);
        addTearDown(subscription.cancel);
        await pumpEventQueue();

        fixture.emitError(code: 'send_error', message: '通道发送失败');
        await pumpEventQueue();

        // 错误之后流必须仍然存活并能继续接收事件。
        fixture.emit(<String, Object>{
          'available': true,
          'red': 5,
          'green': 6,
          'blue': 7,
        });
        await pumpEventQueue();
      }, (Object error, StackTrace stackTrace) {
        unhandled.add(error);
      });

      expect(
        unhandled,
        isEmpty,
        reason: '流错误必须由网关记录并吞掉，不能成为未处理异步错误',
      );
      expect(received, [
        const SystemAccentColor(red: 5, green: 6, blue: 7),
      ]);
    });

    test('非 Linux 宿主直接发出一次 null', () async {
      final gateway = LinuxSystemAccentColorGateway(isLinux: () => false);
      final received = <Object?>[];
      final done = Completer<void>();
      final subscription = gateway.watchAccentColor().listen(
        received.add,
        onDone: done.complete,
      );
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      expect(received, [isNull]);
    });

    test('重复调用 watchAccentColor 的流各自独立可用', () async {
      // EventChannel 的 Dart 实现为单订阅语义：同一通道上后一次 listen
      // 会接管事件分发，因此这里验证串行独立可用（先取消再重新监听），
      // 与「根应用是唯一长期订阅者」的生产形态一致（docs/48 §7.3）。
      final gateway = fixture.createGateway();
      final first = <Object?>[];
      final second = <Object?>[];
      final secondEvent = Completer<void>();

      final subscriptionA = gateway.watchAccentColor().listen(first.add);
      await pumpEventQueue();
      await subscriptionA.cancel();
      await pumpEventQueue();

      final subscriptionB = gateway.watchAccentColor().listen((event) {
        second.add(event);
        if (!secondEvent.isCompleted) {
          secondEvent.complete();
        }
      });
      addTearDown(subscriptionB.cancel);
      await pumpEventQueue();

      fixture.emit(<String, Object>{
        'available': true,
        'red': 8,
        'green': 9,
        'blue': 10,
      });
      await secondEvent.future.timeout(const Duration(seconds: 1));
      await pumpEventQueue();

      expect(first, isEmpty, reason: '已取消的旧流不得再收到事件');
      expect(second, [const SystemAccentColor(red: 8, green: 9, blue: 10)]);
    });
  });
}

/// EventChannel mock 夹具：注册 mock stream handler 并提供事件注入口。
///
/// dispose 必须移除 handler，避免跨用例泄漏。
class _AccentChannelFixture {
  _AccentChannelFixture(String channelName)
      : _channel = EventChannel(channelName) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          _channel,
          MockStreamHandler.inline(
            onListen: (Object? arguments, MockStreamHandlerEventSink sink) {
              _sink = sink;
            },
            onCancel: (Object? arguments) {
              _sink = null;
            },
          ),
        );
  }

  final EventChannel _channel;
  MockStreamHandlerEventSink? _sink;

  /// 创建监听真实 mock 通道的网关。
  LinuxSystemAccentColorGateway createGateway() =>
      const LinuxSystemAccentColorGateway();

  /// 注入一条通道事件。
  void emit(Object? event) => _sink?.success(event);

  /// 注入一条通道流错误（异步派发，测试侧用 pumpEventQueue 等待）。
  void emitError({required String code, required String message}) {
    _sink?.error(code: code, message: message);
  }

  /// 订阅网关流、依次注入事件并收集输出。
  Future<List<Object?>> collect(
    void Function(_AccentChannelFixture fixture) emitEvents,
  ) async {
    final gateway = createGateway();
    final received = <Object?>[];
    final subscription = gateway.watchAccentColor().listen(received.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    emitEvents(this);
    await pumpEventQueue();

    return received;
  }

  void dispose() {
    _sink = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(_channel, null);
  }
}
