/// 定义应用操作批次、持久化副作用和稳定汇总结果。
///
/// 批次是一键更新的领域边界；通知和后续副作用只能消费批次摘要，
/// 不得通过全局队列是否为空来推测一次用户操作是否结束。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_operation_target_snapshot.dart';
import 'install_progress.dart';
import 'install_task.dart';

part 'app_operation_batch.freezed.dart';
part 'app_operation_batch.g.dart';

/// 应用操作批次类型。
enum AppOperationBatchKind {
  /// 用户主动触发的一键更新。
  updateAll,
}

/// 应用操作批次状态。
enum AppOperationBatchStatus {
  /// 批次内仍有未进入终态的任务。
  active,

  /// 批次内所有任务均已进入终态。
  completed,
}

/// 批次通知投递状态。
enum AppOperationNotificationState {
  /// 批次尚未结束，不应投递通知。
  notRequested,

  /// 批次已结束，通知等待 Outbox 消费。
  pending,

  /// 平台已接受通知投递请求。
  submitted,

  /// 用户关闭了应用内通知偏好。
  suppressed,

  /// 当前会话不支持或无法使用系统通知。
  unavailable,

  /// 通知投递请求失败。
  failed,
}

/// 持久化副作用类型。
enum AppOperationEffectType {
  /// 单个任务成功，用于同步列表、统计和可选自动运行。
  taskSucceeded,

  /// 一键更新批次完成，用于生成并投递一次系统通知。
  updateBatchCompleted,
}

/// 一键更新批次。
@freezed
sealed class AppOperationBatch with _$AppOperationBatch {
  /// 创建包含固定任务和目标顺序的批次。
  const factory AppOperationBatch({
    /// 稳定批次 ID，同时作为通知替换 ID 的组成部分。
    required String id,

    /// 批次业务类型。
    @Default(AppOperationBatchKind.updateAll) AppOperationBatchKind kind,

    /// 属于该批次的任务 ID，顺序与 [targets] 一致。
    required List<String> taskIds,

    /// 用户点击一键更新时冻结的目标列表。
    required List<AppOperationTargetSnapshot> targets,

    /// 批次创建时间戳。
    required int createdAt,

    /// 批次完成时间戳。
    int? finishedAt,

    /// 当前批次状态。
    @Default(AppOperationBatchStatus.active) AppOperationBatchStatus status,

    /// 系统通知投递状态。
    @Default(AppOperationNotificationState.notRequested)
    AppOperationNotificationState notificationState,
  }) = _AppOperationBatch;

  /// 从持久化 JSON 恢复批次。
  factory AppOperationBatch.fromJson(Map<String, dynamic> json) =>
      _$AppOperationBatchFromJson(json);
}

/// 可恢复的应用操作副作用。
@freezed
sealed class AppOperationEffect with _$AppOperationEffect {
  /// 创建一条按聚合根幂等消费的 Outbox 事件。
  const factory AppOperationEffect({
    /// 稳定事件 ID。
    required String id,

    /// 事件类型。
    required AppOperationEffectType type,

    /// 任务 ID 或批次 ID。
    required String aggregateId,

    /// 事件创建时间戳。
    required int createdAt,

    /// 已执行的投递次数。
    @Default(0) int attemptCount,

    /// 最近一次尝试时间戳。
    int? lastAttemptAt,
  }) = _AppOperationEffect;

  /// 从持久化 JSON 恢复 Outbox 事件。
  factory AppOperationEffect.fromJson(Map<String, dynamic> json) =>
      _$AppOperationEffectFromJson(json);
}

/// 已完成批次的纯计算摘要。
class AppOperationBatchSummary {
  /// 创建已经按原始目标顺序归类的稳定摘要。
  const AppOperationBatchSummary({
    required this.successfulTargets,
    required this.failedTargets,
    required this.cancelledTargets,
    required this.interruptedTargets,
    required this.totalCount,
    required this.finishedAt,
  });

  /// 从批次和任务记录计算摘要。
  ///
  /// 任务缺失、目标数量不一致或仍有非终态任务时抛出 [StateError]，
  /// 防止通知层把不完整状态误报为已完成。
  factory AppOperationBatchSummary.fromBatch({
    required AppOperationBatch batch,
    required Iterable<InstallTask> tasks,
  }) {
    if (batch.taskIds.length != batch.targets.length) {
      throw StateError('批次任务与目标数量不一致');
    }

    final tasksById = <String, InstallTask>{
      for (final task in tasks) task.id: task,
    };
    final successfulTargets = <AppOperationTargetSnapshot>[];
    final failedTargets = <AppOperationTargetSnapshot>[];
    final cancelledTargets = <AppOperationTargetSnapshot>[];
    final interruptedTargets = <AppOperationTargetSnapshot>[];

    for (var index = 0; index < batch.taskIds.length; index++) {
      final task = tasksById[batch.taskIds[index]];
      if (task == null || !task.isCompleted) {
        throw StateError('批次包含缺失或未完成任务');
      }

      final target = batch.targets[index];
      switch (task.status) {
        case InstallStatus.success:
          successfulTargets.add(target);
        case InstallStatus.failed:
          failedTargets.add(target);
        case InstallStatus.cancelled:
          cancelledTargets.add(target);
        case InstallStatus.interrupted:
          interruptedTargets.add(target);
        case InstallStatus.pending:
        case InstallStatus.downloading:
        case InstallStatus.installing:
          throw StateError('批次包含未完成任务');
      }
    }

    return AppOperationBatchSummary(
      successfulTargets: List.unmodifiable(successfulTargets),
      failedTargets: List.unmodifiable(failedTargets),
      cancelledTargets: List.unmodifiable(cancelledTargets),
      interruptedTargets: List.unmodifiable(interruptedTargets),
      totalCount: batch.taskIds.length,
      finishedAt: batch.finishedAt ?? (throw StateError('已完成批次缺少完成时间')),
    );
  }

  /// 成功更新的目标。
  final List<AppOperationTargetSnapshot> successfulTargets;

  /// 执行失败的目标。
  final List<AppOperationTargetSnapshot> failedTargets;

  /// 用户取消的目标。
  final List<AppOperationTargetSnapshot> cancelledTargets;

  /// 无法证明成功的中断目标。
  final List<AppOperationTargetSnapshot> interruptedTargets;

  /// 批次目标总数。
  final int totalCount;

  /// 批次完成时间戳。
  final int finishedAt;
}
