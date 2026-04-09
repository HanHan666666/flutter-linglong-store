import 'package:flutter/material.dart';

import '../../../application/services/app_uninstall_service.dart';
import '../../../domain/models/installed_app.dart';
import '../../../domain/models/uninstall_result.dart';
import '../../../domain/models/uninstall_blocked_action.dart';
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
      confirmed = await ConfirmDialog.showUninstall(
        context,
        appName: app.name,
      );
    }

    if (confirmed != true || !context.mounted) return false;

    // 3. 执行卸载
    final result = await service.executeUninstall(app);

    // 4. 处理结果
    return result is UninstallResultSuccess;
  }
}
