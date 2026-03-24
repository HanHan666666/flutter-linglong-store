import 'dart:async';

import '../../core/logging/app_logger.dart';
import '../../core/network/api_exceptions.dart';
import '../../domain/models/installed_app.dart';
import '../../domain/models/running_app.dart';

typedef RunningAppsReader = List<RunningApp> Function();
typedef RunningAppKiller = Future<bool> Function(RunningApp app);
typedef AppUninstallExecutor =
    Future<String> Function(String appId, String version);
typedef InstalledAppRemover = void Function(String appId, String version);
typedef AppCollectionSyncer = Future<void> Function();
typedef UninstallReporter =
    Future<void> Function(String appId, String version, {String? appName});
typedef UninstallConfirm =
    Future<bool?> Function({required bool isRunning, String? appName});

enum AppUninstallResultType { success, cancelled, stopFailed, failed }

class AppUninstallResult {
  const AppUninstallResult({required this.type, this.detail});

  const AppUninstallResult.success()
    : this(type: AppUninstallResultType.success);

  const AppUninstallResult.cancelled()
    : this(type: AppUninstallResultType.cancelled);

  const AppUninstallResult.stopFailed({String? detail})
    : this(type: AppUninstallResultType.stopFailed, detail: detail);

  const AppUninstallResult.failed({String? detail})
    : this(type: AppUninstallResultType.failed, detail: detail);

  final AppUninstallResultType type;
  final String? detail;

  bool get didSucceed => type == AppUninstallResultType.success;
}

/// 应用卸载服务
///
/// 统一封装卸载逻辑，确保所有卸载入口行为一致：
/// 1. 检查应用是否正在运行
/// 2. 显示确认弹窗（普通/运行中两种）
/// 3. 先 kill 运行中的实例
/// 4. 执行卸载
/// 5. 刷新已安装列表和更新列表
/// 6. 上报卸载统计
/// 7. 显示结果提示
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
  }) : _readRunningApps = readRunningApps,
       _killRunningApp = killRunningApp,
       _uninstallApp = uninstallApp,
       _removeInstalledApp = removeInstalledApp,
       _syncAfterUninstall = syncAfterUninstall,
       _reportUninstall = reportUninstall;

  final RunningAppsReader _readRunningApps;
  final RunningAppKiller _killRunningApp;
  final AppUninstallExecutor _uninstallApp;
  final InstalledAppRemover _removeInstalledApp;
  final AppCollectionSyncer _syncAfterUninstall;
  final UninstallReporter _reportUninstall;

  /// 执行卸载流程
  ///
  /// [app] 要卸载的应用信息
  Future<AppUninstallResult> uninstall(
    InstalledApp app,
    UninstallConfirm confirm,
  ) async {
    // 1. 检查应用是否正在运行
    final runningApps = _readRunningApps();
    final runningInstances = runningApps
        .where((r) => r.appId == app.appId)
        .toList();

    // 2. 显示确认弹窗
    final confirmed = await confirm(
      isRunning: runningInstances.isNotEmpty,
      appName: app.name,
    );

    if (confirmed != true) {
      return const AppUninstallResult.cancelled();
    }

    // 3. 若运行中，先强制关闭所有运行实例
    if (runningInstances.isNotEmpty) {
      for (final running in runningInstances) {
        final success = await _killRunningApp(running);
        if (!success) {
          AppLogger.warning('[AppUninstall] killApp 失败: ${running.appId}');
          return const AppUninstallResult.stopFailed(detail: '无法停止应用，卸载已取消');
        }
      }
    }

    // 4. 执行卸载
    try {
      await _uninstallApp(app.appId, app.version);

      // 5. 卸载成功后先做精确乐观移除，再走统一同步链路兜底校准。
      _removeInstalledApp(app.appId, app.version);
      await _syncAfterUninstall();

      // 6. 上报卸载统计记录（fire-and-forget）
      unawaited(_reportUninstallSafely(app));

      return const AppUninstallResult.success();
    } on UninstallException catch (e) {
      AppLogger.warning('[AppUninstall] 卸载失败: ${e.message}');
      return AppUninstallResult.failed(detail: e.message);
    } catch (e) {
      AppLogger.error('[AppUninstall] 卸载异常', e);
      return AppUninstallResult.failed(detail: e.toString());
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
