/// 玲珑保存位置管理区域。
///
/// 该文件只展示当前路径、迁移说明和输入控件，通过外部回调发起迁移，
/// 不直接读取 Provider 或执行文件系统操作。
library;

import 'package:flutter/material.dart';

import '../../../application/providers/linglong_environment_management_provider.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/linglong_environment_management.dart';
import 'environment_management_components.dart';

/// 展示玲珑保存位置状态和迁移入口。
class StorageManagementTab extends StatelessWidget {
  /// 创建保存位置管理区域。
  const StorageManagementTab({
    required this.state,
    required this.targetController,
    required this.onMoveStorage,
    required this.onOpenLogDirectory,
    super.key,
  });

  /// 当前环境管理状态。
  final LinglongEnvironmentManagementState state;

  /// 由对话框壳持有的迁移目标输入控制器。
  final TextEditingController targetController;

  /// 二次确认并发起迁移的回调。
  final VoidCallback onMoveStorage;

  /// 打开完整日志目录的回调。
  final ValueChanged<String> onOpenLogDirectory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analysis = state.analysis;
    final storage = analysis?.storage;

    return ListView(
      children: [
        EnvironmentManagementInfoPanel(
          icon: Icons.folder_copy_outlined,
          title: l10n.envCurrentStorageLocation,
          message: storage == null
              ? l10n.envStorageNotAnalyzed
              : storage.usagePercent == null
              ? storage.rootPath
              : l10n.envStorageSummary(storage.rootPath, storage.usagePercent!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: targetController,
          enabled: !state.isBusy,
          decoration: InputDecoration(
            labelText: l10n.envNewStorageLocation,
            prefixIcon: const Icon(Icons.folder_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        EnvironmentManagementInfoPanel(
          icon: Icons.info_outline,
          title: l10n.envStorageMoveMethod,
          message: l10n.envStorageMoveMethodDescription(
            linglongEnvironmentRootPath,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: state.isBusy || analysis?.canMoveStorage == false
              ? null
              : onMoveStorage,
          icon: const Icon(Icons.drive_file_move_outline, size: 18),
          label: Text(l10n.envMoveStorageAction),
        ),
        if (analysis?.runningAppCount case final count? when count > 0) ...[
          const SizedBox(height: 12),
          EnvironmentManagementInfoPanel(
            icon: Icons.warning_amber_rounded,
            title: l10n.envCloseAppsBeforeMoveTitle,
            message: l10n.envCloseAppsBeforeMoveMessage(count),
            warning: true,
          ),
        ],
        if (state.repairResult?.action ==
                LinglongEnvironmentRepairAction.moveStorageRoot &&
            state.repairResult?.logFilePath != null) ...[
          const SizedBox(height: 12),
          EnvironmentManagementRepairResultPanel(
            result: state.repairResult!,
            onOpenLogDirectory: onOpenLogDirectory,
          ),
        ],
      ],
    );
  }
}
