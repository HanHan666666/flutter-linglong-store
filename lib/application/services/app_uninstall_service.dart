import 'dart:async';

import '../../core/logging/app_logger.dart';
import '../../domain/models/installed_app.dart';
import '../../domain/models/linglong_cli_failure.dart';
import '../../domain/models/running_app.dart';
import '../../domain/models/uninstall_result.dart';

typedef RunningAppsReader = List<RunningApp> Function();
typedef RunningAppKiller = Future<bool> Function(RunningApp app);

/// [version] 为 `null` 或空字符串时，仅按 appId 执行卸载命令，不拼接版本号。
typedef AppUninstallExecutor =
    Future<void> Function(String appId, String? version);
typedef InstalledAppRemover = void Function(String appId, String version);
typedef AppCollectionSyncer = Future<void> Function();
typedef UninstallReporter =
    Future<void> Function(String appId, String version, {String? appName});

/// 活跃安装任务读取器：返回 (appName, appId) 元组，无任务时返回 null
typedef ActiveInstallTaskReader = (String appName, String appId)? Function();

/// 应用卸载服务
///
/// 统一封装卸载逻辑，确保所有卸载入口行为一致：
/// 1. 检查是否有活跃安装/更新任务（由调用方处理拦截弹窗）
/// 2. 检查应用是否正在运行（由调用方决定是否显示强制关闭确认）
/// 3. 执行 kill + 卸载 + 刷新 + 上报
///
/// 本服务 **不直接显示任何弹窗**，而是返回 [UninstallResult] 供调用方决定如何展示 UI。
///
/// 参考 Rust 版本的 useAppUninstall hook 实现
class AppUninstallService {
  AppUninstallService({
    required RunningAppsReader readRunningApps,
    required RunningAppKiller killRunningApp,
    required AppUninstallExecutor uninstallApp,
    required InstalledAppRemover removeInstalledApp,
    required AppCollectionSyncer syncAfterUninstall,
    required UninstallReporter reportUninstall,
    ActiveInstallTaskReader? readActiveInstallTask,
  }) : _readRunningApps = readRunningApps,
       _killRunningApp = killRunningApp,
       _uninstallApp = uninstallApp,
       _removeInstalledApp = removeInstalledApp,
       _syncAfterUninstall = syncAfterUninstall,
       _reportUninstall = reportUninstall,
       _readActiveInstallTask = readActiveInstallTask;

  final RunningAppsReader _readRunningApps;
  final RunningAppKiller _killRunningApp;
  final AppUninstallExecutor _uninstallApp;
  final InstalledAppRemover _removeInstalledApp;
  final AppCollectionSyncer _syncAfterUninstall;
  final UninstallReporter _reportUninstall;
  final ActiveInstallTaskReader? _readActiveInstallTask;

  /// 检查是否有活跃安装/更新任务阻挡卸载。
  ///
  /// 返回非 null 时，表示有正在处理的任务，调用方应先显示拦截弹窗。
  /// 返回值为 `(任务名称, 任务 appId)` 元组。
  (String taskName, String appId)? getActiveBlockingTask() {
    final activeTask = _readActiveInstallTask?.call();
    if (activeTask == null) return null;
    final (taskName, taskId) = activeTask;
    return (taskName, taskId);
  }

  /// 查询当前运行中的应用实例（与要卸载的 appId 匹配）。
  List<RunningApp> getRunningInstances(String appId) {
    final runningApps = _readRunningApps();
    return runningApps.where((r) => r.appId == appId).toList();
  }

  /// 执行卸载流程。
  ///
  /// 调用方必须已经通过弹窗确认用户意图，且处理好活跃任务拦截。
  /// 此方法只负责：kill 运行实例 -> 执行卸载 -> 刷新 -> 上报。
  ///
  /// [includeVersion] 控制 ll-cli 卸载命令是否携带精确版本号：
  /// - `true`（默认）：按 `app.version` 精确卸载，用于应用详情页历史版本
  ///   列表等已知精确安装实例的场景。
  /// - `false`：卸载命令只使用 `appId`，用于应用详情页头部“整体卸载”场景——
  ///   该场景下不能假定 `app.version` 一定是实际已安装的版本（详情页可能
  ///   仍显示服务端“最新版本”），带上错误版本号会导致 ll-cli 找不到目标。
  ///   本地已安装列表移除、卸载统计上报仍使用 `app.version`，因为调用方
  ///   已负责传入解析出的真实已安装实例。
  ///
  /// 返回 [UninstallResult] 描述最终结果。
  Future<UninstallResult> executeUninstall(
    InstalledApp app, {
    bool includeVersion = true,
  }) async {
    // 1. 检查运行中实例
    final runningInstances = getRunningInstances(app.appId);

    // 2. 若有运行中实例，先强制关闭
    if (runningInstances.isNotEmpty) {
      for (final running in runningInstances) {
        final success = await _killRunningApp(running);
        if (!success) {
          AppLogger.warning('[AppUninstall] killApp 失败: ${running.appId}');
          return UninstallResultKillFailed(running.appId);
        }
      }
    }

    // 3. 执行卸载
    try {
      await _uninstallApp(app.appId, includeVersion ? app.version : null);

      // 4. 卸载成功后先做精确乐观移除，再走统一同步链路兜底校准。
      _removeInstalledApp(app.appId, app.version);
      await _syncAfterUninstall();

      // 5. 上报卸载统计记录（fire-and-forget）
      unawaited(_reportUninstallSafely(app));

      return UninstallResultSuccess();
    } on LinglongCliException catch (e) {
      final diagnostic = e.failure.diagnostic ?? e.toString();
      AppLogger.warning('[AppUninstall] 卸载失败: $diagnostic');
      return UninstallResultError(diagnostic);
    } catch (e) {
      AppLogger.error('[AppUninstall] 卸载异常', e);
      return UninstallResultError(e.toString());
    }
  }

  /// 上报卸载统计
  Future<void> _reportUninstallSafely(InstalledApp app) async {
    try {
      await _reportUninstall(app.appId, app.version, appName: app.name);
    } catch (e) {
      AppLogger.warning('[AppUninstall] 上报卸载统计失败: $e');
    }
  }
}
