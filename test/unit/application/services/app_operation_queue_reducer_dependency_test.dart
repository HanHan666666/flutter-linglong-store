/// 验证依赖观察事实只由队列 reducer 归并，不影响父任务进度和任务计数。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/app_operation_queue_reducer.dart';
import 'package:linglong_store/domain/models/app_operation_failure.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/install_task.dart';

void main() {
  test(
    'tracks only observed dependencies and clears active on parent or terminal',
    () {
      const reducer = AppOperationQueueReducer();
      var state = const InstallQueueState(
        currentTask: InstallTask(
          id: 'task-1',
          appId: 'org.example.app',
          appName: 'Example',
          status: InstallStatus.installing,
          createdAt: 1,
        ),
        isProcessing: true,
      );

      InstallQueueState apply(
        String? packageId, {
        InstallStatus status = InstallStatus.installing,
      }) {
        return reducer.applyProgress(
          state: state,
          taskId: 'task-1',
          progress: InstallProgress(
            appId: 'org.example.app',
            status: status,
            progress: 0.42,
            processingPackageId: packageId,
          ),
        );
      }

      state = apply('org.deepin.base');
      expect(state.currentTask!.observedDependencyIds, ['org.deepin.base']);
      expect(state.currentTask!.activeDependencyId, 'org.deepin.base');
      expect(state.currentTask!.currentProcessingPackageId, 'org.deepin.base');

      state = apply('org.deepin.runtime.dtk');
      state = apply('org.deepin.runtime.dtk');
      expect(state.currentTask!.observedDependencyIds, [
        'org.deepin.base',
        'org.deepin.runtime.dtk',
      ]);
      expect(state.currentTask!.activeDependencyId, 'org.deepin.runtime.dtk');
      expect(
        state.currentTask!.currentProcessingPackageId,
        'org.deepin.runtime.dtk',
      );

      // 泛化消息不应凭空切换身份；明确的后处理阶段才结束当前依赖展示。
      state = apply(null);
      expect(state.currentTask!.activeDependencyId, 'org.deepin.runtime.dtk');
      expect(
        state.currentTask!.currentProcessingPackageId,
        'org.deepin.runtime.dtk',
      );
      state = reducer.applyProgress(
        state: state,
        taskId: 'task-1',
        progress: const InstallProgress(
          appId: 'org.example.app',
          status: InstallStatus.installing,
          messageCode: AppOperationMessageCode.postProcessing,
        ),
      );
      expect(state.currentTask!.activeDependencyId, isNull);
      expect(state.currentTask!.currentProcessingPackageId, isNull);

      state = apply('org.example.app');
      expect(state.currentTask!.activeDependencyId, isNull);
      expect(state.currentTask!.currentProcessingPackageId, 'org.example.app');
      expect(state.currentTask!.observedDependencyIds, hasLength(2));

      state = apply(null, status: InstallStatus.success);
      expect(state.currentTask!.activeDependencyId, isNull);
      expect(state.currentTask!.currentProcessingPackageId, isNull);
      expect(state.currentTask!.progress, 0.42);
      expect(state.queue, isEmpty);
    },
  );

  test(
    'shows parent package identity only after ll-cli explicitly reports it',
    () {
      const reducer = AppOperationQueueReducer();
      var state = const InstallQueueState(
        currentTask: InstallTask(
          id: 'task-2',
          appId: 'org.deepin.mail',
          appName: '邮箱',
          createdAt: 1,
        ),
      );

      expect(state.currentTask!.currentProcessingPackageId, isNull);
      state = reducer.applyProgress(
        state: state,
        taskId: 'task-2',
        progress: const InstallProgress(
          appId: 'org.deepin.mail',
          status: InstallStatus.installing,
          processingPackageId: 'org.deepin.mail',
        ),
      );

      expect(state.currentTask!.currentProcessingPackageId, 'org.deepin.mail');
      expect(state.currentTask!.observedDependencyIds, isEmpty);
    },
  );
}
