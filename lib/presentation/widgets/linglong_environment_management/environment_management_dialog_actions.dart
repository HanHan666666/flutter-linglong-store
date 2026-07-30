/// 玲珑环境管理对话框的交互编排。
///
/// 该文件集中处理确认弹窗、仓库输入表单、Provider 命令和用户反馈。控制器不保存
/// `BuildContext`，每次异步流程都校验本次调用上下文是否仍挂载。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../../application/providers/linglong_environment_management_provider.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/platform/local_path_opener.dart';
import '../../../core/utils/app_notification_helpers.dart';
import '../../../domain/models/linglong_env_check_result.dart';
import '../../../domain/models/linglong_environment_management.dart';
import 'environment_management_components.dart';

/// 编排环境管理对话框中的用户交互和 Provider 用例调用。
class LinglongEnvironmentManagementActions {
  /// 创建对话框交互控制器。
  ///
  /// [ref] 只用于读取既有 Provider；控制器不持有业务状态，也不直接执行系统命令。
  const LinglongEnvironmentManagementActions(this.ref);

  /// 当前对话框所属的 Riverpod 引用。
  final WidgetRef ref;

  /// 二次确认后修复玲珑本地数据并展示结果。
  Future<void> confirmAndRepairOstree(BuildContext context) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: '修复玲珑本地数据',
      content:
          '将以管理员权限尝试修复玲珑本地数据；'
          '如果检测到需要重新拉取的应用或基础环境数据，可能产生下载并耗时较长。是否继续？',
      confirmText: '执行修复',
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(linglongEnvironmentManagementProvider.notifier)
        .repairOstreeRepository();
    if (!context.mounted) return;
    _showRepairResult(context, result);
  }

  /// 二次确认后修复玲珑数据目录属主和写权限。
  Future<void> confirmAndRepairDataPermissions(BuildContext context) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: '修复玲珑数据目录权限',
      content:
          '将以管理员权限把 $linglongEnvironmentRootPath 的关键目录和状态文件属主恢复为 '
          'deepin-linglong:deepin-linglong，并重启玲珑 package-manager。是否继续？',
      confirmText: '修复权限',
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(linglongEnvironmentManagementProvider.notifier)
        .repairLinglongDataPermissions();
    if (!context.mounted) return;
    _showRepairResult(context, result);
  }

  /// 二次确认后按输入控制器中的目标路径移动玲珑保存位置。
  Future<void> confirmAndMoveStorage(
    BuildContext context,
    TextEditingController targetController,
  ) async {
    final targetPath = targetController.text.trim();
    final confirmed = await _showConfirmDialog(
      context,
      title: '移动玲珑保存位置',
      content:
          '将复制 $linglongEnvironmentRootPath 到 $targetPath，并创建 systemd bind mount。请确认目标分区空间充足。',
      confirmText: '开始移动',
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(linglongEnvironmentManagementProvider.notifier)
        .moveLinglongStorage(targetPath);
    if (!context.mounted) return;
    _showRepairResult(context, result);
  }

  /// 展示仓库新增表单并提交有效输入。
  Future<void> showAddRepositoryDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final aliasController = TextEditingController();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('添加玲珑仓库'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '仓库名称'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(labelText: '仓库地址'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: aliasController,
                    decoration: const InputDecoration(labelText: '别名（可选）'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('添加'),
              ),
            ],
          );
        },
      );
      if (submitted != true || !context.mounted) return;

      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .addRepository(
            name: nameController.text.trim(),
            url: urlController.text.trim(),
            alias: aliasController.text.trim().isEmpty
                ? null
                : aliasController.text.trim(),
          );
      if (context.mounted) showAppSuccess(context, '仓库已添加');
    } catch (error) {
      if (context.mounted) showAppError(context, '添加仓库失败：$error');
    } finally {
      nameController.dispose();
      urlController.dispose();
      aliasController.dispose();
    }
  }

  /// 展示仓库地址修改表单并提交。
  Future<void> showUpdateRepositoryDialog(
    BuildContext context,
    LinglongRepoInfo repo,
  ) async {
    final urlController = TextEditingController(text: repo.url);
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('修改仓库地址：${linglongRepositoryDisplayName(repo)}'),
            content: SizedBox(
              width: 460,
              child: TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: '仓库地址'),
                autofocus: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
      if (submitted != true || !context.mounted) return;

      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .updateRepository(
            aliasOrName: linglongRepositoryDisplayName(repo),
            url: urlController.text.trim(),
          );
      if (context.mounted) showAppSuccess(context, '仓库已更新');
    } catch (error) {
      if (context.mounted) showAppError(context, '更新仓库失败：$error');
    } finally {
      urlController.dispose();
    }
  }

  /// 展示仓库优先级输入表单并校验数字格式。
  Future<void> showPriorityDialog(
    BuildContext context,
    LinglongRepoInfo repo,
  ) async {
    final priorityController = TextEditingController(
      text: repo.priority ?? '0',
    );
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('设置优先级：${linglongRepositoryDisplayName(repo)}'),
            content: SizedBox(
              width: 320,
              child: TextField(
                controller: priorityController,
                decoration: const InputDecoration(labelText: '优先级'),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
      if (submitted != true || !context.mounted) return;

      final priority = int.tryParse(priorityController.text.trim());
      if (priority == null) {
        showAppError(context, '优先级必须是数字');
        return;
      }
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .setRepositoryPriority(linglongRepositoryDisplayName(repo), priority);
      if (context.mounted) showAppSuccess(context, '优先级已更新');
    } catch (error) {
      if (context.mounted) showAppError(context, '设置优先级失败：$error');
    } finally {
      priorityController.dispose();
    }
  }

  /// 二次确认后删除指定仓库。
  Future<void> confirmAndRemoveRepository(
    BuildContext context,
    LinglongRepoInfo repo,
  ) async {
    final displayName = linglongRepositoryDisplayName(repo);
    final confirmed = await _showConfirmDialog(
      context,
      title: '删除仓库',
      content: '确定删除仓库 $displayName 吗？',
      confirmText: '删除',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .removeRepository(displayName);
      if (context.mounted) showAppSuccess(context, '仓库已删除');
    } catch (error) {
      if (context.mounted) showAppError(context, '删除仓库失败：$error');
    }
  }

  /// 把指定仓库设置为默认仓库并展示操作反馈。
  Future<void> setDefaultRepository(
    BuildContext context,
    LinglongRepoInfo repo,
  ) async {
    try {
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .setDefaultRepository(linglongRepositoryDisplayName(repo));
      if (context.mounted) showAppSuccess(context, '默认仓库已更新');
    } catch (error) {
      if (context.mounted) showAppError(context, '设置默认仓库失败：$error');
    }
  }

  /// 修改指定仓库的镜像开关并展示操作反馈。
  Future<void> setRepositoryMirror(
    BuildContext context,
    LinglongRepoInfo repo, {
    required bool enabled,
  }) async {
    try {
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .setRepositoryMirror(
            linglongRepositoryDisplayName(repo),
            enabled: enabled,
          );
      if (context.mounted) {
        showAppSuccess(context, enabled ? '镜像已启用' : '镜像已禁用');
      }
    } catch (error) {
      if (context.mounted) showAppError(context, '修改镜像状态失败：$error');
    }
  }

  /// 通过平台路径打开器打开完整日志所在目录。
  Future<void> openLogDirectory(
    BuildContext context,
    String logFilePath,
  ) async {
    final success = await ref
        .read(localPathOpenerProvider)
        .openDirectory(path.dirname(logFilePath));
    if (!context.mounted) return;
    if (!success) {
      showAppError(context, '打开日志目录失败');
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  void _showRepairResult(
    BuildContext context,
    LinglongEnvironmentRepairResult result,
  ) {
    if (result.success) {
      showAppSuccess(context, result.message);
    } else {
      showAppError(context, result.message);
    }
  }
}
