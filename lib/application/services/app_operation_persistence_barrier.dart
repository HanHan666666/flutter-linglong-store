/// 协调应用操作内存状态与持久化状态的先后关系。
///
/// UI 状态可以立即发布，但启动外部命令和消费 Outbox 前必须确认观察到的最新
/// Journal 保存已经完成，避免不可逆副作用领先于可恢复事实。
library;

/// 跟踪最近一次 Journal 保存并提供稳定持久化屏障。
class AppOperationPersistenceBarrier {
  /// 当前观察到的最新保存；初始状态表示无需等待。
  Future<void> _latestPersistence = Future<void>.value();

  /// 记录一次新的完整快照保存。
  void track(Future<void> persistence) {
    _latestPersistence = persistence;
  }

  /// 等到调用期间观察到的所有更新保存完成。
  ///
  /// 等待旧保存期间若出现更新保存，会继续等待更新值；只有当前最新保存失败时才
  /// 向调用方抛出错误，已经被更新快照覆盖的旧失败不会错误阻断后续操作。
  Future<void> waitForLatest() async {
    while (true) {
      final observedPersistence = _latestPersistence;
      try {
        await observedPersistence;
      } catch (error, stackTrace) {
        if (identical(observedPersistence, _latestPersistence)) {
          Error.throwWithStackTrace(error, stackTrace);
        }
      }

      if (identical(observedPersistence, _latestPersistence)) {
        return;
      }
    }
  }
}
