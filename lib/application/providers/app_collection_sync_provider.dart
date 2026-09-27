import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/models/app_operation_target_snapshot.dart';
import '../services/update_convergence_service.dart';
import 'installed_app_diff_report_provider.dart';
import 'installed_apps_provider.dart';
import 'update_apps_provider.dart';

/// 应用集合变更后的统一同步服务。
///
/// 安装、更新、卸载等会改变“已安装列表”和“可更新列表”的场景，
/// 都应该复用这里，避免页面或 Widget 自己拼 refresh 链路。
class AppCollectionSyncService {
  const AppCollectionSyncService(this._ref);

  final Ref _ref;

  /// 刷新已安装快照并按需重算可更新列表，最后触发差量统计。
  ///
  /// [updateTargets] 非空表示"刚刚成功更新了这些应用，且入队时冻结了
  /// expectedVersion"：此时必须先在已安装快照中确认目标版本可见，才允许
  /// 重算更新列表。否则 `ll-cli list` 尚未收敛（或当次刷新失败）时，会用
  /// 更新前的版本与远端最新版本比对，把刚更新的应用重新判为可更新。
  Future<void> syncAfterSuccessfulOperation({
    List<AppOperationTargetSnapshot> updateTargets = const [],
  }) async {
    final shouldRecomputeUpdates = await _prepareInstalledSnapshot(
      updateTargets,
    );

    if (shouldRecomputeUpdates) {
      await _ref.read(updateAppsProvider.notifier).checkUpdates();
    }

    // 同步完成后触发差量检测上报（对齐旧版 reflushInstalledItemsImmediate），
    // 防抖合并且不阻塞操作链路：安装/卸载统计由差量结果统一产生。该上报与
    // 更新列表重算解耦，跳过重算时同样必须执行，否则统计会丢事件。
    _ref
        .read(installedAppDiffReportServiceProvider)
        .scheduleImmediateCheck();
  }

  /// 准备供更新检查使用的已安装快照，返回是否允许重算更新列表。
  Future<bool> _prepareInstalledSnapshot(
    List<AppOperationTargetSnapshot> updateTargets,
  ) async {
    if (updateTargets.isEmpty) {
      // 安装类操作与页面手动刷新保持既有语义：尽力刷新快照后按快照重算。
      await _ref.read(installedAppsProvider.notifier).refresh();
      return true;
    }

    final result = await _ref
        .read(updateConvergenceVerifierProvider)
        .verify(updateTargets);
    if (result.confirmed) {
      return true;
    }

    // 未收敛时保持乐观移除结果，等下一次成功刷新（手动检查更新/启动/下一次
    // 操作）自然收敛；这里只记录诊断事实，不猜测版本、不额外修改列表状态。
    AppLogger.warning(
      '更新完成后已安装快照未收敛，跳过更新列表重算: '
      'attempts=${result.attempts}, reason=${result.reasonCode}, '
      'unconfirmed=${_describeTargets(result.unconfirmedTargets)}',
    );
    return false;
  }

  /// 生成未收敛目标的诊断描述。
  String _describeTargets(List<AppOperationTargetSnapshot> targets) {
    return targets
        .map((target) => '${target.appId}@${target.expectedVersion ?? '-'}')
        .join(', ');
  }
}

final appCollectionSyncServiceProvider = Provider<AppCollectionSyncService>((
  ref,
) {
  return AppCollectionSyncService(ref);
});
