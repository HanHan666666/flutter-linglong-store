/// 为覆盖式持久化场景提供有界的 latest-wins 异步写入队列。
///
/// Journal 只关心最新可恢复状态，不需要把尚未开始写入的每个中间进度逐一落盘。
/// 该队列把积压限制为一个正在写入的值和一个等待写入的最新值。
library;

import 'dart:async';

/// 实际执行单个值持久化的异步函数。
typedef AsyncValueWriter<T> = Future<void> Function(T value);

/// 只保留最新等待值的串行写入队列。
///
/// [enqueue] 返回的 Future 会在传入值或覆盖它的更新值成功写入后完成，因此调用方
/// 仍可把它作为持久化屏障。已经开始的写入不会被中断，写入失败也不会阻断后续值。
class LatestValueWriteQueue<T> {
  /// 使用实际写入函数创建队列。
  LatestValueWriteQueue(this._writer);

  /// 由持久化实现提供的单次写入函数。
  final AsyncValueWriter<T> _writer;

  /// 尚未开始写入的最新值和共享该值结果的等待者。
  _PendingWrite<T>? _pendingWrite;

  /// 防止并发启动多个 drain 循环。
  bool _isDraining = false;

  /// 排队保存一个值。
  ///
  /// drain 开始前或已有写入进行期间到达的多个值会合并到同一个等待槽；被覆盖值
  /// 的调用方会等待最终保留下来的最新值写入完成。
  Future<void> enqueue(T value) {
    final completer = Completer<void>();
    final pendingWrite = _pendingWrite;
    _pendingWrite = pendingWrite == null
        ? _PendingWrite<T>(value: value, waiters: [completer])
        : _PendingWrite<T>(
            value: value,
            waiters: [...pendingWrite.waiters, completer],
          );

    if (!_isDraining) {
      _isDraining = true;
      // 让 enqueue 先把 Future 返回给调用方，也让同一同步调用栈内的连续状态更新
      // 有机会在第一次编码和 IO 前直接合并。
      scheduleMicrotask(_drain);
    }
    return completer.future;
  }

  /// 严格串行写入当前等待槽，并在每轮开始时取走最新值。
  Future<void> _drain() async {
    try {
      while (true) {
        final pendingWrite = _pendingWrite;
        if (pendingWrite == null) {
          break;
        }
        _pendingWrite = null;
        try {
          await _writer(pendingWrite.value);
          for (final waiter in pendingWrite.waiters) {
            waiter.complete();
          }
        } catch (error, stackTrace) {
          // 当前写入失败只影响由它覆盖的请求；下一轮仍会尝试更新的等待值。
          for (final waiter in pendingWrite.waiters) {
            waiter.completeError(error, stackTrace);
          }
        }
      }
    } finally {
      _isDraining = false;
      // 当前 isolate 不会在 while 判空和 finally 之间抢占执行；这里仍保留兜底，
      // 防止未来实现调整后出现等待值无人消费。
      if (_pendingWrite != null && !_isDraining) {
        _isDraining = true;
        scheduleMicrotask(_drain);
      }
    }
  }
}

/// 一轮尚未开始的写入及其所有调用方。
class _PendingWrite<T> {
  /// 创建等待写入记录。
  const _PendingWrite({required this.value, required this.waiters});

  /// 最后一次入队的值。
  final T value;

  /// 等待该值或更新值完成持久化的调用方。
  final List<Completer<void>> waiters;
}
