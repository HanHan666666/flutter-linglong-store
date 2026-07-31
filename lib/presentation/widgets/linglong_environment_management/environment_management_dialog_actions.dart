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
import 'environment_management_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      context,
      title: l10n.envRepairLocalDataTitle,
      content: l10n.envRepairLocalDataMessage,
      confirmText: l10n.envRepairLocalDataConfirm,
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      context,
      title: l10n.envRepairPermissionTitle,
      content: l10n.envRepairPermissionMessage(
        linglongEnvironmentRootPath,
        'deepin-linglong:deepin-linglong',
      ),
      confirmText: l10n.envRepairPermissionConfirm,
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      context,
      title: l10n.envMoveStorageTitle,
      content: l10n.envMoveStorageMessage(
        linglongEnvironmentRootPath,
        targetPath,
      ),
      confirmText: l10n.envMoveStorageConfirm,
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
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final aliasController = TextEditingController();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.envAddRepositoryTitle),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.envRepositoryName,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: l10n.envRepositoryAddress,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: aliasController,
                    decoration: InputDecoration(
                      labelText: l10n.envRepositoryAliasOptional,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.envAddAction),
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
      if (context.mounted) showAppSuccess(context, l10n.envRepositoryAdded);
    } catch (error) {
      if (context.mounted) {
        showAppError(context, l10n.envRepositoryAddFailed(error.toString()));
      }
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
    final l10n = AppLocalizations.of(context)!;
    final urlController = TextEditingController(text: repo.url);
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              l10n.envUpdateRepositoryTitle(
                linglongRepositoryDisplayName(repo),
              ),
            ),
            content: SizedBox(
              width: 460,
              child: TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: l10n.envRepositoryAddress,
                ),
                autofocus: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.envSaveAction),
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
      if (context.mounted) showAppSuccess(context, l10n.envRepositoryUpdated);
    } catch (error) {
      if (context.mounted) {
        showAppError(context, l10n.envRepositoryUpdateFailed(error.toString()));
      }
    } finally {
      urlController.dispose();
    }
  }

  /// 展示仓库优先级输入表单并校验数字格式。
  Future<void> showPriorityDialog(
    BuildContext context,
    LinglongRepoInfo repo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final priorityController = TextEditingController(
      text: repo.priority ?? '0',
    );
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              l10n.envSetPriorityTitle(linglongRepositoryDisplayName(repo)),
            ),
            content: SizedBox(
              width: 320,
              child: TextField(
                controller: priorityController,
                decoration: InputDecoration(
                  labelText: l10n.envRepositoryPriority,
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.envSaveAction),
              ),
            ],
          );
        },
      );
      if (submitted != true || !context.mounted) return;

      final priority = int.tryParse(priorityController.text.trim());
      if (priority == null) {
        showAppError(context, l10n.envPriorityMustBeNumber);
        return;
      }
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .setRepositoryPriority(linglongRepositoryDisplayName(repo), priority);
      if (context.mounted) showAppSuccess(context, l10n.envPriorityUpdated);
    } catch (error) {
      if (context.mounted) {
        showAppError(context, l10n.envPriorityUpdateFailed(error.toString()));
      }
    } finally {
      priorityController.dispose();
    }
  }

  /// 二次确认后删除指定仓库。
  Future<void> confirmAndRemoveRepository(
    BuildContext context,
    LinglongRepoInfo repo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final displayName = linglongRepositoryDisplayName(repo);
    final confirmed = await _showConfirmDialog(
      context,
      title: l10n.envRemoveRepositoryTitle,
      content: l10n.envRemoveRepositoryMessage(displayName),
      confirmText: l10n.envDeleteAction,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .removeRepository(displayName);
      if (context.mounted) showAppSuccess(context, l10n.envRepositoryRemoved);
    } catch (error) {
      if (context.mounted) {
        showAppError(context, l10n.envRepositoryRemoveFailed(error.toString()));
      }
    }
  }

  /// 把指定仓库设置为默认仓库并展示操作反馈。
  Future<void> setDefaultRepository(
    BuildContext context,
    LinglongRepoInfo repo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .setDefaultRepository(linglongRepositoryDisplayName(repo));
      if (context.mounted) {
        showAppSuccess(context, l10n.envDefaultRepositoryUpdated);
      }
    } catch (error) {
      if (context.mounted) {
        showAppError(
          context,
          l10n.envDefaultRepositoryUpdateFailed(error.toString()),
        );
      }
    }
  }

  /// 修改指定仓库的镜像开关并展示操作反馈。
  Future<void> setRepositoryMirror(
    BuildContext context,
    LinglongRepoInfo repo, {
    required bool enabled,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .setRepositoryMirror(
            linglongRepositoryDisplayName(repo),
            enabled: enabled,
          );
      if (context.mounted) {
        showAppSuccess(
          context,
          enabled ? l10n.envMirrorEnabled : l10n.envMirrorDisabled,
        );
      }
    } catch (error) {
      if (context.mounted) {
        showAppError(context, l10n.envMirrorUpdateFailed(error.toString()));
      }
    }
  }

  /// 通过平台路径打开器打开完整日志所在目录。
  Future<void> openLogDirectory(
    BuildContext context,
    String logFilePath,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await ref
        .read(localPathOpenerProvider)
        .openDirectory(path.dirname(logFilePath));
    if (!context.mounted) return;
    if (!success) {
      showAppError(context, l10n.envOpenLogDirectoryFailed);
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
    final l10n = AppLocalizations.of(context)!;
    final message = localizeLinglongEnvironmentRepairResult(l10n, result);
    if (result.success) {
      showAppSuccess(context, message);
    } else {
      showAppError(context, message);
    }
  }
}
