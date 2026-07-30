/// 判断崩溃恢复后的本机事实能否证明应用操作成功。
///
/// 恢复规则只比较冻结的目标身份和实际安装实例，不生成展示文案，也不访问
/// Riverpod 或 `ll-cli`，避免恢复正确性被页面语言和运行环境耦合。
library;

import '../../domain/models/install_task.dart';
import '../../domain/models/installed_app.dart';

/// 应用操作恢复结论。
enum AppOperationRecoveryStatus {
  /// 本机唯一实例精确满足任务目标。
  verifiedSuccess,

  /// 无法从当前事实证明原任务成功。
  interrupted,
}

/// 一次恢复核验的结构化结果。
class AppOperationRecoveryResult {
  /// 创建恢复核验结果。
  const AppOperationRecoveryResult({
    required this.status,
    this.installedTarget,
  });

  /// 恢复状态。
  final AppOperationRecoveryStatus status;

  /// 唯一匹配的本机实例；不存在或存在歧义时为空。
  final InstalledApp? installedTarget;
}

/// 应用操作恢复规则服务。
class AppOperationRecoveryService {
  /// 创建无状态恢复服务。
  const AppOperationRecoveryService();

  /// 根据冻结目标和当前已安装列表核验任务结果。
  AppOperationRecoveryResult evaluate(
    InstallTask task,
    List<InstalledApp> installedApps,
  ) {
    final installedTarget = _resolveInstalledTarget(task, installedApps);
    final status = _canProveRecoveredSuccess(task, installedTarget)
        ? AppOperationRecoveryStatus.verifiedSuccess
        : AppOperationRecoveryStatus.interrupted;
    return AppOperationRecoveryResult(
      status: status,
      installedTarget: installedTarget,
    );
  }

  /// 按冻结身份定位唯一安装实例；匹配歧义时拒绝猜测。
  InstalledApp? _resolveInstalledTarget(
    InstallTask task,
    List<InstalledApp> installedApps,
  ) {
    final target = task.target;
    final candidates = installedApps.where((app) {
      if (app.appId != task.appId) {
        return false;
      }
      if (target == null) {
        return true;
      }
      return _matchesOptionalIdentity(target.arch, app.arch) &&
          _matchesOptionalIdentity(target.channel, app.channel) &&
          _matchesOptionalIdentity(target.module, app.module) &&
          _matchesOptionalIdentity(target.repoName, app.repoName);
    }).toList();
    return candidates.length == 1 ? candidates.single : null;
  }

  /// 根据操作类型核验实际版本是否满足原任务目标。
  bool _canProveRecoveredSuccess(
    InstallTask task,
    InstalledApp? installedTarget,
  ) {
    if (installedTarget == null) {
      return false;
    }

    final target = task.target;
    if (task.isUpdateTask) {
      final expectedVersion = target?.expectedVersion;
      return expectedVersion != null &&
          expectedVersion.isNotEmpty &&
          installedTarget.version == expectedVersion;
    }

    final requestedVersion = target?.requestedInstallVersion ?? task.version;
    return requestedVersion == null ||
        requestedVersion.isEmpty ||
        installedTarget.version == requestedVersion;
  }

  /// 目标未冻结字段时允许兼容，已冻结字段必须完全一致。
  bool _matchesOptionalIdentity(String? expected, String? actual) {
    return expected == null || expected.isEmpty || expected == actual;
  }
}
