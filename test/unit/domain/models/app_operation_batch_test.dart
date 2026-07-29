import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/domain/models/app_operation_batch.dart';
import 'package:linglong_store/domain/models/app_operation_target_snapshot.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';

void main() {
  group('AppOperationBatchSummary', () {
    test('按批次目标顺序归类成功、失败、取消和中断任务', () {
      const targets = [
        AppOperationTargetSnapshot(
          appId: 'org.example.alpha',
          displayName: 'Alpha',
          installedVersion: '1.0.0',
          expectedVersion: '2.0.0',
        ),
        AppOperationTargetSnapshot(
          appId: 'org.example.beta',
          displayName: 'Beta',
          installedVersion: '1.0.0',
          expectedVersion: '2.0.0',
        ),
        AppOperationTargetSnapshot(
          appId: 'org.example.gamma',
          displayName: 'Gamma',
          installedVersion: '1.0.0',
          expectedVersion: '2.0.0',
        ),
        AppOperationTargetSnapshot(
          appId: 'org.example.delta',
          displayName: 'Delta',
          installedVersion: '1.0.0',
          expectedVersion: '2.0.0',
        ),
      ];
      const batch = AppOperationBatch(
        id: 'batch-1',
        taskIds: ['task-1', 'task-2', 'task-3', 'task-4'],
        targets: targets,
        createdAt: 100,
        finishedAt: 200,
        status: AppOperationBatchStatus.completed,
      );
      final tasks = [
        _task('task-3', targets[2], InstallStatus.cancelled),
        _task('task-1', targets[0], InstallStatus.success),
        _task('task-4', targets[3], InstallStatus.interrupted),
        _task('task-2', targets[1], InstallStatus.failed),
      ];

      final summary = AppOperationBatchSummary.fromBatch(
        batch: batch,
        tasks: tasks,
      );

      expect(summary.successfulTargets, [targets[0]]);
      expect(summary.failedTargets, [targets[1]]);
      expect(summary.cancelledTargets, [targets[2]]);
      expect(summary.interruptedTargets, [targets[3]]);
      expect(summary.totalCount, 4);
      expect(summary.finishedAt, 200);
    });

    test('任务尚未全部进入终态时拒绝生成完成摘要', () {
      const target = AppOperationTargetSnapshot(
        appId: 'org.example.alpha',
        displayName: 'Alpha',
        installedVersion: '1.0.0',
        expectedVersion: '2.0.0',
      );
      const batch = AppOperationBatch(
        id: 'batch-1',
        taskIds: ['task-1'],
        targets: [target],
        createdAt: 100,
      );

      expect(
        () => AppOperationBatchSummary.fromBatch(
          batch: batch,
          tasks: [_task('task-1', target, InstallStatus.installing)],
        ),
        throwsStateError,
      );
    });
  });
}

InstallTask _task(
  String id,
  AppOperationTargetSnapshot target,
  InstallStatus status,
) {
  return InstallTask(
    id: id,
    appId: target.appId,
    appName: target.displayName,
    kind: InstallTaskKind.update,
    target: target,
    status: status,
    createdAt: 100,
  );
}
