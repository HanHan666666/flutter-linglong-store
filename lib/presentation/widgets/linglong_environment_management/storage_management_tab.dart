/// 玲珑保存位置管理区域。
///
/// 该文件只展示当前路径、迁移说明和输入控件，通过外部回调发起迁移，
/// 不直接读取 Provider 或执行文件系统操作。
library;

import 'package:flutter/material.dart';

import '../../../application/providers/linglong_environment_management_provider.dart';
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
    final analysis = state.analysis;
    final storage = analysis?.storage;

    return ListView(
      children: [
        EnvironmentManagementInfoPanel(
          icon: Icons.folder_copy_outlined,
          title: '当前保存位置',
          message: storage == null
              ? '尚未完成保存位置分析'
              : '${storage.rootPath}  ${storage.usagePercent == null ? '' : '使用率 ${storage.usagePercent}%'}',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: targetController,
          enabled: !state.isBusy,
          decoration: const InputDecoration(
            labelText: '新的保存位置',
            prefixIcon: Icon(Icons.folder_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const EnvironmentManagementInfoPanel(
          icon: Icons.info_outline,
          title: '移动方式',
          message:
              '玲珑当前不支持直接改安装目录。这里会复制数据后创建 systemd bind mount，将新目录挂载到 $linglongEnvironmentRootPath。',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: state.isBusy || analysis?.canMoveStorage == false
              ? null
              : onMoveStorage,
          icon: const Icon(Icons.drive_file_move_outline, size: 18),
          label: const Text('移动保存位置'),
        ),
        if (analysis?.runningAppCount case final count? when count > 0) ...[
          const SizedBox(height: 12),
          EnvironmentManagementInfoPanel(
            icon: Icons.warning_amber_rounded,
            title: '移动前需要关闭应用',
            message: '当前仍有 $count 个玲珑应用正在运行。',
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
