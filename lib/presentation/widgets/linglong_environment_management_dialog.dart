/// 玲珑环境管理对话框公共入口和页面框架。
///
/// 该文件只管理对话框生命周期、单次 Provider 订阅和三个业务区域的组合。
/// 表单与确认交互集中在控制器，区域渲染位于独立无状态组件中。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/linglong_environment_management_provider.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import 'linglong_environment_management/environment_analysis_tab.dart';
import 'linglong_environment_management/environment_management_components.dart';
import 'linglong_environment_management/environment_management_dialog_actions.dart';
import 'linglong_environment_management/repository_management_tab.dart';
import 'linglong_environment_management/storage_management_tab.dart';

/// 展示玲珑环境管理模态对话框。
Future<void> showLinglongEnvironmentManagementDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const LinglongEnvironmentManagementDialog(),
  );
}

/// 玲珑环境分析、仓库和保存位置管理的统一对话框。
class LinglongEnvironmentManagementDialog extends ConsumerStatefulWidget {
  /// 创建玲珑环境管理对话框。
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
  late final LinglongEnvironmentManagementActions _actions;

  @override
  void initState() {
    super.initState();
    _actions = LinglongEnvironmentManagementActions(ref);
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
            Expanded(child: Text(l10n.envManagementTitle)),
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
              EnvironmentManagementWarningBanner(
                text: l10n.envManagementWarning,
              ),
              const SizedBox(height: 12),
              EnvironmentManagementSegmentedTabBar(
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
                        EnvironmentAnalysisTab(
                          state: state,
                          onRepairOstree: () {
                            _actions.confirmAndRepairOstree(context);
                          },
                          onRepairDataPermissions: () {
                            _actions.confirmAndRepairDataPermissions(context);
                          },
                          onOpenStorageTab: () {
                            DefaultTabController.of(context).animateTo(2);
                          },
                          onOpenLogDirectory: (logFilePath) {
                            _actions.openLogDirectory(context, logFilePath);
                          },
                        ),
                        RepositoryManagementTab(
                          state: state,
                          onAddRepository: () {
                            _actions.showAddRepositoryDialog(context);
                          },
                          onUpdateRepository: (repo) {
                            _actions.showUpdateRepositoryDialog(context, repo);
                          },
                          onRemoveRepository: (repo) {
                            _actions.confirmAndRemoveRepository(context, repo);
                          },
                          onSetDefaultRepository: (repo) {
                            _actions.setDefaultRepository(context, repo);
                          },
                          onSetPriority: (repo) {
                            _actions.showPriorityDialog(context, repo);
                          },
                          onSetMirror: (repo, {required enabled}) {
                            _actions.setRepositoryMirror(
                              context,
                              repo,
                              enabled: enabled,
                            );
                          },
                        ),
                        StorageManagementTab(
                          state: state,
                          targetController: _storageTargetController,
                          onMoveStorage: () {
                            _actions.confirmAndMoveStorage(
                              context,
                              _storageTargetController,
                            );
                          },
                          onOpenLogDirectory: (logFilePath) {
                            _actions.openLogDirectory(context, logFilePath);
                          },
                        ),
                      ],
                    ),
                    if (state.status ==
                        LinglongEnvironmentManagementStatus.loading)
                      EnvironmentManagementBlockingOverlay(
                        message: l10n.envManagementAnalyzing,
                      ),
                    if (state.status ==
                        LinglongEnvironmentManagementStatus.applying)
                      EnvironmentManagementBlockingOverlay(
                        message: l10n.envManagementApplying,
                      ),
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
}
