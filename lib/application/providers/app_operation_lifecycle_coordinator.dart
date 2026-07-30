/// 统一消费安装、更新及一键更新批次完成后的持久化副作用。
///
/// 该协调器在启动恢复结束后常驻 Application 层，替代 Widget 对队列状态的
/// 瞬时监听。列表同步、统计、自动运行和系统通知因此不再依赖某个页面是否挂载。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart'
    show analyticsRepositoryProvider, currentLocaleProvider;
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/models/app_operation_batch.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_queue_state.dart';
import '../../domain/models/install_task.dart';
import '../../domain/models/system_notification.dart';
import '../../domain/repositories/system_notification_gateway.dart';
import '../../platform/notifications/linux_system_notification_gateway.dart';
import '../services/update_batch_notification_policy.dart';
import 'app_collection_sync_provider.dart';
import 'global_provider.dart';
import 'install_queue_provider.dart';
import 'update_apps_provider.dart';

/// 系统通知平台边界 Provider，测试和未来沙箱实现可以整体替换。
final systemNotificationGatewayProvider = Provider<SystemNotificationGateway>((
  ref,
) {
  return const LinuxSystemNotificationGateway();
});

/// 一键更新通知内容策略 Provider。
final updateBatchNotificationPolicyProvider =
    Provider<UpdateBatchNotificationPolicy>((ref) {
      return const UpdateBatchNotificationPolicy();
    });

/// 应用操作生命周期协调器 Provider。
///
/// 普通 Provider 不自动释放；启动流程读取一次后即可持续监听队列 Outbox。
final appOperationLifecycleCoordinatorProvider =
    Provider<AppOperationLifecycleCoordinator>((ref) {
      final coordinator = AppOperationLifecycleCoordinator(ref);
      coordinator.start();
      return coordinator;
    });

/// 应用操作生命周期协调器。
class AppOperationLifecycleCoordinator {
  /// 创建协调器；调用方随后必须调用 [start]。
  AppOperationLifecycleCoordinator(this._ref);

  final Ref _ref;

  /// 防止 Provider 连续变更时启动多个并发消费者。
  bool _isDraining = false;

  /// 启动队列 Outbox 监听。
  void start() {
    _ref.listen<InstallQueueState>(installQueueProvider, (previous, next) {
      if (next.outbox.isNotEmpty) {
        _scheduleDrain();
      }
    }, fireImmediately: true);
  }

  /// 把消费延迟到当前 Provider 更新完成后，避免在监听回调中同步改写源状态。
  void _scheduleDrain() {
    if (_isDraining) {
      return;
    }
    Future.microtask(_drain);
  }

  /// 严格按 Journal 顺序消费事件；单条失败不得阻断后续批次通知。
  Future<void> _drain() async {
    if (_isDraining) {
      return;
    }
    _isDraining = true;
    try {
      while (true) {
        final queueNotifier = _ref.read(installQueueProvider.notifier);
        // Outbox 事件、上一次确认结果和等待期间产生的更新必须先成为 durable
        // state，再决定是否执行下一个不可逆副作用。
        await queueNotifier.waitForPendingPersistence();
        final queueState = _ref.read(installQueueProvider);
        if (queueState.outbox.isEmpty) {
          break;
        }

        final effect = queueState.outbox.first;
        queueNotifier.markEffectAttempt(effect.id);
        // 尝试次数与事件本身属于同一 Journal 协议；记录成功后才允许对外执行。
        await queueNotifier.waitForPendingPersistence();

        switch (effect.type) {
          case AppOperationEffectType.taskSucceeded:
            await _consumeTaskSucceeded(effect.id, effect.aggregateId);
          case AppOperationEffectType.updateBatchCompleted:
            await _consumeUpdateBatchCompleted(effect.id, effect.aggregateId);
        }
      }
    } catch (error, stackTrace) {
      // 协调器本身的未知错误只结束本轮；后续队列变更或下次启动会继续消费。
      AppLogger.error('应用操作副作用消费异常', error, stackTrace);
    } finally {
      _isDraining = false;
    }
  }

