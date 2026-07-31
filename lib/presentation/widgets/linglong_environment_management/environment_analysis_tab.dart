/// 玲珑环境分析区域。
///
/// 该文件负责把环境分析模型渲染为指标和问题列表，只通过回调请求修复，
/// 不读取 Provider，也不直接执行任何系统操作。
library;

import 'package:flutter/material.dart';

import '../../../application/providers/linglong_environment_management_provider.dart';
import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/linglong_environment_management.dart';
import 'environment_management_components.dart';
import 'environment_management_localizations.dart';

/// 展示玲珑基础环境、本地数据和可修复问题。
class EnvironmentAnalysisTab extends StatelessWidget {
  /// 创建环境分析区域。
  const EnvironmentAnalysisTab({
    required this.state,
    required this.onRepairOstree,
    required this.onRepairDataPermissions,
    required this.onOpenStorageTab,
    required this.onOpenLogDirectory,
    super.key,
  });

  /// 当前环境管理状态。
  final LinglongEnvironmentManagementState state;

  /// 修复玲珑本地数据的回调。
  final VoidCallback onRepairOstree;

  /// 修复玲珑数据目录权限的回调。
  final VoidCallback onRepairDataPermissions;

  /// 切换到保存位置区域的回调。
  final VoidCallback onOpenStorageTab;

  /// 打开完整日志目录的回调。
  final ValueChanged<String> onOpenLogDirectory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analysis = state.analysis;
    if (analysis == null) {
      return EnvironmentManagementEmptyState(
        icon: Icons.manage_search,
        title: state.errorMessage == null
            ? l10n.envManagementNotAnalyzed
            : l10n.envResultUnexpectedFailure(state.errorMessage!),
      );
    }

    final issues = analysis.issues;
    return ListView(
      children: [
        _EnvironmentStatusSummary(analysis: analysis),
        const SizedBox(height: 12),
        if (issues.isEmpty)
          EnvironmentManagementInfoPanel(
            icon: Icons.check_circle_outline,
            title: l10n.envManagementHealthyTitle,
            message: l10n.envManagementHealthyMessage,
          )
        else
          ...issues.map(
            (issue) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EnvironmentIssueTile(
                issue: issue,
                onRepairOstree: onRepairOstree,
                onRepairDataPermissions: onRepairDataPermissions,
                onOpenStorageTab: onOpenStorageTab,
              ),
            ),
          ),
        if (state.repairResult != null) ...[
          const SizedBox(height: 4),
          EnvironmentManagementRepairResultPanel(
            result: state.repairResult!,
            onOpenLogDirectory: onOpenLogDirectory,
          ),
        ],
      ],
    );
  }
}

class _EnvironmentStatusSummary extends StatelessWidget {
  const _EnvironmentStatusSummary({required this.analysis});

  final LinglongEnvironmentAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final env = analysis.envResult;
    final storage = analysis.storage;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // 固定四列等宽布局，避免 Wrap 在最后一行让单个指标占满可用宽度。
    final chips = <_EnvironmentMetricChip>[
      _EnvironmentMetricChip(
        icon: env.isOk ? Icons.check_circle_outline : Icons.error_outline,
        label: l10n.envManagementBaseEnvironment,
        value: localizeLinglongEnvironmentStatus(l10n, env),
        color: env.isOk ? AppColors.success : AppColors.warning,
      ),
      _EnvironmentMetricChip(
        icon: Icons.terminal_outlined,
        label: 'll-cli',
        value: env.llCliVersion ?? l10n.envManagementNotDetected,
        color: theme.colorScheme.primary,
      ),
      _EnvironmentMetricChip(
        icon: Icons.hub_outlined,
        label: l10n.envManagementRepositoryMetric,
        value: localizeLinglongRepositoryStatus(l10n, env.repoStatus),
        color: theme.colorScheme.secondary,
      ),
      _EnvironmentMetricChip(
        icon: _localDataMetricIcon(analysis.ostree),
        label: l10n.envManagementLocalData,
        value: localizeLinglongLocalDataStatus(l10n, analysis.ostree),
        color: _localDataMetricColor(analysis.ostree),
      ),
      _EnvironmentMetricChip(
        icon: Icons.storage_outlined,
        label: l10n.envManagementStorageLocation,
        value: storage.usagePercent == null
            ? l10n.envManagementUnknown
            : l10n.envManagementUsagePercent(storage.usagePercent!),
        color: storage.isNearlyFull ? AppColors.warning : AppColors.info,
      ),
    ];

    const columns = 4;
    const spacing = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
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

  /// 为本地数据指标选择与状态文案一致的图标。
  static IconData _localDataMetricIcon(LinglongOstreeCheckResult localData) {
    if (localData.isOk) {
      return Icons.verified_outlined;
    }
    if (!localData.isAvailable) {
      return Icons.report_problem_outlined;
    }
    return Icons.error_outline;
  }

  /// 为本地数据指标选择颜色，区分检测失败和运行路径不可用。
  static Color _localDataMetricColor(LinglongOstreeCheckResult localData) {
    if (localData.isOk) {
      return AppColors.success;
    }
    if (localData.isAvailable) {
      return AppColors.error;
    }
    return AppColors.warning;
  }
}

class _EnvironmentMetricChip extends StatelessWidget {
  const _EnvironmentMetricChip({
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VerticalDivider(
              width: 4,
              thickness: 4,
              color: color,
              indent: 2,
              endIndent: 2,
            ),
            const SizedBox(width: 10),
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

class _EnvironmentIssueTile extends StatelessWidget {
  const _EnvironmentIssueTile({
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
    final l10n = AppLocalizations.of(context)!;
    final issueText = localizeLinglongEnvironmentIssue(l10n, issue);

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
                  issueText.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: context.appFontWeight(FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Text(issueText.description),
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
              child: Text(l10n.envRepairAction),
            )
          else if (issue.repairAction ==
              LinglongEnvironmentRepairAction.fixDataPermissions)
            FilledButton.tonal(
              onPressed: onRepairDataPermissions,
              child: Text(l10n.envRepairAction),
            )
          else if (issue.repairAction ==
              LinglongEnvironmentRepairAction.moveStorageRoot)
            FilledButton.tonal(
              onPressed: onOpenStorageTab,
              child: Text(l10n.envHandleAction),
            ),
        ],
      ),
    );
  }
}
