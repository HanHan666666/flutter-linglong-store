import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_exceptions.dart';
import '../../domain/models/installed_app.dart';
import '../providers/installed_apps_provider.dart';
import '../providers/running_process_provider.dart';
import '../../presentation/widgets/confirm_dialog.dart';

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
  AppUninstallService(this._ref);

  final Ref _ref;

  /// 执行卸载流程
  ///
  /// [context] BuildContext，用于显示弹窗和 SnackBar
  /// [app] 要卸载的应用信息
  ///
  /// 返回：
  /// - `true` - 卸载成功
  /// - `false` - 用户取消或卸载失败
  Future<bool> uninstall(
    BuildContext context,
    InstalledApp app,
  ) async {
    if (!context.mounted) return false;

    // 1. 检查应用是否正在运行
    final runningApps = _ref.read(runningAppsListProvider);
    final runningInstances = runningApps
        .where((r) => r.appId == app.appId)
        .toList();

    // 2. 显示确认弹窗
    bool? confirmed;
    if (runningInstances.isNotEmpty) {
      // 应用运行中，显示强制关闭确认弹窗
      confirmed = await ConfirmDialog.showUninstallRunning(
        context,
        appName: app.name,
      );
    } else {
      confirmed = await ConfirmDialog.showUninstall(
        context,
        appName: app.name,
      );
    }

    if (confirmed != true || !context.mounted) return false;

    // 3. 若运行中，先强制关闭所有运行实例
    if (runningInstances.isNotEmpty) {
      for (final running in runningInstances) {
        final success = await _ref
            .read(runningProcessProvider.notifier)
            .killApp(running);
        if (!success) {
          // kill 失败，中止卸载
          AppLogger.warning('[AppUninstall] killApp 失败: ${running.appId}');
          if (context.mounted) {
            _showErrorSnackBar(
              context,
              '无法停止应用，卸载已取消',
            );
          }
          return false;
        }
      }
    }

    // 4. 执行卸载
    try {
      final repo = _ref.read(linglongCliRepositoryProvider);
      await repo.uninstallApp(app.appId, app.version);

      // 5. 卸载成功，刷新状态
      _ref
          .read(installedAppsProvider.notifier)
          .removeApp(app.appId, app.version);
      _ref.read(updateAppsProvider.notifier).checkUpdates();

      // 6. 上报卸载统计记录（fire-and-forget）
      _reportUninstall(app);

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
  void _reportUninstall(InstalledApp app) {
    try {
      _ref
          .read(analyticsRepositoryProvider)
          .reportUninstall(app.appId, app.version, appName: app.name);
    } catch (e) {
      AppLogger.warning('[AppUninstall] 上报卸载统计失败: $e');
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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