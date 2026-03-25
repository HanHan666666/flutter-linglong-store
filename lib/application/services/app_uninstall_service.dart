import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_exceptions.dart';
import '../../domain/models/installed_app.dart';
import '../../domain/models/running_app.dart';
import '../../presentation/widgets/confirm_dialog.dart';
import '../../presentation/widgets/uninstall_blocked_dialog.dart';

typedef RunningAppsReader = List<RunningApp> Function();
typedef RunningAppKiller = Future<bool> Function(RunningApp app);
typedef AppUninstallExecutor =
    Future<String> Function(String appId, String version);
typedef InstalledAppRemover = void Function(String appId, String version);
typedef AppCollectionSyncer = Future<void> Function();
typedef UninstallReporter =
    Future<void> Function(String appId, String version, {String? appName});
typedef UninstallConfirmDialog =
    Future<bool?> Function(BuildContext context, {String? appName});

/// 活跃安装任务读取器：返回 (appName, appId) 元组，无任务时返回 null
typedef ActiveInstallTaskReader = (String appName, String appId)? Function();

/// 安装中卸载拦截弹窗回调（可注入以便测试替换）
typedef UninstallInterceptDialog =
    Future<UninstallBlockedAction> Function(
      BuildContext context, {
      required String activeTaskName,
      String fallbackAppId,
    });

/// 打开下载管理界面的回调（可注入以便测试替换）
typedef OpenDownloadManagerCallback = void Function(BuildContext context);

/// 应用卸载服务
///
/// 统一封装卸载逻辑，确保所有卸载入口行为一致：
/// 0. 当有活跃安装/更新任务时，显示拦截弹窗并中止卸载
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
    UninstallConfirmDialog confirmUninstall = ConfirmDialog.showUninstall,
    UninstallConfirmDialog confirmUninstallRunning =
        ConfirmDialog.showUninstallRunning,
    // 活跃安装任务读取器；为 null 时视为无活跃任务（兼容现有调用方）
    ActiveInstallTaskReader? readActiveInstallTask,
    // 拦截弹窗回调；为 null 时使用默认实现
    UninstallInterceptDialog? interceptDialog,
    // 下载管理打开回调；为 null 时不执行任何操作
    OpenDownloadManagerCallback? openDownloadManager,
  }) : _readRunningApps = readRunningApps,
       _killRunningApp = killRunningApp,
       _uninstallApp = uninstallApp,
       _removeInstalledApp = removeInstalledApp,
       _syncAfterUninstall = syncAfterUninstall,
       _reportUninstall = reportUninstall,
       _confirmUninstall = confirmUninstall,
       _confirmUninstallRunning = confirmUninstallRunning,
       _readActiveInstallTask = readActiveInstallTask,
       _interceptDialog = interceptDialog ?? showUninstallBlockedDialog,
       _openDownloadManager = openDownloadManager;

  final RunningAppsReader _readRunningApps;
  final RunningAppKiller _killRunningApp;
  final AppUninstallExecutor _uninstallApp;
  final InstalledAppRemover _removeInstalledApp;
  final AppCollectionSyncer _syncAfterUninstall;
  final UninstallReporter _reportUninstall;
  final UninstallConfirmDialog _confirmUninstall;
  final UninstallConfirmDialog _confirmUninstallRunning;
  final ActiveInstallTaskReader? _readActiveInstallTask;
  final UninstallInterceptDialog _interceptDialog;
  final OpenDownloadManagerCallback? _openDownloadManager;

  /// 执行卸载流程
  ///
  /// [context] BuildContext，用于显示弹窗和 SnackBar
  /// [app] 要卸载的应用信息
  ///
  /// 返回：
  /// - `true` - 卸载成功
  /// - `false` - 用户取消或卸载失败
  Future<bool> uninstall(BuildContext context, InstalledApp app) async {
    if (!context.mounted) return false;

    // 0. 活跃安装/更新任务拦截：ll-package-manager 为串行单队列，
    //    不支持同时执行安装和卸载。只有 currentTask（运行中任务）才触发拦截，
    //    排队中的任务不在此阻断范围内。
    final activeTask = _readActiveInstallTask?.call();
    if (activeTask != null) {
      final (taskName, taskId) = activeTask;
      if (!context.mounted) return false;

      final action = await _interceptDialog(
        context,
        activeTaskName: taskName,
        fallbackAppId: taskId,
      );

      if (!context.mounted) return false;

      // 用户选择「查看下载管理」：关闭弹窗后再打开下载管理
      if (action == UninstallBlockedAction.openDownloadManager) {
        _openDownloadManager?.call(context);
      }

      return false;
    }

    // 1. 检查应用是否正在运行
    final runningApps = _readRunningApps();
    final runningInstances = runningApps
        .where((r) => r.appId == app.appId)
        .toList();

    // 2. 显示确认弹窗
    bool? confirmed;
    if (runningInstances.isNotEmpty) {
      // 应用运行中，显示强制关闭确认弹窗
      confirmed = await _confirmUninstallRunning(context, appName: app.name);
    } else {
      confirmed = await _confirmUninstall(context, appName: app.name);
    }

    if (confirmed != true || !context.mounted) return false;

    // 3. 若运行中，先强制关闭所有运行实例
    if (runningInstances.isNotEmpty) {
      for (final running in runningInstances) {
        final success = await _killRunningApp(running);
        if (!success) {
          // kill 失败，中止卸载
          AppLogger.warning('[AppUninstall] killApp 失败: ${running.appId}');
          if (context.mounted) {
            _showErrorSnackBar(context, '无法停止应用，卸载已取消');
          }
          return false;
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

      // 7. 显示成功提示
      if (context.mounted) {
        _showSuccessSnackBar(
          context,
          AppLocalizations.of(context)?.uninstallSuccess(app.name) ??
              '${app.name} 已卸载',
        );
      }

      return true;
    } on UninstallException catch (e) {
      // 卸载失败（包括 PKExec 取消）
      AppLogger.warning('[AppUninstall] 卸载失败: ${e.message}');
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          AppLocalizations.of(context)?.uninstallFailed(e.message) ??
              '卸载失败: ${e.message}',
        );
      }
      return false;
    } catch (e) {
      // 其他异常
      AppLogger.error('[AppUninstall] 卸载异常', e);
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          AppLocalizations.of(context)?.uninstallError(e.toString()) ??
              '卸载异常: $e',
        );
      }
      return false;
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

  void _showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
