import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/install_task.dart';
import 'install_queue_provider.dart';

/// 应用操作入队参数。
///
/// Presentation 层只声明”这是安装还是更新”，具体如何写入队列由
/// Application 层统一处理，避免页面继续直接操作底层队列实现。
///
/// [version] 仅在显式指定版本安装时传入（如详情页版本列表）；
///          更新操作必须为 null，升级命令不接受版本号。
class EnqueueAppOperationParams {
  const EnqueueAppOperationParams({
    required this.kind,
    required this.appId,
    required this.appName,
    this.icon,
    this.version,
    this.force = false,
  });

  final InstallTaskKind kind;
  final String appId;
  final String appName;
  final String? icon;
  /// 仅 install + 显式版本指定时有效；update 时必须为 null。
  final String? version;
  final bool force;
}

/// 应用操作统一入口。
class AppOperationQueueController {
  const AppOperationQueueController(this._ref);

  final Ref _ref;

  /// 入队单个安装/更新操作。
  ///
  /// 更新任务不允许携带 version，升级命令不接受版本号。
  String enqueueAppOperation(EnqueueAppOperationParams params) {
    assert(
      params.kind == InstallTaskKind.update ? params.version == null : true,
      '更新任务禁止携带 version 参数',
    );
    return _ref.read(installQueueProvider.notifier).enqueueOperation(
          kind: params.kind,
          appId: params.appId,
          appName: params.appName,
          icon: params.icon,
          version: params.version,
          force: params.force,
        );
  }

  /// 批量入队安装/更新操作。
  List<String> enqueueBatchOperations(
    List<EnqueueAppOperationParams> paramsList,
  ) {
    final queueParams = paramsList
        .map(
          (params) {
            assert(
              params.kind == InstallTaskKind.update
                  ? params.version == null
                  : true,
              '批量更新任务禁止携带 version 参数',
            );
            return EnqueueTaskParams(
              kind: params.kind,
              appId: params.appId,
              appName: params.appName,
              icon: params.icon,
              version: params.version,
              force: params.force,
            );
          },
        )
        .toList();
    return _ref
        .read(installQueueProvider.notifier)
        .enqueueBatchOperations(queueParams);
  }
}

final appOperationQueueControllerProvider =
    Provider<AppOperationQueueController>((ref) {
      return AppOperationQueueController(ref);
    });
