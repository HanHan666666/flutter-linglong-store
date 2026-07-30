/// 验证应用操作持久化屏障会追踪等待期间出现的更新保存。
///
/// 该边界保护 ll-cli 启动和 Outbox 消费顺序，不测试与它无关的 UI 行为。
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/app_operation_persistence_barrier.dart';

void main() {
  test('等待旧保存期间出现更新保存时会继续等待最新值', () async {
    final firstPersistence = Completer<void>();
    final latestPersistence = Completer<void>();
    final barrier = AppOperationPersistenceBarrier()
      ..track(firstPersistence.future);

    var barrierCompleted = false;
    final waiting = barrier.waitForLatest().then(
      (_) => barrierCompleted = true,
    );
    barrier.track(latestPersistence.future);
    firstPersistence.complete();

    await Future<void>.delayed(Duration.zero);
    expect(barrierCompleted, isFalse);

    latestPersistence.complete();
    await waiting;
    expect(barrierCompleted, isTrue);
  });

  test('最新保存失败时向关键动作传播错误', () async {
    final barrier = AppOperationPersistenceBarrier()
      ..track(Future<void>.error(StateError('模拟持久化失败')));

    await expectLater(barrier.waitForLatest(), throwsStateError);
  });
}