  /// 消费单任务成功事件。
  ///
  /// 各副作用相互隔离：刷新失败不能吞掉统计或自动运行，任一失败也不能让同一
  /// 事件永久占据 Outbox。任务事实已经成功，外围副作用只做尽力执行。
  Future<void> _consumeTaskSucceeded(String effectId, String taskId) async {
    final task = _ref
        .read(installQueueProvider)
        .history
        .where((item) => item.id == taskId)
        .firstOrNull;
    if (task == null || task.status != InstallStatus.success) {
      AppLogger.warning('成功任务副作用缺少有效任务记录: $taskId');
      _ref.read(installQueueProvider.notifier).acknowledgeEffect(effectId);
      return;
    }

    // 先乐观移除过时更新项，完整同步在后台提供最终一致性。
    _ref.read(updateAppsProvider.notifier).removeApp(task.appId);

    if (task.batchId == null) {
      await _syncAppCollections('同步应用集合失败: ${task.appId}');
    }
    await _runBestEffort(
      '上报安装或更新统计失败: ${task.appId}',
      () => _ref
          .read(analyticsRepositoryProvider)
          .reportInstall(
            task.appId,
            task.version ?? task.target?.expectedVersion ?? 'unknown',
            appName: task.appName,
          ),
    );

    final preferences = _ref.read(globalAppProvider).userPreferences;
    if (preferences.autoRunAfterInstall &&
        task.kind == InstallTaskKind.install) {
      await _runBestEffort(
        '安装完成后自动启动失败: ${task.appId}',
        () => _ref.read(linglongCliRepositoryProvider).runApp(task.appId),
      );
    }

    _ref.read(installQueueProvider.notifier).acknowledgeEffect(effectId);
  }

  /// 消费一键更新批次完成事件并确认其通知结果。
  Future<void> _consumeUpdateBatchCompleted(
    String effectId,
    String batchId,
  ) async {
    final queueState = _ref.read(installQueueProvider);
    final batch = queueState.batches
        .where((item) => item.id == batchId)
        .firstOrNull;
    if (batch == null || batch.status != AppOperationBatchStatus.completed) {
      AppLogger.warning('批次完成副作用缺少有效批次记录: $batchId');
      _ref.read(installQueueProvider.notifier).acknowledgeEffect(effectId);
      return;
    }

    final queueNotifier = _ref.read(installQueueProvider.notifier);
    if (!_ref.read(globalAppProvider).userPreferences.enableNotifications) {
      await _syncAppCollections('一键更新结束后同步应用集合失败: $batchId');
      queueNotifier.acknowledgeEffect(
        effectId,
        notificationState: AppOperationNotificationState.suppressed,
      );
      return;
    }

    try {
      // 批次内每项只做乐观移除，所有任务结束后统一完整同步一次，
      // 避免 N 个更新产生 N 轮已安装列表和远端更新检查。
      await _syncAppCollections('一键更新结束后同步应用集合失败: $batchId');
      final summary = queueState.summarizeBatch(batchId);
      final l10n = lookupAppLocalizations(_ref.read(currentLocaleProvider));
      final message = _ref
          .read(updateBatchNotificationPolicyProvider)
          .format(batch: batch, summary: summary, l10n: l10n);
      final submission = await _ref
          .read(systemNotificationGatewayProvider)
          .submit(message);
      final notificationState = _mapNotificationState(submission.status);
      queueNotifier.acknowledgeEffect(
        effectId,
        notificationState: notificationState,
      );
      AppLogger.info(
        '一键更新系统通知处理完成: batch=$batchId, '
        'status=${submission.status.name}, '
        'diagnostic=${submission.diagnosticCode ?? '-'}',
      );
    } catch (error, stackTrace) {
      // 格式化或平台边界的未知错误也必须确认事件，防止每次启动重复轰炸用户。
      AppLogger.error('一键更新系统通知处理失败: $batchId', error, stackTrace);
      queueNotifier.acknowledgeEffect(
        effectId,
        notificationState: AppOperationNotificationState.failed,
      );
    }
  }

  /// 把平台投递结果收敛为批次诊断状态。
  AppOperationNotificationState _mapNotificationState(
    SystemNotificationSubmissionStatus status,
  ) {
    return switch (status) {
      SystemNotificationSubmissionStatus.submitted =>
        AppOperationNotificationState.submitted,
      SystemNotificationSubmissionStatus.unsupported ||
      SystemNotificationSubmissionStatus.unavailable =>
        AppOperationNotificationState.unavailable,
      SystemNotificationSubmissionStatus.rejected ||
      SystemNotificationSubmissionStatus.failed =>
        AppOperationNotificationState.failed,
    };
  }

  /// 执行一个不改变任务结果的外围副作用。
  Future<void> _runBestEffort(
    String diagnosticMessage,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } catch (error, stackTrace) {
      AppLogger.warning(diagnosticMessage, error, stackTrace);
    }
  }

  /// 通过唯一同步服务刷新已安装列表和待更新列表。
  Future<void> _syncAppCollections(String diagnosticMessage) {
    return _runBestEffort(
      diagnosticMessage,
      () => _ref
          .read(appCollectionSyncServiceProvider)
          .syncAfterSuccessfulOperation(),
    );
  }
}
