/// 验证一键更新完成事件不会重复通知，并且遵守用户通知偏好。
///
/// 这里只覆盖跨 Journal、协调器和通知网关的关键业务边界；通知文案细节和
/// Flutter Widget 展示不在此重复测试。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_operation_lifecycle_coordinator.dart';
import 'package:linglong_store/application/providers/global_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/app_operation_batch.dart';
import 'package:linglong_store/domain/models/app_operation_journal_snapshot.dart';
import 'package:linglong_store/domain/models/app_operation_target_snapshot.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/system_notification.dart';
import 'package:linglong_store/domain/repositories/system_notification_gateway.dart';

import '../../../helpers/memory_app_operation_journal_repository.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  test('完成批次只投递一次系统通知并确认 Outbox', () async {
    final gateway = _RecordingNotificationGateway();
    final container = _createContainer(
      enableNotifications: true,
      gateway: gateway,
    );
    addTearDown(container.dispose);

    container.read(appOperationLifecycleCoordinatorProvider);
    await _waitForOutboxToDrain(container);

    final state = container.read(installQueueProvider);
    expect(gateway.messages, hasLength(1));
    expect(gateway.messages.single.body, contains('示例应用'));
    expect(state.outbox, isEmpty);
    expect(
      state.batches.single.notificationState,
      AppOperationNotificationState.submitted,
    );

    // 重复读取协调器和等待事件循环不得再次投递已经确认的事件。
    container.read(appOperationLifecycleCoordinatorProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(gateway.messages, hasLength(1));
  });

  test('关闭通知偏好时消费事件但不调用系统网关', () async {
    final gateway = _RecordingNotificationGateway();
    final container = _createContainer(
      enableNotifications: false,
      gateway: gateway,
    );
    addTearDown(container.dispose);

    container.read(appOperationLifecycleCoordinatorProvider);
    await _waitForOutboxToDrain(container);

    final state = container.read(installQueueProvider);
    expect(gateway.messages, isEmpty);
    expect(state.outbox, isEmpty);
    expect(
      state.batches.single.notificationState,
      AppOperationNotificationState.suppressed,
    );
  });
}

/// 创建包含一个已完成批次和一条待消费事件的隔离容器。
ProviderContainer _createContainer({
  required bool enableNotifications,
  required SystemNotificationGateway gateway,
}) {
  const target = AppOperationTargetSnapshot(
    appId: 'com.example.demo',
    displayName: '示例应用',
    installedVersion: '1.0.0',
    expectedVersion: '2.0.0',
  );
  const task = InstallTask(
    id: 'task-1',
    batchId: 'batch-1',
    kind: InstallTaskKind.update,
    appId: 'com.example.demo',
    appName: '示例应用',
    version: '2.0.0',
    target: target,
    status: InstallStatus.success,
    createdAt: 1,
    finishedAt: 2,
  );
  const batch = AppOperationBatch(
    id: 'batch-1',
    taskIds: ['task-1'],
    targets: [target],
    createdAt: 1,
    finishedAt: 2,
    status: AppOperationBatchStatus.completed,
    notificationState: AppOperationNotificationState.pending,
  );
  const snapshot = AppOperationJournalSnapshot(
    history: [task],
    batches: [batch],
    outbox: [
      AppOperationEffect(
        id: 'update-batch-completed-batch-1',
        type: AppOperationEffectType.updateBatchCompleted,
        aggregateId: 'batch-1',
        createdAt: 2,
      ),
    ],
  );

  return ProviderContainer(
    overrides: [
      appOperationJournalRepositoryProvider.overrideWithValue(
        MemoryAppOperationJournalRepository(snapshot),
      ),
      globalAppProvider.overrideWith(
        () => _TestGlobalApp(
          GlobalAppState(
            userPreferences: UserPreferences(
              enableNotifications: enableNotifications,
            ),
          ),
        ),
      ),
      installedAppsProvider.overrideWith(_TestInstalledApps.new),
      updateAppsProvider.overrideWith(_TestUpdateApps.new),
      systemNotificationGatewayProvider.overrideWithValue(gateway),
    ],
  );
}

/// 等待协调器确认当前快照中的唯一事件。
Future<void> _waitForOutboxToDrain(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (container.read(installQueueProvider).outbox.isEmpty) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('协调器未在预期时间内确认 Outbox');
}

/// 记录平台网关实际接收的消息。
class _RecordingNotificationGateway implements SystemNotificationGateway {
  /// 已经提交到伪平台边界的消息。
  final List<SystemNotificationMessage> messages = [];

  @override
  Future<SystemNotificationSubmission> submit(
    SystemNotificationMessage message,
  ) async {
    messages.add(message);
    return const SystemNotificationSubmission(
      status: SystemNotificationSubmissionStatus.submitted,
    );
  }
}

/// 提供固定用户偏好的全局状态。
class _TestGlobalApp extends GlobalApp {
  /// 使用固定状态创建测试 Notifier。
  _TestGlobalApp(this.initialState);

  /// 测试需要的初始全局状态。
  final GlobalAppState initialState;

  @override
  GlobalAppState build() => initialState;
}

/// 避免关键协调器验证触发真实 ll-cli 已安装列表查询。
class _TestInstalledApps extends InstalledApps {
  @override
  InstalledAppsState build() => const InstalledAppsState();

  @override
  Future<void> refresh() async {}
}

/// 避免关键协调器验证触发真实远端更新检查。
class _TestUpdateApps extends UpdateApps {
  @override
  UpdateAppsState build() => const UpdateAppsState();

  @override
  Future<void> checkUpdates() async {}
}
