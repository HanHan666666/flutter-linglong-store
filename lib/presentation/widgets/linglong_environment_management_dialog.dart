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
              tooltip: l10n.refresh,
              onPressed: state.isBusy
                  ? null
                  : () => ref
                        .read(linglongEnvironmentManagementProvider.notifier)
                        .load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        content: SizedBox(
          width: 760,
          height: 560,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.health_and_safety_outlined),
                    text: '环境分析',
                  ),
                  Tab(icon: Icon(Icons.hub_outlined), text: '仓库管理'),
                  Tab(icon: Icon(Icons.storage_outlined), text: '保存位置'),
                ],
              ),
              const SizedBox(height: 12),
              // 警示横幅：该功能尚不稳定，需提示用户无问题勿用、遇问题谨慎操作。
              // 横贯三个 Tab 顶部，使用 amber 警告色保证醒目；深色主题下用半透明 amber 适配。
              _EnvManagementWarningBanner(text: l10n.envManagementWarning),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  children: [
                    TabBarView(
                      children: [
                        _EnvironmentAnalysisTab(
                          state: state,
                          onRepairOstree: _confirmAndRepairOstree,
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

  Future<void> _confirmAndRepairOstree() async {
    final confirmed = await _showConfirmDialog(
      title: '修复 OSTree 仓库',
      content: '将以管理员权限执行 OSTree 完整性修复，并删除损坏对象。是否继续？',
      confirmText: '执行修复',
    );
    if (!confirmed || !mounted) return;

    final result = await ref
        .read(linglongEnvironmentManagementProvider.notifier)
        .repairOstreeRepository();
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
    required this.onOpenStorageTab,
    required this.onOpenLogDirectory,
  });

  final LinglongEnvironmentManagementState state;
  final VoidCallback onRepairOstree;
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
            message: '玲珑基础环境、仓库与本地 OSTree 仓库当前状态正常。',
          )
        else
          ...issues.map(
            (issue) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IssueTile(
                issue: issue,
                onRepairOstree: onRepairOstree,
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
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
          icon: analysis.ostree.isOk
              ? Icons.verified_outlined
              : Icons.report_problem_outlined,
          label: 'OSTree',
          value: analysis.ostree.isOk ? '正常' : '异常',
          color: analysis.ostree.isOk ? AppColors.success : AppColors.warning,
        ),
        _MetricChip(
          icon: Icons.storage_outlined,
          label: '保存位置',
          value: storage.usagePercent == null
              ? '未知'
              : '使用率 ${storage.usagePercent}%',
          color: storage.isNearlyFull ? AppColors.warning : AppColors.info,
        ),
      ],
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
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: context.appFontWeight(FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({
    required this.issue,
    required this.onRepairOstree,
    required this.onOpenStorageTab,
  });

  final LinglongEnvironmentIssue issue;
  final VoidCallback onRepairOstree;
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
                      const Chip(
                        label: Text('默认'),
                        visualDensity: VisualDensity.compact,
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
/// 设计原因：该功能涉及 OSTree 修复、保存位置迁移等高危操作，当前尚不稳定，
/// 需在弹窗显眼位置统一提示用户「无问题勿用、遇问题谨慎操作」，
/// 避免用户在不知风险的情况下随意触发高危流程。
/// 横幅使用 amber 警告色保证醒目，并适配深色主题。
class _EnvManagementWarningBanner extends StatelessWidget {
  const _EnvManagementWarningBanner({required this.text});

  /// 警示文案，由调用方通过 l10n 传入，保证多语言正确。
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 浅色用 amber.shade50 背景 + amber.shade800 图标/边框；
    // 深色用半透明 amber 适配，避免在深色背景上过亮刺眼。
    final backgroundColor = isDark
        ? Colors.amber.withValues(alpha: 0.15)
        : Colors.amber.shade50;
    final accentColor = isDark ? Colors.amber.shade300 : Colors.amber.shade800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        // 用与图标同色的细边框增强警示感，但不过分抢眼
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 装饰性警示图标，排除语义避免屏幕阅读器重复朗读无意义内容
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 1),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: accentColor,
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
