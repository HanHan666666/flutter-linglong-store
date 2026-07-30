/// 编排用户主动触发的一键更新操作。
///
/// Presentation 层只表达“一键更新”意图；候选过滤、目标快照冻结和批次入队
/// 全部收敛在这里，避免页面与后续入口复制批次业务规则。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_operation_target_snapshot.dart';
import '../../domain/models/install_task.dart';
import 'app_operation_queue_provider.dart';
import 'install_queue_provider.dart';
import 'update_apps_provider.dart';

/// 一键更新应用服务。
class UpdateAllController {
  /// 使用应用级 Provider 容器创建控制器。
  const UpdateAllController(this._ref);

  /// 应用级依赖读取入口。
  final Ref _ref;

  /// 冻结当前可更新列表并创建一个批次。
  ///
  /// 已经存在活跃任务的应用会被排除；没有任何可入队目标时返回空列表，
  /// 且底层不会创建空批次或通知事件。
  List<String> enqueue() {
    final queueState = _ref.read(installQueueProvider);
    final operations = _ref
        .read(updateAppsProvider)
        .apps
        .where((app) => !queueState.isAppInQueue(app.appId))
        .map(
          (app) => EnqueueAppOperationParams(
            kind: InstallTaskKind.update,
            appId: app.appId,
            appName: app.name,
            icon: app.icon,
            target: createUpdateTargetSnapshot(app),
          ),
        )
        .toList(growable: false);

    if (operations.isEmpty) {
      return const <String>[];
    }
    return _ref
        .read(appOperationQueueControllerProvider)
        .enqueueBatchOperations(operations);
  }
}

/// 把可更新条目冻结为完整操作目标。
AppOperationTargetSnapshot createUpdateTargetSnapshot(UpdatableApp app) {
  final installed = app.installedApp;
  return AppOperationTargetSnapshot(
    appId: app.appId,
    displayName: app.name,
    icon: app.icon,
    arch: installed.arch,
    channel: installed.channel,
    module: installed.module,
    repoName: installed.repoName,
    installedVersion: installed.version,
    expectedVersion: app.latestVersion,
  );
}

/// 一键更新统一入口 Provider。
final updateAllControllerProvider = Provider<UpdateAllController>((ref) {
  return UpdateAllController(ref);
});
