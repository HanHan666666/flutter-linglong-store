/// 玲珑环境管理界面的共享纯展示组件。
///
/// 该文件只承载被对话框壳或多个业务区域复用的视觉组件，不读取 Riverpod，
/// 不执行导航和系统操作，确保共享组件不会成为新的业务编排入口。
library;

import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/linglong_env_check_result.dart';
import '../../../domain/models/linglong_environment_management.dart';
import 'environment_management_localizations.dart';

/// 玲珑本地数据的固定运行根目录，仅用于现有界面说明文案。
const String linglongEnvironmentRootPath = '/var/lib/linglong';

/// 返回仓库在环境管理界面中的首选展示名称。
String linglongRepositoryDisplayName(LinglongRepoInfo repo) {
  final aliasValue = repo.alias?.trim();
  if (aliasValue != null && aliasValue.isNotEmpty) {
    return aliasValue;
  }
  return repo.name;
}

/// 展示环境管理区域中的说明或警告信息。
class EnvironmentManagementInfoPanel extends StatelessWidget {
  /// 创建说明面板。
  const EnvironmentManagementInfoPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.warning = false,
    super.key,
  });

  /// 面板图标。
  final IconData icon;

  /// 面板标题。
  final String title;

  /// 面板说明。
  final String message;

  /// 是否使用警告语义颜色。
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

/// 展示环境修复或保存位置迁移的最近一次结果。
class EnvironmentManagementRepairResultPanel extends StatelessWidget {
  /// 创建操作结果面板。
  const EnvironmentManagementRepairResultPanel({
    required this.result,
    required this.onOpenLogDirectory,
    super.key,
  });

  /// 需要展示的操作结果。
  final LinglongEnvironmentRepairResult result;

  /// 打开完整日志所在目录的回调。
  final ValueChanged<String> onOpenLogDirectory;

  @override
  Widget build(BuildContext context) {
    final color = result.success ? AppColors.success : AppColors.error;
    final l10n = AppLocalizations.of(context)!;
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
                  localizeLinglongEnvironmentRepairResult(l10n, result),
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
                  label: Text(l10n.openRepairLog),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 展示尚无环境管理数据或加载失败的空状态。
class EnvironmentManagementEmptyState extends StatelessWidget {
  /// 创建空状态。
  const EnvironmentManagementEmptyState({
    required this.icon,
    required this.title,
    super.key,
  });

  /// 空状态图标。
  final IconData icon;

  /// 空状态说明。
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

/// 在环境分析或系统变更期间阻断重复交互。
class EnvironmentManagementBlockingOverlay extends StatelessWidget {
  /// 创建阻塞进度层。
  const EnvironmentManagementBlockingOverlay({
    required this.message,
    super.key,
  });

  /// 当前操作说明。
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

/// 在环境管理弹窗顶部展示高风险操作警示。
///
/// 本功能涉及玲珑本地数据修复和保存位置迁移，警示需要跨三个 Tab 始终可见。
class EnvironmentManagementWarningBanner extends StatelessWidget {
  /// 创建警示横幅。
  const EnvironmentManagementWarningBanner({required this.text, super.key});

  /// 已本地化的警示文案。
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppColors.error.withValues(
      alpha: isDark ? 0.18 : 0.10,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: Padding(
              // 错误图标与文本间距随文本方向镜像
              padding: EdgeInsetsDirectional.only(end: 8, top: 1),
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

/// 与 [DefaultTabController] 联动的环境管理分段式 TabBar。
class EnvironmentManagementSegmentedTabBar extends StatelessWidget {
  /// 创建分段式 TabBar。
  const EnvironmentManagementSegmentedTabBar({
    required this.isBusy,
    required this.onRefresh,
    super.key,
  });

  /// 当前是否正在加载或执行变更。
  final bool isBusy;

  /// 刷新完整环境管理状态的回调。
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tabs = <_EnvironmentManagementTabData>[
      _EnvironmentManagementTabData(
        icon: Icons.health_and_safety_outlined,
        label: l10n.envManagementAnalysisTab,
      ),
      _EnvironmentManagementTabData(
        icon: Icons.hub_outlined,
        label: l10n.envManagementRepositoryTab,
      ),
      _EnvironmentManagementTabData(
        icon: Icons.storage_outlined,
        label: l10n.envManagementStorageTab,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final selectedIndex = controller.animation!.value.round();
          return Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _EnvironmentManagementTabItem(
                    data: tabs[i],
                    selected: i == selectedIndex,
                    onTap: () => controller.animateTo(i),
                  ),
                ),
              const SizedBox(width: 4),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  tooltip: l10n.refresh,
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

class _EnvironmentManagementTabItem extends StatelessWidget {
  const _EnvironmentManagementTabItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _EnvironmentManagementTabData data;
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

class _EnvironmentManagementTabData {
  const _EnvironmentManagementTabData({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
