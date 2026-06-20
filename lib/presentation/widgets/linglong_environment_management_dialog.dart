import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../application/providers/linglong_environment_management_provider.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/platform/local_path_opener.dart';
import '../../core/utils/app_notification_helpers.dart';
import '../../domain/models/linglong_env_check_result.dart';
import '../../domain/models/linglong_environment_management.dart';

Future<void> showLinglongEnvironmentManagementDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const LinglongEnvironmentManagementDialog(),
  );
}

class LinglongEnvironmentManagementDialog extends ConsumerStatefulWidget {
  const LinglongEnvironmentManagementDialog({super.key});

  @override
  ConsumerState<LinglongEnvironmentManagementDialog> createState() =>
      _LinglongEnvironmentManagementDialogState();
}

class _LinglongEnvironmentManagementDialogState
    extends ConsumerState<LinglongEnvironmentManagementDialog> {
  final _storageTargetController = TextEditingController(
    text: '/data/linglong',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(linglongEnvironmentManagementProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _storageTargetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(linglongEnvironmentManagementProvider);
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            const Icon(Icons.settings_suggest_outlined, size: 24),
            const SizedBox(width: 10),
            const Expanded(child: Text('玲珑环境管理')),
            IconButton(
              tooltip: l10n.close,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          width: 760,
          height: 560,
          child: Column(
            children: [
              // 警示横幅：该功能尚不稳定，需提示用户无问题勿用、遇问题谨慎操作。
              // 放置在标题与 TabBar 之间，红色强烈警告，横贯三个 Tab 共享。
              _EnvManagementWarningBanner(text: l10n.envManagementWarning),
              const SizedBox(height: 12),
              // 分段式胶囊 TabBar：复用 DefaultTabController，保持与 TabBarView 联动。
              // 选中项填主题色 + 白字，比默认 Material 下划线 TabBar 更精致、更桌面感。
              _SegmentedTabBar(
                isBusy: state.isBusy,
                onRefresh: () => ref
                    .read(linglongEnvironmentManagementProvider.notifier)
                    .load(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  children: [
                    TabBarView(
                      children: [
                        _EnvironmentAnalysisTab(
                          state: state,
                          onRepairOstree: _confirmAndRepairOstree,
                          onRepairDataPermissions:
                              _confirmAndRepairDataPermissions,
                          onOpenStorageTab: () {
                            DefaultTabController.of(context).animateTo(2);
                          },
                          onOpenLogDirectory: _openLogDirectory,
                        ),
                        _RepositoryManagementTab(
                          state: state,
                          onAddRepository: _showAddRepositoryDialog,
                          onUpdateRepository: _showUpdateRepositoryDialog,
                          onRemoveRepository: _confirmAndRemoveRepository,
                          onSetDefaultRepository: _setDefaultRepository,
                          onSetPriority: _showPriorityDialog,
                          onSetMirror: _setRepositoryMirror,
                        ),
                        _StorageManagementTab(
                          state: state,
                          targetController: _storageTargetController,
                          onMoveStorage: _confirmAndMoveStorage,
                          onOpenLogDirectory: _openLogDirectory,
                        ),
                      ],
                    ),
                    if (state.status ==
                        LinglongEnvironmentManagementStatus.loading)
                      const _BlockingProgressOverlay(message: '正在分析玲珑环境...'),
                    if (state.status ==
                        LinglongEnvironmentManagementStatus.applying)
                      const _BlockingProgressOverlay(message: '正在执行操作...'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// 二次确认后执行玲珑本地数据修复与必要的受影响 ref 重拉。
  ///
  /// 该动作内部可能触发底层对象清理和重新拉取，但用户侧只表达 linyaps
  /// 本地数据修复语义，避免把存储实现细节暴露成主健康模型。
  Future<void> _confirmAndRepairOstree() async {
    final confirmed = await _showConfirmDialog(
      title: '修复玲珑本地数据',
      content:
          '将以管理员权限尝试修复玲珑本地数据；'
          '如果检测到需要重新拉取的应用或基础环境数据，可能产生下载并耗时较长。是否继续？',
      confirmText: '执行修复',
    );
    if (!confirmed || !mounted) return;

    final result = await ref
        .read(linglongEnvironmentManagementProvider.notifier)
        .repairOstreeRepository();
    if (!mounted) return;
    _showRepairResult(result);
  }

  /// 二次确认后修复玲珑数据目录权限。
  ///
  /// 权限修复会改变系统数据目录属主并重启 package-manager，所以必须与本地数据修复一样
  /// 经由用户显式确认，且只通过环境管理 Provider 触发服务层脚本。
  Future<void> _confirmAndRepairDataPermissions() async {
    final confirmed = await _showConfirmDialog(
      title: '修复玲珑数据目录权限',
      content:
          '将以管理员权限把 $_kLinglongRootPath 的关键目录和状态文件属主恢复为 '
          'deepin-linglong:deepin-linglong，并重启玲珑 package-manager。是否继续？',
      confirmText: '修复权限',
    );
    if (!confirmed || !mounted) return;

    final result = await ref
        .read(linglongEnvironmentManagementProvider.notifier)
        .repairLinglongDataPermissions();
    if (!mounted) return;
    _showRepairResult(result);
  }

  Future<void> _confirmAndMoveStorage() async {
    final targetPath = _storageTargetController.text.trim();
    final confirmed = await _showConfirmDialog(
      title: '移动玲珑保存位置',
      content:
          '将复制 $_kLinglongRootPath 到 $targetPath，并创建 systemd bind mount。请确认目标分区空间充足。',
      confirmText: '开始移动',
    );
    if (!confirmed || !mounted) return;

    final result = await ref
        .read(linglongEnvironmentManagementProvider.notifier)
        .moveLinglongStorage(targetPath);
    if (!mounted) return;
    _showRepairResult(result);
  }

  Future<void> _showAddRepositoryDialog() async {
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
      if (submitted != true || !mounted) return;

      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .addRepository(
            name: nameController.text.trim(),
            url: urlController.text.trim(),
            alias: aliasController.text.trim().isEmpty
                ? null
                : aliasController.text.trim(),
          );
      if (mounted) showAppSuccess(context, '仓库已添加');
    } catch (error) {
      if (mounted) showAppError(context, '添加仓库失败：$error');
    } finally {
      nameController.dispose();
      urlController.dispose();
      aliasController.dispose();
    }
  }

  Future<void> _showUpdateRepositoryDialog(LinglongRepoInfo repo) async {
    final urlController = TextEditingController(text: repo.url);
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('修改仓库地址：${repo.aliasOrName}'),
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
      if (submitted != true || !mounted) return;

      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .updateRepository(
            aliasOrName: repo.aliasOrName,
            url: urlController.text.trim(),
          );
      if (mounted) showAppSuccess(context, '仓库已更新');
    } catch (error) {
      if (mounted) showAppError(context, '更新仓库失败：$error');
    } finally {
      urlController.dispose();
    }
  }

  Future<void> _showPriorityDialog(LinglongRepoInfo repo) async {
    final priorityController = TextEditingController(
      text: repo.priority ?? '0',
    );
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('设置优先级：${repo.aliasOrName}'),
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
      if (submitted != true || !mounted) return;

      final priority = int.tryParse(priorityController.text.trim());
      if (priority == null) {
        showAppError(context, '优先级必须是数字');
        return;
      }
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .setRepositoryPriority(repo.aliasOrName, priority);
      if (mounted) showAppSuccess(context, '优先级已更新');
    } catch (error) {
      if (mounted) showAppError(context, '设置优先级失败：$error');
    } finally {
      priorityController.dispose();
    }
  }

  Future<void> _confirmAndRemoveRepository(LinglongRepoInfo repo) async {
    final confirmed = await _showConfirmDialog(
      title: '删除仓库',
      content: '确定删除仓库 ${repo.aliasOrName} 吗？',
      confirmText: '删除',
    );
    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .removeRepository(repo.aliasOrName);
      if (mounted) showAppSuccess(context, '仓库已删除');
    } catch (error) {
      if (mounted) showAppError(context, '删除仓库失败：$error');
    }
  }

  Future<void> _setDefaultRepository(LinglongRepoInfo repo) async {
    try {
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .setDefaultRepository(repo.aliasOrName);
      if (mounted) showAppSuccess(context, '默认仓库已更新');
    } catch (error) {
      if (mounted) showAppError(context, '设置默认仓库失败：$error');
    }
  }

  Future<void> _setRepositoryMirror(
    LinglongRepoInfo repo, {
    required bool enabled,
  }) async {
    try {
      await ref
          .read(linglongEnvironmentManagementProvider.notifier)
          .setRepositoryMirror(repo.aliasOrName, enabled: enabled);
      if (mounted) showAppSuccess(context, enabled ? '镜像已启用' : '镜像已禁用');
    } catch (error) {
      if (mounted) showAppError(context, '修改镜像状态失败：$error');
    }
  }

  Future<bool> _showConfirmDialog({
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

  void _showRepairResult(LinglongEnvironmentRepairResult result) {
    if (result.success) {
      showAppSuccess(context, result.message);
    } else {
      showAppError(context, result.message);
    }
  }

  Future<void> _openLogDirectory(String logFilePath) async {
    final success = await ref
        .read(localPathOpenerProvider)
        .openDirectory(path.dirname(logFilePath));
    if (!mounted) return;
    if (!success) {
      showAppError(context, '打开日志目录失败');
    }
  }
}

class _EnvironmentAnalysisTab extends StatelessWidget {
  const _EnvironmentAnalysisTab({
    required this.state,
    required this.onRepairOstree,
    required this.onRepairDataPermissions,
    required this.onOpenStorageTab,
    required this.onOpenLogDirectory,
  });

  final LinglongEnvironmentManagementState state;
  final VoidCallback onRepairOstree;
  final VoidCallback onRepairDataPermissions;
  final VoidCallback onOpenStorageTab;
  final ValueChanged<String> onOpenLogDirectory;

  @override
  Widget build(BuildContext context) {
    final analysis = state.analysis;
    if (analysis == null) {
      return _EmptyManagementState(
        icon: Icons.manage_search,
        title: state.errorMessage ?? '尚未完成环境分析',
      );
    }

    final issues = analysis.issues;
    return ListView(
      children: [
        _StatusSummary(analysis: analysis),
        const SizedBox(height: 12),
        if (issues.isEmpty)
          const _InlineInfoPanel(
            icon: Icons.check_circle_outline,
            title: '未发现需要处理的问题',
            message: '玲珑基础环境、仓库与本地数据当前状态正常。',
          )
        else
          ...issues.map(
            (issue) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IssueTile(
                issue: issue,
                onRepairOstree: onRepairOstree,
                onRepairDataPermissions: onRepairDataPermissions,
                onOpenStorageTab: onOpenStorageTab,
              ),
            ),
          ),
        if (state.repairResult != null) ...[
          const SizedBox(height: 4),
          _RepairResultPanel(
            result: state.repairResult!,
            onOpenLogDirectory: onOpenLogDirectory,
          ),
        ],
      ],
    );
  }
}

class _RepositoryManagementTab extends StatelessWidget {
  const _RepositoryManagementTab({
    required this.state,
    required this.onAddRepository,
    required this.onUpdateRepository,
    required this.onRemoveRepository,
    required this.onSetDefaultRepository,
    required this.onSetPriority,
    required this.onSetMirror,
  });

  final LinglongEnvironmentManagementState state;
  final VoidCallback onAddRepository;
  final ValueChanged<LinglongRepoInfo> onUpdateRepository;
  final ValueChanged<LinglongRepoInfo> onRemoveRepository;
  final ValueChanged<LinglongRepoInfo> onSetDefaultRepository;
  final ValueChanged<LinglongRepoInfo> onSetPriority;
  final void Function(LinglongRepoInfo repo, {required bool enabled})
  onSetMirror;

  @override
  Widget build(BuildContext context) {
    final config = state.repositoryConfig;
    if (config == null) {
      return _EmptyManagementState(
        icon: Icons.hub_outlined,
        title: state.errorMessage ?? '尚未加载仓库配置',
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '默认仓库：${config.defaultRepo ?? '未设置'}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: context.appFontWeight(FontWeight.w600),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: state.isBusy ? null : onAddRepository,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加仓库'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 仓库管理说明提示：本商店仅能获取官方 stable 仓库数据，删除 stable 会导致无法安装应用。
        // 采用中性 primary 主题色（普通信息面板，非警告），避免与弹窗顶部的 amber 警示横幅重复施压。
        _InlineInfoPanel(
          icon: Icons.info_outline,
          title: AppLocalizations.of(context)!.repoManagementHintTitle,
          message: AppLocalizations.of(context)!.repoManagementHintMessage,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: config.repos.isEmpty
              ? const _EmptyManagementState(
                  icon: Icons.hub_outlined,
                  title: '暂无仓库配置',
                )
              : ListView.separated(
                  itemCount: config.repos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final repo = config.repos[index];
                    final isDefault =
                        repo.name == config.defaultRepo ||
                        repo.alias == config.defaultRepo;
                    return _RepositoryTile(
                      repo: repo,
                      isDefault: isDefault,
                      isBusy: state.isBusy,
                      onUpdateRepository: onUpdateRepository,
                      onRemoveRepository: onRemoveRepository,
                      onSetDefaultRepository: onSetDefaultRepository,
                      onSetPriority: onSetPriority,
                      onSetMirror: onSetMirror,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StorageManagementTab extends StatelessWidget {
  const _StorageManagementTab({
    required this.state,
    required this.targetController,
    required this.onMoveStorage,
    required this.onOpenLogDirectory,
  });

  final LinglongEnvironmentManagementState state;
  final TextEditingController targetController;
  final VoidCallback onMoveStorage;
  final ValueChanged<String> onOpenLogDirectory;

  @override
  Widget build(BuildContext context) {
    final analysis = state.analysis;
    final storage = analysis?.storage;

    return ListView(
      children: [
        _InlineInfoPanel(
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
        const _InlineInfoPanel(
          icon: Icons.info_outline,
          title: '移动方式',
          message:
              '玲珑当前不支持直接改安装目录。这里会复制数据后创建 systemd bind mount，将新目录挂载到 $_kLinglongRootPath。',
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
          _InlineInfoPanel(
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
          _RepairResultPanel(
            result: state.repairResult!,
            onOpenLogDirectory: onOpenLogDirectory,
          ),
        ],
      ],
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.analysis});

  final LinglongEnvironmentAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final env = analysis.envResult;
    final storage = analysis.storage;
    final theme = Theme.of(context);

    // 状态指标卡片。固定一行四列等宽布局，避免 Wrap 在内容不足时让单卡占满整行。
    final chips = <_MetricChip>[
      _MetricChip(
        icon: env.isOk ? Icons.check_circle_outline : Icons.error_outline,
        label: '基础环境',
        value: env.statusDescription,
        color: env.isOk ? AppColors.success : AppColors.warning,
      ),
      _MetricChip(
        icon: Icons.terminal_outlined,
        label: 'll-cli',
        value: env.llCliVersion ?? '未检测到',
        color: theme.colorScheme.primary,
      ),
      _MetricChip(
        icon: Icons.hub_outlined,
        label: '仓库',
        value: _repoStatusLabel(env.repoStatus),
        color: theme.colorScheme.secondary,
      ),
      _MetricChip(
        icon: _localDataMetricIcon(analysis.ostree),
        label: '本地数据',
        value: _localDataMetricValue(analysis.ostree),
        color: _localDataMetricColor(analysis.ostree),
      ),
      _MetricChip(
        icon: Icons.storage_outlined,
        label: '保存位置',
        value: storage.usagePercent == null
            ? '未知'
            : '使用率 ${storage.usagePercent}%',
        color: storage.isNearlyFull ? AppColors.warning : AppColors.info,
      ),
    ];

    const columns = 4;
    const spacing = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        // 单元格固定宽度：总宽减去列间距后均分，保证每行严格四列、等宽。
        // 不足一行时剩余位置留空，最后一个卡片不会独占整行。
        final cellWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final rows = <Widget>[];
        for (var i = 0; i < chips.length; i += columns) {
          final rowChildren = <Widget>[];
          for (var j = 0; j < columns; j++) {
            final index = i + j;
            if (j > 0) rowChildren.add(const SizedBox(width: spacing));
            rowChildren.add(
              SizedBox(
                width: cellWidth,
                child: index < chips.length ? chips[index] : const SizedBox(),
              ),
            );
          }
          rows.add(Row(children: rowChildren));
          if (i + columns < chips.length) {
            rows.add(const SizedBox(height: spacing));
          }
        }
        return Column(children: rows);
      },
    );
  }

  static String _repoStatusLabel(RepoStatus status) {
    return switch (status) {
      RepoStatus.ok => '正常',
      RepoStatus.notConfigured => '未配置',
      RepoStatus.misconfigured => '配置异常',
      RepoStatus.unavailable => '不可用',
      RepoStatus.unknown => '未知',
    };
  }

  /// 根据服务层给出的 linyaps 本地数据状态展示指标文案。
  ///
  /// 这里刻意不展示底层存储实现细节；默认健康模型只表达 linyaps
  /// 能否读取本地数据，不把深度审计结果作为用户侧主状态。
  static String _localDataMetricValue(LinglongOstreeCheckResult ostree) {
    if (!ostree.isAvailable) {
      return '检测失败';
    }
    if (!ostree.isOk) {
      return '不可用';
    }
    return '正常';
  }

  /// 为本地数据指标选择状态图标，保持与文案语义一致。
  static IconData _localDataMetricIcon(LinglongOstreeCheckResult ostree) {
    if (ostree.isOk) {
      return Icons.verified_outlined;
    }
    if (!ostree.isAvailable) {
      return Icons.report_problem_outlined;
    }
    return Icons.error_outline;
  }

  /// 为本地数据指标选择状态颜色，区分检测失败和运行路径不可用。
  static Color _localDataMetricColor(LinglongOstreeCheckResult ostree) {
    if (ostree.isOk) {
      return AppColors.success;
    }
    if (!ostree.isOk && ostree.isAvailable) {
      return AppColors.error;
    }
    return AppColors.warning;
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      // 卡片宽度由父级（_StatusSummary 的等宽网格）精确控制，不设内部宽度约束
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // 卡片用 surface 色保持中性，状态含义统一交给左侧色条与图标色表达
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧 4px 状态色条，强化指标的状态语义
            VerticalDivider(
              width: 4,
              thickness: 4,
              color: color,
              indent: 2,
              endIndent: 2,
            ),
            const SizedBox(width: 10),
            // 图标置于淡色圆形背景内，提升精致度与状态辨识
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: context.appFontWeight(FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({
    required this.issue,
    required this.onRepairOstree,
    required this.onRepairDataPermissions,
    required this.onOpenStorageTab,
  });

  final LinglongEnvironmentIssue issue;
  final VoidCallback onRepairOstree;
  final VoidCallback onRepairDataPermissions;
  final VoidCallback onOpenStorageTab;

  @override
  Widget build(BuildContext context) {
    final color = issue.severity == LinglongEnvironmentIssueSeverity.error
        ? AppColors.error
        : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.report_problem_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: context.appFontWeight(FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Text(issue.description),
                if (issue.rawDetail != null &&
                    issue.rawDetail!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SelectableText(
                    issue.rawDetail!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (issue.repairAction ==
              LinglongEnvironmentRepairAction.ostreeFsckDelete)
            FilledButton.tonal(
              onPressed: onRepairOstree,
              child: const Text('修复'),
            )
          else if (issue.repairAction ==
              LinglongEnvironmentRepairAction.fixDataPermissions)
            FilledButton.tonal(
              onPressed: onRepairDataPermissions,
              child: const Text('修复'),
            )
          else if (issue.repairAction ==
              LinglongEnvironmentRepairAction.moveStorageRoot)
            FilledButton.tonal(
              onPressed: onOpenStorageTab,
              child: const Text('处理'),
            ),
        ],
      ),
    );
  }
}

class _RepositoryTile extends StatelessWidget {
  const _RepositoryTile({
    required this.repo,
    required this.isDefault,
    required this.isBusy,
    required this.onUpdateRepository,
    required this.onRemoveRepository,
    required this.onSetDefaultRepository,
    required this.onSetPriority,
    required this.onSetMirror,
  });

  final LinglongRepoInfo repo;
  final bool isDefault;
  final bool isBusy;
  final ValueChanged<LinglongRepoInfo> onUpdateRepository;
  final ValueChanged<LinglongRepoInfo> onRemoveRepository;
  final ValueChanged<LinglongRepoInfo> onSetDefaultRepository;
  final ValueChanged<LinglongRepoInfo> onSetPriority;
  final void Function(LinglongRepoInfo repo, {required bool enabled})
  onSetMirror;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            isDefault ? Icons.star_rounded : Icons.hub_outlined,
            color: isDefault
                ? AppColors.warning
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        repo.aliasOrName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: context.appFontWeight(FontWeight.w600),
                        ),
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      // 默认仓库徽章：使用 AppColors.warning 与左侧星标呼应，
                      // 12% 透明度背景 + 纯色文字，对比度明显优于默认 Chip。
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '默认',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.warning,
                                fontWeight: context.appFontWeight(
                                  FontWeight.w600,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  repo.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'name=${repo.name}  priority=${repo.priority ?? '未设置'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<_RepoAction>(
            enabled: !isBusy,
            tooltip: '仓库操作',
            onSelected: (action) {
              switch (action) {
                case _RepoAction.editUrl:
                  onUpdateRepository(repo);
                case _RepoAction.setDefault:
                  onSetDefaultRepository(repo);
                case _RepoAction.setPriority:
                  onSetPriority(repo);
                case _RepoAction.enableMirror:
                  onSetMirror(repo, enabled: true);
                case _RepoAction.disableMirror:
                  onSetMirror(repo, enabled: false);
                case _RepoAction.remove:
                  onRemoveRepository(repo);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _RepoAction.editUrl,
                child: Text('修改地址'),
              ),
              const PopupMenuItem(
                value: _RepoAction.setDefault,
                child: Text('设为默认'),
              ),
              const PopupMenuItem(
                value: _RepoAction.setPriority,
                child: Text('设置优先级'),
              ),
              const PopupMenuItem(
                value: _RepoAction.enableMirror,
                child: Text('启用镜像'),
              ),
              const PopupMenuItem(
                value: _RepoAction.disableMirror,
                child: Text('禁用镜像'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _RepoAction.remove,
                child: Text('删除仓库'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _RepoAction {
  editUrl,
  setDefault,
  setPriority,
  enableMirror,
  disableMirror,
  remove,
}

class _InlineInfoPanel extends StatelessWidget {
  const _InlineInfoPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.warning = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? AppColors.warning
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: context.appFontWeight(FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepairResultPanel extends StatelessWidget {
  const _RepairResultPanel({
    required this.result,
    required this.onOpenLogDirectory,
  });

  final LinglongEnvironmentRepairResult result;
  final ValueChanged<String> onOpenLogDirectory;

  @override
  Widget build(BuildContext context) {
    final color = result.success ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: context.appFontWeight(FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          if (result.output != null && result.output!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              result.output!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (result.logFilePath != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    result.logFilePath!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => onOpenLogDirectory(result.logFilePath!),
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('打开日志目录'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyManagementState extends StatelessWidget {
  const _EmptyManagementState({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _BlockingProgressOverlay extends StatelessWidget {
  const _BlockingProgressOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}

/// 玲珑环境管理弹窗顶部的警示横幅。
///
/// 设计原因：该功能涉及玲珑本地数据修复、保存位置迁移等高危操作，当前尚不稳定，
/// 需在弹窗显眼位置统一提示用户「无问题勿用、遇问题谨慎操作」，
/// 避免用户在不知风险的情况下随意触发高危流程。
/// 横幅采用红色强烈警告（[AppColors.error]），区别于普通提示，强调高风险性质；
/// 图标使用 error_outline 与红色语义保持一致。深色主题下用半透明红底适配。
class _EnvManagementWarningBanner extends StatelessWidget {
  const _EnvManagementWarningBanner({required this.text});

  /// 警示文案，由调用方通过 l10n 传入，保证多语言正确。
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 背景用 AppColors.error 的低透明度填充；深色主题下透明度略低避免过亮刺眼。
    final backgroundColor = AppColors.error.withValues(
      alpha: isDark ? 0.18 : 0.10,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        // 用同色边框增强警示感
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 装饰性警示图标，排除语义避免屏幕阅读器重复朗读无意义内容
          const ExcludeSemantics(
            child: Padding(
              padding: EdgeInsets.only(right: 8, top: 1),
              child: Icon(
                Icons.error_outline,
                size: 18,
                color: AppColors.error,
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              label: text,
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 玲珑环境管理弹窗的分段式胶囊 TabBar。
///
/// 设计原因：默认 Material TabBar 的下划线指示器在桌面端观感偏粗糙，
/// 改为 SegmentedControl（分段控件）风格：外层中性灰底容器，内部三个等宽胶囊，
/// 选中项填主题色 + 白字，未选中透明。整体更紧凑精致，贴合桌面系统设置的语言。
///
/// 复用上层 [DefaultTabController] 的 [TabController]，通过监听其
/// animation 实时刷新选中态，点击时调用 animateTo 切换，保持与下方
/// [TabBarView] 的联动关系不变，不引入新的状态管理。
class _SegmentedTabBar extends StatelessWidget {
  const _SegmentedTabBar({required this.isBusy, required this.onRefresh});

  final bool isBusy;
  final VoidCallback onRefresh;

  static const _tabs = <_SegmentedTabData>[
    _SegmentedTabData(icon: Icons.health_and_safety_outlined, label: '环境分析'),
    _SegmentedTabData(icon: Icons.hub_outlined, label: '仓库管理'),
    _SegmentedTabData(icon: Icons.storage_outlined, label: '保存位置'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // 中性灰底容器，作为分段控件的轨道
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final selectedIndex = controller.animation!.value.round();
          return Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _SegmentedTabItem(
                    data: _tabs[i],
                    selected: i == selectedIndex,
                    onTap: () => controller.animateTo(i),
                  ),
                ),
              const SizedBox(width: 4),
              // 刷新按钮置于分段控件右侧，三个 Tab 共享，视觉上与胶囊同高
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  tooltip: '刷新',
                  onPressed: isBusy ? null : onRefresh,
                  icon: Icon(
                    Icons.refresh,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    disabledForegroundColor: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.38),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 分段控件的单个胶囊项。
class _SegmentedTabItem extends StatelessWidget {
  const _SegmentedTabItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _SegmentedTabData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? Colors.white
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xs + 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(data.icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                Text(
                  data.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 分段控件 Tab 的静态数据。
class _SegmentedTabData {
  const _SegmentedTabData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

extension on LinglongRepoInfo {
  String get aliasOrName {
    final aliasValue = alias?.trim();
    if (aliasValue != null && aliasValue.isNotEmpty) {
      return aliasValue;
    }
    return name;
  }
}

const String _kLinglongRootPath = '/var/lib/linglong';
