import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/system_accent_color_provider.dart';
import 'package:linglong_store/domain/models/system_accent_color.dart';
import 'package:linglong_store/domain/repositories/system_accent_color_gateway.dart';

/// systemAccentColorProvider 订阅生命周期测试（docs/48 §7.3/§12.2）。
///
/// 覆盖：Fake Gateway 推送颜色后 Provider 发射、null 透传、流错误后
/// Provider 存活且 valueOrNull 为 null、全程不写任何持久化存储。
void main() {
  group('systemAccentColorProvider', () {
    test('Fake Gateway 推送颜色后 Provider 发射该颜色', () async {
      final controller = StreamController<SystemAccentColor?>();
      addTearDown(controller.close);
      final container = _createContainer(_FakeAccentColorGateway(controller.stream));
      addTearDown(container.dispose);

      // 订阅建立后 Provider 处于 loading，主题层此时回退品牌蓝。
      final initial = container.read(systemAccentColorProvider);
      expect(initial.isLoading, isTrue);
      expect(initial.value, isNull);

      controller.add(const SystemAccentColor(red: 255, green: 128, blue: 0));
      await pumpEventQueue();

      final state = container.read(systemAccentColorProvider);
      expect(state.value,
          const SystemAccentColor(red: 255, green: 128, blue: 0));
      expect(state.hasError, isFalse);
    });

    test('不可用事件以 null 透传', () async {
      final controller = StreamController<SystemAccentColor?>();
      addTearDown(controller.close);
      final container = _createContainer(_FakeAccentColorGateway(controller.stream));
      addTearDown(container.dispose);

      controller.add(null);
      await pumpEventQueue();

      final state = container.read(systemAccentColorProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, isNull);
    });

    test('流错误后 Provider 存活且 valueOrNull 为 null', () async {
      final controller = StreamController<SystemAccentColor?>();
      addTearDown(controller.close);
      final container = _createContainer(_FakeAccentColorGateway(controller.stream));
      addTearDown(container.dispose);

      controller.addError(StateError('通道契约异常'));
      await pumpEventQueue();

      final state = container.read(systemAccentColorProvider);
      // Provider 本身未销毁：错误状态可被读取，主题层据此回退品牌蓝。
      expect(container.read(systemAccentColorProvider).hasError, isTrue);
      expect(state.value, isNull);

      // 错误后流继续发射仍能更新状态（Gateway 生产实现会吞掉错误，
      // 这里验证 Provider 侧不会因错误终结订阅）。
      controller.add(const SystemAccentColor(red: 1, green: 2, blue: 3));
      await pumpEventQueue();

      expect(
        container.read(systemAccentColorProvider).value,
        const SystemAccentColor(red: 1, green: 2, blue: 3),
      );
    });

    test('订阅与事件全程不写任何持久化偏好', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getKeys(), isEmpty,
          reason: '用例前置：mock 存储必须为空');

      final controller = StreamController<SystemAccentColor?>();
      addTearDown(controller.close);
      final container = _createContainer(_FakeAccentColorGateway(controller.stream));
      addTearDown(container.dispose);

      controller
        ..add(const SystemAccentColor(red: 9, green: 8, blue: 7))
        ..add(null);
      await pumpEventQueue();
      await pumpEventQueue();

      // 强调色是运行时系统状态（docs/48 §7.3），禁止落到 SharedPreferences。
      expect(preferences.getKeys(), isEmpty);
    });
  });
}

/// 创建注入 Fake Gateway 的容器。
ProviderContainer _createContainer(SystemAccentColorGateway gateway) {
  final container = ProviderContainer(
    overrides: [
      systemAccentColorGatewayProvider.overrideWithValue(gateway),
    ],
  );
  // Riverpod 3 在 provider 无监听者时会暂停内部流订阅，container.read
  // 不构成持续监听；测试必须显式挂一个监听者驱动状态更新。
  container.listen(systemAccentColorProvider, (_, _) {});
  return container;
}

/// 私有 Fake Gateway：直接转发注入的流，不触达平台通道。
class _FakeAccentColorGateway implements SystemAccentColorGateway {
  _FakeAccentColorGateway(this._stream);

  final Stream<SystemAccentColor?> _stream;

  @override
  Stream<SystemAccentColor?> watchAccentColor() => _stream;
}
