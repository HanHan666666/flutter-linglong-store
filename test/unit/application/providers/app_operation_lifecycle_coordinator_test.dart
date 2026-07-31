/// 验证一键更新完成事件不会重复通知，并且遵守用户通知偏好。
///
/// 这里只覆盖跨 Journal、协调器和通知网关的关键业务边界；通知文案细节和
/// Flutter Widget 展示不在此重复测试。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
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
import 'package:linglong_store/domain/repositories/app_operation_journal_repository.dart';

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

  test('俄语环境使用俄语生成批次完成系统通知', () async {
    final gateway = _RecordingNotificationGateway();
    final container = _createContainer(
      enableNotifications: true,
      gateway: gateway,
      locale: const Locale('ru'),
    );
    addTearDown(container.dispose);

    container.read(appOperationLifecycleCoordinatorProvider);
    await _waitForOutboxToDrain(container);

    expect(gateway.messages, hasLength(1));
    expect(gateway.messages.single.title, 'Обновлено 1 приложение');
    expect(gateway.messages.single.body, 'Обновлено: 示例应用.');
  });

  test('Outbox 尝试记录落盘前不会调用系统网关', () async {
    final gateway = _RecordingNotificationGateway();
    final journal = _BlockingJournalRepository(_completedBatchSnapshot);
    final container = _createContainer(
      enableNotifications: true,
      gateway: gateway,
      journal: journal,
    );
    addTearDown(container.dispose);

    container.read(appOperationLifecycleCoordinatorProvider);
    await journal.firstSaveStarted.future;

    expect(gateway.messages, isEmpty);

    journal.releaseFirstSave.complete();
    await _waitForOutboxToDrain(container);
    expect(gateway.messages, hasLength(1));
  });
}

/// 已完成批次及其待消费事件的恢复快照。
const _completedBatchSnapshot = AppOperationJournalSnapshot(
  history: [
    InstallTask(
      id: 'task-1',
      batchId: 'batch-1',
      kind: InstallTaskKind.update,
      appId: 'com.example.demo',
      appName: '示例应用',
      version: '2.0.0',
      target: AppOperationTargetSnapshot(
        appId: 'com.example.demo',
        displayName: '示例应用',
        installedVersion: '1.0.0',
        expectedVersion: '2.0.0',
      ),
      status: InstallStatus.success,
      createdAt: 1,
      finishedAt: 2,
    ),
  ],
  batches: [
    AppOperationBatch(
      id: 'batch-1',
      taskIds: ['task-1'],
      targets: [
        AppOperationTargetSnapshot(
          appId: 'com.example.demo',
          displayName: '示例应用',
          installedVersion: '1.0.0',
          expectedVersion: '2.0.0',
        ),
      ],
      createdAt: 1,
      finishedAt: 2,
      status: AppOperationBatchStatus.completed,
      notificationState: AppOperationNotificationState.pending,
    ),
  ],
  outbox: [
    AppOperationEffect(
      id: 'update-batch-completed-batch-1',
      type: AppOperationEffectType.updateBatchCompleted,
      aggregateId: 'batch-1',
      createdAt: 2,
    ),
  ],
);

/// 创建包含一个已完成批次和一条待消费事件的隔离容器。
ProviderContainer _createContainer({
  required bool enableNotifications,
  required SystemNotificationGateway gateway,
  AppOperationJournalRepository? journal,
  Locale locale = const Locale('zh'),
}) {
  return ProviderContainer(
    overrides: [
      appOperationJournalRepositoryProvider.overrideWithValue(
        journal ?? MemoryAppOperationJournalRepository(_completedBatchSnapshot),
      ),
      globalAppProvider.overrideWith(
        () => _TestGlobalApp(
          GlobalAppState(
            locale: locale,
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

/// 首次保存可控的 Journal，用于确认外部副作用不会越过持久化屏障。
class _BlockingJournalRepository implements AppOperationJournalRepository {
  /// 使用已经持久化的恢复快照创建仓库。
  _BlockingJournalRepository(this.snapshot);

  /// 启动恢复时读取的快照。
  AppOperationJournalSnapshot snapshot;

  /// 第一次 mark-attempt 保存已经开始。
  final Completer<void> firstSaveStarted = Completer<void>();

  /// 允许第一次保存真正完成。
  final Completer<void> releaseFirstSave = Completer<void>();

  /// 只阻塞第一次运行期保存。
  bool _hasBlockedFirstSave = false;

  @override
  AppOperationJournalSnapshot load() => snapshot;

  @override
  Future<void> save(AppOperationJournalSnapshot snapshot) async {
    if (!_hasBlockedFirstSave) {
      _hasBlockedFirstSave = true;
      firstSaveStarted.complete();
      await releaseFirstSave.future;
    }
    this.snapshot = snapshot;
  }
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
