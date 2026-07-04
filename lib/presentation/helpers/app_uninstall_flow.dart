import 'package:flutter/material.dart';

import '../../../application/services/app_uninstall_service.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/utils/app_notification_helpers.dart';
import '../../../domain/models/installed_app.dart';
import '../../../domain/models/uninstall_result.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/download_manager_dialog.dart';
import '../widgets/uninstall_blocked_dialog.dart';

/// 统一的卸载流程辅助类
///
/// 在 Presentation 层编排完整的卸载交互：
/// 1. 检查活跃安装/更新任务 -> 显示拦截弹窗
/// 2. 检查运行中实例 -> 显示对应的确认弹窗
/// 3. 调用 [AppUninstallService.executeUninstall] 执行
/// 4. 返回结果供调用方展示提示
class AppUninstallFlow {
  /// 执行完整卸载流程
  ///
  /// 返回 `true` 表示卸载成功，`false` 表示取消或失败。
  static Future<bool> run(
    BuildContext context,
    InstalledApp app,
    AppUninstallService service,
  ) async {
    if (!context.mounted) return false;

    // 1. 检查活跃任务拦截
    final blockingTask = service.getActiveBlockingTask();
    if (blockingTask != null) {
      final (taskName, taskId) = blockingTask;
      if (!context.mounted) return false;

      final action = await showUninstallBlockedDialog(
        context,
        activeTaskName: taskName,
        fallbackAppId: taskId,
      );

      if (!context.mounted) return false;

      if (action == UninstallBlockedAction.openDownloadManager) {
        await showDownloadManagerDialog(context);
      }

      return false;
    }

    // 2. 检查运行中实例
    final runningInstances = service.getRunningInstances(app.appId);
    final bool? confirmed;
    if (runningInstances.isNotEmpty) {
      confirmed = await ConfirmDialog.showUninstallRunning(
        context,
        appName: app.name,
      );
    } else {
      confirmed = await ConfirmDialog.showUninstall(context, appName: app.name);
    }

    if (confirmed != true || !context.mounted) return false;

    // 3. 执行卸载
    final result = await service.executeUninstall(app);

    // 4. 处理结果：成功返回 true；取消/拦截返回 false 且不提示；
    //    kill 失败或卸载异常时向前端通知中心推送错误信息。
    if (result is UninstallResultSuccess) {
      return true;
    }

    if (result is UninstallResultKillFailed && context.mounted) {
      final l10n = AppLocalizations.of(context);
      showAppError(
        context,
        l10n?.uninstallFailedWithError(l10n.appRunningMessage) ??
            '卸载失败: 无法关闭运行中的应用',
      );
      return false;
    }

    if (result is UninstallResultError && context.mounted) {
      final l10n = AppLocalizations.of(context);
      showAppError(
        context,
        l10n?.uninstallFailedWithError(result.message) ??
            '卸载失败: ${result.message}',
      );
      return false;
    }

    // 取消或拦截场景不弹错误提示
    return false;
  }
}
