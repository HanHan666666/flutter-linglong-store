/// 确认"刚刚更新成功的应用"是否已在已安装快照中收敛到目标版本。
///
/// 为什么需要该文件：`ll-cli upgrade` 报告完成后，`ll-cli list`（即已安装快照）
/// 并不保证立即暴露新版本——可能尚在收敛、可能当次命令失败、也可能被并发刷新
/// 覆盖。若此时直接重算更新列表，就会用"更新前的版本"与远端最新版本比对，
/// 把刚更新的应用重新判为可更新（用户看到的"更新完成仍留在更新列表"）。
///
/// 因此这里以任务入队时冻结的 `expectedVersion` 为收敛凭据做**有界重试**，
/// 只有确认目标版本已在快照中可见才允许重算更新列表；确认失败时上层保持
/// 乐观移除结果，等下一次成功刷新自然收敛。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/models/app_operation_target_snapshot.dart';
import '../../domain/models/installed_app.dart';
import '../providers/installed_apps_provider.dart';
import 'app_operation_target_matcher.dart';

/// 收敛确认结果。
class UpdateConvergenceResult {
  /// 创建收敛确认结果。
  const UpdateConvergenceResult({
    required this.confirmed,
    required this.attempts,
    required this.unconfirmedTargets,
    required this.refreshFailed,
  });

  /// 是否所有参与判定的目标都已在快照中可见。
  final bool confirmed;

  /// 实际执行的快照刷新次数（含首次）。
  final int attempts;

  /// 仍未确认的目标，仅用于诊断日志。
  final List<AppOperationTargetSnapshot> unconfirmedTargets;

  /// 判定过程中是否出现过快照刷新失败。
  ///
  /// 用于区分两类失败原因：刷新失败（`refreshFailed`）与刷新成功但列表尚未
  /// 收敛（`listStale`）。两者都只需保持乐观移除，但真机诊断时必须可区分。
  final bool refreshFailed;

  /// 诊断原因码，供日志与排查使用。
  String get reasonCode {
    if (confirmed) {
      return 'confirmed';
    }
    return refreshFailed ? 'refreshFailed' : 'listStale';
  }
}

/// 更新成功后确认已安装快照是否已收敛到目标版本的端口。
///
/// 抽象出端口是为了让同步入口在测试中注入替身，避免依赖真实 `ll-cli`。
abstract class UpdateConvergenceVerifier {
  /// 有界重试确认给定更新目标是否已经落地。
  ///
  /// 空目标集合（或全部目标缺少 `expectedVersion`）视为无需确认。
  Future<UpdateConvergenceResult> verify(
    List<AppOperationTargetSnapshot> targets,
  );
}

/// 基于已安装快照的收敛确认服务 Provider。
final updateConvergenceVerifierProvider = Provider<UpdateConvergenceVerifier>((
  ref,
) {
  return UpdateConvergenceService(ref);
});

/// 基于已安装快照的收敛确认实现。
class UpdateConvergenceService implements UpdateConvergenceVerifier {
  /// 创建收敛确认服务。
  ///
  /// 默认最多 3 次、间隔 1 秒：既能覆盖"守护进程收尾后列表才可见"的短延迟，
  /// 又避免无界轮询把 `ll-cli` 调用放大成不可预测的开销。参数可注入以便测试。
  const UpdateConvergenceService(
    this._ref, {
    this.maxAttempts = 3,
    this.retryDelay = const Duration(seconds: 1),
    AppOperationTargetMatcher matcher = const AppOperationTargetMatcher(),
  }) : assert(maxAttempts > 0, '收敛确认至少需要一次尝试'),
       _matcher = matcher;

  /// 应用级依赖读取入口。
  final Ref _ref;

  /// 最大刷新次数（含首次）。
  final int maxAttempts;

  /// 两次刷新之间的等待间隔。
  final Duration retryDelay;

  /// 与恢复判定同源的匹配规则。
  final AppOperationTargetMatcher _matcher;

  @override
  Future<UpdateConvergenceResult> verify(
    List<AppOperationTargetSnapshot> targets,
  ) async {
    // 缺少 expectedVersion 的历史任务无法证明结果，不参与判定也不猜测成功。
    final effectiveTargets = targets.where(_hasExpectedVersion).toList();
    if (effectiveTargets.isEmpty) {
      return const UpdateConvergenceResult(
        confirmed: true,
        attempts: 0,
        unconfirmedTargets: [],
        refreshFailed: false,
      );
    }

    var refreshFailed = false;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      // 复用 installedAppsProvider 这一唯一快照入口：确认的就是更新列表随后
      // 将要读取的同一份快照，不引入第二条 list 解析路径。详情富化有缓存，
      // 重试通常不产生额外网络请求。
      final refreshed = await _ref
          .read(installedAppsProvider.notifier)
          .refresh();
      refreshFailed = refreshFailed || !refreshed;

      final snapshot = _ref.read(installedAppsProvider).apps;
      final unconfirmed = effectiveTargets
          .where(
            (target) => !_matcher.isUpdateSatisfiedInSnapshot(
              target: target,
              installedApps: snapshot,
            ),
          )
          .toList();

      if (unconfirmed.isEmpty) {
        AppLogger.info(
          '[更新收敛] attempts=$attempt confirmed=true '
          'targets=${_describeTargets(effectiveTargets, snapshot)}',
        );
        return UpdateConvergenceResult(
          confirmed: true,
          attempts: attempt,
          unconfirmedTargets: const [],
          refreshFailed: refreshFailed,
        );
      }

      if (attempt < maxAttempts) {
        await Future<void>.delayed(retryDelay);
      } else {
        AppLogger.warning(
          '[更新收敛] attempts=$attempt confirmed=false '
          'reason=${refreshFailed ? 'refreshFailed' : 'listStale'} '
          'targets=${_describeTargets(unconfirmed, snapshot)}',
        );
        return UpdateConvergenceResult(
          confirmed: false,
          attempts: attempt,
          unconfirmedTargets: unconfirmed,
          refreshFailed: refreshFailed,
        );
      }
    }

    // 循环在 tryAttempts 次内必然返回；兜底分支只用于满足静态分析，
    // 语义上等价于"最后一次尝试仍未确认"。
    return UpdateConvergenceResult(
      confirmed: false,
      attempts: maxAttempts,
      unconfirmedTargets: effectiveTargets,
      refreshFailed: refreshFailed,
    );
  }

  /// 目标是否携带可用于证明收敛的期望版本。
  bool _hasExpectedVersion(AppOperationTargetSnapshot target) {
    final expectedVersion = target.expectedVersion;
    return expectedVersion != null && expectedVersion.isNotEmpty;
  }

  /// 生成 `appId@expected -> snapshot(versions)` 形式的诊断片段。
  String _describeTargets(
    List<AppOperationTargetSnapshot> targets,
    List<InstalledApp> snapshot,
  ) {
    return targets
        .map(
          (target) =>
              '${target.appId}@${target.expectedVersion ?? '-'}'
              '->${_snapshotVersions(snapshot, target.appId)}',
        )
        .join(', ');
  }

  /// 读取快照中该应用当前可见的版本集合，用于诊断"列表是否尚未收敛"。
  String _snapshotVersions(List<InstalledApp> snapshot, String appId) {
    final versions = snapshot
        .where((app) => app.appId == appId)
        .map((app) => app.version)
        .where((version) => version.isNotEmpty)
        .toList();
    return versions.isEmpty ? '-' : versions.join('|');
  }
}
