/// 验证 latest-wins 写入队列的合并、等待和失败隔离语义。
///
/// 这些语义直接决定应用操作 Journal 会不会重新形成无界积压，以及调用方能否
/// 安全地把 enqueue Future 当作持久化屏障。
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/data/persistence/latest_value_write_queue.dart';

void main() {
  test('正在写入时只保留最新等待值并让被覆盖调用方共同等待', () async {
    final firstWriteStarted = Completer<void>();
    final releaseFirstWrite = Completer<void>();
    final writtenValues = <int>[];
    final queue = LatestValueWriteQueue<int>((value) async {
      writtenValues.add(value);
      if (value == 1) {
        firstWriteStarted.complete();
        await releaseFirstWrite.future;
      }
    });

    final first = queue.enqueue(1);
    await firstWriteStarted.future;
    final replaced = queue.enqueue(2);
    final latest = queue.enqueue(3);
    var replacedCompleted = false;
    replaced.then((_) => replacedCompleted = true);

    await Future<void>.delayed(Duration.zero);
    expect(replacedCompleted, isFalse);

    releaseFirstWrite.complete();
    await Future.wait([first, replaced, latest]);

    expect(writtenValues, [1, 3]);
    expect(replacedCompleted, isTrue);
  });

  test('当前写入失败不会阻断更新等待值', () async {
    final firstWriteStarted = Completer<void>();
    final releaseFirstWrite = Completer<void>();
    final writtenValues = <int>[];
    final queue = LatestValueWriteQueue<int>((value) async {
      writtenValues.add(value);
      if (value == 1) {
        firstWriteStarted.complete();
        await releaseFirstWrite.future;
        throw StateError('模拟写入失败');
      }
    });

    final failedWrite = queue.enqueue(1);
    final failureExpectation = expectLater(failedWrite, throwsStateError);
    await firstWriteStarted.future;
    final newerWrite = queue.enqueue(2);

    releaseFirstWrite.complete();
    await failureExpectation;
    await newerWrite;

    expect(writtenValues, [1, 2]);
  });
}
