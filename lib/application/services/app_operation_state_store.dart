/// 封装应用操作状态的恢复、旧数据迁移和完整快照保存。
///
/// 该服务不依赖 Riverpod，也不决定状态何时发布；它只负责把运行时状态和
/// XDG Journal 之间可靠转换，避免持久化协议散落在队列编排器中。
library;

import '../../core/logging/app_logger.dart';
import '../../domain/models/install_queue_state.dart';
import '../../domain/repositories/app_operation_journal_repository.dart';
import '../../domain/repositories/legacy_app_operation_state_repository.dart';

/// 一次恢复操作返回的内存状态和可选迁移写入。
class AppOperationStateRestoreResult {
  /// 创建恢复结果。
  const AppOperationStateRestoreResult({
    required this.state,
    this.migrationPersistence,
  });

  /// 立即提供给队列的恢复状态。
  final InstallQueueState state;

  /// 旧存储迁移到 Journal 的首次保存；外部动作必须等待它完成。
  final Future<void>? migrationPersistence;
}

/// 应用操作完整状态存储。
class AppOperationStateStore {
  /// 创建存储服务。
  ///
  /// [legacyRepository] 只用于兼容旧队列；新状态始终写入 [journal]。
  const AppOperationStateStore({
    required AppOperationJournalRepository journal,
    LegacyAppOperationStateRepository? legacyRepository,
  }) : _journal = journal,
       _legacyRepository = legacyRepository;

  /// 当前唯一可写的 XDG Journal 端口。
  final AppOperationJournalRepository _journal;

  /// 只在 Journal 不存在时参与一次迁移的旧状态端口。
  final LegacyAppOperationStateRepository? _legacyRepository;

  /// 优先从 Journal 恢复；不存在有效快照时再尝试迁移旧队列。
  AppOperationStateRestoreResult restore() {
    try {
      final snapshot = _journal.load();
      if (snapshot != null) {
        return AppOperationStateRestoreResult(
          state: InstallQueueState.fromJournalSnapshot(snapshot),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error('应用操作 Journal 恢复失败', error, stackTrace);
    }

    final legacyRepository = _legacyRepository;
    if (legacyRepository == null) {
      return const AppOperationStateRestoreResult(state: InstallQueueState());
    }

    try {
      final restoredState = legacyRepository.load();
      if (restoredState.currentTask == null && restoredState.queue.isEmpty) {
        return AppOperationStateRestoreResult(state: restoredState);
      }

      AppLogger.info(
        'Migrating legacy install queue: '
        'current=${restoredState.currentTask?.appId}, '
        'pending=${restoredState.queue.length}',
      );
      final migrationPersistence = _journal
          .save(restoredState.toJournalSnapshot())
          .then((_) async {
            // 只有新 Journal 已落盘才删除旧事实，迁移中断后仍能重试。
            await legacyRepository.clear();
          });
      return AppOperationStateRestoreResult(
        state: restoredState,
        migrationPersistence: migrationPersistence,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to restore persisted install queue state',
        error,
        stackTrace,
      );
      return const AppOperationStateRestoreResult(state: InstallQueueState());
    }
  }

  /// 保存队列、当前任务、历史、批次和 Outbox 的同一完整快照。
  Future<void> save(InstallQueueState state) {
    return _journal.save(state.toJournalSnapshot());
  }
}
