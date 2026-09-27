/// 提供应用操作目标快照与已安装实例之间的匹配规则。
///
/// 该文件存在的唯一原因是避免"同一套匹配口径"被复制到多处：启动崩溃恢复
/// （[AppOperationRecoveryService]）与更新成功后的已安装快照收敛判定
/// （[UpdateConvergenceService]）必须得出完全一致的结论，否则会出现
/// "重启后认为更新已完成、运行期却仍认为应用可更新"的分叉。
///
/// 本文件只做纯函数判定，不访问 Riverpod、不执行 `ll-cli`、不生成展示文案，
/// 因此可以脱离运行环境被单元测试直接覆盖。
library;

import '../../domain/models/app_operation_target_snapshot.dart';
import '../../domain/models/installed_app.dart';

/// 应用操作目标与已安装实例的匹配规则。
class AppOperationTargetMatcher {
  /// 创建无状态判定器。
  const AppOperationTargetMatcher();

  /// 按 appId 与已冻结身份字段判断某实例是否属于该操作目标。
  ///
  /// 目标快照未冻结的字段（`null` 或空串）视为"不约束"，只有冻结过的字段
  /// 必须完全一致；这样既兼容旧版本任务缺失字段的情况，也能在多架构、
  /// 多渠道、多模块实例并存时避免匹配到错误的实例。
  ///
  /// [appId] 与 [target] 分开传入，是为了兼容历史任务没有目标快照、
  /// 只能退化到"仅按 appId 匹配"的场景。
  bool matchesInstalledApp({
    required InstalledApp app,
    required String appId,
    AppOperationTargetSnapshot? target,
  }) {
    if (app.appId != appId) {
      return false;
    }
    if (target == null) {
      return true;
    }
    return _matchesOptionalIdentity(target.arch, app.arch) &&
        _matchesOptionalIdentity(target.channel, app.channel) &&
        _matchesOptionalIdentity(target.module, app.module) &&
        _matchesOptionalIdentity(target.repoName, app.repoName);
  }

  /// 在已安装列表中解析唯一匹配实例。
  ///
  /// 不存在或存在多个匹配实例（身份歧义）时返回 `null`：调用方必须把
  /// "无法唯一证明"当作未完成处理，禁止任选一个实例作为事实。
  InstalledApp? resolveUniqueInstalledTarget({
    required String appId,
    required List<InstalledApp> installedApps,
    AppOperationTargetSnapshot? target,
  }) {
    final candidates = installedApps
        .where(
          (app) => matchesInstalledApp(app: app, appId: appId, target: target),
        )
        .toList();
    return candidates.length == 1 ? candidates.single : null;
  }

  /// 更新目标是否已经在给定实例上落地。
  ///
  /// `expectedVersion` 是入队时冻结的"更新成功后应当出现的版本"；缺失时
  /// 无法证明结果，返回 `false` 而不是猜测成功。
  bool isUpdateSatisfiedOnInstance(
    InstalledApp app,
    AppOperationTargetSnapshot? target,
  ) {
    final expectedVersion = target?.expectedVersion;
    if (expectedVersion == null || expectedVersion.isEmpty) {
      return false;
    }
    return app.version == expectedVersion;
  }

  /// 给定已安装快照中是否已出现满足更新目标的唯一实例。
  ///
  /// 这是"更新成功后已安装快照是否已收敛"的唯一判定口径：收敛判定与恢复
  /// 判定共用 [resolveUniqueInstalledTarget] 与 [isUpdateSatisfiedOnInstance]。
  bool isUpdateSatisfiedInSnapshot({
    required AppOperationTargetSnapshot target,
    required List<InstalledApp> installedApps,
  }) {
    final installedTarget = resolveUniqueInstalledTarget(
      appId: target.appId,
      installedApps: installedApps,
      target: target,
    );
    return installedTarget != null &&
        isUpdateSatisfiedOnInstance(installedTarget, target);
  }

  /// 目标未冻结字段时允许兼容，已冻结字段必须完全一致。
  bool _matchesOptionalIdentity(String? expected, String? actual) {
    return expected == null || expected.isEmpty || expected == actual;
  }
}
