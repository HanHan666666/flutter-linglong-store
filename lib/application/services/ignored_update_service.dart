/// 应用忽略与恢复更新提醒的统一业务入口。
///
/// 该服务协调安装队列、忽略持久化、可更新列表和应用集合刷新，避免页面
/// 分别拼接副作用，并确保忽略操作不被误解为取消正在执行的更新任务。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/ignored_update.dart';
import '../providers/app_collection_sync_provider.dart';
import '../providers/ignored_updates_provider.dart';
import '../providers/install_queue_provider.dart';
import '../providers/installed_apps_provider.dart';
import '../providers/update_apps_provider.dart';

/// 忽略更新操作结果。
enum IgnoreUpdateResult {
  /// 忽略记录已持久化，当前更新状态已同步移除。
  success,

  /// 应用缺少有效 appId，不能创建可恢复的持续忽略身份。
  invalidApp,

  /// 应用已有排队或执行中的任务，忽略操作被拒绝。
  activeTask,

  /// 本地记录写入失败，任何可见状态均未改变。
  persistenceFailed,
}

/// 恢复更新提醒操作结果。
enum RestoreIgnoredUpdateResult {
  /// 忽略记录已移除，且更新检查成功完成。
  success,

  /// 本地记录写入失败，应用仍保持忽略。
  persistenceFailed,

  /// 忽略记录已移除，但刷新已安装快照或更新检查失败。
  refreshFailed,
}

/// 忽略更新业务服务 Provider。
final ignoredUpdateServiceProvider = Provider<IgnoredUpdateService>((ref) {
  return IgnoredUpdateService(ref);
});

/// 忽略更新业务服务。
class IgnoredUpdateService {
  /// 创建依赖当前 Provider 容器的业务服务。
  const IgnoredUpdateService(this._ref);

  /// 用于读取和协调应用级状态的 Riverpod 引用。
  final Ref _ref;

  /// 持续忽略一个当前可更新的应用。
  Future<IgnoreUpdateResult> ignore(UpdatableApp app) async {
    if (app.appId.trim().isEmpty) {
      return IgnoreUpdateResult.invalidApp;
    }

    final installState = _ref.read(installQueueProvider);
    if (installState.isAppInQueue(app.appId)) {
      return IgnoreUpdateResult.activeTask;
    }

    final saved = await _ref
        .read(ignoredUpdatesProvider.notifier)
        .ignore(
          IgnoredUpdate(
            appId: app.appId,
            appName: app.name.trim().isEmpty ? app.appId : app.name,
            icon: app.icon,
            ignoredVersion: app.currentVersion,
            ignoredAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    if (!saved) {
      return IgnoreUpdateResult.persistenceFailed;
    }

    _ref.read(updateAppsProvider.notifier).removeApp(app.appId);
    return IgnoreUpdateResult.success;
  }

  /// 恢复指定应用的更新提醒，并重新同步本机与远端更新状态。
  Future<RestoreIgnoredUpdateResult> restore(String appId) async {
    // 重复恢复保持幂等且不产生无意义的 ll-cli/API 刷新。
    if (!_ref.read(ignoredUpdatesProvider).contains(appId)) {
      return RestoreIgnoredUpdateResult.success;
    }

    final saved = await _ref
        .read(ignoredUpdatesProvider.notifier)
        .restore(appId);
    if (!saved) {
      return RestoreIgnoredUpdateResult.persistenceFailed;
    }

    await _ref
        .read(appCollectionSyncServiceProvider)
        .syncAfterSuccessfulOperation();

    final installedError = _ref.read(installedAppsProvider).error;
    final updateError = _ref.read(updateAppsProvider).error;
    if (installedError != null || updateError != null) {
      return RestoreIgnoredUpdateResult.refreshFailed;
    }
    return RestoreIgnoredUpdateResult.success;
  }
}
